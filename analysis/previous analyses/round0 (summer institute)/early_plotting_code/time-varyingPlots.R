library(tidyverse)

### compute accuracy & confidence as a function of response period & congruence ### 
tpSummary_group <- inferenceData_tidy %>%
  filter(is.na(respPeriod)==F) %>%
  mutate(respPeriod = factor(respPeriod, levels=c(1,2,3,4),
                             labels = c('first noise', 'first signal','second noise','second signal'))) %>%
  group_by(respPeriod, congruent) %>%
  summarise(propCorrect = mean(accuracy),
            accuracy_sem = sd(accuracy)/sqrt(nSubs),
            meanConf = mean(zConf),
            conf_sem = sd(zConf)/sqrt(nSubs))

tpSummary_individual <- inferenceData_tidy %>%
  filter(is.na(respPeriod)==F) %>%
  mutate(respPeriod = factor(respPeriod, levels=c(1,2,3,4),
                             labels = c('first noise', 'first signal','second noise','second signal'))) %>% 
  group_by(respPeriod, congruent, subID) %>%
  summarise(propCorrect = mean(accuracy),
            meanConf = mean(zConf))

# plot accuracy as a function of response period
tpSummary_group %>%
  ggplot(aes(x=respPeriod, y=propCorrect, color=congruent, fill=congruent)) +
  geom_hline(yintercept=0.5, linewidth=0.15) +
  geom_col(position=position_dodge()) +
  geom_errorbar(aes(ymin=propCorrect - accuracy_sem, ymax = propCorrect + accuracy_sem), width=0.1,
                position = position_dodge(width=0.9), color='gray25') + 
  geom_point(data=tpSummary_individual, position=position_jitterdodge(dodge.width=0.9, jitter.width = 0.15), 
             color='gray25', shape=21, size=1, alpha=0.7) +
  theme_classic() 

# plot confidence as a function of response period
tpSummary_group %>%
  ggplot(aes(x=respPeriod, y=meanConf, color=congruent, fill=congruent)) +
  geom_hline(yintercept=0, linewidth=0.15) +
  geom_col(position=position_dodge()) +
  geom_errorbar(aes(ymin=meanConf - conf_sem, ymax = meanConf + conf_sem), width=0.1,
                position = position_dodge(width=0.9), color='gray25') + 
  geom_point(data=tpSummary_individual, position=position_jitterdodge(dodge.width=0.9, jitter.width = 0.15), 
             color='gray25', shape=21, size=1, alpha=0.7) +
  theme_classic() 


### compute accuracy & confidence as a function of total trial noise & congruence ### 
tnSummary_group <- inferenceData_tidy %>%
  group_by(totalNoise_quartile, congruent) %>%
  summarise(propCorrect = mean(accuracy),
            accuracy_sem = sd(accuracy)/sqrt(nSubs),
            meanConf = mean(zConf),
            conf_sem = sd(zConf)/sqrt(nSubs))

tnSummary_individual <- inferenceData_tidy %>%
  group_by(totalNoise_quartile, congruent, subID) %>%
  summarise(propCorrect = mean(accuracy),
            meanConf = mean(zConf))

# plot accuracy as a function of trial noise
tnSummary_group %>%
  ggplot(aes(x=totalNoise_quartile, y=propCorrect, color=congruent, fill=congruent, group=congruent)) +
  geom_hline(yintercept=0.5, linewidth=0.15) +
  geom_pointrange(aes(ymin=propCorrect - accuracy_sem, ymax = propCorrect + accuracy_sem)) +
  geom_line() +
  theme_classic() +
  ggtitle('accuracy as a function of total trial noise')

# confidence as a function of trial noise
tnSummary_group %>%
  ggplot(aes(x=totalNoise_quartile, y=meanConf, color=congruent, fill=congruent, group=congruent)) +
  geom_hline(yintercept=0, linewidth=0.15) +
  geom_pointrange(aes(ymin=meanConf - conf_sem, ymax = meanConf + conf_sem)) +
  geom_line() +
  theme_classic() +
  labs(title = 'confidence as a function of total trial noise', y='confidence (z-scored)')


### compute accuracy & confidence as a function of first trial noise & congruence ### 
fnSummary_group <- inferenceData_tidy %>%
  group_by(firstNoise_quartile, congruent) %>%
  summarise(propCorrect = mean(accuracy),
            accuracy_sem = sd(accuracy)/sqrt(nSubs),
            meanConf = mean(zConf),
            conf_sem = sd(zConf)/sqrt(nSubs))

fnSummary_individual <- inferenceData_tidy %>%
  group_by(firstNoise_quartile, congruent, subID) %>%
  summarise(propCorrect = mean(accuracy),
            meanConf = mean(zConf))

# plot accuracy as a function of trial noise
fnSummary_group %>%
  ggplot(aes(x=firstNoise_quartile, y=propCorrect, color=congruent, fill=congruent, group=congruent)) +
  geom_hline(yintercept=0.5, linewidth=0.15) +
  geom_pointrange(aes(ymin=propCorrect - accuracy_sem, ymax = propCorrect + accuracy_sem)) +
  geom_line() +
  theme_classic() +
  ggtitle('accuracy as a function of first noise duration')

# confidence as a function of trial noise
fnSummary_group %>%
  ggplot(aes(x=firstNoise_quartile, y=meanConf, color=congruent, fill=congruent, group=congruent)) +
  geom_hline(yintercept=0, linewidth=0.15) +
  geom_pointrange(aes(ymin=meanConf - conf_sem, ymax = meanConf + conf_sem)) +
  geom_line() +
  theme_classic() +
  labs(title = 'confidence as a function of total trial noise', y='confidence (z-scored)')

#### compute accuracy and confidence as a function of second noise duration #### 
snSummary_group <- inferenceData_tidy %>%
  group_by(secondNoise_quartile, congruent) %>%
  summarise(propCorrect = mean(accuracy),
            accuracy_sem = sd(accuracy)/sqrt(nSubs),
            meanConf = mean(zConf),
            conf_sem = sd(zConf)/sqrt(nSubs))

snSummary_individual <- inferenceData_tidy %>%
  group_by(secondNoise_quartile, congruent, subID) %>%
  summarise(propCorrect = mean(accuracy),
            meanConf = mean(zConf))

# plot accuracy as a function of trial noise
snSummary_group %>%
  ggplot(aes(x=secondNoise_quartile, y=propCorrect, color=congruent, fill=congruent, group=congruent)) +
  geom_hline(yintercept=0.5, linewidth=0.15) +
  geom_pointrange(aes(ymin=propCorrect - accuracy_sem, ymax = propCorrect + accuracy_sem)) +
  geom_line() +
  theme_classic() +
  ggtitle('accuracy as a function of second noise duration')
ggsave(paste0(outdir,'secondNoise_accuracy.png'), width=6, height=4, dpi='retina')

# confidence as a function of trial noise
snSummary_group %>%
  ggplot(aes(x=secondNoise_quartile, y=meanConf, color=congruent, fill=congruent, group=congruent)) +
  geom_hline(yintercept=0, linewidth=0.15) +
  geom_pointrange(aes(ymin=meanConf - conf_sem, ymax = meanConf + conf_sem)) +
  geom_line() +
  theme_classic() +
  labs(title = 'confidence as a function of second noise duration', y='confidence (z-scored)')  


#### let's see if we can get confidence effects by splitting by accuracy
snSummary_group <- inferenceData_tidy %>%
  group_by(secondNoise_quartile, congruent, accuracyFactor) %>%
  summarise(meanConf = mean(zConf),
            conf_sem = sd(zConf)/sqrt(nSubs))

snSummary_individual <- inferenceData_tidy %>%
  group_by(totalNoise_quartile, congruent, subID) %>%
  summarise(propCorrect = mean(accuracy),
            meanConf = mean(zConf))

# confidence as a function of trial noise * accuracy
snSummary_group %>%
  ggplot(aes(x=secondNoise_quartile, y=meanConf, color=congruent, fill=congruent, group=congruent)) +
  facet_wrap(~accuracyFactor) + 
  geom_hline(yintercept=0, linewidth=0.15) +
  geom_pointrange(aes(ymin=meanConf - conf_sem, ymax = meanConf + conf_sem)) +
  geom_line() +
  theme_classic() +
  labs(title = 'confidence as a function of second noise duration', y='confidence (z-scored)')  
ggsave(paste0(outdir, 'secondNoise_confidence.png'), width=8, height=4, dpi='retina')


####### now let's see accuracy as a function of RT ####### 
rt_quantiles <- quantile(inferenceData_tidy$zlogRT, names=F)

rtSummary_group <- inferenceData_tidy %>%
  mutate(rt_quartile = ifelse(zlogRT >= rt_quantiles[1] & zlogRT < rt_quantiles[2], 1,
                              ifelse(zlogRT >= rt_quantiles[2] & zlogRT < rt_quantiles[3], 2,
                                     ifelse(zlogRT >= rt_quantiles[3] & zlogRT < rt_quantiles[4], 3,
                                            ifelse(zlogRT >= rt_quantiles[4] & zlogRT <= rt_quantiles[5], 4, NA))))) %>%
  group_by(rt_quartile, congruent) %>%
  summarise(propCorrect = mean(accuracy),
            sem = sd(accuracy)/sqrt(nSubs),
            meanConf = mean(zConf),
            conf_sem = sd(zConf)/sqrt(nSubs))

rtSummary_individual <- inferenceData_tidy %>%
  mutate(rt_quartile = ifelse(zlogRT >= rt_quantiles[1] & zlogRT < rt_quantiles[2], 1,
                              ifelse(zlogRT >= rt_quantiles[2] & zlogRT < rt_quantiles[3], 2,
                                     ifelse(zlogRT >= rt_quantiles[3] & zlogRT < rt_quantiles[4], 3,
                                            ifelse(zlogRT >= rt_quantiles[4] & zlogRT <= rt_quantiles[5], 4, NA))))) %>%
  group_by(subID, rt_quartile, congruent) %>%
  summarise(propCorrect = mean(accuracy))

rtSummary_group %>%
  ggplot(aes(x=rt_quartile, y=propCorrect, color=congruent,group=congruent)) +
  geom_hline(yintercept=0.5, linewidth=0.15) + 
  geom_pointrange(aes(ymin=propCorrect - sem, ymax = propCorrect + sem)) +
  #geom_point(data=rtSummary_individual, position=position_jitter(width=0.1, height=0)) +
  geom_line() +
  theme_classic()


rtSummary_group %>%
  ggplot(aes(x=rt_quartile, y=meanConf, color=congruent,group=congruent)) +
  geom_hline(yintercept=0, linewidth=0.15) + 
  geom_pointrange(aes(ymin=meanConf - conf_sem, ymax = meanConf + conf_sem)) +
  #geom_point(data=rtSummary_individual, position=position_jitter(width=0.1, height=0)) +
  geom_line() +
  theme_classic()
