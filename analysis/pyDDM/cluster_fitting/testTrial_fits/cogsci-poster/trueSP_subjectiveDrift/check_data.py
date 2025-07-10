# %% 
import pandas as pd
import numpy as np

#%%
df = pd.read_csv('inference_test_tidy.csv')

check_df =df.drop_duplicates(subset=['subID', 'subjectiveCongCue', 'trueCongruence'])

check_df = check_df[['subID', 'subjectiveCongCue', 'trueCue', 'trueCongruence']]

with pd.option_context('display.max_rows', None):
    print(check_df)