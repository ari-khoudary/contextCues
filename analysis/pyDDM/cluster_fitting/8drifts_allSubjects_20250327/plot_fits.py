import pyddm
from pyddm import Sample
import pyddm.plot
import matplotlib.pyplot as plt
import numpy as np
import os
import sys
import pandas as pd
import re

# Define paths
data_path = '../../inference_80cue.csv'
fitted_params_path = 'fitted_parameters.txt'
results_dir = './plots/'  
plots_dir = results_dir

# Create plots directory if it doesn't exist
os.makedirs(plots_dir, exist_ok=True)

# Read in data
df = pd.read_csv(data_path)
df = df.dropna(subset=['RT'])
# Get unique subjects
unique_subjects = df['subID'].unique()

# Read the fitted parameters file
with open(fitted_params_path, 'r') as f:
    fitted_params_text = f.read()

# Parse the fitted parameters by splitting at "Info: Params"
sections = re.split(r'Info: Params', fitted_params_text)
# Remove the first empty section if it exists
if sections[0].strip() == '':
    sections = sections[1:]
    
# Process each section to extract parameters and loss
param_entries = []
for section in sections:
    # Find the parameters array and loss value
    match = re.search(r'(.*) gave ([\d\.]+)', section.strip(), re.DOTALL)
    if match:
        params_str = match.group(1).strip()
        loss = match.group(2)
        param_entries.append((params_str, loss))

print(f"Found {len(param_entries)} parameter entries in the fitted_parameters.txt file")
        
if len(param_entries) != len(unique_subjects):
    print(f"Warning: Number of parameter entries ({len(param_entries)}) doesn't match number of subjects ({len(unique_subjects)})")

# Define drift function for the model (based on eightDrifts from fitting_code.py)
def eightDrifts(t, trueCongruence, signal1_onset, noise2_onset, signal2_onset,
                noise1Drift_80, noise1Drift_50, signal1Drift_80, signal1Drift_50, 
                noise2Drift_80, noise2Drift_50, signal2Drift_80, signal2Drift_50):
    # drift rate during first noise period
    if t < signal1_onset:
        if trueCongruence == 'congruent':
            return noise1Drift_80
        elif trueCongruence == 'incongruent':
            return -noise1Drift_80
        else:
            return noise1Drift_50

    # drift rates during first signal period
    if t >= signal1_onset and t < noise2_onset:
        if trueCongruence == 'congruent':
            return signal1Drift_80
        elif trueCongruence == 'incongruent':
            return -signal1Drift_80
        else:
            return signal1Drift_50

    # drift rates during the second noise period
    if t >= noise2_onset and t < signal2_onset:
        if trueCongruence == 'congruent':
            return noise2Drift_80
        elif trueCongruence == 'incongruent':
            return -noise2Drift_80
        else:
            return noise2Drift_50

    # drift rates during the second signal period
    if t >= signal2_onset:
        if trueCongruence == 'congruent':
            return signal2Drift_80
        elif trueCongruence == 'incongruent':
            return -signal2Drift_80
        else:
            return signal2Drift_50
        

# Loop through each subject and corresponding parameters
for i, subject_id in enumerate(unique_subjects):
    if i >= len(param_entries):
        print(f"Not enough parameter entries for subject {subject_id}, skipping...")
        continue
        
    params_str, loss = param_entries[i]
    loss_value = float(loss)
    
    # Clean up the params_str to ensure it can be evaluated
    # Sometimes multi-line arrays need cleaning and proper formatting for eval()
    params_str = params_str.replace('\n', '').strip()
    
    # Check if string already has outer brackets and remove them if needed
    if params_str.startswith('[') and params_str.endswith(']'):
        params_str = params_str[1:-1].strip()
        
    # Convert the NumPy array string format to a valid Python list
    # This replaces spaces between numbers with commas for proper list syntax
    params_str = re.sub(r'(\d+\.\d+|\d+\.|\.\d+|\d+)\s+', r'\1, ', params_str)
    
    # Now ensure we have exactly one set of brackets
    params_str = '[' + params_str + ']'

    try:
        # Parse the parameters string into a numpy array
        params_array = np.array(eval(params_str))
        
        # Extract parameters based on eightDrifts function
        # The last element in params_array is the boundary 'B'
        B = params_array[-1]
        
        # Map parameters to the drift function parameters
        # Assuming the order in params_array matches the order in eightDrifts
        params = {
            'B': B,
            'noise1Drift_80': params_array[0],
            'noise1Drift_50': params_array[1],
            'signal1Drift_80': params_array[2],
            'signal1Drift_50': params_array[3],
            'noise2Drift_80': params_array[4],
            'noise2Drift_50': params_array[5],
            'signal2Drift_80': params_array[6],
            'signal2Drift_50': params_array[7]
        }
    except Exception as e:
        print(f"Error parsing parameters for subject {subject_id}: {e}")
        print(f"Parameter string: {params_str}")
        continue
            
    # Subset dataframe for this subject
    subject_df = df[df['subID'] == subject_id]
    
    if subject_df.empty:
        print(f"  No data found for subject {subject_id}")
        continue
    
    # Create model with extracted parameters
    model = pyddm.gddm(
        drift=eightDrifts,
        starting_position=0,
        T_dur=4.1,
        bound='B',
        nondecision=0.2,
        parameters=params,
        conditions=['trueCongruence', 'coherence', 'signal1_onset', 'noise2_onset', 'signal2_onset'])
    
    # Create the sample for this subject
    sample = pyddm.Sample.from_pandas_dataframe(
        subject_df,
        rt_column_name="RT",
        choice_column_name="accuracy")
    
      # Create parameter text
    param_text = f"""
    Fitted Parameters for Subject {subject_id} (Loss: {loss_value:.4f})        
    Boundary (B): {params.get('B'):.3f}     NDT: fixed for all at 0.2
    
    Noise Drifts: 
    noise1Drift_80: {params.get('noise1Drift_80'):.3f}         noise2Drift_80: {params.get('noise2Drift_80'):.3f} 
    noise1Drift_50: {params.get('noise1Drift_50'):.3f}         noise2Drift_50: {params.get('noise2Drift_50'):.3f}
    
    Signal Drifts:
    signal1Drift_80: {params.get('signal1Drift_80'):.3f}        signal1Drift_50: {params.get('signal1Drift_50'):.3f}
    signal2Drift_80: {params.get('signal2Drift_80'):.3f}        signal2Drift_50: {params.get('signal2Drift_50'):.3f}
    """

    subject_df[['noise2_onset', 'signal2_onset']] = subject_df[['noise2_onset', 'signal2_onset']].replace(0, np.nan)
    signal1_onset = subject_df['signal1_onset'].median()
    noise2_onset = subject_df['noise2_onset'].median()
    signal2_onset = subject_df['signal2_onset'].median()
    
    # Create figure
    fig = plt.figure(figsize=(12, 10))
    pyddm.plot.plot_fit_diagnostics(model, sample, fig, data_dt=0.04)
    # Add noise regions to each subplot
    second_ax = False
    for ax in fig.get_axes():
        try:
            ylim = ax.get_ylim()
            xlim = ax.get_xlim()
            # add boxes
            ax.axvspan(signal1_onset, noise2_onset, alpha=0.25, color='lightblue', zorder=0)
            ax.axvspan(signal2_onset, xlim[1], alpha=0.25, color='lightblue', zorder=0)
            # add labels
            if second_ax:
                label_y_pos = ylim[0] + (ylim[1] - ylim[0]) * 0.07
                # label signal 1
                ax.text((signal1_onset+noise2_onset)/2, label_y_pos, 'median signal 1', 
                ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
                # label signal 2
                ax.text((signal2_onset+xlim[1])/2, label_y_pos, 'median signal 2', 
                ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
                # label noise 1 
                ax.text((signal1_onset+0)/2, label_y_pos, 'median noise 1', 
                ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
                # label noise 2 
                ax.text((noise2_onset+signal2_onset)/2, label_y_pos, 'median noise2', 
                ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
            # Force redraw
            ax.figure.canvas.draw()
            second_ax = True
        except Exception as e:
            print(f"Warning: Could not add noise regions to a subplot: {e}")
        # Add the parameter text to the bottom right corner
    ax = fig.get_axes()[-1]  # gca = get current axis
    xlim = ax.get_xlim()
    ylim = ax.get_ylim()
    # Add the text below the x-axis
    ax.text(xlim[0],  # Center horizontally
            ylim[0] - (ylim[1] - ylim[0]) * 0.15,  # Below x-axis (adjust the 0.15 factor as needed)
            param_text,
            ha='left',
            va='top',
            fontsize=14, fontfamily='monospace',
            transform=ax.transData)  # Use data coordinate system

    # Ensure there's enough room at the bottom
    plt.tight_layout(rect=[0, 0.25, 1, 0.95])  # Adjust bottom margin
    plt.suptitle(f'Subject {subject_id} Fit', fontsize=16, y=1.025)
    # Save the figure
    plt.savefig(os.path.join(plots_dir, f'subject_{subject_id}_fit.png'), dpi=300, bbox_inches='tight')
    plt.close()