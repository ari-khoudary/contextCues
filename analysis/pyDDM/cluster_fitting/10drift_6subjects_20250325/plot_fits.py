import pyddm
from pyddm import Sample
import pyddm.plot
import matplotlib.pyplot as plt
import numpy as np
import os
import sys
import pandas as pd
import re

def plot_model_fit(results_dir):
    """Plot model fits for all subjects in the results directory."""
    # Read the tidy data file
    df = pd.read_csv('../../inference_80cue.csv')
    df = df.dropna(subset=['RT'])
    subjects = df['subID'].unique()
    
    # Create output directory
    output_dir = os.path.join(results_dir, "../plots")
    os.makedirs(output_dir, exist_ok=True)
    # output_dir = os.getcwd()
    
    for subID in subjects:
        print(f"Processing subject {subID}...")
        
        # Get subject-specific timing parameters from dataframe
        subject_df = df[df['subID'] == subID]
        if subject_df.empty:
            print(f"No data found for subject {subID}, skipping.")
            continue

        # Read results file
        results_file = os.path.join(results_dir, f"s{subID}_results.txt")
        if not os.path.exists(results_file):
            print(f"Results file not found for subject {subID}, skipping.")
            continue
            
        with open(results_file, 'r') as f:
            content = f.read()
        
        # Extract loss
        loss_match = re.search(r'Loss: ([\d\.]+)', content)
        loss = float(loss_match.group(1)) if loss_match else None
        
        # Extract parameters
        params = {}
        pattern = r"'([\w_]+)': Fitted\(([\d\.\-]+), minval=([\d\.\-]+), maxval=([\d\.\-]+)\)"
        for name, value, minval, maxval in re.findall(pattern, content):
            params[name] = {
                'fitted': float(value),
                'minval': float(minval),
                'maxval': float(maxval)}
            
        fitted_params = {}
        for name, value in re.findall(r"'([\w_]+)': Fitted\(([\d\.\-]+)", content):
            fitted_params[name] = float(value)

        # Create parameter text
        param_text = f"""
        Fitted Parameters for Subject {subID} (Loss: {loss:.4f})    
        Boundary (B): {params.get('B').get('fitted'):.3f} [min: {params.get('B').get('minval'):.3f}, max: {params.get('B').get('maxval'):.3f}]
        Nondectime: {params.get('nondectime').get('fitted', 0):.3f} [min: {params.get('nondectime').get('minval'):.3f}, max: {params.get('nondectime').get('maxval'):.3f}]
            
        Noise Drifts: [min: {params.get('mw80_noise1').get('minval'):.3f}, max: {params.get('mw80_noise1').get('maxval'):.3f}]
        mw80_noise1: {params.get('mw80_noise1').get('fitted'):.3f}         mw80_noise2: {params.get('mw80_noise2').get('fitted'):.3f}
        mw50_noise1: {params.get('mw50_noise1').get('fitted'):.3f}         mw50_noise2: {params.get('mw50_noise2').get('fitted'):.3f}
        
        Signal Drifts: [min: {params.get('mw80_signal1').get('minval'):.3f}, max: {params.get('mw80_signal1').get('maxval'):.3f}]
        mw80_signal1: {params.get('mw80_signal1').get('fitted'):.3f}        mw80_signal2: {params.get('mw80_signal2').get('fitted'):.3f}
        mw50_signal1: {params.get('mw50_signal1').get('fitted'):.3f}        mw50_signal2: {params.get('mw50_signal2').get('fitted'):.3f}
        vw80_signal1: {params.get('vw80_signal1').get('fitted'):.3f}        vw80_signal2: {params.get('vw80_signal2').get('fitted'):.3f}
        vw50_signal1: {params.get('vw50_signal1').get('fitted'):.3f}        vw50_signal2: {params.get('vw50_signal2').get('fitted'):.3f}     
        """
        
        # specify drift function
        def drift_weights2(t, trueCue, coherence, signal1_onset, noise2_onset, signal2_onset,
                            mw80_noise1, mw50_noise1, mw80_signal1, mw50_signal1, mw80_noise2, mw50_noise2, mw80_signal2, mw50_signal2,
                            vw80_signal1, vw50_signal1, vw80_signal2, vw50_signal2):
            if t < signal1_onset:
                return trueCue * (mw80_noise1 if abs(trueCue) == 0.8 else mw50_noise1)
            elif t < noise2_onset:
                return trueCue * (mw80_signal1 if abs(trueCue) == 0.8 else mw50_signal1) + coherence * (vw80_signal1 if abs(trueCue) == 0.8 else vw50_signal1)
            elif t < signal2_onset:
                return trueCue * (mw80_noise2 if abs(trueCue) == 0.8 else mw50_noise2)
            else:
                return trueCue * (mw80_signal2 if abs(trueCue) == 0.8 else mw50_signal2) + coherence * (vw80_signal2 if abs(trueCue) == 0.8 else vw50_signal2)

            # initialize model object
        model = pyddm.gddm(
        drift=drift_weights2,
        starting_position=0,
        bound='B',
        T_dur=4.1,
        nondecision='nondectime',
        parameters=fitted_params,
        conditions=['trueCue', 'coherence', 'signal1_onset', 'noise2_onset', 'signal2_onset'])
        
        # create pyDDM sample object
        sample = pyddm.Sample.from_pandas_dataframe(subject_df, rt_column_name='RT', choice_column_name='accuracy')
        pyddm.Sample.from_pandas_dataframe(df, rt_column_name='RT', choice_column_name='accuracy')

        # Extract timing parameters
        subject_df[['noise2_onset', 'signal2_onset']] = subject_df[['noise2_onset', 'signal2_onset']].replace(0, np.nan)
        signal1_onset = subject_df['signal1_onset'].median()
        noise2_onset = subject_df['noise2_onset'].median()
        signal2_onset = subject_df['signal2_onset'].median()
        median_rt = subject_df.loc[subject_df['RT'] > subject_df['signal2_onset'], 'RT'].median()
        max_rt = subject_df.loc[subject_df['RT'] > subject_df['signal2_onset'], 'RT'].max()
        
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
                ax.axvspan(signal2_onset, median_rt, alpha=0.25, color='lightblue', zorder=0)
                if max_rt > median_rt:
                    ax.axvspan(signal2_onset, max_rt, alpha=0.25, color='lightpink', zorder=0)
                # add labels
                if second_ax:
                    label_y_pos = ylim[0] + (ylim[1] - ylim[0]) * 0.07
                    # label signal 1
                    ax.text((signal1_onset+noise2_onset)/2, label_y_pos, 'median signal 1', 
                    ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
                    # label signal 2
                    ax.text((signal2_onset+median_rt)/2, label_y_pos, 'median signal 2', 
                    ha='center', va='top', backgroundcolor='white', alpha=0.7, zorder=5)
                    if max_rt > median_rt:
                        ax.text((signal2_onset+max_rt)/2, label_y_pos, 'max signal 2', 
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
        plt.suptitle(f'Subject {subID} Fit', fontsize=16, y=1.025)
        # Save the figure
        plt.savefig(os.path.join(output_dir, f'subject_{subID}_fit.png'), dpi=300, bbox_inches='tight')
        plt.close()


plot_model_fit('results/')