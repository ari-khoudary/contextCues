import pyddm
from pyddm import Sample
import pyddm.plot
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd
import re

def extract_parameters_from_results(results_file):
    """Extract parameters from a results file."""
    if not os.path.exists(results_file):
        return None, None
        
    with open(results_file, 'r') as f:
        content = f.read()
    
    # Extract loss
    loss_match = re.search(r'Loss: ([\d\.]+)', content)
    if not loss_match:
        return None, None
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

def extract_sample_size_from_summary(summary_file):
    """Extract sample size from a summary file."""
    if not os.path.exists(summary_file):
        return None
        
    with open(summary_file, 'r') as f:
        content = f.read()
    
    sample_match = re.search(r'- samplesize: (\d+)', content)
    sample_size = int(sample_match.group(1)) if sample_match else None
        
    # Extract number of parameters
    nparams_match = re.search(r'- nparams: (\d+)', content)
    n_params = int(nparams_match.group(1)) if nparams_match else None
    
    return sample_size, n_params


def process_subjects(results_dir, data_csv, plot_results=False, subjects_to_process=None):
    """Process subjects data and generate fits.csv and optional plots.
    
    Parameters:
        results_dir (str): Directory containing results files
        data_csv (str): Path to the CSV file with subject data
        plot_results (bool): Whether to generate diagnostic plots for each subject
        subjects_to_process (list or None): List of subject IDs to process; if None, process all subjects
    """
    # Extract model name from results directory path
    model_name_match = re.search(r'/([^/]+)$', os.getcwd())
    model_name = model_name_match.group(1) if model_name_match else "unknown_model"
    
    # Read the data file
    print(f"Reading data from {data_csv}...")
    df = pd.read_csv(data_csv)
    df = df.dropna(subset=['RT'])
    df[['signal1_onset', 'noise2_onset', 'signal2_onset']] = df[['signal1_onset', 'noise2_onset', 'signal2_onset']].fillna(0)
    
    # Get all unique subjects from the data
    all_subjects = df['subID'].unique()
    all_subjects = all_subjects[all_subjects > 0]
    
    # Determine which subjects to process
    if subjects_to_process is not None:
        # Convert to set for faster lookup
        subjects_to_process_set = set(subjects_to_process)
        # Keep only subjects that exist in the data
        subjects = np.array([s for s in all_subjects if s in subjects_to_process_set])
        if len(subjects) < len(subjects_to_process):
            missing = set(subjects_to_process) - set(subjects)
            print(f"Warning: Some requested subjects were not found in the data: {missing}")
    else:
        # Process all subjects
        subjects = all_subjects
    
    print(f"Will process {len(subjects)} subjects.")
    
    # Create output directory for plots if needed
    if plot_results:
        plots_dir = os.path.join(results_dir, "plots/")
        os.makedirs(plots_dir, exist_ok=True)

        def drift(t, trueCongruence, signal1_onset, noise2_onset, signal2_onset,
                noise1_cong, noise1_neut, signal1_cong, signal1_incong, signal1_neut,
                noise2_cong, noise2_incong, noise2_neut, signal2_cong, signal2_incong, signal2_neut):
            # drift rate during first noise period
            if t < signal1_onset:
                if trueCongruence == 'congruent': 
                    return noise1_cong
                elif trueCongruence == 'incongruent':
                    return -noise1_cong
                else:
                    return noise1_neut

            # drift rates during first signal period
            if t >= signal1_onset and t < noise2_onset:
                if trueCongruence == 'congruent':
                    return signal1_cong
                elif trueCongruence == 'incongruent':
                    return -signal1_incong
                else:
                    return signal1_neut

            # drift rates during the second noise period
            if t >= noise2_onset and t < signal2_onset:
                if trueCongruence == 'congruent':
                    return noise2_cong
                elif trueCongruence == 'incongruent':
                    return -noise2_incong
                else:
                    return noise2_neut

            # drift rates during the second signal period
            if t >= signal2_onset:
                if trueCongruence == 'congruent':
                    return signal2_cong
                elif trueCongruence == 'incongruent':
                    return -signal2_incong
                else:
                    return signal2_neut
                
        def boundary(trueCongruence, B_cue, B_neut):
                if trueCongruence == 'neutral':
                    return B_neut
                else:
                    return B_cue
    # Initialize list to store parameter data
    all_param_data = []
    
    # Process each subject
    for subID in subjects:
        print(f"Processing subject {subID}...")
        
        # Get subject-specific data
        subject_df = df[df['subID'] == subID]
        if subject_df.empty:
            print(f"No data found for subject {subID}, skipping.")
            continue

        # Read results file
        results_file = os.path.join(results_dir, f"s{subID}_results.txt")
        params, loss = extract_parameters_from_results(results_file)
        # inform if not
        if params is None:
            print(f"Results file not found or invalid for subject {subID}, skipping.")
            continue

        # Store parameter data
        group_params = {'subID': subID, 'model': model_name, 'loss': loss}
        
        # Add condition information
        if 'condition' in subject_df.columns:
            group_params['condition'] = subject_df['condition'].iloc[0]
        else:
            # Use the same condition logic as in the original script
            group_params['condition'] = 'condition_80cue' if subID < 55 else 'condition_65cue'
        
        # Check if summary file exists before trying to extract data from it
        summary_file = os.path.join(results_dir, f"s{subID}_summary.txt")
        if os.path.exists(summary_file):
            sample_size, n_params = extract_sample_size_from_summary(summary_file)
            group_params['sample_size'] = sample_size
            group_params['n_params'] = n_params
        else:
            print(f"No summary file found for subject {subID}, continuing with results data only.")
            
        # Add fitted parameters, min/max values
        for key, value_dict in params.items():
            group_params[f'{key}_fitted'] = value_dict['fitted']
            group_params[f'{key}_min'] = value_dict['minval']
            group_params[f'{key}_max'] = value_dict['maxval']
        
        all_param_data.append(group_params)
        
        # Generate diagnostic plot if requested
        if plot_results:
            # Extract fitted parameters for model
            fitted_params = {key: value_dict['fitted'] for key, value_dict in params.items()}
            # Create parameter text
            param_text = f"""
            Loss: {loss:.4f}  
            """
            for key, value_dict in params.items():
                param_text += f"{key}: {value_dict['fitted']:.3f} [min: {value_dict['minval']:.3f}, max: {value_dict['maxval']:.3f}]\n"
            
            if sample_size is not None:
                param_text += f"Sample size: {sample_size}\n"
                
            if n_params is not None:
                param_text += f"n_params: {n_params}"

            # Initialize model object
            model = pyddm.gddm(
            drift = drift,
            starting_position = 0,
            bound=boundary,
            T_dur = 4.1,
            nondecision=0,
            parameters=fitted_params,
            conditions = ['trueCongruence', 'signal1_onset', 'noise2_onset', 'signal2_onset'])
            
            # Create pyDDM sample object
            samp = pyddm.Sample.from_pandas_dataframe(subject_df, rt_column_name='RT', choice_column_name='accuracy')

            # extract timing
            subject_df[['noise2_onset', 'signal2_onset']] = subject_df[['noise2_onset', 'signal2_onset']].replace(0, np.nan)
            signal1_onset = subject_df['signal1_onset'].median()
            noise2_onset = subject_df['noise2_onset'].median()
            signal2_onset = subject_df['signal2_onset'].median()
            median_rt = subject_df.loc[subject_df['RT'] > subject_df['signal2_onset'], 'RT'].median()
            max_rt = subject_df.loc[subject_df['RT'] > subject_df['signal2_onset'], 'RT'].max()

            # Create figure
            fig = plt.figure(figsize=(12, 10))
            pyddm.plot.plot_fit_diagnostics(model, samp, fig, data_dt=0.05)

            # Add noise regions to each subplot
            second_ax = False
            for ax in fig.get_axes():
                try:
                    ylim = ax.get_ylim()
                    xlim = ax.get_xlim()
                    # Add boxes
                    ax.axvspan(signal1_onset, noise2_onset, alpha=0.25, color='lightblue', zorder=0)
                    ax.axvspan(signal2_onset, median_rt, alpha=0.25, color='lightblue', zorder=0)
                    if max_rt > median_rt:
                        ax.axvspan(signal2_onset, max_rt, alpha=0.25, color='lightpink', zorder=0)
                    # Add labels
                    if second_ax:
                        label_y_pos = ylim[0] + (ylim[1] - ylim[0]) * 0.07
                        # Label signal 1
                        ax.text((signal1_onset+noise2_onset)/2, label_y_pos, 'median signal 1', 
                        ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
                        # Label median signal 2
                        ax.text((signal2_onset+median_rt)/2, label_y_pos, 'median signal 2', 
                        ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
                        # Label max signal 2
                        if max_rt > median_rt:
                            ax.text((signal2_onset+max_rt)/2, label_y_pos, 'max signal 2', 
                            ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
                        # Label noise 1 
                        ax.text((signal1_onset+0)/2, label_y_pos, 'median noise 1', 
                        ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
                        # Label noise 2 
                        ax.text((noise2_onset+signal2_onset)/2, label_y_pos, 'median noise2', 
                        ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
                    # Force redraw
                    ax.figure.canvas.draw()
                    second_ax = True
                except Exception as e:
                    print(f"Warning: Could not add noise regions to a subplot: {e}")

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
            
            # Get condition info for title
            condition = group_params['condition']
            plt.suptitle(f"Subject {subID} Fit: {condition} - {model_name}", fontsize=16, y=1.025)
            
            # Save the figure
            plt.savefig(os.path.join(plots_dir, f's{subID}_fit.png'), dpi=300, bbox_inches='tight')
            plt.close()

    if all_param_data:
        # Create and save parameter dataframe
        param_df = pd.DataFrame(all_param_data)
        csv_path = os.path.join(results_dir, 'fits.csv')
        param_df.to_csv(csv_path, index=False)
        print(f"Parameter data saved to {csv_path}")
        return param_df
    
    return None

# Run the analysis when script is executed
if __name__ == "__main__":
    import argparse
    
    # Set up command line argument parsing
    parser = argparse.ArgumentParser(description='Process DDM results and generate fits.csv')
    parser.add_argument('--results_dir', type=str, required=True,
                        help='Directory containing results and summary files')
    parser.add_argument('--data_csv', type=str, default='../../../inference_test.csv',
                        help='Path to the CSV file with subject data')
    parser.add_argument('--plot_results', action='store_true',
                        help='Whether to generate diagnostic plots for each subject')
    parser.add_argument('--subjects', type=int, nargs='+',
                        help='Optional list of specific subject IDs to process (default: process all subjects)')
    
    # Parse arguments
    args = parser.parse_args()
    
    print(f"Processing data from {args.data_csv}...")
    print(f"Using results from {args.results_dir}...")
    print(f"Generating plots: {args.plot_results}")
    
    if args.subjects:
        print(f"Processing only the following subjects: {args.subjects}")
    else:
        print("Processing all subjects")
    
    param_df = process_subjects(
        args.results_dir,
        args.data_csv, 
        args.plot_results,
        subjects_to_process=args.subjects
    )
    
    print("Processing complete!")