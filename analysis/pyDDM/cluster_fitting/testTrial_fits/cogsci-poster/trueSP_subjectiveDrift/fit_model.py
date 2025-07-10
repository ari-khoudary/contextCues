# initialize
import pyddm
import pandas as pd
import numpy as np
from pyddm import Sample
import os
import sys
import scipy.stats

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
  
def drift_rate(t, subjectiveCongCue, coherence, drift,
               signal1_onset, noise2_onset, signal2_onset):
  # drift rate during first noise period
  if t < signal1_onset:
      return 0 + subjectiveCongCue*(1 if subjectiveCongCue >= 0.5 else 1-subjectiveCongCue)
  # drift rates during first signal period
  if t >= signal1_onset and t < noise2_onset:
     return drift*coherence + subjectiveCongCue*(1 if subjectiveCongCue >= 0.5 else 1-subjectiveCongCue)
  # drift rates during the second noise period
  if t >= noise2_onset and t < signal2_onset:
     return 0 + subjectiveCongCue*(1 if subjectiveCongCue >= 0.5 else 1-subjectiveCongCue)
  # drift rates during the second signal period
  if t >= signal2_onset:
    return drift*coherence + subjectiveCongCue*(1 if subjectiveCongCue >= 0.5 else 1-subjectiveCongCue)
  
def start_point(trueCongruence, trueCue):
    if trueCongruence == 'congruent' | trueCongruence == 'neutral':
        return trueCue
    else:
        return -trueCue
try:
    # Load and filter data
    df = pd.read_csv('../inference_test_tidy.csv')
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
        subject_df, rt_column_name='RT', choice_column_name='accuracy')
    
    # initialize model
    model = pyddm.gddm(starting_position=start_point, 
                       T_dur=4.1,
                       bound = 'boundary',
                       drift = drift_rate,
                       parameters={'boundary': (0.25, 12), 'drift': (0, 10)},
                       conditions = {"subjectiveCongCue", 'coherence', 'trueCongruence', 'trueCue','signal1_onset', 'noise2_onset', 'signal2_onset'})

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