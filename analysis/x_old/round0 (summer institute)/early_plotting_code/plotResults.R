# load in necessary packages
library(tidyverse) # for data wrangling and plotting
library(patchwork) # for combining plots into bigger figures


###### compute individual summary statistics ######
individualSummary <- inferenceData_tidy %>%
  group_by(subID, cueLevel, pilotGroup) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T),
            propCorrect_sd = sd(accuracy, na.rm=T), 
            RT = mean(zlogRT),
            RT_sd = sd(RT),
            avgConf = mean(confResp, na.rm=T),
            conf_sd = sd(confResp, na.rm=T),
            confRT = mean(zlogconfRT),
            confRT_sd = sd(zlogconfRT))

##### start by plotting just the subjects who had the right learning probabilities
## plot individual accuracy as a function of congruence for PG2
individualSummary %>%
  filter(pilotGroup=='group2') %>%
  ggplot(aes(x=cueLevel, y=propCorrect, group=subID)) +
  geom_hline(yintercept = 0.5) +
  facet_wrap(~ subID, nrow=2) + 
  geom_point() +
  geom_line() + 
  theme_classic() +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) + 
  ylim(0, 1) +
  labs(x = 'cueLevel', title = 'subjects with intended transition probabilities during learning')
ggsave(paste0(outdir, 'individual_accuracy.png'), width = 8, height = 4)

## plot individual RTs as a function of congruence for PG 2
individualSummary %>%
  filter(pilotGroup=='group2') %>%
  ggplot(aes(x=cueLevel, y=RT, group=subID)) +
  facet_wrap(~ subID, nrow=2) + 
  geom_point() +
  geom_line() +
  theme_classic() +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) + 
  labs(y = 'zlogged mean RT', x='cue')
ggsave(paste0(outdir, '/individual_RT.png'), width = 8, height = 4)

## plot individual confidence as a function of congruence
p1 <- individualSummary %>% 
  filter(pilotGroup=='group2') %>%
  ggplot(aes(x=cueLevel, y=avgConf)) +
  facet_wrap(~subID, ncol=1) + 
  ylim(1,4) + 
  geom_hline(yintercept = mean(1:4)) +
  geom_point() +
  geom_line(aes(group=subID)) +
  theme_classic() +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) +
  labs(y = 'mean confidence', x = 'cue')

## plot individual confRT as a function of congruence
p2 <- individualSummary %>% 
  filter(pilotGroup=='group2') %>%
  ggplot(aes(x=cueLevel, y=confRT)) +
  facet_wrap(~subID, ncol=1) +
  geom_point() +
  geom_line(aes(group=subID)) +
  theme_classic() +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) + 
  labs(y='Z-logged Confidence RT', x='cue')

p1 + p2
ggsave(paste0(outdir, 'individual_ConfAndRT.png'), width=5, height=10)

## accuracy & RT side by side
p1 <- individualSummary %>%
  filter(pilotGroup=='group2') %>%
  ggplot(aes(x=cueLevel, y=propCorrect, group=subID)) +
  geom_hline(yintercept = 0.5) +
  facet_wrap(~ subID, ncol=1) + 
  geom_point() +
  geom_line() + 
  theme_classic() +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) + 
  ylim(0, 1) +
  labs(x = 'cueLevel')

## plot individual RTs as a function of congruence for PG 2
p2 <- individualSummary %>%
  filter(pilotGroup=='group2') %>%
  ggplot(aes(x=cueLevel, y=RT, group=subID)) +
  facet_wrap(~ subID, ncol=1) + 
  geom_point() +
  geom_line() +
  theme_classic() +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) + 
  labs(y = 'zlogged mean RT', x='cue')

p1 + p2
ggsave(paste0(outdir, 'individual_speedAccuracy.png'), width=5, height=10)

###### compute group summary statistics ###### 
groupSummary <- inferenceData_tidy %>% 
  ungroup() %>%
  filter(pilotGroup=='group2') %>%
  group_by(cueLevel) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T),
            propCorrect_sem = (sd(accuracy, na.rm=T) / sqrt(nSubs)),
            RT = mean(zlogRT),
            RT_sem = (sd(zlogRT) / sqrt(nSubs)),
            confidence = mean(confResp, na.rm = T),
            confidence_sem = sd(confResp, na.rm=T) / sqrt(nSubs),
            confRT = mean(zlogconfRT),
            confRT_sem = sd(zlogconfRT)/sqrt(nSubs))

## plot group-level accuracy as a function of cue level
p1 <- groupSummary %>%
  ggplot(aes(x=cueLevel, y=propCorrect)) +
  geom_hline(yintercept=0.5, linewidth=0.15) + 
  geom_pointrange(aes(ymin = propCorrect-propCorrect_sem, ymax=propCorrect+propCorrect_sem)) + 
  geom_line() +
  theme_classic() +
  ylim(c(0, 1)) +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) +
  labs(title = 'group accuracy (n=8, SEM)')

## plot group-level RTs as a function of cue level
p2 <- groupSummary %>%
  ggplot(aes(x=cueLevel, y=RT)) +
  geom_pointrange(aes(ymin = RT-RT_sem, ymax=RT+RT_sem)) + 
  geom_line() +
  theme_classic() +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) +
  labs(y = 'log-transformed z-scored RT', title='group RTs (n=8, SEM)')
  
p1 + p2
ggsave(paste0(outdir, 'group_speedAccuracy.png'), width=8, height=4)

inferenceData_tidy %>%
  filter(pilotGroup=='group2') %>%
  group_by(accuracy, congruent, cueLevel) %>%
  summarise(meanRT = mean(zlogRT),
            sem = sd(zlogRT) / sqrt(8)) %>%
  ggplot(aes(x=cueLevel, y=meanRT, group=accuracy)) +
  geom_pointrange(aes(ymin = meanRT - sem, ymax = meanRT + sem)) +
  geom_line() +
  theme_classic() + 
  facet_wrap(~ accuracy) 

inferenceData_tidy %>%
  filter(pilotGroup=='group2') %>%
  group_by(subID) %>%
  mutate(zconf = scale(confResp)) %>%
  group_by(accuracy, congruent, cueLevel) %>%
  summarise(meanRT = mean(zconf),
            sem = sd(zconf) / sqrt(8)) %>%
  ggplot(aes(x=cueLevel, y=meanRT, group=accuracy,color=accuracy)) +
  geom_pointrange(aes(ymin = meanRT - sem, ymax = meanRT + sem)) +
  geom_line() +
  theme_classic() + 
  #facet_wrap(~ accuracy)  +
  labs(y = 'confidence')

inferenceData_tidy %>%
  filter(pilotGroup=='group2') %>%
  group_by(subID) %>%
  mutate(zconf = scale(confResp),
         cueLevel = factor(cueLevel)) %>%
  group_by(accuracy, congruent, cueLevel, confResp) %>%
  summarise(meanRT = mean(zconf),
            sem = sd(zconf) / sqrt(8)) %>%
  ggplot(aes(x=confResp, y=meanRT, color=cueLevel)) +
  geom_pointrange(aes(ymin = meanRT - sem, ymax = meanRT + sem)) +
  geom_line() +
  theme_classic() + 
  facet_wrap(~ accuracy)  +
  labs(y = 'RT')



## plot group-level confidence as a function of congruence
p1 <- groupSummary %>%
  ggplot(aes(x=cueLevel, y=confidence)) +
  geom_pointrange(aes(ymin = confidence-confidence_sem, ymax=confidence+confidence_sem)) + 
  geom_line() +
  theme_classic() +
  geom_hline(yintercept = mean(1:4)) +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) +
  ylim(c(1, 4)) +
  labs(title = 'group confidence (n=8, SEM)')

## plot group-level conf RTs as a function of congruence
p2 <- groupSummary %>%
  ggplot(aes(x=cueLevel, y=confRT)) +
  geom_pointrange(aes(ymin = confRT-confRT_sem, ymax=confRT+confRT_sem)) + 
  geom_line() +
  theme_classic() +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) +
  labs(y='Z-logged Confidence RT', title = 'group confidence RTs (n=8, SEM)')

p1 + p2
ggsave(paste0(outdir, 'group_speedConfidence.png'), width=8, height=4)

  

########### let's get distributional (plotting RT distributions) ########### 
# raw RTs
inferenceData_tidy %>%
  group_by(subID, congruent) %>%
  filter(pilotGroup=='group2') %>%
  ggplot(aes(x=RT, color=congruent, fill=congruent)) +
  facet_wrap(~ subID, nrow=2) +
  theme_classic() +
  geom_density(fill=NA, linewidth=1) +
  ggtitle('Raw RTs')
ggsave(paste0(outdir, 'dist_rawRT.png'), width=10, height=5)

# zlogged RTs
inferenceData_tidy %>%
  group_by(subID, congruent) %>%
  filter(pilotGroup=='group2', catch_trial==0) %>%
  ggplot(aes(x=zlogRT, color=congruent, fill=congruent)) +
  facet_wrap(~ subID, nrow=2) +
  theme_classic() +
  geom_density(fill=NA, linewidth=1) +
  ggtitle('zlogged RTs')
ggsave(paste0(outdir, 'dist_zlogRT.png'), width=10, height=5)

# individual-level distributions
inferenceData_tidy %>%
  group_by(subID, congruent) %>%
  filter(pilotGroup=='group2', catch_trial==0) %>%
  ggplot(aes(x=respPeriod, color=congruent, fill=congruent)) +
  facet_wrap(~subID, nrow=2) +
  geom_density(alpha=0.25) +
  theme_classic()
ggsave(paste0(outdir, 'dist_respPeriod.png'), width=10, height=5)

inferenceData_tidy %>%
  filter(pilotGroup=='group2') %>%
  ggplot(aes(x=confResp, color=congruent)) +
  facet_wrap(~subID, nrow=2) +
  geom_density(fill=NA, linewidth=1) +
  theme_classic()

 
############ pilot group 1 INFERENCE ############ 
## speed accuracy
p1 <- individualSummary %>%
  filter(pilotGroup=='group1') %>%
  ggplot(aes(x=cueLevel, y=propCorrect, group=subID)) +
  geom_hline(yintercept = 0.5) +
  facet_wrap(~ subID, ncol=1) + 
  geom_point() +
  geom_line() + 
  theme_classic() +
  ylim(0, 1) +
  scale_x_continuous(n.breaks=10) + 
  labs(x = 'cueLevel', title = 'accuracy')

p2 <- individualSummary %>%
  filter(pilotGroup=='group1') %>%
  ggplot(aes(x=cueLevel, y=RT, group=subID)) +
  facet_wrap(~ subID, ncol=1) + 
  geom_point() +
  geom_line() + 
  theme_classic() +
  scale_x_continuous(n.breaks=10) +
  labs(x = 'cueLevel', title = 'RT')

patch <- p1 + p2
patch + plot_annotation(title = 'subs with incorrect learning probabilities')
ggsave(paste0(outdir, 'individual_speedAccuracy_pg1.png'), width=7, height=5)

## speed confidence
p1 <- individualSummary %>%
  filter(pilotGroup=='group1') %>%
  ggplot(aes(x=cueLevel, y=avgConf, group=subID)) +
  geom_hline(yintercept = mean(1:4)) +
  facet_wrap(~ subID, ncol=1) + 
  geom_point() +
  geom_line() + 
  theme_classic() +
  scale_x_continuous(n.breaks=8) + 
  ylim(1,4) +
  labs(x = 'cueLevel', title = 'average confidence')

p2 <- individualSummary %>%
  filter(pilotGroup=='group1') %>%
  ggplot(aes(x=cueLevel, y=confRT, group=subID)) +
  facet_wrap(~ subID, ncol=1) + 
  geom_point() +
  geom_line() + 
  theme_classic() +
  scale_x_continuous(n.breaks=8) + 
  labs(x = 'cueLevel', title = 'average conf RT')

patch <- p1 + p2
patch + plot_annotation(title = 'subs with incorrect learning probabilities')
ggsave(paste0(outdir, 'individual_speedConfidence_pg1.png'), width=7, height=5)

### distributions
p1 <- inferenceData_tidy %>%
  filter(pilotGroup=='group1') %>%
  mutate(cue = factor(cue_rgb)) %>%
  ggplot(aes(x=zlogRT, color=cue)) +
  facet_wrap(~ subID, ncol=1) +
  theme_classic() +
  theme(legend.position = 'none') +
  geom_density(fill=NA, linewidth=1) +
  ggtitle('zlogged RTs')

p2 <- inferenceData_tidy %>%
  filter(pilotGroup=='group1') %>%
  mutate(cue = factor(cue_rgb)) %>%
  ggplot(aes(x=respPeriod, color=cue, fill=cue)) +
  facet_wrap(~subID, ncol=1) +
  geom_density(alpha=0.25) +
  theme_classic() +
  ggtitle('response period densities')

patch <- p1 + p2
patch + plot_annotation(title = 'subs with incorrect learning probabilities')
ggsave(paste0(outdir, 'dist_RTs_pg1.png'), width=8, height=7)


############################## PLOT LEARNING RESULTS ############################## 
learnSummary <- learningData_tidy %>%
  mutate(cue = factor(cue_rgb)) %>%
  group_by(subID, cue, learning_time, pilotGroup) %>%
  summarise(meanRT = mean(zlogRT))

# group 2
learnSummary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cue = plyr::revalue(cue, c("1" = "80% A", "2" = "80% B", "3" = 'neutral'))) %>%
  ggplot(aes(x=learning_time, y=meanRT, color=cue, group=cue)) +
  facet_wrap(~subID, nrow=2) +
  geom_point() +
  geom_line() +
  theme_classic() +
  labs(x = 'learning trial quartile', y='mean RT (zlogged)', title='learning RTs')
ggsave(paste0(outdir, 'individual_RTLearning.png'), width=8, height=4)

# group 1
learnSummary %>%
  filter(pilotGroup == 'group1') %>%
  ggplot(aes(x=learning_time, y=meanRT, color=cue, group=cue)) +
  facet_wrap(~subID, ncol=1) +
  geom_point() +
  geom_line() +
  theme_classic() +
  labs(x = 'learning trial quartile', y='mean RT (zlogged)')
ggsave(paste0(outdir, 'individual_RTLearning_pg1.png'), width=3, height=6)



####################################### TIME VARYING SUMMARIES ####################################### 
firstNoise_summary <- inferenceData_tidy %>%
  group_by(firstNoise_quartile, cueLevel, pilotGroup, congruent) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T),
            accuracy_sem = sd(accuracy, na.rm=T)/sqrt(8),
            meanRT = mean(zlogRT),
            RT_sem = sd(zlogRT)/sqrt(8),
            avgConf = mean(confResp, na.rm=T),
            conf_sem = sd(confResp)/sqrt(8))

f1 <- firstNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=firstNoise_quartile, y=propCorrect, color=cueLevel)) +
  geom_hline(yintercept = 0.5) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=propCorrect-accuracy_sem, ymax=propCorrect+accuracy_sem)) + 
  geom_line()

f2 <- firstNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=firstNoise_quartile, y=meanRT, color=cueLevel)) +
  geom_hline(yintercept = 0) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=meanRT-RT_sem, ymax=meanRT+RT_sem)) + 
  geom_line() +
  labs(y='z-scored log RTs')

firstNoisePlots <- f1 + f2 
firstNoisePlots + plot_annotation(title = 'accuracy & RT as a function of first noise duration') + plot_layout(guides = 'collect')
ggsave(paste0(outdir, 'noise1_summary.png'), width=8, height=4)


secondNoise_summary <- inferenceData_tidy %>%
  group_by(secondNoise_quartile, cueLevel, pilotGroup, congruent) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T),
            accuracy_sem = sd(accuracy, na.rm=T)/sqrt(8),
            meanRT = mean(zlogRT),
            RT_sem = sd(zlogRT)/sqrt(8),
            avgConf = mean(confResp, na.rm=T),
            conf_sem = sd(confResp)/sqrt(8))

f1 <- secondNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=secondNoise_quartile, y=propCorrect, color=cueLevel)) +
  geom_hline(yintercept = 0.5) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=propCorrect-accuracy_sem, ymax=propCorrect+accuracy_sem)) + 
  geom_line()

f2 <- secondNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=secondNoise_quartile, y=meanRT, color=cueLevel)) +
  geom_hline(yintercept = 0) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=meanRT-RT_sem, ymax=meanRT+RT_sem)) + 
  geom_line() +
  labs(y='z-scored log RTs')

secondNoisePlots <- f1 + f2 
secondNoisePlots + plot_annotation(title = 'accuracy & RT as a function of second noise duration') + plot_layout(guides = 'collect')
ggsave(paste0(outdir, 'noise2_summary.png'), width=8, height=4)

totalNoise_summary <- inferenceData_tidy %>%
  group_by(totalNoise_quartile, cueLevel, pilotGroup, congruent) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T),
            accuracy_sem = sd(accuracy, na.rm=T)/sqrt(8),
            meanRT = mean(zlogRT),
            RT_sem = sd(zlogRT)/sqrt(8),
            avgConf = mean(confResp, na.rm=T),
            conf_sem = sd(confResp)/sqrt(8))

f1 <- totalNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=totalNoise_quartile, y=propCorrect, color=cueLevel)) +
  geom_hline(yintercept = 0.5) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=propCorrect-accuracy_sem, ymax=propCorrect+accuracy_sem)) + 
  geom_line()

f2 <- totalNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=totalNoise_quartile, y=meanRT, color=cueLevel)) +
  geom_hline(yintercept = 0) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=meanRT-RT_sem, ymax=meanRT+RT_sem)) + 
  geom_line() +
  labs(y='z-scored log RTs')

totalNoisePlots <- f1 + f2 
totalNoisePlots + plot_annotation(title = 'accuracy & RT as a function of total noise duration') + plot_layout(guides = 'collect')
ggsave(paste0(outdir, 'noise2_summary.png'), width=8, height=4)