library(tidyverse)
library(lmerTest)
library(lme4)
library(patchwork)
library(emmeans)
library(performance)

#### setup ####
outdir <- '../figures/'

# load in inference data
inference_df <- read.csv('../tidied_data/inference.csv') %>% 
  mutate(noise1Resp = ifelse(respPeriod==1, 1, 0),
         cueConf_factor = factor(cueConfidence),
         subjectiveCue = subjectiveCue/100,
         trueCue = trueCue/100,
         trueCongruence = factor(trueCongruence, levels=c('incongruent', 'neutral', 'congruent'))) %>%
  filter(subID != c(33), catch_trial==0, zlogRT > -10) %>%
  group_by(subID) %>%
  mutate(cueCorr_spearman = cor(subjectiveCue, trueCue),
         cueDiff = subjectiveCue - trueCue,
         cueCorr_spearman_spearman = cor(subjectiveCue, trueCue, method = 'spearman'))

#### swap out subjectiveCue for cueConf, look at RTs for all trials ####
m1 <- lm(zlogRT ~ cueCorr_spearman_spearman * subjectiveCue * trueCongruence, inference_df)
m2 <- lm(zlogRT ~ cueCorr_spearman_spearman * cueConfidence * trueCongruence, inference_df)
m3 <- lm(zlogRT ~ cueCorr_spearman_spearman * subjectiveCue * congCue, inference_df)
m4 <- lm(zlogRT ~ cueCorr_spearman_spearman * cueConfidence * congCue, inference_df)

compare_performance(m1, m2, m3, m4)

p1 <- emmip(m1, cueCorr_spearman ~ subjectiveCue | trueCongruence, CIs=T, plotit=T, dodge=0,
            at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                      subjectiveCue = round(quantile(inference_df$subjectiveCue, probs = seq(0,1,0.3), na.rm = T),2)))

p2 <- emmip(m2, cueCorr_spearman ~ cueConfidence | trueCongruence, CIs=T, plotit=T, dodge=0,
            at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                      subjectiveCue = round(quantile(inference_df$subjectiveCue, probs = seq(0,1,0.3), na.rm = T),2),
                      cueConfidence = c(1,2,3,4))) 

p3 <- emmip(m3, cueCorr_spearman ~ subjectiveCue | congCue, CIs=T, plotit=T, dodge=0,
            at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                      subjectiveCue = round(quantile(inference_df$subjectiveCue, probs = seq(0,1,0.3), na.rm = T),2),
                      congCue = c(0.2, 0.5, 0.8)))

p4 <- emmip(m4, cueCorr_spearman ~ cueConfidence | congCue, CIs=T, plotit=T, dodge=0,
            at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                      cueConfidence = c(1,2,3,4),
                      congCue = c(0.2, 0.5, 0.8)))

p1 <- p1 + labs(y='zlogRT', title = 'cueCorr_spearman * subjectiveCue * trueCongruence') 
p2 <- p2 + labs(y='zlogRT', title = 'cueCorr_spearman * cueConfidence * trueCongruence')
p3 <- p3 + labs(y='zlogRT', title = 'cueCorr_spearman * subjectiveCue * congCue')  
p4 <- p4 + labs(y='zlogRT', title = 'cueCorr_spearman * cueConfidence * congCue') 

(p1 | p3) / (p2 | p4) + plot_layout(guides = 'collect') & theme_bw()
ggsave(paste0(outdir, 'predictorComparisons_rt_ccSpearman.png'), height=5, width=10)

m3 <- lm(zlogRT ~ cueCorr_spearman * subjectiveCue * congCue, inference_df)
m5 <- lm(zlogRT ~ cueCorr_spearman * subjectiveCue * congCue + scale(cueConfidence), inference_df)
m6 <- lm(zlogRT ~ cueCorr_spearman * subjectiveCue * congCue * scale(cueConfidence), inference_df)
m7 <- lm(zlogRT ~ cueCorr_spearman * congCue * scale(cueConfidence), inference_df)
m8 <- lm(zlogRT ~ cueCorr_spearman * congCue * scale(cueConfidence) + subjectiveCue, inference_df)

p1 <- emmip(m6, cueCorr_spearman ~ subjectiveCue | cueConfidence*congCue, CIs=T, plotit=T, dodge=0, facetlab='label_both',
            at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                      subjectiveCue = round(quantile(inference_df$subjectiveCue, probs = seq(0,1,0.3), na.rm = T),2),
                      cueConfidence = c(1,2,3,4),
                      congCue = c(0.2, 0.5, 0.8))) + theme_bw() + ylab('zlogRT') + ggtitle('m6: interaction')

p2 <- emmip(m5, cueCorr_spearman ~ subjectiveCue | cueConfidence*congCue, CIs=T, plotit=T, dodge=0, facetlab='label_both',
            at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                      subjectiveCue = round(quantile(inference_df$subjectiveCue, probs = seq(0,1,0.3), na.rm = T),2),
                      cueConfidence = c(1,2,3,4),
                      congCue = c(0.2, 0.5, 0.8))) + theme_bw() + ylab('zlogRT') + ggtitle('m5: additive')

p1 + p2 + plot_layout(guides = 'collect')
ggsave(paste0(outdir, 'predictorComparisons_cueConf_rt.png'), width=10, height=5.5)

#### same comparisons for accuracy ####
m1 <- glm(accuracy ~ cueCorr_spearman * subjectiveCue * trueCongruence, family = 'binomial', inference_df)
m2 <- glm(accuracy ~ cueCorr_spearman * cueConfidence * trueCongruence, family = 'binomial', inference_df)
m3 <- glm(accuracy ~ cueCorr_spearman * subjectiveCue * congCue, family = 'binomial', inference_df)
m4 <- glm(accuracy ~ cueCorr_spearman * cueConfidence * congCue, family = 'binomial', inference_df)

compare_performance(m1, m2, m3, m4)

p1 <- emmip(m1, cueCorr_spearman ~ subjectiveCue | trueCongruence, CIs=T, plotit=T, dodge=0, type='response',
            at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                      subjectiveCue = round(quantile(inference_df$subjectiveCue, probs = seq(0,1,0.3), na.rm = T),2)))

p2 <- emmip(m2, cueCorr_spearman ~ cueConfidence | trueCongruence, CIs=T, plotit=T, dodge=0, type='response',
            at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                      subjectiveCue = round(quantile(inference_df$subjectiveCue, probs = seq(0,1,0.3), na.rm = T),2),
                      cueConfidence = c(1,2,3,4))) 

p3 <- emmip(m3, cueCorr_spearman ~ subjectiveCue | congCue, CIs=T, plotit=T, dodge=0, type='response',
            at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                      subjectiveCue = round(quantile(inference_df$subjectiveCue, probs = seq(0,1,0.3), na.rm = T),2),
                      congCue = c(0.2, 0.5, 0.8)))

p4 <- emmip(m4, cueCorr_spearman ~ cueConfidence | congCue, CIs=T, plotit=T, dodge=0, type='response',
            at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                      cueConfidence = c(1,2,3,4),
                      congCue = c(0.2, 0.5, 0.8)))

p1 <- p1 + labs(y='p(correct)', title = 'cueCorr_spearman * subjectiveCue * trueCongruence') 
p2 <- p2 + labs(y='p(correct)', title = 'cueCorr_spearman * cueConfidence * trueCongruence')
p3 <- p3 + labs(y='p(correct)', title = 'cueCorr_spearman * subjectiveCue * congCue')  
p4 <- p4 + labs(y='p(correct)', title = 'cueCorr_spearman * cueConfidence * congCue') 

(p1 | p3) / (p2 | p4) + plot_layout(guides = 'collect') & theme_bw()
ggsave(paste0(outdir, 'predictorComparisons_accuracy_ccSpearman.png'), height=5, width=10)


#### speed - accuracy predicted by cueCorr_spearman * subjectiveCue * congCue ####
rt <- lm(zlogRT ~ cueCorr_spearman * subjectiveCue * congCue, inference_df)
acc <- glm(accuracy ~ cueCorr_spearman * subjectiveCue * congCue, family='binomial', inference_df)

inference_df <- inference_df %>%
  mutate(sc_quartile = ntile(subjectiveCue, 4),
         cc_quartile = ntile(cueCorr_spearman, 4))


rt_df <- emmip(rt, cueCorr_spearman ~ subjectiveCue | congCue, CIs=T, plotit=F, dodge=0,
               at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                         subjectiveCue = round(quantile(inference_df$subjectiveCue, probs = seq(0,1,0.3), na.rm = T),2),
                         congCue = c(0.2, 0.5, 0.8)))

acc_df <- emmip(acc, cueCorr_spearman ~ subjectiveCue | congCue, CIs=T, plotit=F, dodge=0, type='response',
                at = list(cueCorr_spearman = round(quantile(inference_df$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),2),
                          subjectiveCue = round(quantile(inference_df$subjectiveCue, probs = seq(0,1,0.3), na.rm = T),2),
                          congCue = c(0.2, 0.5, 0.8)))

# plot RT
p1 <- ggplot(inference_df, aes(subjectiveCue, zlogRT, color=cueCorr_spearman)) +
  theme_bw() +
  geom_hline(yintercept = 0, linewidth=0.25, color='gray40') +
  facet_wrap(~ congCue, labeller = labeller(.cols = function(x) paste0("trueCue = ", x))) +
  geom_point(size=0.1, position=position_jitter(width=0.02, height=0), alpha=0.5) +
  scale_color_gradient2() +
  geom_line(aes(xvar, yvar, color=cueCorr_spearman, group=cueCorr_spearman), rt_df) +
  geom_pointrange(aes(xvar, yvar, ymin=LCL, ymax=UCL, color=cueCorr_spearman), rt_df) +
  ylim(-2.5, 2.5) +
  scale_x_continuous(n.breaks = 6)
ggsave(paste0(outdir, 'rt_regression_all.png'), width=5, height=2)

# plot accuracy
p2 <- inference_df %>%
  ggplot(aes(subjectiveCue, accuracy, color=cueCorr_spearman)) +
  theme_bw() +
  geom_hline(yintercept = 0.5, linewidth=0.25, color='gray40') +
  geom_hline(yintercept = 0.7, linewidth=0.25, linetype='dashed', color='gray40') +
  facet_wrap(~ congCue, labeller = labeller(.cols = function(x) paste0("trueCue = ", x))) +
  geom_point(size=0.25, position=position_jitter(width=0.01, height=0.05), alpha=0.5) +
  scale_color_gradient2() +
  geom_pointrange(aes(xvar, yvar, ymin=LCL, ymax=UCL, color=cueCorr_spearman), acc_df) +
  geom_line(aes(xvar, yvar, color=cueCorr_spearman, group=cueCorr_spearman), acc_df) +
  scale_y_continuous(n.breaks=7)
ggsave(paste0(outdir, 'accuracy_regression_all.png'), width=5, height=4)

p1 + p2 + plot_layout(guides = 'collect')
ggsave(paste0(outdir, 'rt-accuracy.png'), width=12, height=3, dpi='retina')

#### test noise2 addition to existing model - same results as before! ####
rt <- lm(zlogRT ~ cueCorr_spearman * subjectiveCue * congCue, inference_df)
rt_add <- lm(zlogRT ~ cueCorr_spearman * subjectiveCue * congCue + noise2frames_obs, inference_df)
rt_int <- lm(zlogRT ~ cueCorr_spearman * subjectiveCue * congCue * noise2frames_obs, inference_df)
compare_performance(rt, rt_add, rt_int)

acc <- glm(accuracy ~ cueCorr_spearman * subjectiveCue * congCue, family='binomial', inference_df)
acc_add <- glm(accuracy ~ cueCorr_spearman * subjectiveCue * congCue + noise2frames_obs, family='binomial', inference_df)
acc_int <- glm(accuracy ~ cueCorr_spearman * subjectiveCue * congCue * noise2frames_obs, family='binomial', inference_df)
compare_performance(acc, acc_add, acc_int)

# plot RTs
emmip(rt_int, cueCorr_spearman ~ noise2frames_obs | congCue * subjectiveCue, CIs=T, plotit=T, dodge=0, facetlab='label_both',
      at=list(congCue = c(0.2, 0.5, 0.8),
              cueCorr_spearman = round(quantile(inference_post1$cueCorr_spearman, probs=seq(0,1,0.3)),2),
              noise2frames_obs = quantile(inference_df$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T),
              subjectiveCue = c(0.5, 0.65, 0.8, 0.9))) +
  labs(title = 'additive model', subtitle='columns=cueConfidence', y='linear prediction (zlogRT)') +
  geom_hline(yintercept=0, color='gray')

# plot accuracy
emmip(acc_int, cueCorr_spearman ~ noise2frames_obs | congCue * subjectiveCue, CIs=T, plotit=T, dodge=0, facetlab='label_both',type='response',
      at=list(congCue = c(0.2, 0.5, 0.8),
              cueCorr_spearman = round(quantile(inference_post1$cueCorr_spearman, probs=seq(0,1,0.3)),2),
              noise2frames_obs = quantile(inference_df$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T),
              subjectiveCue = c(0.5, 0.65, 0.8, 0.9))) +
  geom_hline(yintercept=0, color='gray') + theme_bw()


inference_df <- inference_df %>% mutate(chooseMem = ifelse(response==imgIdx_subjective, 1, 0))

m <- glm(chooseMem ~ cueCorr_spearman * subjectiveCue * congCue * noise2frames_obs,family='binomial', inference_df)

emmip(m, cueCorr_spearman ~ noise2frames_obs | congCue * subjectiveCue, CIs=T, plotit=T, dodge=0, facetlab='label_both',type='response',
      at=list(congCue = c(0.2, 0.5, 0.8),
              cueCorr_spearman = round(quantile(inference_post1$cueCorr_spearman, probs=seq(0,1,0.3)),2),
              noise2frames_obs = quantile(inference_df$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T),
              subjectiveCue = c(0.5, 0.65, 0.8, 0.9))) +
  geom_hline(yintercept=0, color='gray') + theme_bw() + labs(y='p(chooseMem)') 

#### accuracy for resps after first noise ####
inference_post1 <- inference_post1 %>% mutate(trueCongruence=factor(trueCongruence, levels=c('neutral', 'congruent', 'incongruent')))

m1 <- glm(accuracy ~ trueCue, inference_post1, family='binomial')
m2 <- glm(accuracy ~ subjectiveCue, inference_post1, family = 'binomial')
m3 <- glm(accuracy ~ cueCorr_spearman, inference_post1, family='binomial')
m4 <- glm(accuracy ~ cueConfidence, inference_post1, family='binomial')
m5 <- glm(accuracy ~ trueCue * trueCongruence, inference_post1, family='binomial')
m6 <- glm(accuracy ~ subjectiveCue * trueCongruence, inference_post1, family = 'binomial')
m7 <- glm(accuracy ~ cueConfidence * trueCongruence, inference_post1, family = 'binomial')
m8 <- glm(accuracy ~ trueCue * cueConfidence * trueCongruence, inference_post1, family = 'binomial')
m9 <- glm(accuracy ~  cueCorr_spearman * cueConfidence * trueCongruence, inference_post1, family = 'binomial')

compare_performance(m1, m2, m3, m4, m5, m6, m7, m8, m9)


mp_df <- m9 %>% emmip(., cueCorr_spearman ~ cueConfidence | trueCongruence, CIs=T, type='response', plotit=F,
                      at = list(cueCorr_spearman = quantile(inference_post1$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),
                                cueConfidence = unique(inference_post1$cueConfidence)))

m9 %>% emmip(., cueCorr_spearman ~ cueConfidence | trueCongruence, CIs=T, type='response',
             at = list(cueCorr_spearman = quantile(inference_post1$cueCorr_spearman, probs = seq(0,1,0.3), na.rm = T),
                       cueConfidence = unique(inference_post1$cueConfidence)))

post1Acc_emm <- mp_df %>%
  mutate(tvar = as.numeric(levels(tvar))[tvar]) %>%
  ggplot(aes(cueConfidence, yvar, ymin=LCL, ymax=UCL, color=tvar)) +
  theme_bw() +
  geom_hline(yintercept = 0.5, color='gray') +
  facet_wrap(~ trueCongruence) +
  geom_pointrange() +
  geom_line(aes(group=tvar)) +
  scale_color_gradient2() +
  labs(y='estimated p(correct)', x='cueConfidence', color='cueCorr_spearman', 
       title = 'Accuracy after visual evidence onset', subtitle='model estimates')

post1Acc_raw <- inference_post1 %>%
  group_by(subID, trueCongruence, cueConfidence, cueCorr_spearman) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T)) %>%
  ggplot(aes(cueConfidence, propCorrect, color=cueCorr_spearman)) +
  theme_bw() +
  geom_hline(yintercept = 0.5, color='gray') +
  facet_wrap(~ trueCongruence) +
  geom_point(position=position_jitter(width=0.25, height=0), size=2.5) +
  stat_summary(fun='mean', geom='line', linewidth=1.5, color='gray50') +
  scale_color_gradient2() + theme(legend.position = 'none') +
  labs(y='propCorrect', x='cueConfidence', color='cueCorr_spearman', 
       title = 'Accuracy after visual evidence onset', subtitle='summary stats on raw data')

post1Acc_raw + post1Acc_emm + plot_layout(guides='collect')

ggsave(paste0(outdir, 'accuracy_post1.png'), width=12, height=4)

#### noise2 interactions - RT ####

m1 <- lm(zlogRT ~ cueCorr_spearman * cueConfidence * trueCongruence, inference_post1)
m2 <-lm(zlogRT ~ cueCorr_spearman * cueConfidence * trueCongruence + noise2frames_obs, inference_post1)
m3 <- lm(zlogRT ~ cueCorr_spearman * cueConfidence * trueCongruence * noise2frames_obs, inference_post1)
m4 <- lm(zlogRT ~ cueCorr_spearman * trueCongruence * noise2frames_obs, inference_post1)
m5 <- lm(zlogRT ~ cueCorr_spearman * trueCue * trueCongruence * noise2frames_obs, inference_post1)
m6 <- lm(zlogRT ~ cueCorr_spearman * cueDiff * trueCongruence * noise2frames_obs, inference_post1)

compare_performance(m1, m2, m3, m4, m5, m6) ## MODEL 3 WINS!


### plotting interaction result
m3_df <- emmip(m3, cueCorr_spearman ~ noise2frames_obs | cueConfidence*trueCongruence, CIs=T, plotit=F,
               at=list(cueConfidence = unique(inference_post1$cueConfidence),
                       cueCorr_spearman = quantile(inference_post1$cueCorr_spearman, probs=seq(0,1,0.3),na.rm=T),
                       noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) 

m3_df %>%
  filter(is.na(cueConfidence)==F) %>%
  ggplot(aes(x=noise2frames_obs, y=yvar, color=cueCorr_spearman)) +
  theme_bw() +
  facet_grid(trueCongruence ~ cueConfidence) +
  geom_hline(yintercept = 0) +
  geom_pointrange(aes(ymin=LCL, ymax=UCL)) +
  geom_line(aes(group=interaction(cueCorr_spearman, trueCongruence))) +
  scale_color_gradient2() +
  labs(y='estimated zlogRT', title='zlogRT ~ cueCorr_spearman * cueConf * congruent * noise2frames_obs',
       subtitle = 'columns=cueConfidence, rows=congruent')


### plotting additive result
emmip(m2, cueCorr_spearman ~ noise2frames_obs | trueCongruence*cueConfidence, CIs=T, plotit=T,
      at=list(cueConfidence = seq(1,4,1),
              cueCorr_spearman = quantile(inference_post1$cueCorr_spearman, probs=seq(0,1,0.3)),
              noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) +
  labs(title = 'additive model', subtitle='columns=cueConfidence', y='linear prediction (zlogRT)') +
  geom_hline(yintercept=0, color='gray') +
  
  emmip(m3, cueCorr_spearman ~ noise2frames_obs | trueCongruence*cueConfidence, CIs=T, plotit=T,
        at=list(cueConfidence = seq(1,4,1),
                cueCorr_spearman = quantile(inference_post1$cueCorr_spearman, probs=seq(0,1,0.3),na.rm=T),
                noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) +
  labs(title = 'interaction model', subtitle='columns=cueConfidence', y='linear prediction(zlogRT)') +
  geom_hline(yintercept=0, color='gray') +
  
  plot_layout(guides='collect') & theme_bw()

ggsave(paste0(outdir, 'RTs_noise2models.png'), width=12, height=4)

# plot slopes for interaction model
rtSlopes <- emtrends(m3, ~ cueConfidence*cueCorr_spearman*trueCongruence, var='noise2frames_obs',          
                     at = list(cueCorr_spearman=quantile(inference_post1$cueCorr_spearman, probs=seq(0,0.9,0.4),na.rm=T),
                               cueConfidence=seq(1,4,1))) %>% as.data.frame() 

zero <- mean(rtSlopes$noise2frames_obs.trend)

noise2_rt <- rtSlopes %>%
  ggplot(aes(x=cueConfidence, y=noise2frames_obs.trend, ymin=lower.CL, ymax=upper.CL, 
             color=cueCorr_spearman, fill=cueCorr_spearman, group=cueCorr_spearman)) +
  theme_bw() +
  facet_wrap(~trueCongruence) +
  geom_hline(yintercept = zero, color='gray20') +
  geom_ribbon(alpha=0.05, color=NA) +
  geom_pointrange(position=position_jitter(width=0, height=0)) +
  scale_color_gradient2(aes(group=cueCorr_spearman)) + scale_fill_gradient2() +
  geom_line(aes(group=cueCorr_spearman)) +
  labs(title='slope of noise2 effect: RT', subtitle='solid line=average noise2 effect')


#### looking at signal2 RTs ####
m1 <- lm(zlogRT_sig2locked ~ cueCorr_spearman * cueConfidence * trueCongruence, inference_post1)
m2 <-lm(zlogRT_sig2locked ~ cueCorr_spearman * cueConfidence * trueCongruence + noise2frames_obs, inference_post1)
m3 <- lm(zlogRT_sig2locked ~ cueCorr_spearman * cueConfidence * trueCongruence * noise2frames_obs, inference_post1)
m4 <- lm(zlogRT_sig2locked ~ cueCorr_spearman * trueCongruence * noise2frames_obs, inference_post1)
m5 <- lm(zlogRT_sig2locked ~ cueCorr_spearman * trueCue * trueCongruence * noise2frames_obs, inference_post1)

compare_performance(m1, m2, m3, m4, m5) # when outcome is sig2locked RT, the additive model is better

emmip(m2, cueCorr_spearman ~ noise2frames_obs | cueConfidence*trueCongruence, CIs=T, plotit=T,
      at=list(cueConfidence = unique(inference_post1$cueConfidence),
              cueCorr_spearman = quantile(inference_post1$cueCorr_spearman, probs=seq(0,1,0.3),na.rm=T),
              noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) 

### looking at signal1-locked RT
m1 <- lm(zlogRT_sig1locked ~ cueCorr_spearman * cueConfidence * trueCongruence, inference_post1)
m2 <-lm(zlogRT_sig1locked ~ cueCorr_spearman * cueConfidence * trueCongruence + noise2frames_obs, inference_post1)
m3 <- lm(zlogRT_sig1locked ~ cueCorr_spearman * cueConfidence * trueCongruence * noise2frames_obs, inference_post1)
m4 <- lm(zlogRT_sig1locked ~ cueCorr_spearman * trueCongruence * noise2frames_obs, inference_post1)
m5 <- lm(zlogRT_sig1locked ~ cueCorr_spearman * trueCue * trueCongruence * noise2frames_obs, inference_post1)

compare_performance(m1, m2, m3, m4, m5) # when outcome is sig1locked RT, M3 wins again

emmip(m3, cueCorr_spearman ~ noise2frames_obs | cueConfidence*trueCongruence, CIs=T, plotit=T,
      at=list(cueConfidence = unique(inference_post1$cueConfidence),
              cueCorr_spearman = quantile(inference_post1$cueCorr_spearman, probs=seq(0,1,0.3),na.rm=T),
              noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) 


#### noise2 interactions -- accuracy ####
m1 <- glm(accuracy ~ cueCorr_spearman * cueConfidence * trueCongruence, 'binomial', inference_post1)
m2 <- glm(accuracy ~ cueCorr_spearman * cueConfidence * trueCongruence + noise2frames_obs, 'binomial', inference_post1)
m3 <- glm(accuracy ~ cueCorr_spearman * cueConfidence * trueCongruence * noise2frames_obs, 'binomial', inference_post1)
m4 <- glm(accuracy ~ cueCorr_spearman * trueCongruence * noise2frames_obs, 'binomial', inference_post1)
m5 <- glm(accuracy ~ cueCorr_spearman * cueDiff * trueCongruence * noise2frames_obs, 'binomial', inference_post1)


compare_performance(m1, m2, m3, m4, m5) # interaction model wins again!

# plot additive & interaction models
emmip(m2, cueCorr_spearman ~ noise2frames_obs | trueCongruence*cueConfidence, type='response', CIs=T, plotit=T,
      at=list(cueConfidence = seq(1,4,1),
              cueCorr_spearman = quantile(inference_post1$cueCorr_spearman, probs=seq(0,0.9,0.3),na.rm=T),
              noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) + 
  theme_bw() + geom_hline(yintercept = 0.5) + 
  labs(title='additive model', subtitle='columns=cueConfidence') +
  
  emmip(m3, cueCorr_spearman ~ noise2frames_obs | trueCongruence*cueConfidence, type='response', CIs=T, plotit=T,
        at=list(cueConfidence = seq(1,4,1),
                cueCorr_spearman = quantile(inference_post1$cueCorr_spearman, probs=seq(0,0.9,0.3),na.rm=T),
                noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) + 
  theme_bw() + geom_hline(yintercept = 0.5) + 
  labs(title='interaction model', subtitle='columns=cueConfidence') +
  
  plot_layout(guides = 'collect')

ggsave(paste0(outdir, 'accuracy_noise2models.png'), width=10, height=4)

# get p values for contrasts
emtrends(m3, ~cueCorr_spearman*trueCongruence*cueConfidence, var='noise2frames_obs',
         at = list(cueCorr_spearman=quantile(inference_post1$cueCorr_spearman, probs=seq(0,0.9,0.4),na.rm=T),
                   cueConfidence=c(1,4))) %>% test()

## plot trends of noise2frames_obs as a function of cueConf
accTrends <- emtrends(m3, ~cueCorr_spearman*trueCongruence*cueConfidence, var='noise2frames_obs',
                      at = list(cueCorr_spearman=quantile(inference_post1$cueCorr_spearman, probs=seq(0,1,0.5),na.rm=T),
                                cueConfidence=unique(inference_post1$cueConfidence))) %>% 
  as.data.frame() %>%
  filter(is.na(cueConfidence)==F)

noise2_acc <- accTrends %>%
  ggplot(aes(x=cueConfidence, y=noise2frames_obs.trend, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cueCorr_spearman, fill=cueCorr_spearman, group=cueCorr_spearman)) +
  theme_bw() +
  facet_wrap(~trueCongruence) +
  geom_hline(yintercept = 0, color='gray') +
  geom_ribbon(alpha=0.05, color=NA) +
  geom_pointrange(position=position_jitter(width=0, height=0)) +
  scale_color_gradient2(aes(group=cueCorr_spearman)) + scale_fill_gradient2() +
  geom_line(aes(group=cueCorr_spearman)) +
  labs(title='slope of noise2 effect: accuracy', subtitle='solid line=0')

noise2_rt + noise2_acc & theme(legend.position = 'none')

ggsave(paste0(outdir, 'noise2_slopes.png'), width=9, height=3)



#### SPAN model comparisons ####

# for accuracy
m1 <- glm(accuracy ~ trueCue, 'binomial', inference_post1)
m2 <- glm(accuracy ~ subjectiveCue, 'binomial', inference_post1)
m3 <- glm(accuracy ~ cueCorr_spearman, 'binomial', inference_post1)
m4 <- glm(accuracy ~ cueConfidence, 'binomial', inference_post1)
m5 <- glm(accuracy ~ trueCue*trueCongruence, 'binomial', inference_post1)
m6 <- glm(accuracy ~ subjectiveCue*trueCongruence, 'binomial', inference_post1)
m7 <- glm(accuracy ~ cueConfidence*trueCongruence, 'binomial', inference_post1)
m8 <- glm(accuracy ~ trueCue*cueConfidence*trueCongruence, 'binomial', inference_post1)
m9 <- glm(accuracy ~ cueCorr_spearman*cueConfidence*trueCongruence, 'binomial', inference_post1)
m10 <- glm(accuracy ~ cueCorr_spearman*cueConfidence*trueCongruence + noise2frames_obs, 'binomial', inference_post1)
m11 <- glm(accuracy ~ cueCorr_spearman*cueConfidence*trueCongruence*noise2frames_obs, 'binomial', inference_post1)


# for RT
m1 <- lm(zlogRT ~ trueCue, inference_post1)
m2 <- lm(zlogRT ~ subjectiveCue, inference_post1)
m3 <- lm(zlogRT ~ cueCorr_spearman, inference_post1)
m4 <- lm(zlogRT ~ cueConfidence, inference_post1)
m5 <- lm(zlogRT ~ trueCue*trueCongruence, inference_post1)
m6 <- lm(zlogRT ~ subjectiveCue*trueCongruence, inference_post1)
m7 <- lm(zlogRT ~ cueConfidence*trueCongruence, inference_post1)
m8 <- lm(zlogRT ~ trueCue*cueConfidence*trueCongruence, inference_post1)
m9 <- lm(zlogRT ~ cueCorr_spearman*cueConfidence*trueCongruence, inference_post1)
m10 <- lm(zlogRT ~ cueCorr_spearman*cueConfidence*trueCongruence + noise2frames_obs, inference_post1)
m11 <- lm(zlogRT ~ cueCorr_spearman*cueConfidence*trueCongruence*noise2frames_obs, inference_post1)

compare_performance(m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, metrics = 'AIC')
