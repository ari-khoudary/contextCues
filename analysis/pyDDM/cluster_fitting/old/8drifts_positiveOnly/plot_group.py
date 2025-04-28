import matplotlib.pyplot as plt
import numpy as np
import os
import re
import pandas as pd

def process_subjects(results_dir):
    """Process all subjects and plot parameter means with SE."""
    # Find all subject directories
    subject_dirs = [d for d in os.listdir(results_dir) if d.startswith('s') and os.path.isdir(os.path.join(results_dir, d))]
    
    # Collect parameter data from all subjects
    all_data = []
    for subj_dir in subject_dirs:
        results_file = os.path.join(results_dir, subj_dir, f"{subj_dir}_results.txt")
        if not os.path.exists(results_file):
            continue
            
        # Extract parameters from file
        with open(results_file, 'r') as f:
            content = f.read()
        
        # Get parameters using regex
        params = {'subID': subj_dir.replace('s', '')}
        for name, value, _, _ in re.findall(r"'([\w_]+)': Fitted\(([\d\.\-]+), minval=([\d\.\-]+), maxval=([\d\.\-]+)\)", content):
            params[name] = float(value)
        
        all_data.append(params)
    
    # Convert to DataFrame
    df = pd.DataFrame(all_data)
    
    # Exclude non-parameter columns
    exclude = ['subID']
    params = [col for col in df.columns if col not in exclude]
    
    # Calculate mean and SE
    mean_vals = df[params].mean()
    se_vals = df[params].sem()
    
    # Create bar plot with error bars
    plt.figure(figsize=(12, 6))
    x = np.arange(len(params))
    plt.bar(x, mean_vals, color='skyblue')
    plt.errorbar(x, mean_vals, yerr=se_vals, fmt='none', color='black', capsize=5)
    
    # Add labels and formatting
    plt.xticks(x, params, rotation=45, ha='right')
    plt.title('Mean Parameter Values Across Subjects')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.ylabel('Mean Parameter Value')
    plt.tight_layout()
    
    # Save results
    output_dir = os.path.join(results_dir, "parameter_plots")
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(os.path.join(output_dir, 'parameter_means.png'), dpi=300)
    df.to_csv(os.path.join(output_dir, 'all_subject_parameters.csv'), index=False)
    
    return df

# Run the code
if __name__ == "__main__":
    process_subjects('cluster_fitting/8drifts_positiveOnly')