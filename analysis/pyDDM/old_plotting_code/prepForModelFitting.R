library(tidyverse)

df <- read.csv('../tidied_data/condition_80cue/inference.csv')

out_df <- df %>%
  mutate(noise1duration = noise1frames_obs / 72,
         signal1duration = signal1frames_obs / 72,
         noise2duration = noise2frames_obs / 72,
         signal2duration = signal2frames_obs / 72,
         signal1_onset = ifelse(is.na(signal1frames_obs)==0, signal1Onset_design / 72, 0),
         noise2_onset = ifelse(is.na(noise2frames_obs)==0, noise2Onset_design / 72, 0),
         signal2_onset = ifelse(is.na(signal2frames_obs)==0, signal2Onset_design / 72, 0))

out_df <- out_df %>%
  filter(catch_trial==0) %>%
  mutate(trueCue = case_when(trueCongruence=='congruent' ~ trueCue / 100,
                             trueCongruence=='incongruent' ~ -1* (trueCue / 100),
                             trueCongruence=='neutral' ~ trueCue / 100),
         coherence = rep(0.7, nrow(.))) %>%
  select(subID, block, trial, cueIdx, targetIdx, trueCongruence, response, accuracy, RT, respFrame, trueCue, coherence,
         noise1duration, signal1duration, noise2duration, signal2duration, signal1_onset, noise2_onset, signal2_onset)

write.csv(out_df, '../../../pyDDM/inference_tidy.csv', row.names = F)

