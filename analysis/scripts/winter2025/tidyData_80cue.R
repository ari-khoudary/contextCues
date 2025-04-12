### loads, tidies, and outputs aggregated & tidied dataframes
library(tidyverse)

# add condition flag
cond_string <- 'condition_80cue'

# define directory to write tidied data
outdir <- paste0('../tidied_data/', cond_string, '/')

# define directory to read in data from
indir <- paste0('../../data/', cond_string)
  

#### calibration data ####
# load
calibration_files = list.files(indir, full.names = TRUE, pattern='calibration.csv', recursive = T)
calibration_keep_idx <- grep('excluded', calibration_files, invert=T)
calibration_df = do.call(rbind, lapply(calibration_files[calibration_keep_idx], function(x) { read.csv(x, header = TRUE)} )) 

# tidy
calibration_df <- calibration_df %>%
  mutate(subID = factor(subID),
         accuracyFactor = factor(ifelse(accuracy==1, 1, 0))) %>%
  group_by(subID) %>%
  mutate(zlogRT = scale(log(RT))) %>% 
  ungroup()

# write
write.csv(calibration_df, paste0(outdir, 'calibration.csv'), row.names = F)


#### coherence validation ####
# load
cohVal_files = list.files(indir, full.names = TRUE, pattern='coherenceValidation.csv', recursive = T)
calibration_keep_idx <- grep('excluded', cohVal_files, invert=T)
cohVal_df = do.call(rbind, lapply(cohVal_files[calibration_keep_idx], function(x) { read.csv(x, header = TRUE)} )) 

# tidy
cohVal_df <- cohVal_df %>%
  mutate(subID = factor(subID),
         accuracyFactor = factor(ifelse(accuracy==1, 1, 0)),
         respFrame = ifelse(is.na(respFrame), 240, respFrame),
         signal1Onset_design = ifelse(is.na(response)==0 & is.na(signal1frames_obs), NA, signal1Onset_design),
         noise2Onset_design = ifelse(is.na(response)==0 & is.na(noise2frames_obs), NA, noise2Onset_design),
         signal2Onset_design = ifelse(is.na(response)==0 & is.na(signal2frames_obs), NA, signal2Onset_design),
         conversionFactor = respFrame / RT,
         conversionFactor = case_when(is.na(conversionFactor)==1 ~ mean(conversionFactor, na.rm=T),
                                      is.na(conversionFactor)==0 ~ conversionFactor),
         noise1_duration = noise1frames_obs / conversionFactor,
         signal1_onset = signal1Onset_design / conversionFactor,
         signal1_duration = signal1frames_obs / conversionFactor,
         noise2_onset = noise2Onset_design / conversionFactor,
         noise2_duration = noise2frames_obs / conversionFactor,
         signal2_onset = signal2Onset_design / conversionFactor,
         signal2_duration = signal2frames_obs / conversionFactor) %>%
  select(c(subID, block, trial, targetName, targetIdx, response, accuracy, RT, postFlickerResp, confidence, confRT, coherence,  
           noise1_duration, signal1_onset, signal1_duration, noise2_onset, noise2_duration, signal2_onset, signal2_duration)) %>%
  group_by(subID) %>%
  mutate(zlogRT = scale(log(RT)))

# write
write.csv(cohVal_df, paste0(outdir, 'coherenceValidation.csv'), row.names = F)


#### cue learning ####
learning_files = list.files(indir, full.names = TRUE, pattern='learning.csv', recursive = T)
learning_keep_idx <- grep('excluded', learning_files, invert=T)
learning_df = do.call(rbind, lapply(learning_files[learning_keep_idx], function(x) { read.csv(x, header = TRUE)} )) 
# load second round of learning data (if applicable)
learning2_files = list.files(indir, full.names = TRUE, pattern='learning2.csv', recursive = T)
learning2_keep_idx <- grep('excluded', learning2_files, invert=T)
learning2_df = do.call(rbind, lapply(learning2_files[learning2_keep_idx], function(x) { read.csv(x, header = TRUE)} )) # append round 2 onto round 1 dataframe

# tidy learning 2 -- make trial numbers continguous with first round of learning
## first get max number of learning trials in the first round
nLearningTrials <- max(unique(learning_df$trial))
## then add a column to learning2 that counts up from there within a participant
learning2_df <- learning2_df %>%
  group_by(subID) %>%
  mutate(trial = row_number() + (nLearningTrials))

# add learning2_df to learning_df and tidy
learning_df <- learning_df %>%
  rbind(., learning2_df) %>%
  mutate(congruent = factor(congruent, levels=c("0", "1", "NaN"), labels=c('incongruent', 'congruent', 'neutral')),
         trueCue = case_when(congruent != 'neutral' ~ 0.66,
                             congruent == 'neutral' ~ 0.5),
         congCue = ifelse(congruent=='incongruent', 1-trueCue, trueCue),
         imgLockedRT = RT - cueDuration) 

# write out 
write.csv(learning_df, paste0(outdir, 'learning.csv'), row.names = F)


#### learning validation ####
# load
learnVal_files = list.files(indir, full.names = TRUE, pattern='learningValidation.csv', recursive = T)
learnVal_keep_idx <- grep('excluded', learnVal_files, invert=T)
learnVal_df = do.call(rbind, lapply(learnVal_files[learnVal_keep_idx], function(x) { read.csv(x, header = TRUE)} ))

# tidy
learnVal_df <- learnVal_df %>%
  mutate(subID = factor(subID),
         cueIdx = factor(cueIdx),
         trueCue = case_when(cueIdx != '3' ~ 80,
                             cueIdx == '3' ~ 50)) %>%
  rename(cueName = cueString,
         cueConfidence = confidence)


#### inference ####
# load
inference_files = list.files(indir, full.names = TRUE, pattern='cuedInference_table.csv', recursive = T)
inference_keep_idx <- grep('excluded', inference_files, invert=T)
inference_df = do.call(rbind, lapply(inference_files[inference_keep_idx], function(x) { read.csv(x, header = TRUE)} ))

# tidy
inference_df <- inference_df %>%
  mutate(congruent = factor(congruent, levels=c("0", "1", "NaN"), labels=c('incongruent', 'congruent', 'neutral')),
         cueCongResponse_obj = case_when(cueIdx < 3 & response==cueIdx ~ 1,
                                         cueIdx < 3 & response!=cueIdx ~ 0,
                                         cueIdx==3 ~ NA),
         accuracyFactor = factor(case_when(accuracy==1 ~ 1,
                                           accuracy==0 ~ 0)),
         trueCue = case_when(cueIdx < 3 ~ 80,
                             cueIdx == 3 ~ 50),
         congCue = factor(case_when(congruent=='congruent' ~ trueCue/100,
                                    congruent=='incongruent' ~ (100-trueCue)/100,
                                    congruent=='neutral' ~ 0.5)),
         subID = factor(subID)) %>%
  group_by(subID) %>%
  mutate(zlogRT = scale(log(RT)),
         cueIdx = factor(cueIdx)) %>%
  ungroup()


#### add subjective cue values to inference ####
# tidy up / add relevant variables to estimate
estimates <- learnVal_df %>%
  select(c(subID, block, cueName, cueIdx, estimate, congImgIdx, sliderValue, cueConfidence)) %>%
  filter(subID != '33') %>%
  mutate(imgIdx_subjective = case_when(cueIdx==1 & sliderValue < 50 |
                                         cueIdx==2 & sliderValue > 50 |
                                         cueIdx==3 & sliderValue==50 ~ congImgIdx,
                                       cueIdx==1 & sliderValue > 50 |
                                         cueIdx==2 & sliderValue < 50 ~ 3-congImgIdx,
                                       cueIdx==3 & sliderValue > 50 ~ 2,
                                       cueIdx==3 & sliderValue < 50 ~ 1),
         subjectiveCue = case_when(estimate < 50 ~ 100 - estimate,
                              estimate >= 50 ~ estimate),
         subjectiveCue = ifelse((cueIdx==1 | cueIdx==2) & cueIdx != imgIdx_subjective, 100-subjectiveCue, subjectiveCue)) %>%
  group_by(subID) %>%
  mutate(subjectiveCueOrder = factor(case_when(subjectiveCue==max(subjectiveCue) ~ 1,
                                        subjectiveCue==min(subjectiveCue) ~ 3,
                                        subjectiveCue < max(subjectiveCue) & subjectiveCue > min(subjectiveCue) ~ 2)))
# write out tidied data
write.csv(estimates, paste0(outdir, 'learningValidation.csv'), row.names = F)

# add to inference
estimates <-  estimates %>% select(c(subID, block, cueName, cueIdx, imgIdx_subjective, subjectiveCue, cueConfidence, subjectiveCueOrder))

inference_df <- inference_df %>%
  left_join(., estimates, by=c('subID', 'block', 'cueName', 'cueIdx')) %>%
  rename(trueCongruence = congruent) %>%
  mutate(subjectiveCongruence = case_when(imgIdx_subjective!=targetIdx ~ 'incongruent',
                                          imgIdx_subjective==targetIdx ~ 'congruent',
                                          is.na(imgIdx_subjective)==1 ~ 'neutral'))

# add columns to inference that were added in subsequent analyses scripts
inference_df <- inference_df %>%
  mutate(respPeriod = factor(case_when(respFrame < signal1Onset_design ~ 1,
                             respFrame >= signal1Onset_design & respFrame < noise2Onset_design ~ 2,
                             respFrame >= noise2Onset_design & respFrame < signal2Onset_design ~ 3,
                             respFrame >= signal2Onset_design ~ 4)),
         respLabel = factor(respPeriod, labels=c('noise1', 'signal1', 'noise2', 'signal2')),
  catch_label = factor(catch_trial, levels=c(0,1), labels=c('test trials', 'catch trials'))) %>%
  group_by(subID) %>%
  mutate(sig1Locked_rt = RT - (signal1Onset_design/72),
         sig2Locked_rt = RT - (signal2Onset_design/72),
         zlogRT_sig1locked = scale(log(sig1Locked_rt)),
         zlogRT_sig2locked = scale(log(sig2Locked_rt))) %>%
  ungroup()


# write out tidied inference data
write.csv(inference_df, paste0(outdir, 'inference.csv'), row.names = F)

# add respPeriod & noise_obs to model data
model_df <- read.csv('../tidied_data/steadyState_modelBehavior.csv')
model_df <- model_df %>%
  mutate(respPeriod = case_when(RT < signal1Onsets ~ 1,
                                       RT = signal1Onsets & RT < noise2Onsets ~ 2,
                                       RT >= noise2Onsets & RT < signal2Onsets ~ 3,
                                       RT >= signal2Onsets ~ 4),
         respLabel = factor(respPeriod, labels=c('noise1', 'signal1', 'noise2', 'signal2')),
         noise1Frames_obs = case_when(respPeriod==1 ~ RT,
                                      respPeriod>1 ~ noise1Frames),
         signal1Frames_obs = case_when(respPeriod==2 ~ RT - noise1Frames,
                                       respPeriod==1 ~ NA,
                                       respPeriod>2 ~ signal1Frames),
         noise2Frames_obs = case_when(respPeriod==3 ~ RT - (noise1Frames + signal1Frames),
                                      respPeriod<3 ~ NA,
                                      respPeriod>3 ~ noise2Frames),
         signal2Frames_obs = case_when(respPeriod==4 ~ RT - (noise1Frames + signal1Frames + noise2Frames),
                                       respPeriod<4 ~ NA),
         signal1Locked_rt = RT - signal1Onsets,
         signal2Locked_rt = RT - signal2Onsets,
         congCue = case_when(congruent==1 ~ cue,
                             congruent==0 ~ 1-cue),
         cueCongChoice = case_when(congruent==1 & forcedChoice==1 ~ 1,
                                   congruent==0 & forcedChoice==0 ~ 1,
                                   congruent==1 & forcedChoice==0 ~ 0,
                                   congruent==0 & forcedChoice==1 ~ 0,
                                   cue==0.5 ~ NA)) %>%
  group_by(subID) %>%
  mutate(zlogRT = scale(log(RT)),
         zlogRT_sig1locked = scale(log(signal1Locked_rt)),
         zlogRT_sig2locked = scale(log(signal2Locked_rt))) %>%
  ungroup()

write.csv(model_df, paste0(outdir, 'model.csv'), row.names = F)

# remove variables from workspace
rm(calibration_files, calibration_keep_idx, cohVal_files, inference_files, inference_keep_idx, learning_files, learning_keep_idx,
   learning2_files, learning2_keep_idx, learnVal_files, learnVal_keep_idx, nLearningTrials)
