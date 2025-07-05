import pyddm
from pyddm import Sample
import pyddm.plot
import matplotlib.pyplot as plt
import numpy as np
import os
import sys
import pandas as pd
import re

def extract_parameters(results_file):
    """Extract parameters from a results file."""
    if not os.path.exists(results_file):
        return None, None
        
    with open(results_file, 'r') as f:
        content = f.read()
    
    # Extract loss
    loss_match = re.search(r'Loss: ([\d\.]+)', content)
    loss = float(loss_match.group(1))
    
    # Extract parameters
    params = {}
    pattern = r"'([\w_]+)': Fitted\(([\d\.\-]+), minval=([\d\.\-]+), maxval=([\d\.\-]+)\)"
    for name, value, minval, maxval in re.findall(pattern, content):
        params[name] = {
            'fitted': float(value),
            'minval': float(minval),
            'maxval': float(maxval)
        }
        
    return params, loss

def make_plots(results_dir, subdir=0, group_only=False):
    """Run both individual and group analyses using a single data read.
    
    Parameters:
        results_dir (str): Directory containing results files
        subdir (int): Whether subject results are in subdirectories
        group_only (bool): If True, only generate group plots without processing individual subjects
    """
    # Read the tidy data file once
    df = pd.read_csv('inference_all.csv')
    df = df.dropna(subset=['RT'])
    subjects = df['subID'].unique()
    subjects = subjects[subjects > 0]
    
    # Create output directories
    plots_dir = os.path.join(results_dir, "plots/")
    os.makedirs(plots_dir, exist_ok=True)
    
    # initialize group dict
    all_param_data = []
    
    # If group_only is True and a group data file exists, load it instead of processing subjects
    group_file = os.path.join(results_dir, 'all_fits.csv')     
    if group_only and os.path.exists(group_file):         
        print(f"Loading existing group data from {group_file}...")         
        param_df = pd.read_csv(group_file)         
    all_param_data = param_df.to_dict('records')
    # Add condition based on subID
    for subject in all_param_data:
        subject['condition'] = 'condition_80cue' if subject['subID'] < 55 else 'condition_65cue'
    
    # Only proceed with individual subject processing if not in group_only mode
    if not group_only:
        def start_point(trueCongruence, bias, bias50):
            if trueCongruence == 'congruent':
                return bias
            elif trueCongruence == 'incongruent':
                return -bias
            else:
                return bias50
        
    # Process each subject - only if not in group_only mode
    if not group_only:
        for subID in subjects:
            print(f"Processing subject {subID}...")
            
            # Get subject-specific data
            subject_df = df[df['subID'] == subID]
            if subject_df.empty:
                print(f"No data found for subject {subID}, skipping.")
                continue

            # Read results file
            if subdir:
                results_file = os.path.join(results_dir, f"s{subID}/s{subID}_results.txt")
            else:
                results_file = os.path.join(results_dir, f"s{subID}_results.txt")
            params, loss = extract_parameters(results_file)
            
            if params is None:
                print(f"Results file not found for subject {subID}, skipping.")
                continue
                
            # Store parameter data for group analysis
            group_params = {'subID': subID}
            # Add condition information
            group_params['condition'] = subject_df['condition'].iloc[0]
            for key, value_dict in params.items():
                group_params[key] = value_dict['fitted']
            all_param_data.append(group_params)
            
            # Extract fitted parameters for model
            fitted_params = {key: value_dict['fitted'] for key, value_dict in params.items()}
            plot_params = {k: v for k, v in fitted_params.items()}

            # Create parameter text
            param_text = f"""
            Loss: {loss:.4f}  
            Boundary (B): {params.get('B').get('fitted'):.3f} [min: {params.get('B').get('minval'):.3f}, max: {params.get('B').get('maxval'):.3f}]
            Non-decision time: fixed to 0

            Non-neutral starting point: {params.get('bias').get('fitted'):.3f} [min: {params.get('bias').get('minval'):.3f}, max: {params.get('bias').get('maxval'):.3f}]
            50% cue starting point: {params.get('bias50').get('fitted'):.3f} [min: {params.get('bias50').get('minval'):.3f}, max: {params.get('bias50').get('maxval'):.3f}]
            """
            

            # Initialize model object
            model = pyddm.gddm(
                    starting_position=start_point,
                    bound='B',
                    T_dur=4.1,
                    nondecision=0,
                    parameters=plot_params,
                    conditions=['trueCongruence'])
            
            # Create pyDDM sample object
            sample = pyddm.Sample.from_pandas_dataframe(subject_df, rt_column_name='RT', choice_column_name='accuracy')

            # Create figure
            fig = plt.figure(figsize=(12, 10))
            pyddm.plot.plot_fit_diagnostics(model, sample, fig, data_dt=0.05)
            
            # Add the parameter text to the bottom right corner
            ax = fig.get_axes()[-1]
            xlim = ax.get_xlim()
            ylim = ax.get_ylim()
            # Add the text below the x-axis
            ax.text(xlim[0],
                    ylim[0] - (ylim[1] - ylim[0]) * 0.15,
                    param_text,
                    ha='left',
                    va='top',
                    fontsize=14, fontfamily='monospace',
                    transform=ax.transData)

            # Ensure there's enough room at the bottom
            plt.tight_layout(rect=[0, 0.25, 1, 0.95])
            plt.suptitle(f"Subject {subID} Fit: {subject_df['condition'].iloc[0]}", fontsize=16, y=1.025)
            # Save the figure
            plt.savefig(os.path.join(plots_dir, f's{subID}_fit.png'), dpi=300, bbox_inches='tight')
            plt.close()

    if all_param_data:
        param_df = pd.DataFrame(all_param_data)
        
        # Exclude non-parameter columns
        exclude = ['subID', 'condition']
        params_cols = [col for col in param_df.columns if col not in exclude]
        
        # Get unique conditions
        conditions = param_df['condition'].unique()
        
        # Define a color map for different conditions
        condition_colors = {
            condition: plt.cm.tab10(i % 10) 
            for i, condition in enumerate(conditions)
        }
        
        # Create a single plot with parameters on x-axis and conditions as grouped bars
        fig, ax = plt.figure(figsize=(12, 8)), plt.gca()
        
        # Set up the bar positions
        num_conditions = len(conditions)
        bar_width = 0.35  # Width of each bar
        x = np.arange(len(params_cols))  # Parameter positions
        
        # For storing means and errors for each condition
        all_means = []
        all_errors = []
        
        # Calculate means and standard errors for each condition
        for i, condition in enumerate(conditions):
            condition_df = param_df[param_df['condition'] == condition]
            means = condition_df[params_cols].mean().values
            errors = condition_df[params_cols].sem().values
            all_means.append(means)
            all_errors.append(errors)
            
            # Position for this condition's bars
            pos = x - bar_width/2 + i*bar_width
            
            # Create bars for this condition
            bars = ax.bar(pos, means, bar_width, 
                         label=condition,
                         color=condition_colors[condition],
                         alpha=0.8)
            
            # Add error bars
            ax.errorbar(pos, means, yerr=errors, fmt='none', 
                       color='black', capsize=5, alpha=0.7)
            
            # Add value labels on bars
            for j, bar in enumerate(bars):
                height = bar.get_height()
                if height >= 0:
                    ax.text(bar.get_x() + bar.get_width()/2, height + max(means)*0.02,
                           f'{means[j]:.3f}', ha='center', va='bottom', rotation=0,
                           fontsize=9)
                else:
                    ax.text(bar.get_x() + bar.get_width()/2, height - max(means)*0.05,
                           f'{means[j]:.3f}', ha='center', va='top', rotation=0,
                           fontsize=9)
        
        # Add labels and formatting
        ax.set_xticks(x)
        ax.set_xticklabels(params_cols, rotation=0, ha='right')
        ax.set_title('Mean Parameter Values by Condition', fontsize=14)
        ax.set_ylabel('Parameter Value', fontsize=12)
        ax.grid(axis='y', linestyle='--', alpha=0.7)
        ax.legend(title='Condition')        
        plt.tight_layout()
        
        # Save the figure
        plt.savefig(os.path.join(plots_dir, 'parameter_comparison.png'), dpi=300, bbox_inches='tight')
        
        # Save results to CSV
        param_df.to_csv(os.path.join(results_dir, 'all_fits.csv'), index=False)


# Run the analysis when script is executed
if __name__ == "__main__":
    import argparse
    
    # Set up command line argument parsing
    parser = argparse.ArgumentParser(description='Run DDM analysis and plotting')
    parser.add_argument('--results_dir', type=str, 
                        default='cluster_fitting/startPoint_0ndt/results',
                        help='Directory containing results files')
    parser.add_argument('--subdir', type=int, default=0,
                        help='Whether subject results are in subdirectories')
    parser.add_argument('--group_only', action='store_true',
                        help='Only generate group plots without processing individual subjects')
    
    # Parse arguments
    args = parser.parse_args()
    
    print(f"Running {'group-only' if args.group_only else 'combined'} analysis...")
    param_df = make_plots(args.results_dir, args.subdir, args.group_only)
    
    print("Analysis complete!")