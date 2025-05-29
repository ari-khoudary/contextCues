#!/bin/bash

#SBATCH --job-name=simple4
#SBATCH -A bornstea_lab
#SBATCH -p standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --output=slurm_messages/slurm-%A_%a.out 
#SBATCH --error=slurm_messages/slurm-%A_%a.err
#SBATCH -t 1-00:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=makhouda@uci.edu
#SBATCH --array=0-43  # Adjust the range based on your subject list length

mkdir -p slurm_messages

source ~/.bashrc
module load python/3.10.2

# Get the subject ID for this task
SUBJECT=$(python -c "
import pandas as pd
df = pd.read_csv('../../../inference_test.csv')
subjects = df['subID'].unique().tolist()
if $SLURM_ARRAY_TASK_ID < len(subjects):
    print(subjects[$SLURM_ARRAY_TASK_ID])
")

# # Skip if no subject found
if [ -z "$SUBJECT" ]; then
    echo "No subject found for task ID $SLURM_ARRAY_TASK_ID. Exiting."
    exit 0
fi

# fit on last subs of expt 1
#SUBJECT_LIST=("73" "75" "76" "77")
#SUBJECT=${SUBJECT_LIST[$SLURM_ARRAY_TASK_ID]}

# Run the fitting code
python -u fit_model.py ${SUBJECT}