# initialize
import pyddm
import pandas as pd
import numpy as np
from pyddm import Sample
import os
from datetime import datetime
import gc

# Get number of CPUs from SLURM environment variable
n_cpus = int(os.environ.get('SLURM_CPUS_PER_TASK', 1))
pyddm.set_N_cpus(n_cpus)

# specify drift function
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
    
# Create results directory
results_dir = f'fitting_results_{datetime.now().strftime("%Y%m%d_%H%M%S")}'
os.makedirs(results_dir, exist_ok=True)

# Load data efficiently
df = pd.read_csv('../inference_tidy.csv')
df = df.dropna(subset=['RT'])

# Get all unique subjects
unique_subjects = df['subID'].unique()
results = {}

for subject in unique_subjects:
    try:
        # Process subject data
        subject_df = df[df['subID'] == subject].copy()
        subject_sample = pyddm.Sample.from_pandas_dataframe(
            subject_df, rt_column_name="RT", choice_column_name="accuracy"
        )
        del subject_df
        gc.collect()

        # Fit model
        model = pyddm.gddm(
            drift=eightDrifts,
            starting_position = 0,
            bound="B",
            T_dur = 4.1,
            nondecision=0.2,
            parameters={'B': (0.01, 10), 
                'noise1Drift_80': (-1, 1), 'noise1Drift_50': (-1,1),
                'signal1Drift_80': (-1, 1), 'signal1Drift_50': (-1, 1),
                'noise2Drift_80': (-1, 1), 'noise2Drift_50': (-1,1),
                'signal2Drift_80': (-1, 1), 'signal2Drift_50': (-1, 1)},
    conditions = ['trueCongruence', 'coherence', 'signal1_onset', 'noise2_onset', 'signal2_onset'])

        
        # Fit the model (parallelization happens internally)
        model.fit(subject_sample, verbose=False)
        
        # Save results
        results[subject] = {
            'loss': model.get_fit_result().value(),
            'boundary': model.parameters()['B'],
            'drifts': {
                'noise1': {
                    '80': model.parameters()['noise1Drift_80'],
                    '50': model.parameters()['noise1Drift_50']
                },
                'signal1': {
                    '80': model.parameters()['signal1Drift_80'],
                    '50': model.parameters()['signal1Drift_50']
                },
                'noise2': {
                    '80': model.parameters()['noise2Drift_80'],
                    '50': model.parameters()['noise2Drift_50']
                },
                'signal2': {
                    '80': model.parameters()['signal2Drift_80'],
                    '50': model.parameters()['signal2Drift_50']
                }
            }
        }
        
        with open(os.path.join(results_dir, f'subject_{subject}_results.txt'), 'w') as f:
            f.write(f"Subject: {subject}\nLoss: {model.get_fit_result().value()}\nParameters:\n")
            for param, value in model.parameters().items():
                f.write(f"{param}: {value}\n")
        
        # Cleanup
        del model, subject_sample
        gc.collect()
        
    except Exception as e:
        results[subject] = {'error': str(e)}

# Save summary
with open(os.path.join(results_dir, 'summary.txt'), 'w') as f:
    f.write(f"Fitting Results Summary\nDate: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"Total Subjects: {len(unique_subjects)}\n\n")
    for subject, result in results.items():
        f.write(f"\nSubject {subject}:\n")
        f.write(f"{'Error: ' + result['error'] if 'error' in result else 'Loss: ' + str(result['loss'])}\n")