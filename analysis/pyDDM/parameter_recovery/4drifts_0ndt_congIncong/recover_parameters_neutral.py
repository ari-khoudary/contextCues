# initialize
import pyddm
import pandas as pd
import numpy as np
from pyddm import Sample
import os
import sys
import re

# Get number of CPUs from SLURM environment variable
n_cpus = int(os.environ.get('SLURM_CPUS_PER_TASK', 1))
pyddm.set_N_cpus(n_cpus)

# Get the subject ID and results directory from command line arguments
if len(sys.argv) < 2:
    print("Error: Subject ID not provided. Use as: python fitting_code.py [subject_id] [results_dir]")
    sys.exit(1)

subject_id = sys.argv[1]
results_dir = 'recovered_results'

# Create results directory if it doesn't exist
os.makedirs(results_dir, exist_ok=True)

# make df filtering robust against type mismatches in bash and python
subject_id_str = str(subject_id)
subject_id_int = int(subject_id) 

# specify drift function
def drift(t, signal1_onset, noise2_onset, signal2_onset,
                noise1_neut, signal1_neut, noise2_neut, signal2_neut):
  # drift rate during first noise period
  if t < signal1_onset:
    return noise1_neut
  # drift rates during first signal period
  elif t >= signal1_onset and t < noise2_onset:
     return signal1_neut
  # drift rates during the second noise period
  elif t >= noise2_onset and t < signal2_onset:
     return noise2_neut
  # drift rates during the second signal period
  elif t >= signal2_onset:
      return signal2_neut
    
def extract_parameters_from_results(results_file):
    """Extract parameters from a results file."""
    if not os.path.exists(results_file):
        return None, None
        
    with open(results_file, 'r') as f:
        content = f.read()
    
    # Extract loss
    # loss_match = re.search(r'Loss: ([\d\.]+)', content)
    # if not loss_match:
    #     return None, None
    # loss = float(loss_match.group(1))
    
    # Extract parameters
    params = {}
    pattern = r"'([\w_]+)': Fitted\(([\d\.\-]+), minval=([\d\.\-]+), maxval=([\d\.\-]+)\)"
    for name, value, minval, maxval in re.findall(pattern, content):
        params[name] = {
            'fitted': float(value),
            'minval': float(minval),
            'maxval': float(maxval)
        }

    fitted_params = {key: value_dict['fitted'] for key, value_dict in params.items()}
        
    return fitted_params

try:
    # load fits 
    fits_file = os.path.join('results/', f"s{subject_id}_results.txt")
    fitted_params = extract_parameters_from_results(fits_file)
    neut_fitted_params = {k: v for k, v in fitted_params.items() if k.endswith('_neut') or k == 'B'}

    # Load experimental data
    df = pd.read_csv('../../inference_test.csv')
    df = df.dropna(subset=['RT'])
    df[['signal1_onset', 'noise2_onset', 'signal2_onset']] = df[['signal1_onset', 'noise2_onset', 'signal2_onset']].fillna(0)
    subject_df = df[(df['subID'] == subject_id_str) | 
                (df['subID'] == subject_id_int)].copy()

    # get onsets
    neutral_trials = subject_df[subject_df['trueCongruence'] == 'neutral']
    onsets = neutral_trials[['signal1_onset', 'noise2_onset', 'signal2_onset']].value_counts()
    onsets = onsets.reset_index()
    
    # initialize model
    fitting_model = pyddm.gddm(
        drift = drift,
        starting_position = 0,
        bound="B",
        T_dur = 4.1,
        nondecision=0,
        parameters={'B': (0.5, 12), 
                    'noise1_neut': (0, 10), 'signal1_neut': (0, 10), 'noise2_neut': (0, 10), 'signal2_neut': (0, 10)},
        conditions = ['signal1_onset', 'noise2_onset', 'signal2_onset'])

   
    # specify generating model
    generating_model = pyddm.gddm(
        drift = drift,
        starting_position = 0,
        bound="B",
        T_dur = 4.1,
        nondecision=0,
        parameters = neut_fitted_params,
        conditions = ['signal1_onset', 'noise2_onset', 'signal2_onset'])
    
    # create a sample for each combination of onsets
    initial_run = True
    for index, row in onsets.iterrows():
        signal1_onset = int(row['signal1_onset'])
        noise2_onset = int(row['noise2_onset'])
        signal2_onset = int(row['signal2_onset'])
        nTrials = int(row['count'])

        if initial_run == True:
            sample = generating_model.solve(conditions = {'signal1_onset': signal1_onset, 
                                                          'noise2_onset': noise2_onset, 
                                                          'signal2_onset': signal2_onset}).sample(nTrials)
            initial_run = False
        else:
            sample += generating_model.solve(conditions = {'signal1_onset': signal1_onset, 
                                                          'noise2_onset': noise2_onset, 
                                                          'signal2_onset': signal2_onset}).sample(nTrials)

    fitting_model.fit(sample, verbose=False)
    
    
    # Gather results
    loss = fitting_model.get_fit_result().value()
    params = fitting_model.parameters()
    
    # Save text results (basic summary)
    with open(os.path.join(results_dir, f's{subject_id}_cong.txt'), 'w') as f:
        f.write(f'Subject: {subject_id}\nLoss: {loss}\nParameters:\n')
        for param, value in params.items():
            f.write(f'{param}: {value}\n')

    original_stdout = sys.stdout
    with open(os.path.join(results_dir, f's{subject_id}_cong_summary.txt'), "w") as f:
        sys.stdout = f
        fitting_model.show()
    sys.stdout = original_stdout
    
except Exception as e:
    error_msg = f"Error processing subject {subject_id}: {str(e)}"
    # Save error information
    with open(os.path.join(results_dir, f's{subject_id}_error.txt'), 'w') as f:
        f.write(error_msg)