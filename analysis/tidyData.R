## tidy data for analysis
library(tidyverse)

####### load in data #######
learning_files = list.files('../data', full.names = TRUE, pattern='block1_learning.*.csv', recursive = TRUE)
learning_keep_idx <- grep('excluded', learning_files, invert=T)
learning_df = do.call(rbind, lapply(learning_files[learning_keep_idx], function(x) { read.csv(x, header = TRUE)} )) 

inference_files = list.files('../data', full.names = TRUE, pattern='block1_inference.csv', recursive = TRUE)
inference_keep_idx <- grep('excluded', inference_files, invert=T)
inference_df = do.call(rbind, lapply(inference_files[inference_keep_idx], function(x) { read.csv(x, header = TRUE)} )) 

evidence_frames <- read.csv('../data/tidied/evidenceFrames.csv')

####### see how many trials had no response ####### 
missed_trials_learning <- learning_df %>% filter(is.na(response)) # only 6 trials total
missed_trials_inference <- inference_df %>% filter(is.na(RT)) # 24 trials, sub 15 alone accounts for 14 of them!
missed_confidence_inference <- inference_df %>% filter(is.na(confRT)) # 29 trials, subs 13 and 15 with the most 

############### tidy learning data ############### 
learning_df_tidy <- learning_df %>%
  mutate(congruent = factor(as.character(congruent), levels=c("0", "1", "NaN"), labels=c('incongruent', 'congruent', 'neutral'))) %>%
  # compute objective cue level based on observed transitions
  group_by(subID, cueIdx, learningRound) %>%
  mutate(tp = ifelse(cueIdx==imageIdx, 1,
                           ifelse(cueIdx==3, 0.5, 0)),
         cueLevel = mean(tp)) %>%
  # because we know there was a bug with the second round of learning, let's discard those trials for now, along with trials where no response was made
  filter(learningRound==1, is.na(RT)==F) %>%
  ungroup() %>%
  mutate(cueLevel = ifelse(congruent=='incongruent', 1-cueLevel, cueLevel),
         learning_quartile = cut(trial, breaks=quantile(trial), include.lowest=T, labels=F)) %>%
  group_by(subID) %>%
  mutate(logRT = log(RT),
         zlogRT = scale(logRT))

## find subjects who had multiple rounds of learning
extra_learn_subs <- learning_df_tidy %>% filter(learningRound==2) %>% select(subID) %>% unique()


############### tidy inference data ############### 
cueLevels <- learning_df_tidy %>% group_by(subID, cueIdx, congruent) %>% summarise(cueLevel = mean(cueLevel))
evidence_frames <- evidence_frames %>% 
  rename(respFrame = response_frame,
         targetIdx = target) %>%
  mutate(congruent = factor(as.character(congruent), levels=c("0", "NaN", "1"), labels=c('incongruent', 'neutral', 'congruent')))

inference_df_tidy <- inference_df %>% 
  mutate(congruent = factor(as.character(congruent), levels=c("0", "NaN", "1"), labels=c('incongruent', 'neutral', 'congruent')), # rename congruent
         signal2frames = ((9*60) - respFrame),
         totalNoise = noise1frames + noise2frames,
         cueIdx = case_when(targetIdx == 1 & congruent == 'congruent' ~ 1,
                            targetIdx == 1 & congruent == 'incongruent' ~ 2,
                            targetIdx == 1 & congruent == 'incongruent' ~ 2,
                            targetIdx == 2 & congruent =='congruent' ~ 2,
                            targetIdx == 2 & congruent=='incongruent' ~ 1,
                            congruent == 'neutral' ~ 3),
         firstNoiseRT = ifelse(respFrame <= noise1frames, 1, 0),
         secondNoiseRT = ifelse(respFrame > (noise1frames+signal1frames) & respFrame <= (noise1frames+signal1frames+noise2frames),
                                1, 0),
         firstSignalRT = ifelse(respFrame > noise1frames & respFrame <= (noise1frames+signal1frames), 1, 0),
         secondSignalRT = ifelse(respFrame > (noise1frames + signal1frames + noise2frames), 1, 0),
         respPeriod = case_when(firstNoiseRT==1 ~ 'noise1',
                                firstSignalRT==1 ~ 'signal1',
                                secondNoiseRT==1 ~ 'noise2',
                                secondSignalRT==1 ~ 'signal2'),
         firstNoise_quartile = cut(noise1frames, breaks=quantile(noise1frames), include.lowest = T, labels=F), 
         secondNoise_quartile = cut(noise2frames, breaks=quantile(noise2frames), include.lowest = T, labels=F), 
         totalNoise_quartile = cut(totalNoise, breaks=quantile(totalNoise), include.lowest = T, labels=F),
         accuracyFactor = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect')),
         cueCongChoice = case_when(cueIdx==3 ~ NA, cueIdx==response ~ 1, cueIdx!=response ~ 0)) %>% 
  left_join(select(cueLevels, c(subID,cueIdx,congruent,cueLevel)), by=c('subID', 'congruent', 'cueIdx')) %>% # add transition probabilities from learning
  filter(is.na(RT)==F, is.na(confRT)==F) %>% # remove trials with no decision response and trials with no confidence response 
  group_by(subID) %>%
  mutate(logRT = log(RT),
         zlogRT = scale(logRT),
         zConf = scale(confResp),
         logConfRT = log(confRT),
         zlogconfRT = scale(logConfRT), 
         rt_quartile = cut(zlogRT, breaks=quantile(zlogRT), include.lowest=T, labels=F),
         trial_quartile = cut(trial, breaks=quantile(trial), include.lowest=T, labels=F)) %>%
  ungroup() %>%
  left_join(evidence_frames, by=c('subID', 'trial', 'catch_trial', 'congruent', 'respFrame', 'targetIdx', 'response'))



########## write out tidied CSVs ############### 
outdir <- '../data/tidied/'
write.csv(learning_df_tidy, paste0(outdir, 'learning_data.csv'), row.names=F)
write.csv(inferenceData_tidy, paste0(outdir, 'inference_data.csv'), row.names=F)
