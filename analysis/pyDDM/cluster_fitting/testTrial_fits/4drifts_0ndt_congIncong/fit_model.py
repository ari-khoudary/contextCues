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

try:
    # Load and filter data
    df = pd.read_csv('../../../inference_test.csv')
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
        drift = drift,
        starting_position = 0,
        bound="B",
        T_dur = 4.1,
        nondecision=0,
        parameters={'B': (0.5, 12), 
                    'noise1_cong': (0, 10), 'noise1_neut': (0,10),
                    'signal1_cong': (0, 10), 'signal1_incong': (0, 10), 'signal1_neut': (0, 10),
                    'noise2_cong': (0, 10), 'noise2_incong': (0,10), 'noise2_neut': (0,10),
                    'signal2_cong': (0, 10), 'signal2_incong': (0, 10), 'signal2_neut': (0,10)},
        conditions = ['trueCongruence', 'signal1_onset', 'noise2_onset', 'signal2_onset']
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

    original_stdout = sys.stdout
    with open(os.path.join(results_dir, f's{subject_id}_summary.txt'), "w") as f:
        sys.stdout = f
        model.show()
    sys.stdout = original_stdout
    
except Exception as e:
    error_msg = f"Error processing subject {subject_id}: {str(e)}"
    # Save error information
    with open(os.path.join(results_dir, f's{subject_id}_error.txt'), 'w') as f:
        f.write(error_msg)