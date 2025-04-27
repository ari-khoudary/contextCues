#!/bin/bash

#SBATCH --job-name=4drifts
#SBATCH -A bornstea_lab
#SBATCH -p standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH -c 12
#SBATCH --output=slurm_messages/slurm-%A_%a.out 
#SBATCH --error=slurm_messages/slurm-%A_%a.err
#SBATCH -t 1-00:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=makhouda@uci.edu
#SBATCH --array=0-40  # Adjust the range based on your subject list length

mkdir -p slurm_messages

source ~/.bashrc
module load python/3.10.2

# get unique subject IDs
# Get the subject ID for this task
SUBJECT=$(python -c "
import pandas as pd
df = pd.read_csv('../../inference_all.csv')
subjects = df['subID'].unique().tolist()
if $SLURM_ARRAY_TASK_ID < len(subjects):
    print(subjects[$SLURM_ARRAY_TASK_ID])
")

# Skip if no subject found
if [ -z "$SUBJECT" ]; then
    echo "No subject found for task ID $SLURM_ARRAY_TASK_ID. Exiting."
    exit 0
fi

# Run the fitting code
<<<<<<< HEAD
python -u fit_model.py ${SUBJECT}
=======
python -u fit_model.py ${SUBJECT}
>>>>>>> 0cd9647 (make new directory)
