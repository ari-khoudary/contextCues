outdir <- '../figures/'
inference_df <- read.csv('../tidied_data/inference.csv')
model_df <- read.csv('../tidied_data/model.csv')

noise2_test <- inference_df %>%
  filter(respLabel == c('noise2'), catch_trial==0) %>% 
  mutate(congCue = case_when(trueCongruence=='congruent' ~ trueCue/100,
                             trueCongruence=='incongruent' ~ (100-trueCue)/100,
                             trueCongruence=='neutral' ~ 0.5),
         vizLockedRT = respFrame - signal2Onset_design,
         cueCongChoice = case_when(cueIdx<3 & cueIdx==response ~ 1,
                                   cueIdx<3 & cueIdx != response ~ 0,
                                   cueIdx==3 ~ NA)) 

## first just effects of cue * noise2
mb <- glm(accuracy ~ noise2frames_obs * congCue + zlogRT, noise2_test, family='binomial')

mb %>%
  emmeans(., ~ noise2frames_obs | congCue, type='response', 
          at=list(noise2frames_obs=quantile(noise2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.1)),
                  congCue = unique(noise2_test$congCue))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=congCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(title = 'behavior')


## now add interaction with signal1 evidence
mb <- glm(accuracy ~ noise2frames_obs * congCue * targetEv_signal1 + zlogRT, noise2_test, family='binomial')

p1 <- mb %>%
  emmeans(., ~ noise2frames_obs * targetEv_signal1 | congCue, type='response', 
          at=list(noise2frames_obs=quantile(noise2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.1)),
                  targetEv_signal1 = quantile(noise2_test$targetEv_signal1, na.rm=T, probs=seq(0.05,1,0.5)),
                  congCue = unique(noise2_test$congCue))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=targetEv_signal1, fill=targetEv_signal1)) +
  theme_bw() +
  geom_pointrange() +
  geom_line(aes(group=targetEv_signal1)) +
  facet_wrap(~ congCue) +
  geom_hline(yintercept = 0.5) +
  labs(title = 'behavior: noise2 responses')

p2 <- mb %>% 
  emtrends(.,  ~ congCue | targetEv_signal1, var = "noise2frames_obs", 
           at=list(noise2frames_obs=quantile(noise2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.1)),
                   targetEv_signal1 = quantile(noise2_test$targetEv_signal1, na.rm=T, probs=seq(0.05,1,0.5)),
                   congCue = unique(noise2_test$congCue))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=targetEv_signal1, y=noise2frames_obs.trend, color = congCue, 
             ymin=asymp.LCL, ymax=asymp.UCL)) +
  theme_bw() +
  geom_hline(yintercept = 0, linetype='dashed') +
  geom_pointrange(position=position_dodge(width=1)) +
  #geom_line() +
  labs(y = 'slope of noise2 effect')

p1 + p2 + plot_layout(widths=c(2,1))

#### cuecong choice ####
# just cue first
mb <- glm(cueCongChoice ~ noise2frames_obs * congCue + zlogRT, noise2_test, family='binomial')

p1 <- mb %>%
  emmeans(., ~ noise2frames_obs | congCue, type='response', 
          at=list(noise2frames_obs=quantile(noise2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.1)),
                  congCue = c(0.2, 0.8))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=congCue, fill=congCue)) +
  theme_bw() +
  geom_pointrange() +
  geom_line() +
  geom_hline(yintercept = 0.5) +
  labs(title = 'p(chooseCue) during noise2')

p2 <- mb %>% 
  emtrends(.,  ~ congCue, var = "noise2frames_obs", 
           at=list(noise2frames_obs=quantile(noise2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.1)),
                   congCue = c(0.2, 0.8))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=congCue, y=noise2frames_obs.trend, color = congCue, 
             ymin=asymp.LCL, ymax=asymp.UCL)) +
  theme_bw() +
  geom_hline(yintercept = 0, linetype='dashed') +
  geom_pointrange(position=position_dodge(width=1)) +
  labs(y = 'slope of noise2 effect')

p1 + p2 + plot_layout(widths=c(2,1))


# then cue & targetEv_signal1 interaction
mb <- glm(cueCongChoice ~ noise2frames_obs * congCue * targetEv_signal1 + zlogRT, noise2_test, family='binomial')

p1 <- mb %>%
  emmeans(., ~ noise2frames_obs * targetEv_signal1 | congCue, type='response', 
          at=list(noise2frames_obs=quantile(noise2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.1)),
                  targetEv_signal1 = quantile(noise2_test$targetEv_signal1, na.rm=T, probs=seq(0.05,1,0.5)),
                  congCue = c(0.2, 0.8))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=noise2frames_obs, y=prob, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=targetEv_signal1, fill=targetEv_signal1)) +
  theme_bw() +
  geom_pointrange() +
  geom_line(aes(group=targetEv_signal1)) +
  facet_wrap(~ congCue) +
  geom_hline(yintercept = 0.5) +
  labs(title = 'p(chooseCue) during noise2')

p2 <- mb %>% 
  emtrends(.,  ~ congCue | targetEv_signal1, var = "noise2frames_obs", 
           at=list(noise2frames_obs=quantile(noise2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.1)),
                   targetEv_signal1 = quantile(noise2_test$targetEv_signal1, na.rm=T, probs=seq(0.05,1,0.5)),
                   congCue = c(0.2, 0.8))) %>% 
  as.data.frame() %>%
  mutate(congCue = factor(congCue)) %>%
  ggplot(aes(x=targetEv_signal1, y=noise2frames_obs.trend, color = congCue, 
             ymin=asymp.LCL, ymax=asymp.UCL)) +
  theme_bw() +
  geom_hline(yintercept = 0, linetype='dashed') +
  geom_pointrange(position=position_dodge(width=1)) +
  #geom_line() +
  labs(y = 'slope of noise2 effect')

p1 + p2 + plot_layout(widths=c(2,1))

#### sanity check
noise2_q <- quantile(noise2_test$noise2frames_obs, na.rm=T, probs=seq(0,1,0.1), names=F)
signal1_q <- quantile(noise2_test$targetEv_signal1, na.rm=T, probs=seq(0.05,1,0.5), names=F)

noise2_test %>%
  mutate(noise2_bin = findInterval(noise2frames_obs, quantile(noise2frames_obs,probs=seq(0,1,0.25))),
         signal1_bin = findInterval(targetEv_signal1, quantile(targetEv_signal1, probs=seq(0.0,1,0.25)))) %>%
  group_by(signal1_bin, noise2_bin, congCue, subID) %>%
  filter(congCue != 0.5) %>%
  summarise(pChooseCue = mean(cueCongChoice)) %>%
  mutate(congCue=factor(congCue)) %>%
  ggplot(aes(x=noise2_bin, y=pChooseCue, color=congCue)) +
  theme_bw() +
  stat_summary(fun.data = 'mean_se') +
  facet_wrap(~ signal1_bin)
  
  

