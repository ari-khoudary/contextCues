library(tidyverse)
library(patchwork)
outdir <- '../figures/'

validation_df <- read.csv('../tidied_data/coherenceValidation.csv') %>%
  mutate(targetIdx = factor(targetIdx))

# accuracy
validation_df %>%
  ggplot(aes(x=targetIdx, y=accuracy, color=targetIdx)) +
  theme_bw() +
  stat_summary(fun.data='mean_se', position=position_dodge(width=0.5)) +
  geom_hline(yintercept = 0.7) +
  geom_hline(yintercept = 0.5, linetype='dashed') +
  facet_wrap(~ subID, ncol=3)
  #scale_x_continuous(n.breaks = length(unique(validation_df$subID))) 

ggsave(paste0(outdir, 'validationAccuracy.png'), width=5, height=8)          

# RT distributions
validation_df %>% 
  group_by(subID, targetIdx) %>%
  ggplot(aes(x=zlogRT, fill=targetIdx, color=targetIdx)) +
  theme_bw() +
  geom_density(alpha=0.5) +
  facet_wrap(~ subID, ncol=3)

ggsave(paste0(outdir, 'validationRT.png'), width=5, height=8)

# RTs as a function of trial
validation_df %>%
  ggplot(aes(x=trial, y=zlogRT, color=targetIdx)) +
  theme_bw() +
  geom_point() +
  geom_smooth(method='lm') + facet_wrap(~ subID, ncol=3)
ggsave(paste0(outdir, 'validationRT_byTrial.png'), width=5, height=8)
