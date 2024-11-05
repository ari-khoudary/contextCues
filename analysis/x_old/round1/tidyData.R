## tidy data for analysis
library(tidyverse)

####### load in data #######
evidence_frames <- read.csv('../data/tidied/evidenceFrames.csv')
inference_files = list.files('../data', full.names = TRUE, pattern='block1_inference.csv', recursive = TRUE)
inference_keep_idx <- grep('excluded', inference_files, invert=T)
inference_df = do.call(rbind, lapply(inference_files[inference_keep_idx], function(x) { read.csv(x, header = TRUE)} )) 


############### tidy inference data ############### 
evidence_frames <- evidence_frames %>%rename(respFrame = response_frame)
inference_df_ev <- inference_df %>%
  filter(subID != 16) %>%
  select(-c(noise1frames, noise2frames, signal1frames, block, targetImg, cue_rgb, cue_string, targetIdx)) %>%
  full_join(., evidence_frames, by=c('subID', 'trial', 'catch_trial', 'congruent', 'respFrame', 'response')) %>%
  mutate(accuracy = case_when(rowSums(across(c(signal1_target1, signal2_target1)), na.rm=T) > rowSums(across(c(signal1_target2, signal2_target2)), na.rm=T) & response==1 ~ 1,
                                  rowSums(across(c(signal1_target1, signal2_target1)), na.rm=T) > rowSums(across(c(signal1_target2, signal2_target2)), na.rm=T) & response==2 ~ 0,
                                  rowSums(across(c(signal1_target1, signal2_target1)), na.rm=T) < rowSums(across(c(signal1_target2, signal2_target2)), na.rm=T) & response==2 ~ 1,
                                  rowSums(across(c(signal1_target1, signal2_target1)), na.rm=T) < rowSums(across(c(signal1_target2, signal2_target2)), na.rm=T) & response==1 ~ 0),
         accuracyFactor = factor(as.character(accuracy), levels=c("0", "1", "NaN"), labels=c('correct', 'incorrect', 'NA')),
         congruent = factor(as.character(congruent), levels=c("0", "NaN", "1"), labels=c('incongruent', 'neutral', 'congruent')),
         cueIdx = case_when(target == 1 & congruent == 'congruent' ~ 1,
                            target == 1 & congruent == 'incongruent' ~ 2,
                            target == 1 & congruent == 'incongruent' ~ 2,
                            target == 2 & congruent =='congruent' ~ 2,
                            target == 2 & congruent=='incongruent' ~ 1,
                            congruent == 'neutral' ~ 3),
         signal2frames = (respFrames - (noise1frames + signal1frames + noise2frames)),
         totalNoise = noise1frames + noise2frames,
         firstNoiseRT = ifelse(respFrame <= noise1frames, 1, 0),
         secondNoiseRT = ifelse(respFrame > (noise1frames+signal1frames) & respFrame <= (noise1frames+signal1frames+noise2frames),
                                1, 0),
         firstSignalRT = ifelse(respFrame > noise1frames & respFrame <= (noise1frames+signal1frames), 1, 0),
         secondSignalRT = ifelse(respFrame > (noise1frames + signal1frames + noise2frames), 1, 0),
         respPeriod = case_when(firstNoiseRT==1 ~ 'noise1',
                                firstSignalRT==1 ~ 'signal1',
                                secondNoiseRT==1 ~ 'noise2',
                                secondSignalRT==1 ~ 'signal2'), 
          cueCongChoice = case_when(cueIdx==3 ~ NA, cueIdx==response ~ 1, cueIdx!=response ~ 0),
         firstNoise_quartile = cut(noise1frames, breaks=quantile(noise1frames), include.lowest = T, na.rm=T), 
         secondNoise_quartile = cut(noise2frames, breaks=quantile(noise2frames), include.lowest = T, labels=F, na.rm=T), 
         totalNoise_quartile = cut(totalNoise, breaks=quantile(totalNoise), include.lowest = T, labels=F, na.rm=T)) %>%
  group_by(subID) %>%
  mutate(logRT = log(RT),
         zlogRT = scale(logRT),
         zConf = scale(confResp),
         logConfRT = log(confRT),
         zlogconfRT = scale(logConfRT), 
         rt_quartile = cut(zlogRT, breaks=quantile(zlogRT, na.rm=T), include.lowest=T, labels=F),
         trial_quartile = cut(trial, breaks=quantile(trial), include.lowest=T, labels=F))

  # to see which trials had the wrong target saved
  # check <- inference_df %>%
  #   filter(subID != 16) %>%
  #   select(-c(noise1frames, noise2frames, signal1frames, block, targetImg, cue_rgb, cue_string)) %>%
  #   full_join(., evidence_frames, by=c('subID', 'trial', 'catch_trial', 'congruent', 'respFrame', 'response')) %>%
  #   mutate(targetDiff = target - targetIdx) %>%
  #   filter(targetDiff != 0)
         

############### tidy learning data ############### 
learning_files = list.files('../data', full.names = TRUE, pattern='block1_learning.*.csv', recursive = TRUE)
learning_keep_idx <- grep('excluded', learning_files, invert=T)
learning_df = do.call(rbind, lapply(learning_files[learning_keep_idx], function(x) { read.csv(x, header = TRUE)} )) 
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



########## write out tidied CSVs ############### 
outdir <- '../data/tidied/'
#write.csv(learning_df_tidy, paste0(outdir, 'learning_data.csv'), row.names=F)
write.csv(inference_df_ev, paste0(outdir, 'inference_data_ev.csv'), row.names=F)
#write.csv(inference_df_tidy, paste0(outdir, 'inference_data_wrongNoiseInfo.csv'), row.names=F)

