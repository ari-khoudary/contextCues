# initialize
import pyddm
import pandas as pd
import numpy as np
from pyddm import Sample
import os
import sys
import json
import pickle
import matplotlib.pyplot as plt
import gc

# Get number of CPUs from SLURM environment variable
n_cpus = int(os.environ.get('SLURM_CPUS_PER_TASK', 1))
pyddm.set_N_cpus(n_cpus)

# Get the subject ID and results directory from command line arguments
if len(sys.argv) < 2:
    print("Error: Subject ID not provided. Use as: python fitting_code.py [subject_id] [results_dir]")
    sys.exit(1)

subject_id = sys.argv[1]
results_dir = sys.argv[2] if len(sys.argv) > 2 else f's{subject_id}'

# Create results directory if it doesn't exist
os.makedirs(results_dir, exist_ok=True)

# make df filtering robust against type mismatches in bash and python
subject_id_str = str(subject_id)
subject_id_int = int(subject_id) if subject_id.isdigit() else None

# specify drift function
def eightDrifts(t, trueCongruence, signal1_onset, noise2_onset, signal2_onset,
                  noise1Drift_80, noise1Drift_50, signal1Drift_80, signal1Drift_50, 
                  noise2Drift_80, noise2Drift_50, signal2Drift_80, signal2Drift_50):
    # First noise period
    if t < signal1_onset:
        if trueCongruence == 'congruent': return noise1Drift_80
        elif trueCongruence == 'incongruent': return -noise1Drift_80
        else: return noise1Drift_50
    # First signal period
    elif t < noise2_onset:
        if trueCongruence == 'congruent': return signal1Drift_80
        elif trueCongruence == 'incongruent': return -signal1Drift_80
        else: return signal1Drift_50
    # Second noise period
    elif t < signal2_onset:
        if trueCongruence == 'congruent': return noise2Drift_80
        elif trueCongruence == 'incongruent': return -noise2Drift_80
        else: return noise2Drift_50
    # Second signal period
    else:
        if trueCongruence == 'congruent': return signal2Drift_80
        elif trueCongruence == 'incongruent': return -signal2Drift_80
        else: return signal2Drift_50

try:
    # Load and filter data
    df = pd.read_csv('../inference_tidy.csv')
    df = df.dropna(subset=['RT'])
    subject_df = df[(df['subID'] == subject_id_str) | 
                (df['subID'] == subject_id_int)].copy()
    
    if len(subject_df) == 0:
        error_msg = f"Error: No data found for subject {subject_id}"
        with open(os.path.join(results_dir, f's{subject_id}_error.txt'), 'w') as f:
            f.write(error_msg)
        sys.exit(1)
    
    # Create sample
    sample = pyddm.Sample.from_pandas_dataframe(
        subject_df, rt_column_name='RT', choice_column_name='accuracy'
    )
    
    # initialize model
    model = pyddm.gddm(
        drift=eightDrifts,
        name=f"eightDrifts_s{subject_id}",
        starting_position=0,
        bound='B',
        T_dur=4.1,
        nondecision='ndt',
        parameters={
            'B': (0.5, 10), 'ndt': (0.01, 0.5),
            'noise1Drift_80': (0, 3), 'noise1Drift_50': (0,3),
            'signal1Drift_80': (0, 3), 'signal1Drift_50': (0, 3),
            'noise2Drift_80': (0, 3), 'noise2Drift_50': (0,3),
            'signal2Drift_80': (0, 3), 'signal2Drift_50': (0, 3)
        },
        conditions=['trueCongruence', 'coherence', 'signal1_onset', 'noise2_onset', 'signal2_onset']
    )

    # fit
    model.fit(sample, verbose=True)
    
    # Gather results
    loss = model.get_fit_result().value()
    params = model.parameters()
    
    # Save text results (basic summary)
    with open(os.path.join(results_dir, f's{subject_id}_results.txt'), 'w') as f:
        f.write(f'Subject: {subject_id}\nLoss: {loss}\nParameters:\n')
        for param, value in params.items():
            f.write(f'{param}: {value}\n')
    
    # Save the fitted model using pickle (this contains all information)
    with open(os.path.join(results_dir, f's{subject_id}_model.pkl'), 'wb') as f:
        pickle.dump(model, f)
    
    # Also save the sample with the model for easier plotting later
    with open(os.path.join(results_dir, f's{subject_id}_sample.pkl'), 'wb') as f:
        pickle.dump(sample, f)
        
    # Save the most common onsets for this subject (for plotting)
    onsets = {
        'signal1_onset': subject_df['signal1_onset'].value_counts().idxmax(),
        'noise2_onset': subject_df['noise2_onset'].value_counts().idxmax(),
        'signal2_onset': subject_df['signal2_onset'].value_counts().idxmax()
    }
    with open(os.path.join(results_dir, f's{subject_id}_onsets.pkl'), 'wb') as f:
        pickle.dump(onsets, f)
    
except Exception as e:
    error_msg = f"Error processing subject {subject_id}: {str(e)}"
    
    # Save error information
    with open(os.path.join(results_dir, f's{subject_id}_error.txt'), 'w') as f:
        f.write(error_msg)