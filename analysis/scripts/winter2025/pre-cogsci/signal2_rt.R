library(tidyverse)
library(patchwork)
library(lme4)
library(lmerTest)
library(emmeans)

outdir <- '../figures/cogsci'
inference_df <- read.csv('../tidied_data/inference.csv')
model_df <- read.csv('../tidied_data/model.csv')

signal2_test <- inference_df %>% 
  filter(respLabel == c('signal2'), catch_trial==0, subID > 33) %>% 
  mutate(congCue = case_when(trueCongruence=='congruent' ~ trueCue/100,
                             trueCongruence=='incongruent' ~ (100-trueCue)/100,
                             trueCongruence=='neutral' ~ 0.5),
         vizLockedRT = respFrame - signal2Onset_design,
         cueCongChoice = case_when(cueIdx<3 & cueIdx==response ~ 1,
                                   cueIdx<3 & cueIdx != response ~ 0,
                                   cueIdx==3 ~ NA)) %>%
  group_by(subID) %>% 
  mutate(rt = scale(log(RT - (signal2Onset_design/72))))

signal2_model <- model_df %>% 
  filter(respLabel == c('signal2')) %>% 
  mutate(congCue = case_when(congruent==1 ~ cue,
                             congruent==0 ~ 1-cue),
         vizLockedRT = RT - signal2Onsets,
         cueCongChoice = case_when(congruent==1 & forcedChoice==1 ~ 1,
                                   congruent==0 & forcedChoice==0 ~ 1,
                                   congruent==1 & forcedChoice==0 ~ 0,
                                   congruent==0 & forcedChoice==1 ~ 0,
                                   cue==0.5 ~ NA)) %>%
  filter(noise2Frames <= max(signal2_test$noise2frames_obs, na.rm=T))

#### RT ####
# emmeans for behavior
mb <- lm(accuracy ~ scale(noise2frames_obs) * congCue * scale(targetEv_signal1) + 
            #(1+congCue+scale(noise2frames_obs)|subID) +
            zlogRT_sig2locked, signal2_test, family='binomial')

p1 <- mb %>%
  emmeans(., ~ noise2frames_obs * targetEv_signal1  | congCue, type='response', 
          at=list(noise2frames_obs=quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.25)),
                  targetEv_signal1 = quantile(signal2_test$targetEv_signal1, na.rm=T, probs=seq(0,1,0.23)),
                  congCue = unique(signal2_test$congCue))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=targetEv_signal1)) +
  theme_bw() +
  geom_pointrange() +
  geom_line(aes(group=targetEv_signal1)) +
  facet_wrap(~ congCue) +
  geom_hline(yintercept = 0.5) +
  labs(title = 'behavior', y='estimated accuracy')

# slopes for behavior
p2 <- mb %>% 
  emtrends(.,  ~ congCue | targetEv_signal1, var = "noise2frames_obs", 
           at=list(congCue = unique(signal2_model$congCue),
                   noise2frames_obs = quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,0.99,0.3)),
                   targetEv_signal1 = quantile(signal2_test$targetEv_signal1, na.rm=T, probs=seq(0,1,0.5)))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=targetEv_signal1, y=noise2frames_obs.trend, color = congCue, 
             ymin=asymp.LCL, ymax=asymp.UCL)) +
  theme_bw() +
  geom_hline(yintercept = 0, linetype='dashed') +
  geom_pointrange(position=position_dodge(width=4)) +
  #geom_line() +
  labs(y = 'slope of noise2 effect')

p1 + p2 + plot_layout(widths=c(2,1))

# stats on the slopes
emtrends(mb,  ~ congCue | targetEv_signal1, var = "noise2frames_obs", 
         at=list(congCue = unique(signal2_model$congCue),
                 noise2frames_obs = quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,0.99,0.3)),
                 targetEv_signal1 = quantile(signal2_test$targetEv_signal1, na.rm=T, probs=seq(0,1,1)))) %>%
  test(null=0)


# let's look at individual behavior
signal2_test %>% group_by(subID) %>% count()
inference_df %>% group_by(subID) %>% count()



#### let's run with subjectiveCue instead of congCue?
## TAKEAWAY: verbal estimates match the trends of objective estimates
signal2_test <- signal2_test %>%
  mutate(congCue_subjective = case_when(subjectiveCongruence=='congruent' ~ subjectiveCue/100,
                                        subjectiveCongruence=='incongruent' ~ (100-subjectiveCue)/100,
                                        subjectiveCongruence=='neutral' ~ 0.5))

mb_s <- glm(accuracy ~ scale(noise2frames_obs) * congCue_subjective * scale(targetEv_signal1) + 
              #(1+congCue+scale(noise2frames_obs)|subID) +
              zlogRT_sig2locked, signal2_test, family='binomial')

mb_s %>%
  emmeans(., ~ noise2frames_obs * targetEv_signal1  | congCue_subjective, type='response', 
          at=list(noise2frames_obs=quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.25)),
                  targetEv_signal1 = quantile(signal2_test$targetEv_signal1, na.rm=T, probs=seq(0,1,0.5)),
                  congCue_subjective = quantile(signal2_test$congCue_subjective, na.rm=T, probs=seq(0.1,0.9,0.3)))) %>% 
  as.data.frame() %>%
  mutate(congCue_subjective = factor(congCue_subjective)) %>%
  ggplot(aes(x=noise2frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=targetEv_signal1)) +
  theme_bw() +
  geom_pointrange() +
  geom_line(aes(group=targetEv_signal1)) +
  facet_wrap(~ congCue_subjective) +
  geom_hline(yintercept = 0.5) +
  labs(title = 'behavior', y='estimated accuracy')

# slopes for behavior
mb_s %>% 
  emtrends(.,  ~ congCue_subjective | targetEv_signal1, var = "noise2frames_obs", 
           at=list(congCue_subjective = quantile(signal2_test$congCue_subjective, na.rm=T, probs=seq(0.1,0.9,0.3)),
                   noise2frames_obs = quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,0.99,0.3)),
                   targetEv_signal1 = quantile(signal2_test$targetEv_signal1, na.rm=T, probs=seq(0,1,0.5)))) %>% 
  as.data.frame() %>%
  ggplot(aes(x=targetEv_signal1, y=noise2frames_obs.trend, color = congCue_subjective, 
             ymin=asymp.LCL, ymax=asymp.UCL)) +
  theme_bw() +
  geom_hline(yintercept = 0, linetype='dashed') +
  geom_pointrange(position=position_dodge(width=4)) +
  geom_line(aes(group=congCue_subjective)) +
  labs(y = 'slope of noise2 effect')


mb_s %>% 
  emtrends(.,  ~ congCue_subjective | targetEv_signal1, var = "noise2frames_obs", 
           at=list(congCue_subjective = quantile(signal2_test$congCue_subjective, na.rm=T, probs=seq(0.1,0.9,0.3)),
                   noise2frames_obs = quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,0.99,0.3)),
                   targetEv_signal1 = quantile(signal2_test$targetEv_signal1, na.rm=T, probs=seq(0,1,0.5)))) %>%
  pairs()

