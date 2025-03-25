library(tidyverse)
library(patchwork)


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
