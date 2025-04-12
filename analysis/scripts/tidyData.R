### loads, tidies, and outputs aggregated & tidied dataframes for both conditions
library(tidyverse)

# Create a vector of condition names
conditions <- c("condition_80cue", "condition_65cue")

# specify nFrames based on matlab expt code
nFrames = 240

# Process each condition
for (cond_string in conditions) {
  # Set cueValue based on condition
  cueValue <- ifelse(cond_string == "condition_80cue", 80, 65)
  
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
           respFrame = ifelse(is.na(respFrame), nFrames, respFrame),
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
  
  # Only run this block for 80cue condition
  if (cond_string == "condition_80cue") {
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
    
    # add learning2_df to learning_df
    learning_df <- rbind(learning_df, learning2_df)
  }
  
  # tidy
  learning_df <- learning_df %>%
    mutate(congruent = factor(congruent, levels=c("0", "1", "NaN"), labels=c('incongruent', 'congruent', 'neutral')),
           trueCue = case_when(congruent != 'neutral' ~ cueValue,
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
    mutate(trueCue = case_when(cueIdx != '3' ~ cueValue/100,
                               cueIdx == '3' ~ 0.5)) %>%
    rename(cueName = cueString,
           cueConfidence = confidence)
  
  # tidy up / add relevant variables to estimate
  estimates <- learnVal_df %>%
    select(c(subID, block, cueName, cueIdx, congImgIdx, RT, sliderValue, cueConfidence, confRT, trueCue)) %>%
    mutate(imgIdx_subjective = case_when(cueIdx==1 & sliderValue < 50 | cueIdx==2 & sliderValue > 50 | cueIdx==3 & sliderValue==50 ~ congImgIdx,
                                         cueIdx==1 & sliderValue > 50 | cueIdx==2 & sliderValue < 50 ~ 3-congImgIdx,
                                         cueIdx==3 & sliderValue > 50 ~ 2,
                                         cueIdx==3 & sliderValue < 50 ~ 1),
           subjectiveCue = case_when(imgIdx_subjective==1 ~ 100-sliderValue, 
                                     imgIdx_subjective==2 ~ sliderValue,
                                     is.na(imgIdx_subjective) ~ 50),
           subjectiveCongCue = case_when(congImgIdx=='NaN' & imgIdx_subjective==1 ~ 100 - sliderValue,
                                         congImgIdx=='NaN' & imgIdx_subjective==2 ~ sliderValue,
                                         congImgIdx==1 ~ 100 - sliderValue,
                                         congImgIdx==2 ~ sliderValue),
           subjectiveCue = subjectiveCue / 100,
           subjectiveCongCue = subjectiveCongCue / 100)

  # write out tidied data
  write.csv(estimates, paste0(outdir, 'learningValidation.csv'), row.names = F)
  
  #### inference ####
  # load
  inference_files = list.files(indir, full.names = TRUE, pattern='cuedInference_table.csv', recursive = T)
  inference_keep_idx <- grep('excluded', inference_files, invert=T)
  inference_df = do.call(rbind, lapply(inference_files[inference_keep_idx], function(x) { read.csv(x, header = TRUE)} ))
  
  # Prepare estimates for joining with inference data
  estimates <- estimates %>% 
    select(c(subID, block, cueName, cueIdx, cueConfidence, imgIdx_subjective, subjectiveCue, subjectiveCongCue))
  
  # tidy
  inference_df <- inference_df %>%
    left_join(., estimates, by=c('subID', 'block', 'cueName', 'cueIdx')) %>%
    mutate(trueCongruence = factor(congruent, levels=c("0", "1", "NaN"), labels=c('incongruent', 'congruent', 'neutral')),
           trueCue = case_when(cueIdx < 3 ~ cueValue/100,
                               cueIdx == 3 ~ 0.5),
           congCue = ifelse(trueCongruence=='incongruent', 1-trueCue, trueCue),
           respFrame = ifelse(is.na(respFrame), nFrames, respFrame),
           signal1Onset_design = ifelse(is.na(response)==0 & is.na(signal1frames_obs), NA, signal1Onset_design),
           noise2Onset_design = ifelse(is.na(response)==0 & is.na(noise2frames_obs), NA, noise2Onset_design),
           signal2Onset_design = ifelse(is.na(response)==0 & is.na(signal2frames_obs), NA, signal2Onset_design),
           conversionFactor = respFrame / RT,
           conversionFactor = case_when(is.na(RT) ~ mean(conversionFactor, na.rm=T),
                                        is.na(RT)==0 ~ conversionFactor),
           noise1_duration = noise1frames_obs / conversionFactor,
           signal1_onset = signal1Onset_design / conversionFactor,
           signal1_duration = signal1frames_obs / conversionFactor,
           noise2_onset = noise2Onset_design / conversionFactor,
           noise2_duration = noise2frames_obs / conversionFactor,
           signal2_onset = signal2Onset_design / conversionFactor,
           signal2_duration = signal2frames_obs / conversionFactor) %>%
    group_by(subID) %>%
    mutate(zlogRT = scale(log(RT))) %>%
    select(c(subID, block, trial, cueName, targetName, cueIdx, targetIdx, response, accuracy, RT, confidence, confRT, flickerDuration, coherence, catch_trial,
             cueConfidence, imgIdx_subjective, subjectiveCue, subjectiveCongCue, trueCue, congCue, noise1_duration, signal1_onset, noise2_onset, noise2_duration,
             signal2_onset, signal2_duration, zlogRT))
  
  # write out tidied inference data
  write.csv(inference_df, paste0(outdir, 'inference.csv'), row.names = F)
}
