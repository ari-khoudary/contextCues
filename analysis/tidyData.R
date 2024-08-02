## tidy early csvs
library(tidyverse)

####### load in data #######
learningFiles = list.files('../data', full.names = TRUE, pattern='block1_learning.*.csv', recursive = TRUE)
learningData = do.call(rbind, lapply(learningFiles, function(x) { read.csv(x, header = TRUE)} )) 

inferenceFiles = list.files('../data', full.names = TRUE, pattern='block1_inference.csv', recursive = TRUE)
inferenceData = do.call(rbind, lapply(inferenceFiles, function(x) { read.csv(x, header = TRUE)} )) 

############### tidy learning data ############### 
learn_quantiles <- quantile(learningData$trial, names=F)

learningData_tidy <- learningData %>%
  mutate(congruent = factor(as.character(congruent), levels=c("0", "1", "NaN"), labels=c('incongruent', 'congruent', 'neutral')),
         subID = ifelse(subID==101, 9, subID)) %>%
  # compute objective cue level based on observed transitions
  group_by(subID, cueIdx, learningRound) %>%
  mutate(tp = ifelse(cueIdx==imageIdx, 1,
                           ifelse(cueIdx==3, 0.5, 0)),
         cueLevel = mean(tp)) %>%
  # because we know there was a bug with the second round of learning, let's discard those trials for now, along with trials where no response was made
  filter(learningRound==1, is.na(RT)==F) %>%
  ungroup() %>%
  mutate(cueLevel = ifelse(congruent=='incongruent', 1-cueLevel, cueLevel),
         learning_time = ifelse(trial >= learn_quantiles[1] & trial < learn_quantiles[2], 1,
                                ifelse(trial >= learn_quantiles[2] & trial < learn_quantiles[3], 2,
                                       ifelse(trial >= learn_quantiles[3] & trial < learn_quantiles[4], 3,
                                              ifelse(trial >= learn_quantiles[4] & trial <= learn_quantiles[5], 4, NA))))) %>%
  group_by(subID) %>%
  mutate(logRT = log(RT),
         zlogRT = scale(logRT))


## find subjects who had multiple rounds of learning
extra_learn_subs <- learningData_tidy %>% filter(learningRound==2) %>% select(subID) %>% unique()



############### tidy inference data ############### 
cueLevels <- learningData_tidy %>% group_by(subID, cueIdx, congruent) %>% summarise(cueLevel = mean(cueLevel))
inference_quartiles <- quantile(inferenceData$noise1frames, names=F)
totalNoise_quartiles <- inferenceData %>% mutate(totalNoise = noise1frames + noise2frames) %>% summarise(q = quantile(totalNoise, names=F)) %>% dplyr::pull(q)

inferenceData_tidy <- inferenceData %>% 
  mutate(congruent = factor(as.character(congruent), levels=c("0", "1", "NaN"), labels=c('incongruent', 'congruent', 'neutral')), # rename congruent
         pilotGroup = ifelse(subID==101 | subID==10 | subID==11, 'group1', 'group2'), # make a column telling us if people had the buggy version of the expt
         subID = ifelse(subID==101, 9, subID),
         totalNoise = noise1frames + noise2frames,
         cueIdx = ifelse(targetIdx==1 & congruent == 'congruent', 1,
                         ifelse(targetIdx==1 & congruent == 'incongruent', 2,
                                ifelse(congruent == 'neutral', 3, 
                                       ifelse(targetIdx==1 & congruent=='incongruent', 2,
                                              ifelse(targetIdx==2 & congruent =='congruent', 2, 
                                                     ifelse(targetIdx==2 & congruent=='incongruent', 1, NA)))))),
         firstNoiseRT = ifelse(respFrame <= noise1frames, 1, 0),
         secondNoiseRT = ifelse(respFrame > (noise1frames+signal1frames) & respFrame <= (noise1frames+signal1frames+noise2frames),
                                1, 0),
         firstSignalRT = ifelse(respFrame > noise1frames & respFrame <= (noise1frames+signal1frames), 1, 0),
         secondSignalRT = ifelse(respFrame > (noise1frames + signal1frames + noise2frames), 1, 0),
         respPeriod = ifelse(firstNoiseRT==1, 1, NA),
         respPeriod = ifelse(firstSignalRT==1, 2, respPeriod),
         respPeriod = ifelse(secondNoiseRT==1, 3, respPeriod),
         respPeriod = ifelse(secondSignalRT==1, 4, respPeriod),
         firstNoise_quartile = ifelse(noise1frames >= inference_quartiles[1] & noise1frames < inference_quartiles[2], 1, 
                                      ifelse(noise1frames >= inference_quartiles[2] & noise1frames < inference_quartiles[3], 2,
                                             ifelse(noise1frames >= inference_quartiles[3] & noise1frames < inference_quartiles[4], 3,
                                                    ifelse(noise1frames >= inference_quartiles[4] & noise1frames <= inference_quartiles[5], 4, NA)))),
         secondNoise_quartile = ifelse(noise2frames >= inference_quartiles[1] & noise2frames < inference_quartiles[2], 1, 
                                       ifelse(noise2frames >= inference_quartiles[2] & noise2frames < inference_quartiles[3], 2,
                                              ifelse(noise2frames >= inference_quartiles[3] & noise2frames < inference_quartiles[4], 3,
                                                     ifelse(noise2frames >= inference_quartiles[4] & noise2frames <= inference_quartiles[5], 4, NA)))),
         totalNoise_quartile = ifelse(totalNoise >= totalNoise_quartiles[1] & totalNoise < totalNoise_quartiles[2], 1, 
                                      ifelse(totalNoise >= totalNoise_quartiles[2] & totalNoise < totalNoise_quartiles[3], 2,
                                             ifelse(totalNoise >= totalNoise_quartiles[3] & totalNoise < totalNoise_quartiles[4], 3,
                                                    ifelse(totalNoise >= totalNoise_quartiles[4] & totalNoise <= totalNoise_quartiles[5], 4, NA))))) %>%
  left_join(select(cueLevels, c(subID,cueIdx,congruent,cueLevel)), by=c('subID', 'congruent', 'cueIdx')) %>% # add transition probabilities from learning
  filter(catch_trial==0, is.na(RT)==F, is.na(confRT)==F) %>% # remove catch trials, trials with no decision response, trials with no confidence response 
  group_by(subID) %>%
  mutate(logRT = log(RT),
         zlogRT = scale(logRT),
         logConfRT = log(confRT),
         zlogconfRT = scale(logConfRT))


########## write out tidied CSVs ############### 
outdir <- 'poster_data/'
write.csv(learningData_tidy, paste0(outdir, 'learning_data.csv'), row.names=F)
write.csv(inferenceData_tidy, paste0(outdir, 'inference_data.csv'), row.names=F)
