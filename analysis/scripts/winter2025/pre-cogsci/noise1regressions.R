library(tidyverse)
library(patchwork)
library(lme4)
library(lmerTest)
library(emmeans)

# load it up
outdir <- '../figures/'
inference_df <- read.csv('../tidied_data/inference.csv') %>% mutate(cueIdx=factor(cueIdx),
                                                                    trueCue = factor(trueCue, levels=c(80, 50)),
                                                                    subjectiveCueOrder = factor(subjectiveCueOrder))

model_df <- read.csv('../tidied_data/model.csv') %>% mutate(cue=factor(cue, levels=c(0.8, 0.5)))

# subdivide data
noise1_test <- inference_df %>% filter(catch_trial==0, respPeriod==1)
noise1_catch <- inference_df %>% filter(catch_trial==1, respPeriod==1)
noise1_model <- model_df %>% filter(respPeriod==1)

signal1_test <- inference_df %>% filter(catch_trial==0, respPeriod==2)
signal1_catch <- inference_df %>% filter(catch_trial==1, respPeriod==2)
signal1_model <- model_df %>% filter(respPeriod=='1')

#### effect of noise1 duration on NOISE1 ACCURACY ####
m_test <- glm(accuracy ~ cueIdx * noise1frames_obs, noise1_test, family='binomial')

p1 <- m_test %>%
  emmeans(., ~noise1frames_obs | cueIdx, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cueIdx, fill=cueIdx)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (3 = 50%)')

p2 <- glm(accuracy ~ factor(trueCue) * noise1frames_obs, noise1_test, family='binomial') %>%
  emmeans(., ~noise1frames_obs | trueCue, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=trueCue, fill=trueCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (binary)')

p3 <- glm(accuracy ~ factor(subjectiveCueOrder) * noise1frames_obs, noise1_test, family='binomial') %>%
  emmeans(., ~noise1frames_obs | subjectiveCueOrder, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCueOrder, fill=subjectiveCueOrder)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='subjective cue (ordinal)')

p4 <- glm(accuracy ~ subjectiveCue * noise1frames_obs, noise1_test, family='binomial') %>%
  emmeans(., ~noise1frames_obs | subjectiveCue, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs),
                                                                         subjectiveCue=unique(noise1_test$subjectiveCue))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCue, group=subjectiveCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  scale_color_gradient(low = "lightblue", high = "darkblue", na.value = NA) + 
  labs(y='p(correct)', title='subjective cue (continuous)')

# model predictions
p5 <- glm(rawChoice ~ cue * noise1Frames_obs, noise1_model, family='binomial') %>%
  emmeans(., ~noise1Frames_obs | cue, type='response', at=list(noise1Frames_obs=unique(noise1_model$noise1Frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1Frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: all durations')

p6 <- glm(rawChoice ~ cue * noise1Frames_obs, noise1_model, family='binomial') %>%
  emmeans(., ~noise1Frames_obs | cue, type='response', at=list(noise1Frames_obs=unique(noise1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1Frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: behavior-matched durations')


((p1 / p2) | (p3 / p4) | (p5 / p6)) + plot_annotation(tag_levels = 'A')
ggsave(paste0(outdir, 'noise1Accuracy_test.png'), width=12, height=5)


#### effect of noise1 duration on SIGNAL1 ACCURACY ####
p1 <- glm(accuracy ~ cueIdx * noise1frames_obs, signal1_test, family='binomial') %>%
  emmeans(., ~noise1frames_obs | cueIdx, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cueIdx, fill=cueIdx)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (3 = 50%)')

p2 <- glm(accuracy ~ trueCue * noise1frames_obs, signal1_test, family='binomial') %>%
  emmeans(., ~noise1frames_obs | trueCue, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=trueCue, fill=trueCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (binary)')

p3 <- glm(accuracy ~ subjectiveCueOrder * noise1frames_obs, signal1_test, family='binomial') %>%
  emmeans(., ~noise1frames_obs | subjectiveCueOrder, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCueOrder, fill=subjectiveCueOrder)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='subjective cue (ordinal)')

p4 <- glm(accuracy ~ subjectiveCue * noise1frames_obs, signal1_test, family='binomial') %>%
  emmeans(., ~noise1frames_obs | subjectiveCue, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs),
                                                                         subjectiveCue=unique(noise1_test$subjectiveCue))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCue, group=subjectiveCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  scale_color_gradient(low = "lightblue", high = "darkblue", na.value = NA) + 
  labs(y='p(correct)', title='subjective cue (continuous)')

# model predictions
p5 <- glm(rawChoice ~ cue * noise1Frames, signal1_model, family='binomial') %>%
  emmeans(., ~noise1Frames | cue, type='response', at=list(noise1Frames=unique(signal1_model$noise1Frames))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1Frames, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: all durations')

p6 <- glm(rawChoice ~ cue * noise1Frames, signal1_model, family='binomial') %>%
  emmeans(., ~noise1Frames | cue, type='response', at=list(noise1Frames=unique(signal1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1Frames, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: behavior-matched durations')

((p1 / p2) | (p3 / p4) | (p5 / p6)) + plot_annotation(tag_levels = 'A')
ggsave(paste0(outdir, 'signal1Accuracy_noise1Frames.png'), width=12, height=5)




#### same plots but with RT on on the X axis ####
p7 <- glm(accuracy ~ cueIdx * respFrame, signal1_test, family='binomial') %>%
  emmeans(., ~respFrame | cueIdx, type='response', at=list(respFrame=unique(signal1_test$respFrame))) %>%
  as.data.frame() %>%
  ggplot(aes(x=respFrame, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cueIdx, fill=cueIdx)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (3 = 50%)')

p8 <- glm(accuracy ~ trueCue * respFrame, signal1_test, family='binomial') %>%
  emmeans(., ~respFrame | trueCue, type='response', at=list(respFrame=unique(signal1_test$respFrame))) %>%
  as.data.frame() %>%
  ggplot(aes(x=respFrame, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=trueCue, fill=trueCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (binary)')

p9 <- glm(accuracy ~ subjectiveCueOrder * respFrame, signal1_test, family='binomial') %>%
  emmeans(., ~respFrame | subjectiveCueOrder, type='response', at=list(respFrame=unique(signal1_test$respFrame))) %>%
  as.data.frame() %>%
  ggplot(aes(x=respFrame, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCueOrder, fill=subjectiveCueOrder)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='subjective cue (ordinal)')

p10 <- glm(accuracy ~ subjectiveCue * respFrame, signal1_test, family='binomial') %>%
  emmeans(., ~respFrame | subjectiveCue, type='response', at=list(respFrame=unique(signal1_test$respFrame),
                                                                         subjectiveCue=unique(signal1_test$subjectiveCue))) %>%
  as.data.frame() %>%
  ggplot(aes(x=respFrame, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCue, group=subjectiveCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  scale_color_gradient(low = "lightblue", high = "darkblue", na.value = NA) + 
  labs(y='p(correct)', title='subjective cue (continuous)')

p11 <- glm(rawChoice ~ cue * RT, signal1_model, family='binomial') %>%
  emmeans(., ~RT | cue, type='response', at=list(RT=unique(signal1_model$RT))) %>%
  as.data.frame() %>%
  ggplot(aes(x=RT, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: all RTs')

p12 <- glm(rawChoice ~ cue * RT, signal1_model, family='binomial') %>%
  emmeans(., ~RT | cue, type='response', at=list(RT=unique(signal1_test$respFrame))) %>%
  as.data.frame() %>%
  ggplot(aes(x=RT, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: behavior-matched durations')

((p7 / p8) | (p9 / p10) | (p11 / p12)) 
ggsave(paste0(outdir, 'signal1Accuracy_respFrame.png'), width=12, height=5)


#### SIGNAL1 ACCURACY by EVIDENCE-LOCKED RESPFRAME ####
rm(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12)

# lock response frames to onset of visual evidence
p1 <- glm(accuracy ~ cueIdx * zlogRT_sig1locked, signal1_test, family='binomial') %>%
  emmeans(., ~zlogRT_sig1locked | cueIdx, type='response', at=list(zlogRT_sig1locked=unique(signal1_test$zlogRT_sig1locked))) %>%
  as.data.frame() %>%
  ggplot(aes(x=zlogRT_sig1locked, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cueIdx, fill=cueIdx)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (3 = 50%)')

p2 <- glm(accuracy ~ trueCue * zlogRT_sig1locked, signal1_test, family='binomial') %>%
  emmeans(., ~zlogRT_sig1locked | trueCue, type='response', at=list(zlogRT_sig1locked=unique(signal1_test$zlogRT_sig1locked))) %>%
  as.data.frame() %>%
  ggplot(aes(x=zlogRT_sig1locked, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=trueCue, fill=trueCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (binary)')

p3 <- glm(accuracy ~ subjectiveCueOrder * zlogRT_sig1locked, signal1_test, family='binomial') %>%
  emmeans(., ~zlogRT_sig1locked | subjectiveCueOrder, type='response', at=list(zlogRT_sig1locked=unique(signal1_test$zlogRT_sig1locked))) %>%
  as.data.frame() %>%
  ggplot(aes(x=zlogRT_sig1locked, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCueOrder, fill=subjectiveCueOrder)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (binary)')

p4 <- glm(accuracy ~ subjectiveCue * zlogRT_sig1locked, signal1_test, family='binomial') %>%
  emmeans(., ~zlogRT_sig1locked | subjectiveCue, type='response', at=list(zlogRT_sig1locked=quantile(signal1_test$zlogRT_sig1locked, na.rm=T),
                                                                         subjectiveCue=quantile(signal1_test$subjectiveCue, na.rm=T))) %>%
  as.data.frame() %>%
  ggplot(aes(x=zlogRT_sig1locked, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCue, group=subjectiveCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  scale_color_gradient(low = "lightblue", high = "darkblue", na.value = NA) + 
  labs(y='p(correct)', title='subjective cue (continuous)')


p5 <- glm(rawChoice ~ cue * zlogRT_sig1locked, signal1_model, family='binomial') %>%
  emmeans(., ~zlogRT_sig1locked | cue, type='response', at=list(zlogRT_sig1locked=unique(signal1_model$zlogRT_sig1locked))) %>%
  as.data.frame() %>%
  ggplot(aes(x=zlogRT_sig1locked, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: all durations')

p6 <- glm(rawChoice ~ cue * zlogRT_sig1locked, signal1_model, family='binomial') %>%
  emmeans(., ~vizLockedRT | cue, type='response', at=list(vizLockedRT=unique(signal1_test$vizLockedRT))) %>%
  as.data.frame() %>%
  ggplot(aes(x=vizLockedRT, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: behavior-matched durations')

((p1 / p2) | (p3 / p4) | (p5 / p6)) + plot_annotation(tag_levels = 'A')
ggsave(paste0(outdir, 'signal1Accuracy_imgLockedRT.png'), width=12, height=5)


#### signal1 frames effect ####
p1 <- glm(accuracy ~ cueIdx * signal1frames_obs, signal1_test, family='binomial') %>%
  emmeans(., ~signal1frames_obs | cueIdx, type='response', at=list(signal1frames_obs=unique(signal1_test$signal1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=signal1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cueIdx, fill=cueIdx)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (3 = 50%)')

p2 <- glm(accuracy ~ trueCue * signal1frames_obs, signal1_test, family='binomial') %>%
  emmeans(., ~signal1frames_obs | trueCue, type='response', at=list(signal1frames_obs=unique(signal1_test$signal1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=signal1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=trueCue, fill=trueCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (binary)')

p3 <- glm(accuracy ~ subjectiveCueOrder * signal1frames_obs, signal1_test, family='binomial') %>%
  emmeans(., ~signal1frames_obs | subjectiveCueOrder, type='response', at=list(signal1frames_obs=unique(signal1_test$signal1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=signal1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCueOrder, fill=subjectiveCueOrder)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (binary)')

p4 <- glm(accuracy ~ subjectiveCue * signal1frames_obs, signal1_test, family='binomial') %>%
  emmeans(., ~signal1frames_obs | subjectiveCue, type='response', at=list(signal1frames_obs=unique(signal1_test$signal1frames_obs),
                                                                    subjectiveCue=unique(signal1_test$subjectiveCue))) %>%
  as.data.frame() %>%
  ggplot(aes(x=signal1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCue, group=subjectiveCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  scale_color_gradient(low = "lightblue", high = "darkblue", na.value = NA) + 
  labs(y='p(correct)', title='subjective cue (continuous)')


p5 <- glm(rawChoice ~ cue * signal1frames_obs, signal1_model, family='binomial') %>%
  emmeans(., ~signal1frames_obs | cue, type='response', at=list(signal1frames_obs=unique(signal1_model$signal1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=signal1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: all durations')

p6 <- glm(rawChoice ~ cue * signal1frames_obs, signal1_model, family='binomial') %>%
  emmeans(., ~signal1frames_obs | cue, type='response', at=list(signal1frames_obs=unique(signal1_test$signal1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=signal1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: behavior-matched durations')

((p1 / p2) | (p3 / p4) | (p5 / p6)) + plot_annotation(tag_levels = 'A')
ggsave(paste0(outdir, 'signal1Accuracy_imgLockedRT.png'), width=12, height=5)

#### effect of noise1 duration on signal1 accuracy -- CATCH TRIALS ####
p1 <- glm(accuracy ~ cueIdx * noise1frames_obs, signal1_catch, family='binomial') %>%
  emmeans(., ~noise1frames_obs | cueIdx, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cueIdx, fill=cueIdx)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (3 = 50%)')

p2 <- glm(accuracy ~ trueCue * noise1frames_obs, signal1_catch, family='binomial') %>%
  emmeans(., ~noise1frames_obs | trueCue, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=trueCue, fill=trueCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='objective cue (binary)')

p3 <- glm(accuracy ~ subjectiveCueOrder * noise1frames_obs, signal1_catch, family='binomial') %>%
  emmeans(., ~noise1frames_obs | subjectiveCueOrder, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCueOrder, fill=subjectiveCueOrder)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='subjective cue (ordinal)')

p4 <- glm(accuracy ~ subjectiveCue * noise1frames_obs, signal1_catch, family='binomial') %>%
  emmeans(., ~noise1frames_obs | subjectiveCue, type='response', at=list(noise1frames_obs=unique(noise1_test$noise1frames_obs),
                                                                         subjectiveCue=unique(noise1_test$subjectiveCue))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=subjectiveCue, group=subjectiveCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  scale_color_gradient(low = "lightblue", high = "darkblue", na.value = NA) + 
  labs(y='p(correct)', title='subjective cue (continuous)')

# model predictions
p5 <- glm(rawChoice ~ cue * noise1Frames, signal1_model, family='binomial') %>%
  emmeans(., ~noise1Frames | cue, type='response', at=list(noise1Frames=unique(signal1_model$noise1Frames))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1Frames, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: all durations')

p6 <- glm(rawChoice ~ cue * noise1Frames, signal1_model, family='binomial') %>%
  emmeans(., ~noise1Frames | cue, type='response', at=list(noise1Frames=unique(signal1_test$noise1frames_obs))) %>%
  as.data.frame() %>%
  ggplot(aes(x=noise1Frames, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cue, fill=cue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(y='p(correct)', title='model: behavior-matched durations')

((p1 / p2) | (p3 / p4)) + plot_annotation(tag_levels = 'A')
ggsave(paste0(outdir, 'signal1Accuracy_noise1Frames_catchTrials.png'), width=8, height=5)


