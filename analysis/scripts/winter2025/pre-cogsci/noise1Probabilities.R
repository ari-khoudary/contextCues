library(tidyverse)
library(lmerTest)
library(lme4)
library(patchwork)
library(emmeans)

outdir <- '../figures/cogsci/'
inference_df <- read.csv('../tidied_data/inference.csv') %>% 
  mutate(congCue = factor(congCue),
         noise1Resp = ifelse(respPeriod==1, 1, 0),
         cueConf_factor = factor(cueConfidence)) %>%
  filter(subID != 33)

# first, plot correlation between trueCue and subjectiveCue
inference_df %>%
  group_by(subID) %>%
  summarise(cueCorr = cor(subjectiveCue, trueCue)) %>%
  ggplot(aes(x=subID, y=cueCorr)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_col() +
  scale_x_continuous(breaks = unique(inference_df$subID)) +
  labs(title = 'correlation between objective cue strength & subjective estimate')

ggsave(paste0(outdir, 'cueCorr_allSubs.png'), width=6, height=4)

# add correlation as a variable to inference_df
inference_df <- inference_df %>% group_by(subID) %>% mutate(cueCorr = cor(subjectiveCue, trueCue))


# does cueCorr predict confidence in cue estimate?
## one observation per subject
p1 <- inference_df %>%
  distinct(subID, cueConfidence, cueCorr) %>%
  ggplot(aes(x=cueConfidence, y=cueCorr)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_jitter(width=0.1) +
  stat_smooth(method='lm') +
  labs(title = 'relationship between cueCorr & cueConfidence')

# multiple observations per subject
p2 <- inference_df %>%
  ggplot(aes(x=cueConfidence, y=cueCorr)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_jitter(width=0.1) +
  stat_smooth(method='lm') +
  labs(title = 'estimated using all inference trials')

p1 / p2
ggsave(paste0(outdir, 'cueCorr_cueConf.png'), width=4.5, height=6)

# estimate significance of relationship
inference_df %>%
  group_by(subID) %>%
  distinct(cueConfidence, cueCorr) %>%
  lm(cueConfidence ~ cueCorr, .,) %>%
  emtrends(., var='cueCorr') %>%
  test(null=0)

# probability of making a response during noise1 by objective cue
objectiveLines <- glm(noise1Resp ~ trueCue * noise1frames_design, inference_df, family='binomial') %>%
  emmip(., trueCue ~ noise1frames_design, type='response', CI=T,
        at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                trueCue = unique(inference_df$trueCue))) + 
  theme_bw() + 
  ggtitle('probability of noise1 response')

objectiveSlopes <- glm(noise1Resp ~ trueCue * noise1frames_design, inference_df, family='binomial') %>%
  emmip(., trueCue ~ noise1frames_design, type='response', CI=T,
        at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                trueCue = unique(inference_df$trueCue))) + 
  theme_bw() + 
  ggtitle('probability of noise1 response')