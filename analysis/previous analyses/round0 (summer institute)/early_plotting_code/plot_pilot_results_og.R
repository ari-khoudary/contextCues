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
