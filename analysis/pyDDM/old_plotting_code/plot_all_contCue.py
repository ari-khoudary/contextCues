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

def make_plots(results_dir, subdir=0):
    """Run both individual and group analyses using a single data read."""
    # Read the tidy data file once
    df = pd.read_csv('inference_all.csv')
    df = df.dropna(subset=['RT'])
    df[['signal1_onset', 'noise2_onset', 'signal2_onset']] = df[['signal1_onset', 'noise2_onset', 'signal2_onset']].fillna(0)
    subjects = df['subID'].unique()
    subjects = subjects[subjects > 0]
    
    # Create output directories
    plots_dir = os.path.join(results_dir, "plots/")
    os.makedirs(plots_dir, exist_ok=True)
    
    # initialize group dict
    all_param_data = []

    # Specify drift function
    def drift_weights(t, congCue, coherence, signal1_onset, noise2_onset, signal2_onset,
                      m_noise1, m50_noise1, m_signal1, m50_signal1, v_signal1, v50_signal1,
                      m_noise2, m50_noise2, m_signal2, m50_signal2, v_signal2, v50_signal2):
        if t < signal1_onset:
            return congCue * (m_noise1 if abs(congCue) > 0.5 else m50_noise1)
        elif t < noise2_onset:
            return congCue * (m_signal1 if abs(congCue) > 0.5 else m50_signal1) + coherence * (v_signal1 if abs(congCue) > 0.5 else v50_signal1)
        elif t < signal2_onset:
            return congCue * (m_noise2 if abs(congCue) > 0.5 else m50_noise2)
        else:
            return congCue * (m_signal2 if abs(congCue) > 0.5 else m50_signal2) + coherence * (v_signal2 if abs(congCue) > 0.5 else v50_signal2)
    
    
    # Process each subject
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
        for key, value_dict in params.items():
            group_params[key] = value_dict['fitted']
        all_param_data.append(group_params)
        
        # Extract fitted parameters for model
        fitted_params = {key: value_dict['fitted'] for key, value_dict in params.items()}
        plot_params = {k: v for k, v in fitted_params.items() if k != 'noise1_incong'}

        # Create parameter text
        param_text = f"""
        Loss: {loss:.4f}  
        Boundary (B): {params.get('B').get('fitted'):.3f} [min: {params.get('B').get('minval'):.3f}, max: {params.get('B').get('maxval'):.3f}]
        Non-decision time: {params.get('nondectime').get('fitted'):.3f} [min: {params.get('nondectime').get('minval'):.3f}, max: {params.get('nondectime').get('maxval'):.3f}]
        
        Memory weights (min: {params.get('m_noise1').get('minval'):.3f}, max: {params.get('m_noise1').get('maxval'):.3f})
        noise1: {params.get('m_noise1').get('fitted'):.3f}                  noise1_50: {params.get('m50_noise1').get('fitted'):.3f} 
        signal1: {params.get('m_signal1').get('fitted'):.3f}                signal1_50: {params.get('m50_signal1').get('fitted'):.3f} 
        noise2: {params.get('m_noise2').get('fitted'):.3f}                  noise2_50: {params.get('m50_noise2').get('fitted'):.3f} 
        signal2: {params.get('m_signal2').get('fitted'):.3f}                signal2_50: {params.get('m50_signal2').get('fitted'):.3f} 

        Vision weights:
        signal1: {params.get('v_signal1').get('fitted'):.3f}                signal1_50: {params.get('v50_signal1').get('fitted'):.3f} 
        signal2: {params.get('v_signal2').get('fitted'):.3f}                signal2_50: {params.get('v50_signal2').get('fitted'):.3f}
        """
        

        # Initialize model object
        model = pyddm.gddm(
            drift=drift_weights,
            starting_position=0,
            bound='B',
            T_dur=4.1,
            nondecision='nondectime',
            parameters=plot_params,
            conditions=['congCue', 'coherence', 'signal1_onset', 'noise2_onset', 'signal2_onset'])
        
        # Create pyDDM sample object
        sample = pyddm.Sample.from_pandas_dataframe(subject_df, rt_column_name='RT', choice_column_name='accuracy')

        # Extract timing parameters
        subject_df[['noise2_onset', 'signal2_onset']] = subject_df[['noise2_onset', 'signal2_onset']].replace(0, np.nan)
        signal1_onset = subject_df['signal1_onset'].median()
        noise2_onset = subject_df['noise2_onset'].median()
        signal2_onset = subject_df['signal2_onset'].median()
        median_rt = subject_df.loc[subject_df['RT'] > subject_df['signal2_onset'], 'RT'].median()
        max_rt = subject_df.loc[subject_df['RT'] > subject_df['signal2_onset'], 'RT'].max()
    
        # Create figure
        fig = plt.figure(figsize=(12, 10))
        pyddm.plot.plot_fit_diagnostics(model, sample, fig, data_dt=0.05)
        
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
        plt.suptitle(f"Subject {subID} Fit: {subject_df['condition'].iloc[0]}", fontsize=16, y=1.025)
        # Save the figure
        plt.savefig(os.path.join(plots_dir, f's{subID}_fit.png'), dpi=300, bbox_inches='tight')
        plt.close()

    # Process group data
    if all_param_data:
        param_df = pd.DataFrame(all_param_data)
        
        # Exclude non-parameter columns
        exclude = ['subID']
        params_cols = [col for col in param_df.columns if col not in exclude]
        
        # Calculate mean and SE
        mean_vals = param_df[params_cols].mean()
        se_vals = param_df[params_cols].sem()
        
        # Create bar plot with error bars
        plt.figure(figsize=(12, 6))
        x = np.arange(len(params_cols))
        plt.bar(x, mean_vals, color='skyblue')
        plt.errorbar(x, mean_vals, yerr=se_vals, fmt='none', color='black', capsize=5)
        
        # Add labels and formatting
        plt.xticks(x, params_cols, rotation=45, ha='right')
        plt.title('Mean Parameter Values Across Subjects')
        plt.grid(axis='y', linestyle='--', alpha=0.7)
        plt.ylabel('Mean Parameter Value')
        plt.tight_layout()
        
        # Save results
        plt.savefig(os.path.join(plots_dir, 'mean_fits.png'), dpi=300)
        param_df.to_csv(os.path.join(results_dir, 'all_fits.csv'), index=False)
        
        return param_df
    
    return None

# Run the analysis when script is executed
if __name__ == "__main__":
    results_dir = 'cluster_fitting/12drift_contCue/results'
    subdir = 0
    
    print("Running combined analysis...")
    param_df = make_plots(results_dir, subdir)
    
    print("Analysis complete!")