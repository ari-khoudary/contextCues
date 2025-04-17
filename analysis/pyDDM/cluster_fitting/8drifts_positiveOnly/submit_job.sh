#!/bin/bash

#SBATCH --job-name=8drifts
#SBATCH -A bornstea_lab
#SBATCH -p standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH -c 28
#SBATCH --error=slurm-%A_%a.err
#SBATCH -t 1-00:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=makhouda@uci.edu
#SBATCH --array=0-25  # Adjust the range based on your subject list length

source ~/.bashrc
module load python/3.10.2

# get unique subject IDs
# Get the subject ID for this task
SUBJECT=$(python -c "
import pandas as pd
df = pd.read_csv('../inference_tidy.csv')
subjects = df['subID'].unique().tolist()
if $SLURM_ARRAY_TASK_ID < len(subjects):
    print(subjects[$SLURM_ARRAY_TASK_ID])
")

# Skip if no subject found
if [ -z "$SUBJECT" ]; then
    echo "No subject found for task ID $SLURM_ARRAY_TASK_ID. Exiting."
    exit 0
fi

# Create directory
RESULTS_DIR="s${SUBJECT}"
mkdir -p $RESULTS_DIR

# Run the fitting code
python -u fit_model.py ${SUBJECT} ${RESULTS_DIR}