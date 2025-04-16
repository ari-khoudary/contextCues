import pyddm
import matplotlib.pyplot as plt
import os
import sys
import pickle
import numpy as np

def plot_model_fit(subject_id, results_dir=None):
    """
    Create an enhanced diagnostic plot for a fitted DDM model.
    
    Parameters:
    -----------
    subject_id : str
        The subject ID to plot
    results_dir : str, optional
        Directory containing the model files. If None, defaults to 'results_{subject_id}'
    """
    # Set up paths
    if results_dir is None:
        results_dir = f'results_{subject_id}'
    
    model_path = os.path.join(results_dir, f's{subject_id}_model.pkl')
    sample_path = os.path.join(results_dir, f's{subject_id}_sample.pkl')
    onsets_path = os.path.join(results_dir, f's{subject_id}_onsets.pkl')
    
    # Check if files exist
    for path, name in [(model_path, 'model'), (sample_path, 'sample'), (onsets_path, 'onsets')]:
        if not os.path.exists(path):
            error_msg = f"Error: {name} file not found at {path}"
            print(error_msg)
            with open(os.path.join(results_dir, f's{subject_id}_plot_error.txt'), 'w') as f:
                f.write(error_msg)
            return False
    
    try:
        # Load model, sample, and onsets
        with open(model_path, 'rb') as f:
            model = pickle.load(f)
            
        with open(sample_path, 'rb') as f:
            sample = pickle.load(f)
            
        with open(onsets_path, 'rb') as f:
            onsets = pickle.load(f)
        
        # Extract parameters
        params = model.parameters()
        loss = model.get_fit_result().value()
        
        # Extract common onset values
        common_signal1_onset = onsets['signal1_onset']
        common_noise2_onset = onsets['noise2_onset']
        common_signal2_onset = onsets['signal2_onset']
        
        # Initialize figure
        fig = plt.figure(figsize=(12, 10))
        
        # Define function to add noise region highlighting
        def add_noise_regions(ax):
            # First noise period (0 to signal1_onset)
            rect1 = ax.axvspan(0, common_signal1_onset, alpha=0.25, color='lightblue')
            # Second noise period (noise2_onset to signal2_onset)
            rect2 = ax.axvspan(common_noise2_onset, common_signal2_onset, alpha=0.25, color='lightblue')
            
            # Add labels for the timing
            ylim = ax.get_ylim()
            ax.text(common_signal1_onset/2, ylim[1]*0.95, 'Noise 1', 
                    ha='center', va='top', backgroundcolor='white', alpha=0.7)
            midpoint = (common_noise2_onset + common_signal2_onset)/2
            ax.text(midpoint, ylim[1]*0.95, 'Noise 2', 
                    ha='center', va='top', backgroundcolor='white', alpha=0.7)
        
        # Generate the pyddm diagnostic plot
        pyddm.plot.plot_fit_diagnostics(model, sample, data_dt=0.1, fig=fig)
        
        # Apply noise region highlighting to each subplot
        for ax in fig.get_axes():
            try:
                add_noise_regions(ax)
            except Exception as e:
                print(f"Warning: Could not add noise regions to a subplot: {e}")
                continue
        
        # Create parameter text for caption
        param_text = f"""
        Fitted Parameters for Subject {subject_id} (Loss: {loss:.4f})
        Boundary (B): {params['B']:.3f}
        Non-decision time: {params['ndt']:.3f}
        
        First Period Drifts:
        noise1Drift_80: {params['noise1Drift_80']:.3f}  noise1Drift_50: {params['noise1Drift_50']:.3f}
        signal1Drift_80: {params['signal1Drift_80']:.3f}  signal1Drift_50: {params['signal1Drift_50']:.3f}
        
        Second Period Drifts:
        noise2Drift_80: {params['noise2Drift_80']:.3f}  noise2Drift_50: {params['noise2Drift_50']:.3f}
        signal2Drift_80: {params['signal2Drift_80']:.3f}  signal2Drift_50: {params['signal2Drift_50']:.3f}
        
        Timing: signal1_onset={common_signal1_onset:.2f}, noise2_onset={common_noise2_onset:.2f}, signal2_onset={common_signal2_onset:.2f}
        """
        
        # Add a text box at the bottom of the figure
        fig.text(0.5, 0.01, param_text, ha='center', va='bottom', 
                 bbox=dict(boxstyle='round', facecolor='white', alpha=0.9),
                 fontsize=10, fontfamily='monospace')
        
        # Adjust layout to make room for the caption
        plt.tight_layout(rect=[0, 0.15, 1, 0.95])
        plt.suptitle(f'Subject {subject_id} Model Fit', fontsize=16, y=0.98)
        
        # Save the figure
        plt.savefig(os.path.join(results_dir, f'subject_{subject_id}_fit.png'), dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"Successfully created plot for subject {subject_id}")
        return True
        
    except Exception as e:
        error_msg = f"Error plotting model for subject {subject_id}: {str(e)}"
        print(error_msg)
        
        # Save error information
        with open(os.path.join(results_dir, f'subject_{subject_id}_plot_error.txt'), 'w') as f:
            f.write(error_msg)
        return False

if __name__ == "__main__":
    # Check command line arguments
    if len(sys.argv) < 2:
        print("Error: Subject ID not provided. Use as: python plot_model.py [subject_id] [results_dir]")
        sys.exit(1)
    
    # Get arguments
    subject_id = sys.argv[1]
    results_dir = sys.argv[2] if len(sys.argv) > 2 else None
    
    # Run the plotting function
    success = plot_model_fit(subject_id, results_dir)
    sys.exit(0 if success else 1)