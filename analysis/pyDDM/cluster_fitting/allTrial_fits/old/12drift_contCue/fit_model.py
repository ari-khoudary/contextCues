# initialize
import pyddm
import pandas as pd
import numpy as np
from pyddm import Sample
import os
import sys
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
results_dir = 'results'

# Create results directory if it doesn't exist
os.makedirs(results_dir, exist_ok=True)

# make df filtering robust against type mismatches in bash and python
subject_id_str = str(subject_id)
subject_id_int = int(subject_id) 

# specify drift function
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
    
try:
    # Load and filter data
    df = pd.read_csv('../../inference_all.csv')
    df = df.dropna(subset=['RT'])
    df[['signal1_onset', 'noise2_onset', 'signal2_onset']] = df[['signal1_onset', 'noise2_onset', 'signal2_onset']].fillna(0)
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
        drift = drift_weights,
        starting_position = 0,
        bound="B",
        T_dur = 4.1,
        nondecision='ndt',
        parameters={'B': (0.5, 25), 'ndt': (0.01, 1.5),
                    'm_noise1': (0, 10), 'm50_noise1': (0,10), 'm_signal1': (0,10),
                    'm50_signal1': (0, 10), 'v_signal1': (0, 10), 'v50_signal1': (0, 10),
                    'm_noise2': (0, 10), 'm50_noise2': (0,10), 'm_signal2': (0,10),
                    'm50_signal2': (0, 10), 'v_signal2': (0, 10), 'v50_signal2': (0,10)},
        conditions = ['congCue', 'coherence', 'signal1_onset', 'noise2_onset', 'signal2_onset']
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
    
except Exception as e:
    error_msg = f"Error processing subject {subject_id}: {str(e)}"
    # Save error information
    with open(os.path.join(results_dir, f's{subject_id}_error.txt'), 'w') as f:
        f.write(error_msg)