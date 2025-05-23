library(tidyverse)
library(patchwork)
library(emmeans)

outdir <- '../figures/allconditions/'
inference_df <- read.csv('../tidied_data/all_conditions/inference.csv')

inference_df <- inference_df %>% 
  filter(subID != c(33), catch_trial==0, zlogRT > -10) %>%
  group_by(subID) %>%
  mutate(condition = ifelse(subID < 55, '80/50', '65/50'),
         cueCorr = cor(subjectiveCue, trueCue),
         cueDiff = subjectiveCue - trueCue,
         cueCorr_spearman = cor(subjectiveCue, trueCue, method = 'spearman'),
         cueCorr_q = ntile(cueCorr, n=2),
         cueCorr_sign = case_when(cueCorr < 0 ~ 'negative',
                                  cueCorr > 0 ~ 'positive'),
         noise1resp = ifelse(RT <= noise1_duration, 1, 0))

#### plot response probabilities ####
noise1acc_df <- glm(accuracy ~ factor(trueCue) + subjectiveCue + cueCorr, family='binomial', filter(inference_df, condition=='80/50' & noise1resp==1)) %>% 
  emmip(., ~ trueCue, CIs=T, type='response', plotit=F) 

inference_df %>% 
  filter(condition == '80/50') %>%
  mutate(noise1resp = ifelse(RT <= noise1_duration, 1, 0)) %>%
  filter(noise1resp==1) %>%
  group_by(subID, trueCue) %>%
  summarise(propCorrect = mean(accuracy)) %>%
  ggplot(aes(x=trueCue, y=propCorrect)) +
  theme_minimal() + ylim(0,1) +
  geom_hline(yintercept = 0.5, linetype='dashed') +
  geom_col(aes(y=yvar), data=noise1acc_df, fill='gray') +
  geom_pointrange(aes(y=yvar, ymin=LCL, ymax=UCL), data=noise1acc_df, fatten=10, linewidth=1) +
  geom_point() + 
  geom_line(aes(group=subID), linewidth=0.2)





#### plot accuracy as a function of true cue values #### 
p1 <- inference_df %>%
  mutate(trueCue = factor(trueCue, levels=c(50,80), labels=c('50%','80%'))) %>%
  group_by(subID, respLabel, trueCue, catch_label) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T)) %>%
  ggplot(aes(x=respLabel, y=propCorrect, color=trueCue, fill=trueCue)) +
  theme_bw() +
  geom_hline(yintercept = 0.5) +
  geom_jitter(alpha=0.25, size=1, height=0, width=0.2) +
  stat_summary(fun.data = 'mean_se') +
  stat_summary(aes(group=trueCue), fun = 'mean', geom='line') +
  facet_wrap(~ catch_label) +
  ggtitle('behavior')

p2 <- model_df %>%
  group_by(subID, respLabel, trueCue) %>%
  summarise(propCorrect = mean(rawChoice, na.rm=T)) %>%
  ggplot(aes(x=respLabel, y=propCorrect, color=trueCue, fill=trueCue)) +
  theme_bw() +
  geom_hline(yintercept = 0.5) +
  geom_jitter(alpha=0.2, size=0.5, height=0, width=0.2) +
  stat_summary(fun.data = 'mean_se', shape=9) +
  stat_summary(aes(group=trueCue), fun = 'mean', geom='line') +
  ggtitle('model') +
  ylim(0, 1)

p1 + p2 + plot_layout(widths=c(2, 1), guides = 'collect')
ggsave(paste0(outdir, 'inferenceAccuracy_byEpoch_trueCue.png'), width=8, height=3)



#### plot accuracy as a function of subjective cue values ####
p1 <- inference_df %>%
  mutate(subjectiveCue = factor(case_when(subjectiveCueOrder == 3 ~ 'weakest cue',
                                          subjectiveCueOrder < 3 ~ 'stronger cues'),
                                levels = c('weakest cue', 'stronger cues'))) %>%
  filter(is.na(subjectiveCue)==0) %>%
  group_by(subID, respLabel, subjectiveCue, catch_label) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T)) %>%
  ggplot(aes(x=respLabel, y=propCorrect, color=subjectiveCue, fill=subjectiveCue)) +
  theme_bw() +
  geom_hline(yintercept = 0.5) +
  geom_jitter(alpha=0.2, size=1, height=0, width=0.2) +
  stat_summary(fun.data = 'mean_se') +
  stat_summary(aes(group=subjectiveCue), fun = 'mean', geom='line') +
  facet_wrap(~ catch_label) +
  ggtitle('behavior: subjective cues')

p1 + p2 + plot_layout(widths=c(2, 1), guides = 'collect')
ggsave(paste0(outdir, 'inferenceAccuracy_byEpoch_subjCue.png'), width=8, height=3)


inference_df %>%
  mutate(subjectiveCueOrder = factor(subjectiveCueOrder)) %>%
  filter(is.na(subjectiveCueOrder)==0) %>%
  group_by(subID, respLabel, subjectiveCueOrder, catch_label) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T)) %>%
  ggplot(aes(x=respLabel, y=propCorrect, color=subjectiveCueOrder, fill=subjectiveCueOrder)) +
  theme_bw() +
  geom_hline(yintercept = 0.5) +
  geom_jitter(alpha=0.2, size=1, height=0, width=0.2) +
  stat_summary(fun.data = 'mean_se') +
  stat_summary(aes(group=subjectiveCueOrder), fun = 'mean', geom='line') +
  facet_wrap(~ catch_label) +
  ggtitle('behavior')

ggsave(paste0(outdir, 'inferenceAccuracy_byEpoch_subjCueAll.png'), width=6, height=3)



#### proportion of responses made during each period ####
rm(p1, p2)

# by objective cueIdx
nTrials <- inference_df %>% group_by(cueIdx, catch_label) %>% count() %>% rename(totalTrials = n)
respTrials <- inference_df %>% group_by(respLabel, cueIdx, catch_label) %>% count()
p1 <- left_join(respTrials, nTrials, by=c('cueIdx', 'catch_label')) %>%
  group_by(cueIdx, respLabel, catch_label) %>%
  mutate(pResp = n/totalTrials) %>%
  ggplot(aes(x=respLabel, y=pResp, fill=cueIdx)) +
  theme_bw() + 
  facet_wrap(~ catch_label) +
  geom_col(position = position_dodge()) + 
  labs(y = 'proportion of trials', x='', title='objective cues') 

# by trueCue
nTrials <- inference_df %>% group_by(trueCue, catch_label) %>% count() %>% rename(totalTrials = n)
respTrials <- inference_df %>% group_by(respLabel, trueCue, catch_label) %>% count()
p2 <- left_join(respTrials, nTrials, by=c('trueCue', 'catch_label')) %>%
  mutate(trueCue = factor(trueCue, levels=c(80, 50))) %>%
  group_by(trueCue, respLabel, catch_label) %>%
  mutate(pResp = n/totalTrials) %>%
  ggplot(aes(x=respLabel, y=pResp, fill=trueCue)) +
  theme_bw() + 
  facet_wrap(~ catch_label) +
  geom_col(position = position_dodge()) + 
  labs(y = 'proportion of trials', x='', title='collapsing across 80% cues') 

# by subjectiveCueOrder
nTrials <- inference_df %>% group_by(subjectiveCueOrder, catch_label) %>% count() %>% rename(totalTrials = n)
respTrials <- inference_df %>% group_by(respLabel, subjectiveCueOrder, catch_label) %>% count()
p3 <- left_join(respTrials, nTrials, by=c('subjectiveCueOrder', 'catch_label')) %>%
  group_by(subjectiveCueOrder, respLabel, catch_label) %>%
  filter(is.na(subjectiveCueOrder)==0) %>%
  mutate(subjectiveCueOrder = factor(subjectiveCueOrder),
         pResp = n/totalTrials) %>%
  ggplot(aes(x=respLabel, y=pResp, fill=subjectiveCueOrder)) +
  theme_bw() + 
  facet_wrap(~ catch_label) +
  geom_col(position = position_dodge()) + 
  labs(y = 'proportion of trials', x='', title='subjective cues (3=weakest)') 

# by subjectiveCue (binary)
inference_df <- inference_df %>%
  mutate(subjectiveCueBinary = factor(case_when(subjectiveCueOrder == 3 ~ 'weakest cue',
                                                subjectiveCueOrder < 3 ~ 'stronger cues'),
                                      levels = c('weakest cue', 'stronger cues')))

nTrials <- inference_df %>% group_by(subjectiveCueBinary, catch_label) %>% count() %>% rename(totalTrials = n)
respTrials <- inference_df %>% group_by(respLabel, subjectiveCueBinary, catch_label) %>% count()
p4 <- left_join(respTrials, nTrials, by=c('subjectiveCueBinary', 'catch_label')) %>%
  group_by(subjectiveCueBinary, respLabel, catch_label) %>%
  filter(is.na(subjectiveCueBinary)==0) %>%
  mutate(subjectiveCueBinary = factor(subjectiveCueBinary),
         pResp = n/totalTrials,
         subjectiveCueBinary = factor(subjectiveCueBinary, levels=c('stronger cues', 'weakest cue'))) %>%
  ggplot(aes(x=respLabel, y=pResp, fill=subjectiveCueBinary)) +
  theme_bw() + 
  facet_wrap(~ catch_label) +
  geom_col(position = position_dodge()) + 
  labs(y = 'proportion of trials', x='', title='subjective cues (binary)') 

p1 + p2 + p3 + p4
ggsave(paste0(outdir, 'respProportion_behavior.png'), height=5, width=12)

# model predictions
nTrials <- model_df %>% group_by(cue) %>% count() %>% rename(totalTrials = n)
respTrials <- model_df %>% group_by(respLabel, cue) %>% count()

p <- left_join(respTrials, nTrials, by=c('cue')) %>%
  group_by(cue, respLabel) %>%
  mutate(cue = factor(cue, levels=c(0.8, 0.5)),
         pResp = n/totalTrials) %>%
  ggplot(aes(x=respLabel, y=pResp, fill=cue)) +
  theme_bw() + 
  geom_col(position = position_dodge()) + 
  labs(y = 'proportion of trials', x='', title='model predictions') 


p2 + p + plot_layout(widths=c(2,1))
ggsave(paste0(outdir, 'respProportion_model.png'), height=4, width=8)


#### epoch durations across model & behavior ####
m1 <- model_df %>%
  pivot_longer(cols=contains('Frames'),
               names_to = 'epoch',
               values_to = 'duration') %>%
  filter(epoch == c('noise1Frames', 'signal1Frames', 'noise2Frames', 'signal2Frames')) %>%
  mutate(epoch = factor(epoch, levels=c('noise1Frames', 'signal1Frames', 'noise2Frames', 'signal2Frames'))) %>%
  ggplot(aes(x=duration)) + 
  theme_bw() + 
  geom_histogram(bins=50) +
  facet_grid(~epoch) +
  labs(title = 'intended epoch durations: simulation', x = 'frames')

m2 <- model_df %>%
  pivot_longer(cols=contains('Frames'),
               names_to = 'epoch',
               values_to = 'duration') %>%
  filter(epoch == c('noise1Frames_obs', 'signal1Frames_obs', 'noise2Frames_obs', 'signal2Frames_obs')) %>%
  mutate(epoch = factor(epoch, levels=c('noise1Frames_obs', 'signal1Frames_obs', 'noise2Frames_obs', 'signal2Frames_obs'))) %>%
  ggplot(aes(x=duration)) + 
  theme_bw() + 
  geom_histogram(bins=50) +
  facet_grid(~epoch) +
  labs(title = 'observed epoch durations: simulation', x = 'frames')

modelDurations <- (m1 / m2)

b1 <- inference_df %>%
  pivot_longer(cols=contains('frames_design'),
               names_to = 'epoch',
               values_to = 'duration') %>%
  filter(epoch == c('noise1frames_design', 'signal1frames_design', 'noise2frames_design', 'signal2frames_design')) %>%
  mutate(epoch = factor(epoch, levels=c('noise1frames_design', 'signal1frames_design', 'noise2frames_design', 'signal2frames_design'))) %>%
  ggplot(aes(x=duration)) + 
  theme_bw() + 
  geom_histogram(bins=50) +
  facet_grid(~epoch) +
  labs(title = 'intended epoch durations: behavior', x = 'frames')

b2 <- inference_df %>%
  pivot_longer(cols=contains('frames_obs'),
               names_to = 'epoch',
               values_to = 'duration') %>%
  filter(epoch == c('noise1frames_obs', 'signal1frames_obs', 'noise2frames_obs', 'signal2frames_obs')) %>%
  mutate(epoch = factor(epoch, levels=c('noise1frames_obs', 'signal1frames_obs', 'noise2frames_obs', 'signal2frames_obs'))) %>%
  ggplot(aes(x=duration)) + 
  theme_bw() + 
  geom_histogram(bins=50) +
  facet_grid(~epoch) +
  labs(title = 'observed epoch durations: behavior', x = 'frames')

modelDurations | (b1 / b2)

ggsave(paste0(outdir, 'epochDurations.png'), width=11, height=5)

#### RT histograms #### 
find_mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

noise1_mode <- find_mode(inference_df$noise1frames_design) / 72
noise2Onset_mode <- find_mode(inference_df$noise2Onset_design) / 72
signal2Onset_mode <- find_mode(inference_df$signal2Onset_design) / 72

p1 <- inference_df %>%
  ggplot(aes(x=RT, color=congCue, fill=congCue)) +
  theme_bw() +
  annotate('rect', xmin=0, xmax=noise1_mode, ymin=0, ymax=70, alpha=0.5, fill='gray') + 
  annotate('rect', xmin=noise2Onset_mode, xmax=signal2Onset_mode, ymin=0, ymax=70, alpha=0.5, fill='gray') +
  geom_histogram(bins=50, alpha=0.5) +
  facet_wrap(~ subID, nrow=3) +
  labs(title = 'individual RT histograms', subtitle = 'boxes=mode noise durations')

p2 <- inference_df %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=RT, color=congCue, fill=congCue)) +
  theme_bw() +
  annotate('rect', xmin=0, xmax=noise1_mode, ymin=0, ymax=500, alpha=0.5, fill='gray') + 
  annotate('rect', xmin=noise2Onset_mode, xmax=signal2Onset_mode, ymin=0, ymax=500, alpha=0.5, fill='gray') +
  geom_histogram(bins=50, alpha=0.5) +
  labs(title = 'group histogram', subtitle = 'boxes=mode noise durations')

p3 <- inference_df %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=RT, color=congCue, fill=congCue)) +
  theme_bw() +
  annotate('rect', xmin=0, xmax=mean(inference_df$noise1frames_design)/72, ymin=0, ymax=500, alpha=0.5, fill='gray') + 
  annotate('rect', xmin=mean(inference_df$noise2Onset_design)/72, 
           xmax=mean(inference_df$signal2Onset_design)/72, ymin=0, ymax=500, alpha=0.5, fill='gray') +
  geom_histogram(bins=50, alpha=0.5) +
  labs(subtitle = 'boxes=mean noise durations')

p1 + (p2/p3) + plot_layout(guides='collect', widths=c(4, 1))
ggsave(paste0(outdir, 'RT_histograms.png'), width=12, height=5)

## split by correct & incorrect
inference_df %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=RT, color=congCue, fill=congCue)) +
  theme_bw() +
  annotate('rect', xmin=0, xmax=noise1_mode, ymin=0, ymax=70, alpha=0.5, fill='gray') + 
  annotate('rect', xmin=noise2Onset_mode, xmax=signal2Onset_mode, ymin=0, ymax=70, alpha=0.5, fill='gray') +
  geom_histogram(bins=50, alpha=0.5) +
  facet_wrap(~ subID, nrow=3) +
  labs(title = 'individual RT histograms', subtitle = 'boxes=mode noise durations')

inference_df %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=RT, color=congCue, fill=congCue)) +
  theme_bw() +
  annotate('rect', xmin=0, xmax=noise1_mode, ymin=0, ymax=500, alpha=0.5, fill='gray') + 
  annotate('rect', xmin=noise2Onset_mode, xmax=signal2Onset_mode, ymin=0, ymax=500, alpha=0.5, fill='gray') +
  geom_histogram(bins=50, alpha=0.5) +
  labs(title = 'group histogram', subtitle = 'boxes=mode noise durations')

# claude's code modified by me
p1 <- ggplot() +
  theme_bw() +
  annotate('rect', xmin=0, xmax=noise1_mode, ymin=-0.7, ymax=0.7, alpha=0.5, fill='gray') + 
  annotate('rect', xmin=noise2Onset_mode, xmax=signal2Onset_mode, ymin=-0.7, ymax=0.7, alpha=0.5, fill='gray') +
  geom_density(data = inference_df %>% filter(accuracy == 1), aes(x=RT, y=after_stat(density), group=congCue, color=factor(congCue))) +
  geom_density(data = inference_df %>% filter(accuracy == 0), aes(x=RT, y=-after_stat(density), group=congCue, color=factor(congCue))) +
  scale_y_continuous(name = "density", labels = function(x) abs(x), n.breaks = 6) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  labs(title = 'group density plot', subtitle = 'boxes=mode noise durations', x='RT(s)')

# extension to individual subjects
p2 <- ggplot() +
  theme_bw() +
  annotate('rect', xmin=0, xmax=noise1_mode, ymin=-1, ymax=1, alpha=0.5, fill='gray') + 
  annotate('rect', xmin=noise2Onset_mode, xmax=signal2Onset_mode, ymin=-1, ymax=1, alpha=0.5, fill='gray') +
  geom_density(data = inference_df %>% filter(accuracy == 1), aes(x=RT, y=after_stat(density), group=congCue, color=factor(congCue))) +
  geom_density(data = inference_df %>% filter(accuracy == 0), aes(x=RT, y=-after_stat(density), group=congCue, color=factor(congCue))) +
  scale_y_continuous(name = "scaled density", labels = function(x) abs(x), n.breaks = 6) +
  facet_wrap(~subID, nrow=3) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  labs(title = 'individual subject densities', subtitle = 'boxes=mode noise durations', x='RT (s)')

p2 + p1 + plot_layout(guides='collect', widths=c(4, 1))
ggsave(paste0(outdir, 'RT_densities.png'), width=12, height=5)


#### RT violins ####
meanRT <- median(inference_df$RT, na.rm=T) 
p1 <- inference_df %>%
  ggplot(aes(x=congCue, y=RT, color=congCue)) +
  theme_bw() +
  geom_hline(yintercept = meanRT) +
  geom_violin(aes(fill=congCue), alpha=0.25) +
  geom_boxplot(width=0.25) +
  labs(title = 'raw RT', subtitle='solid line = grand median')

p2 <- inference_df %>%
  ggplot(aes(x=congCue, y=zlogRT, color=congCue)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_violin(aes(fill=congCue), alpha=0.25) +
  geom_boxplot(width=0.25) +
  labs(title = 'zlogRT', subtitle='solid line = 0')

p1 + p2 + plot_layout(guides = 'collect')
ggsave(paste0(outdir, 'RT_summaries.png'), width=8, height=4)


#### RT & accuracy summaries defined by "competing" linear models - 02/26 ####

# accuracy & rt by cueConf * trueCongruence
# accuracy
inference_df %>%
  group_by(subID, cueCorr_sign, cueConfidence, trueCongruence) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T)) %>%
  ggplot(aes(x=cueConfidence, y=propCorrect, color=cueCorr_sign)) + 
  theme_bw() + facet_wrap(~ trueCongruence) +
  geom_hline(yintercept = 0.5, linewidth=0.25) +
  geom_hline(yintercept = 0.7, linetype='dashed', linewidth=0.25) +
  geom_point(position=position_jitter(width=0.1, height=0), alpha=0.5) +
  stat_summary(aes(group=cueCorr_sign), fun.data = 'mean_se') +
  stat_summary(aes(group=cueCorr_sign), fun.y = 'mean', geom='line') +
  labs(title = 'raw data: cueCorr * cueConfidence * trueCongruence')
ggsave(paste0(outdir, 'rawAccuracy_cueConf*trueCong.png'), width=6, height=3)

# rt
inference_df %>%
  group_by(subID, cueCorr_sign, cueConfidence, trueCongruence) %>%
  summarise(meanRT = mean(zlogRT, na.rm=T)) %>%
  ggplot(aes(x=cueConfidence, y=meanRT, color=cueCorr_sign)) + 
  theme_bw() + facet_wrap(~ trueCongruence) +
  geom_hline(yintercept = 0, linewidth=0.25) +
  geom_point(position=position_jitter(width=0.1, height=0), alpha=0.5) +
  stat_summary(aes(group=cueCorr_sign), fun.data = 'mean_se') +
  stat_summary(aes(group=cueCorr_sign), fun.y = 'mean', geom='line') +
  labs(title = 'raw data: cueCorr * cueConfidence * trueCongruence')
ggsave(paste0(outdir, 'rawRT_cueConf*trueCong.png'), width=6, height=3)

# accuracy & rt by subjectiveCue * congCue
# rt
inference_df %>%
  mutate(sc_quartile = ntile(subjectiveCue, 4)) %>%
  group_by(subID, cueCorr_sign, sc_quartile, congCue) %>%
  summarise(meanRT = mean(zlogRT, na.rm=T)) %>%
  ggplot(aes(x=sc_quartile, y=meanRT, color=cueCorr_sign)) + 
  theme_bw() + facet_wrap(~ congCue) +
  geom_hline(yintercept = 0, linewidth=0.25) +
  geom_point(position=position_jitter(width=0.1, height=0), alpha=0.5) +
  stat_summary(aes(group=cueCorr_sign), fun.data = 'mean_se') +
  stat_summary(aes(group=cueCorr_sign), fun.y = 'mean', geom='line') +
  labs(title = 'raw data: cueCorr * subjectiveCue * congCue')
ggsave(paste0(outdir, 'rawRT_subjectiveCue*congCue.png'), width=6, height=3)

# accuracy
inference_df %>%
  mutate(sc_quartile = ntile(subjectiveCue, 4)) %>%
  group_by(subID, cueCorr_sign, sc_quartile, congCue) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T)) %>%
  ggplot(aes(x=sc_quartile, y=propCorrect, color=cueCorr_sign)) + 
  theme_bw() + facet_wrap(~ congCue) +
  geom_hline(yintercept = 0.5, linewidth=0.25) +
  geom_hline(yintercept = 0.7, linetype='dashed', linewidth=0.25) +
  geom_point(position=position_jitter(width=0.1, height=0), alpha=0.5) +
  stat_summary(aes(group=cueCorr_sign), fun.data = 'mean_se') +
  stat_summary(aes(group=cueCorr_sign), fun.y = 'mean', geom='line') +
  labs(title = 'raw data: cueCorr * subjectiveCue * congCue')
ggsave(paste0(outdir, 'rawAccuracy_subjectiveCue*congCue.png'), width=6, height=3)
