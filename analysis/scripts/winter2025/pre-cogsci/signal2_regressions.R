library(tidyverse)
library(patchwork)
library(lme4)
library(lmerTest)
library(emmeans)

outdir <- '../figures/'
inference_df <- read.csv('../tidied_data/inference.csv')
model_df <- read.csv('../tidied_data/model.csv')

signal2_test <- inference_df %>% 
  filter(respLabel == 'signal2', catch_trial==0) %>% 
  mutate(congCue = case_when(trueCongruence=='congruent' ~ trueCue/100,
                             trueCongruence=='incongruent' ~ (100-trueCue)/100,
                             trueCongruence=='neutral' ~ 0.5),
         cueCongChoice = case_when(cueIdx<3 & cueIdx==response ~ 1,
                                   cueIdx<3 & cueIdx != response ~ 0,
                                   cueIdx==3 ~ NA))

signal2_model <- model_df %>% 
  filter(respLabel == c('signal2')) %>% 
  mutate(congCue = case_when(congruent==1 ~ cue,
                             congruent==0 ~ 1-cue),
         vizLockedRT = RT - signal2Onsets,
         cueCongChoice = case_when(congruent==1 & forcedChoice==1 ~ 1,
                                   congruent==0 & forcedChoice==0 ~ 1,
                                   congruent==1 & forcedChoice==0 ~ 0,
                                   congruent==0 & forcedChoice==1 ~ 0,
                                   cue==0.5 ~ NA))

#### ACCURACY ####
mb <- glm(accuracy ~ noise2frames_obs * congCue + 
      zlogRT_sig2locked + noise1frames_obs + signal1frames_obs, signal2_test, family='binomial')

p1 <- mb %>%
  emmeans(., ~ noise2frames_obs | congCue , type='response', 
          at=list(noise2frames_obs=quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,0.99,0.1)),
                  congCue = unique(signal2_test$congCue))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=congCue, fill=congCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  labs(title = 'behavior')

p2 <- mb %>% 
  emtrends(., 'congCue', var='noise2frames_obs', at=list(congCue = unique(signal2_model$congCue))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=congCue, y=noise2frames_obs.trend, color = congCue, 
             ymin=asymp.LCL, ymax=asymp.UCL)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_pointrange()

mm <- glm(rawChoice ~ noise2Frames * congCue + 
           zlogRT_sig2locked + noise1Frames + signal1Frames, signal2_model, family='binomial')

p3 <- mm %>%
  emmeans(., ~ noise2Frames | congCue, type='response',
          at = list(noise2Frames = quantile(signal2_model$noise2Frames),
                    congCue = unique(signal2_model$congCue))) %>%
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2Frames, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=congCue, fill=congCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5)  +
  labs(title = 'model predictions')

p4 <- mm %>% 
  emtrends(., 'congCue', var='noise2Frames', at=list(congCue = unique(signal2_test$congCue))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=congCue, y=noise2Frames.trend, color = congCue, 
             ymin=asymp.LCL, ymax=asymp.UCL)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_pointrange()

(p1 + p2) / (p3 + p4)

ggsave(paste0(outdir, 'signal2Accuracy.png'), width=8, height=4)


emtrends(mb, 'congCue', var='noise2frames_obs', at=list(congCue = unique(signal2_model$congCue)))

mb <- glm(accuracy ~ noise2frames_obs * congCue * targetEv_signal2 + 
            zlogRT_sig2locked + noise1frames_obs + signal1frames_obs, signal2_test, family='binomial')
  
emmeans(mb, ~ noise2frames_obs * targetEv_signal1 | congCue , type='response', 
        at=list(noise2frames_obs=quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.25)),
                targetEv_signal1=quantile(signal2_test$targetEv_signal1, na.rm=T, probs=seq(0,1,0.5)),
                congCue = unique(signal2_test$congCue))) 

emmip(mb, ~ noise2frames_obs * targetEv_signal2 | congCue , type='response', CIs=TRUE,
       at=list(noise2frames_obs=quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.5)),
               targetEv_signal1=quantile(signal2_test$targetEv_signal2, na.rm=T, probs=seq(0,1,0.5)),
               congCue = unique(signal2_test$congCue)))

#### RT ####
mb <- lm(zlogRT_sig2locked ~ noise2frames_obs * congCue + 
            accuracy, signal2_test)

p1 <- mb %>%
  emmeans(., ~ noise2frames_obs | congCue , type='response', 
          at=list(noise2frames_obs=quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,0.99,0.1)),
                  congCue = unique(signal2_test$congCue))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2frames_obs, y=emmean, ymin=lower.CL, ymax=upper.CL, 
             color=congCue, fill=congCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  labs(title = 'behavior')

p2 <- mb %>% 
  emtrends(., 'congCue', var='noise2frames_obs', at=list(congCue = unique(signal2_model$congCue))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=congCue, y=noise2frames_obs.trend, color = congCue, 
             ymin=lower.CL, ymax=upper.CL)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_pointrange()

mm <- lm(zlogRT_sig2locked ~ noise2Frames * congCue + 
            rawChoice, signal2_model)

p3 <- mm %>%
  emmeans(., ~ noise2Frames | congCue, type='response',
          at = list(noise2Frames = quantile(signal2_model$noise2Frames),
                    congCue = unique(signal2_model$congCue))) %>%
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2Frames, y=emmean, ymin=lower.CL, ymax=upper.CL, 
             color=congCue, fill=congCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5)  +
  labs(title = 'model predictions')

p4 <- mm %>% 
  emtrends(., 'congCue', var='noise2Frames', at=list(congCue = unique(signal2_model$congCue))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=congCue, y=noise2Frames.trend, color = congCue, 
             ymin=lower.CL, ymax=upper.CL)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_pointrange()

(p1 + p2) / (p3 + p4)
ggsave(paste0(outdir, 'signal2RT.png'), width=8, height=5)

#### CHOICE BIAS ####
mb <- glm(cueCongChoice ~ noise2frames_obs * congCue + zlogRT_sig2locked, signal2_test, family='binomial')

p1 <- mb %>%
  emmeans(., ~ noise2frames_obs | congCue , type='response', 
          at=list(noise2frames_obs=quantile(signal2_test$noise2frames_obs, na.rm=T, probs=seq(0,0.99,0.1)),
                  congCue = c(0.2, 0.8))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=congCue, fill=congCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(title = 'behavior: p(chooseCue)')

p2 <- mb %>% 
  emtrends(., 'congCue', var='noise2frames_obs', at=list(congCue = c(0.2, 0.8))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=congCue, y=noise2frames_obs.trend, color = congCue, 
             ymin=asymp.LCL, ymax=asymp.UCL)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_pointrange()

mm <- glm(cueCongChoice ~ noise2Frames * congCue + zlogRT_sig2locked, signal2_model, family='binomial')

p3 <- mm %>%
  emmeans(., ~ noise2Frames | congCue, type='response',
          at = list(noise2Frames = quantile(signal2_model$noise2Frames),
                    congCue = c(0.2, 0.8))) %>%
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2Frames, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=congCue, fill=congCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5)  +
  labs(title = 'model predictions: p(chooseCue)')

p4 <- mm %>% 
  emtrends(., 'congCue', var='noise2Frames', at=list(congCue = c(0.2, 0.8))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=congCue, y=noise2Frames.trend, color = congCue, 
             ymin=asymp.LCL, ymax=asymp.UCL)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_pointrange()

(p1 + p2) / (p3 + p4)
ggsave(paste0(outdir, 'signal2chooseCue.png'), width=8, height=5)
