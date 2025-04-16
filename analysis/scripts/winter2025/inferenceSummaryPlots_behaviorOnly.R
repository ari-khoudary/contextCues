library(tidyverse)
library(patchwork)
library(emmeans)

# load data
outdir <- '../figures/'
inference_df <- read.csv('../tidied_data/condition_80cue/inference.csv')
validation_df <- read.csv('../tidied_data/condition_80cue/learningValidation.csv')

# tidy data
inference_df <- inference_df %>% 
  mutate(noise1Resp = ifelse(respPeriod==1, 1, 0),
         choose1 = ifelse(response==1, 1, 0),
         choose2 = ifelse(response==2, 1, 0), 
         cueConf_factor = factor(cueConfidence),
         subjectiveCue = subjectiveCue/100,
         trueCue = trueCue/100,
         trueCongruence = factor(trueCongruence, levels=c('incongruent', 'neutral', 'congruent'))) %>%
  filter(subID != c(33), catch_trial==0, zlogRT > -10) %>%
  group_by(subID) %>%
  mutate(cueCorr = cor(subjectiveCue, trueCue),
         cueDiff = subjectiveCue - trueCue,
         cueCorr_spearman = cor(subjectiveCue, trueCue, method = 'spearman'),
         cueCorr_q = ntile(cueCorr, n=2),
         cueCorr_sign = case_when(cueCorr < 0 ~ 'negative',
                                  cueCorr > 0 ~ 'positive'))


# plot choice probabilities
colors <- c("choice probability" = "maroon", "reported probability" = "pink", 'reported p(target)' = 'black')

inference_df %>%
  mutate(cueIdx = factor(cueIdx, levels=c(1,3,2), labels=c('80% A', '50%', '80% B')),
         subjectiveCue = ifelse(imgIdx_subjective==2, 1-subjectiveCue, subjectiveCue),
         trueCue = ifelse(cueIdx != '80% A', 1-trueCue, trueCue)) %>%
  ggplot() +
  theme_bw() + 
  facet_wrap(~ subID) +
  labs(y = 'p(chooseA)', x='true prediction') + 
  ylim(0,1) +
  geom_hline(yintercept = 0.5, linetype='dashed', linewidth=0.5, color='gray') +
  # Create a grouped position
  stat_summary(aes(x=cueIdx, y=trueCue, fill='true probability'), 
               fun='mean', geom='bar', width=0.4, 
               position=position_dodge(width=0.9)) +
  stat_summary(aes(x=cueIdx, y=choose1, fill='choice probability'), 
               fun='mean', geom='bar', width=0.4, 
               position=position_dodge(width=0.9)) +   scale_fill_manual(values=c('choice probability'='coral', 'true probability'='turquoise'))




+
  geom_col(aes(y=mean(subjectiveCue), fill='reported probability'), position=position_dodge2(width=1)) +
  scale_fill_manual(values = colors) +
  
  
  geom_point(aes(x=congCue, y=subjectiveCue, group=targetIdx)) +
  geom_line(aes(x=congCue, y=subjectiveCue, group=targetIdx))

# objective probabilities
inference_df %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=congCue, y=cueCongResponse_obj, fill=congCue, color=congCue)) +
  theme_bw() + 
  facet_wrap(~ subID) +
  stat_summary(fun.data = 'mean_se', geom='pointrange') + 
  stat_summary(aes(group=subID), fun = 'mean', geom='line')
  
  
  geom_point(aes(x=congCue, y=subjectiveCue, group=targetIdx)) +
  geom_line(aes(x=congCue, y=subjectiveCue, group=targetIdx))
  
  
  stat_summary(fun.data = 'mean', aes(x=cueIdx, y=subjectiveCue/100)) +
  stat_summary(fun.data = 'mean_se', geom='pointrange') +
  stat_summary(aes(group=subID), fun = 'mean', geom='line', color='gray')
