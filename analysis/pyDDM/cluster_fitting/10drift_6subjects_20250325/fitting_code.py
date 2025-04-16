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

# Create results directory
results_dir = f'fitting_results_{datetime.now().strftime("%Y%m%d_%H%M%S")}'
os.makedirs(results_dir, exist_ok=True)

# Load data efficiently
df = pd.read_csv('inference_tidy.csv', usecols=['subID', 'RT', 'accuracy', 'trueCue', 'coherence', 
                                               'signal1_onset', 'noise2_onset', 'signal2_onset'])
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
            drift=drift_weights2,
            starting_position=0,
            bound="B",
            T_dur=4.1,
            nondecision='ndt',
            parameters={'B': (0.01, 10), 'ndt': (0, 0.4),
                       'mw80_noise1': (-1, 1), 'mw50_noise1': (-1,1),
                       'mw80_signal1': (-1, 1), 'mw50_signal1': (-1, 1),
                       'mw80_noise2': (-1, 1), 'mw50_noise2': (-1,1),
                       'mw80_signal2': (-1, 1), 'mw50_signal2': (-1, 1),
                       'vw80_signal1': (-1, 1), 'vw50_signal1': (-1, 1),
                       'vw80_signal2': (-1, 1), 'vw50_signal2': (-1, 1)},
            conditions=['trueCue', 'coherence', 'signal1_onset', 'noise2_onset', 'signal2_onset']
        )
        
        # Fit the model (parallelization happens internally)
        model.fit(subject_sample, verbose=False)
        
        # Save results
        results[subject] = {
            'parameters': model.parameters(),
            'loss': model.get_fit_result().value()
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