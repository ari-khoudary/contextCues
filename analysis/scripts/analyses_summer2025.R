library(tidyverse)
library(patchwork)
library(lme4)
library(lmerTest)

#### setup ####
outdir <- 'results_summer2025/'
inference <- read.csv('../../../contextCues/analysis/tidied_data/all_conditions/inference.csv') 

inference <- inference %>%
  mutate(condition = factor(condition, 
                            levels=c('condition_80cue', 'condition_65cue'), 
                            labels=c('80/50 condition', '65/50 condition')))

estimates <- read.csv('../../../contextCues/analysis/tidied_data/all_conditions/estimates.csv') %>%
  filter(subID != 33) %>%
  group_by(subID) %>%
  mutate(cueCorr = cor(subjectiveCue, trueCue),
         cueDiff = subjectiveCue - trueCue,
         condition = ifelse(subID > 54, '65/50 condition', '80/50 condition'))


# compute cueCorr & cueDiff
inference <- inference %>%
  filter(subID > 0) %>%
  group_by(subID) %>% 
  mutate(propCorrect = mean(accuracy),
         cueCorr = cor(trueCue,subjectiveCue),
         cueDiff = subjectiveCue - trueCue) 

#### plot cueCorr & cueDiff ####

# cueCorr
estimates %>%
  ggplot(aes(x=subID, y=cueCorr, shape=condition)) +
  geom_hline(yintercept = 0) +
  ylim(-1,1.2) +
  geom_segment(aes(x=subID, xend=subID, y=0, yend=cueCorr)) +
  geom_point(aes(shape=condition, fill=cueCorr), size=5, stroke=1, color='gray20') +
  scale_shape_manual(values = c(23, 21)) +
  scale_x_continuous(breaks = unique(estimates$subID)) +
  scale_fill_gradient2() +
  labs(x = 'subject') +
  theme_bw() +
  theme(text = element_text(size=14))
ggsave(paste0(outdir, 'cueCorr.png'), width=14, height=4)

# cueDiff
estimates %>%
  ggplot(aes(x=trueCue, y=cueDiff, group=trueCue)) +
  geom_hline(yintercept = 0) +
  facet_wrap(~ condition) +
  geom_violin(alpha=0.3, scale='count') + 
  geom_boxplot(width=0.1, fill=NA, color='black', outliers=FALSE) +
  geom_point(position = position_jitter(width=0.01), alpha=0.5, size=1) +
  geom_line(aes(group=subID), alpha=0.25, color='gray20') +
  scale_x_continuous(breaks = c(0.5, 0.65, 0.8)) +
  ylim(-0.3, 0.5) +
  theme_bw() +
  theme(legend.position = 'none', 
        text = element_text(size=16))
ggsave(paste0(outdir, 'cueDiff.png'), width=6, height=3)

#### test for differences in cueDiff for 50% cue by condition & cueCorr ####

# condition only
estimates %>%
  filter(trueCue == 0.5) %>%
  lm(cueDiff ~ condition, .) %>%
  summary()

estimates %>%
  filter(trueCue == 0.5) %>%
  ggplot(aes(x=condition, y=cueDiff)) +
  theme_bw() +
  geom_point(alpha=0.5, size=0.5) +
  #geom_line(alpha=0.5, size=0.5) +
  stat_summary(fun.data = 'mean_se', geom='pointrange', fatten=6) +
  stat_summary(aes(group=trueCue), fun = 'mean', geom='line') +
  labs(title = 'cueDiff for 50% cues by condition', subtitle = 'mean +/- SEM', x='') +
  theme(text = element_text(size=14))
ggsave(paste0(outdir, 'cueDiff_50cue.png'), width=4.5, height=3)

# condition * cueCorr interaction
estimates %>%
  filter(trueCue == 0.5) %>%
  lm(cueDiff ~ condition * cueCorr, .) %>%
  summary()

# plot
estimates %>%
  #filter(trueCue == 0.5) %>%
  ggplot(aes(x = cueCorr, y=cueDiff, color=condition)) +
  facet_wrap(~ trueCue) +
  theme_bw() + geom_hline(yintercept = 0) +
  geom_smooth(method = 'lm', alpha = 0.25) +
  geom_point(size=1) + 
  labs(title = 'cueCorr predicting cueDiff')
ggsave(paste0(outdir, 'cueDiff ~ cueCorr.png'), width=7, height=2.5)

# get model estimates for full set of trueCues
estimates %>%
  lm(cueDiff ~ condition * cueCorr, .) %>%
  summary()

estimates %>%
  ggplot(aes(x=cueCorr, y=cueDiff)) +
  theme_bw() + facet_wrap(trueCue ~ condition) +
  geom_hline(yintercept = 0) +
  geom_point() +
  geom_smooth(method = 'lm')

#### accuracy colored by cueCorr ####
inference %>%
  group_by(subID) %>%
  select(subID, propCorrect, cueCorr, condition) %>%
  distinct() %>%
  ggplot(aes(x=subID, y=propCorrect)) +
  geom_hline(yintercept = 0.5) +
  geom_hline(yintercept = 0.7, linetype='dashed') +
  ylim(0,1) +
  geom_segment(aes(x=subID, xend=subID, y=0, yend=propCorrect)) +
  geom_point(aes(shape=condition, fill=cueCorr), size=5, stroke=1, color='gray20') +
  scale_shape_manual(values = c(21, 23)) + scale_fill_gradient2() +
  scale_x_continuous(breaks = unique(inference$subID)) + theme_bw() 
ggsave(paste0(outdir, 'propCorrect_bySubject.png'), width=15, height=4, dpi='retina')

#### accuracy, RT, and confidence plots ####
inference_aboveChance <- inference %>% 
  group_by(subID) %>% mutate(propCorrect = mean(accuracy)) %>% filter(propCorrect > 0.52) %>% ungroup() %>%
  group_by(subID) %>% mutate(zConf = scale(confidence))

### accuracy by congCue
inference %>%
  group_by(subID, congCue, condition, cueCorr) %>%
  summarise(propCorrect = mean(accuracy)) %>%
  ggplot(aes(x=congCue, y=propCorrect)) +
  facet_wrap(~ condition) + geom_hline(yintercept = 0.5) +
  geom_hline(yintercept = 0.7, linetype='dashed') +
  theme_bw() +
  geom_line(aes(group=subID, color=cueCorr), size=0.35, alpha=0.7) + 
  geom_point(aes(fill=cueCorr), shape=21, size=2, alpha=0.5, stroke=0.1) +
  stat_summary(fun.data = 'mean_se', geom='pointrange', size=0.5) +
  stat_summary(fun = 'mean', geom='line', size=1) +
  scale_color_gradient2() + scale_x_continuous(breaks = unique(inference$congCue)) + scale_fill_gradient2() +
  labs(title = 'choice accuracy')
ggsave(paste0(outdir, 'propCorrect_byTrueCue.png'), width=6, height=3.5)

### accuracy by subjectiveCongCue
inference %>%
  mutate(subjectiveCongCue_binned = cut(subjectiveCongCue, 
                                        breaks = c(0.5, 0.6, 0.7, 0.8, 0.9, 1.0),
                                        labels = FALSE,
                                        include.lowest = TRUE)) %>%
  group_by(subID, subjectiveCongCue_binned, condition, cueCorr) %>%
  summarise(propCorrect = mean(accuracy)) %>%
  ggplot(aes(x=subjectiveCongCue_binned, y=propCorrect)) +
  facet_wrap(~ condition) + geom_hline(yintercept = 0.5) +
  geom_hline(yintercept = 0.7, linetype='dashed') +
  theme_bw() +
  #stat_summary(fun.y = 'mean', geom='col', position=position_dodge(), fill='gray80') +
  geom_line(aes(group=subID, color=cueCorr), size=0.35, alpha=0.7) + 
  geom_point(aes(fill=cueCorr), shape=21, size=2, alpha=0.5, stroke=0.1) +
  stat_summary(fun.data = 'mean_se', geom='pointrange', size=0.5) +
  stat_summary(fun = 'mean', geom='line', size=0.5) +
  scale_color_gradient2() + scale_fill_gradient2() + scale_x_continuous(labels = c(0.5, 0.6, 0.7, 0.8, 0.9)) +
  labs(title = 'choice accuracy')
ggsave(paste0(outdir, 'propCorrect_bySubjectiveCongCue.png'), width=6, height=3.5)

### RTs by congCue, condition, and accuracy
p0 <- inference_aboveChance %>%
  mutate(accuracy = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect'))) %>%
  group_by(subID, congCue, condition, cueCorr, accuracy) %>%
  summarise(rt = mean(zlogRT)) %>%
  ggplot(aes(x=congCue, y=rt, color=accuracy)) +
  facet_wrap(~ condition) + 
  geom_hline(yintercept = 0) +
  theme_bw() +
  geom_boxplot(aes(group=interaction(congCue, accuracy))) + 
  geom_point(aes(group=interaction(congCue, accuracy)), shape=21, size=0.5,
             position=position_jitterdodge(jitter.width=0.04, jitter.height = 0, dodge.width=0.1)) +
  scale_x_continuous(breaks = unique(inference$congCue)) +
  #scale_fill_manual(values = c('firebrick', 'forestgreen')) +
  labs(y = 'zlogRT', title = 'raw data')
ggsave(paste0(outdir, 'zlogRT_byCongCue_andAccuracy.png'), width = 10, height=3.5, dpi='retina')

p1 <- inference_aboveChance %>%
  mutate(accuracy = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect'))) %>%
  group_by(subID, congCue, condition, cueCorr, accuracy) %>%
  summarise(rt = mean(zlogRT)) %>%
  ggplot(aes(x=congCue, y=rt, color=congCue)) +
  facet_wrap(~ accuracy) + 
  geom_hline(yintercept = 0) +
  theme_bw() +
  geom_boxplot(aes(group=interaction(congCue, accuracy)), alpha=0.7) + 
  geom_point(aes(group=interaction(congCue, accuracy)), shape=21, position=position_jitterdodge(jitter.width=0.04, jitter.height = 0, dodge.width=0.1)) +
  scale_x_continuous(breaks = unique(inference$congCue)) +
  #scale_fill_manual(values = c('firebrick', 'forestgreen')) +
  labs(y = 'zlogRT')
ggsave(paste0(outdir, 'zlogRT_byAccuracy.png'), width = 10, height=3.5, dpi='retina')

## regression plot
p2 <- inference_aboveChance %>%
  mutate(accuracy = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect'))) %>%
  group_by(subID, congCue, condition, cueCorr, accuracy) %>%
  summarise(rt = mean(zlogRT)) %>%
  ggplot(aes(x=congCue, y=rt, color=accuracy)) +
  facet_wrap(~ condition) + 
  geom_hline(yintercept = 0) +
  theme_bw() +
  geom_point(aes(group=interaction(congCue, accuracy)), shape=21, 
             position=position_jitterdodge(jitter.width=0.04, jitter.height = 0, dodge.width=0.1)) +
  stat_smooth(method = 'lm') +
  scale_x_continuous(breaks = unique(inference$congCue)) +
  #scale_fill_manual(values = c('firebrick', 'forestgreen')) +
  labs(y = 'zlogRT', title = 'regression lines')

p0 + p2 + plot_layout(widths = c(1, 1), guides = 'collect')
ggsave(paste0(outdir, 'zlogRTs_withRegressions.png'), width=9, height=3, dpi='retina')

# linear model
lm(zlogRT ~ congCue * accuracy, inference_aboveChance) %>% summary()


### confidence by congCue, condition, and accuracy
mean_correct_conf <- inference %>% filter(accuracy==1) %>% ungroup() %>% summarise(mean(confidence, na.rm=T)) %>% pull
mean_incorrect_conf <- inference %>% filter(accuracy==0) %>% ungroup() %>% summarise(mean(confidence, na.rm=T)) %>% pull


# raw confidence
inference %>%
  mutate(accuracy = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect'))) %>%
  group_by(subID, congCue, condition, cueCorr, accuracy) %>%
  summarise(confidence = mean(confidence)) %>%
  ggplot(aes(x=congCue, y=confidence, color=congCue)) +
  facet_wrap(~ accuracy) + 
  geom_hline(data = tibble(accuracy = 'correct'), aes(yintercept = mean_correct_conf)) + 
  geom_hline(data = tibble(accuracy = 'incorrect'), aes(yintercept = mean_incorrect_conf)) + 
  ylim(1,4) +
  theme_bw() +
  geom_boxplot(aes(group=interaction(congCue, accuracy)), alpha=0.7) + 
  #geom_point(aes(group=interaction(congCue, accuracy), fill=cueCorr), shape=21, size=2, alpha=0.75, position=position_jitterdodge(jitter.width=0.04, jitter.height = 0, dodge.width=0.1)) +
  #geom_line(aes(group=interaction(subID), color=cueCorr), alpha=0.2) +
  scale_x_continuous(breaks = unique(inference$congCue)) +
  scale_fill_gradient2() + scale_color_gradient2()
ggsave(paste0(outdir, 'confidence_byCongCue_andAccuracy.png'), width = 10, height=3.5, dpi='retina')

# z-scored confidence
p0 <- inference_aboveChance %>%
  mutate(accuracy = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect'))) %>%
  group_by(subID) %>%
  mutate(zconf = scale(confidence)) %>%
  group_by(subID, congCue, condition, cueCorr, accuracy) %>%
  summarise(confidence = mean(zconf)) %>%
  ggplot(aes(x=congCue, y=confidence, color=accuracy)) +
  facet_wrap(~ condition, scales='free') + 
  geom_hline(yintercept = 0) +
  theme_bw() +
  geom_boxplot(aes(group=interaction(congCue, accuracy))) + 
  geom_point(aes(group=interaction(congCue, accuracy)), shape=21, size=2, position=position_jitterdodge(jitter.width=0.04, jitter.height = 0, dodge.width=0.1)) +
  #geom_line(aes(group=interaction(subID), color=cueCorr), alpha=0.2) +
  scale_x_continuous(breaks = unique(inference$congCue)) +
  #scale_fill_gradient2() + scale_color_gradient2() +
  labs(y = 'confidence (z-scored)', title = 'z-scored confidence')
ggsave(paste0(outdir, 'confidenceZ_byCongCue_andAccuracy.png'), width = 10, height=3.5, dpi='retina')

## linear regression
p1 <- inference_aboveChance %>%
  mutate(accuracy = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect'))) %>%
  group_by(subID) %>%
  mutate(zconf = scale(confidence)) %>%
  group_by(subID, congCue, condition, accuracy) %>%
  summarise(confidence = mean(zconf)) %>%
  ggplot(aes(x=congCue, y=confidence, color=accuracy)) +
  facet_wrap(~ condition, scales='free') + 
  geom_hline(yintercept = 0) +
  theme_bw() +
  geom_point(aes(group=interaction(congCue, accuracy)), shape=21, size=2, 
             position=position_jitterdodge(jitter.width=0.04, jitter.height = 0, dodge.width=0.1)) +
  stat_smooth(method = 'lm') +
  scale_x_continuous(breaks = unique(inference$congCue)) +
  labs(y = 'confidence (z-scored)', title = 'regression lines')

p0 + p1 + plot_layout(guides = 'collect')

ggsave(paste0(outdir, 'confidenceZ_withRegression.png'), width=9, height=3)

## linear model
lm(zConf ~ congCue * accuracy, inference_aboveChance) %>% summary()

trueCues <- estimates %>% ungroup() %>% select(cueIdx, condition, trueCue) %>% unique()

# show how cueCorr relates to trueCue
estimates %>%
  ggplot(aes(x=cueIdx, y=subjectiveCue, fill=cueCorr)) +
  theme_bw() + facet_wrap(~condition) +
  #geom_hline(yintercept=c(0.5, 0.65, 0.8)) + 
  #geom_violin(aes(group=cueIdx), alpha=0.3, scale='count') + 
  #geom_boxplot(aes(group=cueIdx), width=0.3, fill=NA, color='black', outliers=FALSE) +
  geom_col(aes(x=cueIdx, y=trueCue), data=trueCues, fill='gray') +
  geom_point(position = position_jitter(width=0.01), alpha=0.5, size=3, shape=21) +
  geom_line(aes(group=subID, color=cueCorr), alpha=0.5) +
  scale_fill_gradient2() + scale_color_gradient2() +
  #scale_x_continuous(breaks = c(0.5, 0.65, 0.8)) +
  #ylim(-0.3, 0.5) +
  labs(title = 'bars = trueCue values') 
ggsave(paste0(outdir, 'subjectiveCue_wCueCorr.png'), width=9, height=3.5, dpi='retina')

# new metric: totalDiff
estimates %>%
  group_by(subID) %>%
  mutate(totalDiff = sum(cueDiff)) %>% 
  ggplot(aes(x=cueIdx, y=subjectiveCue, fill=totalDiff)) +
  theme_bw() + facet_wrap(~condition) +
  geom_col(aes(x=cueIdx, y=trueCue), data=trueCues, fill='gray') +
  geom_point(position = position_jitter(width=0.01), alpha=0.5, size=3, shape=21) +
  geom_line(aes(group=subID, color=totalDiff), alpha=0.5) +
  scale_fill_gradient() + scale_color_gradient() +
  #scale_x_continuous(breaks = c(0.5, 0.65, 0.8)) +
  #ylim(-0.3, 0.5) +
  labs(title = 'bars = trueCue values') 



#### confidence & RT relationships ####

inference_aboveChance %>% 
  filter(zlogRT > -6) %>% 
  mutate(accuracy = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect'))) %>%
  ggplot(aes(x=zlogRT, y=zConf, color=accuracy)) +
  theme_bw() + geom_hline(yintercept = 0) + 
  geom_point(size=1, alpha=0.5) +
  facet_grid(~ congCue) +
  stat_smooth(method = 'lm') +
  labs(title = "RT predicting confidence")
ggsave(paste0(outdir, 'conf ~ RT.png'), width=9, height=3)



inference_aboveChance %>% 
  filter(zlogRT > -6) %>% 
  mutate(accuracy = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect')),
         totalNoise = noise1_duration + noise2_duration) %>%
  ggplot(aes(x=totalNoise, y=zConf, color=accuracy)) +
  theme_bw() + geom_hline(yintercept = 0) + 
  geom_point(size=0.2, alpha=0.2) +
  facet_grid(~ congCue) +
  stat_smooth(method = 'lm') 

inference_aboveChance %>% 
  filter(zlogRT > -6) %>% 
  mutate(accuracy = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect'))) %>%
  ggplot(aes(x=noise2_duration, y=zConf, color=accuracy)) +
  theme_bw() + geom_hline(yintercept = 0) + 
  geom_point(size=0.2, alpha=0.2) +
  facet_grid(~ congCue) +
  stat_smooth(method = 'lm')


inference_aboveChance %>% 
  filter(zlogRT > -6) %>% 
  ggplot(aes(x=noise2_duration, y=accuracy)) +
  theme_bw() + geom_hline(yintercept = 0) + 
  geom_point(size=0.2, alpha=0.2) +
  geom_hline(yintercept = 0.5) +
  facet_grid(~ congCue) +
  stat_smooth(aes(group=congCue), method = 'lm') +
  labs(title = 'effect of noise2 duration on accuracy')
glm(accuracy ~ noise2_duration * congCue, inference_aboveChance, family='binomial') %>% summary()

ggsave(paste0(outdir, 'accuracy ~ noise2 * congCue.png'), width=9, height=3)
