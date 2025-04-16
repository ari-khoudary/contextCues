library(tidyverse)
library(lmerTest)
library(lme4)
library(patchwork)
library(emmeans)
library(performance)

#### setup ####
outdir <- '../figures/'

# load in learning validation data
validation_df <- read.csv('../tidied_data/learningValidation.csv') %>%
  filter(subID != c(33)) %>%
  mutate(trueCue = case_when(cueIdx!='3' ~ 0.8,
                             cueIdx=='3' ~ 0.5),
         subjectiveCue = subjectiveCue/100,
         subID = ifelse(subID==32, 34, subID)) %>% # change subID value for nicer plots
  group_by(subID) %>%
  mutate(cueCorr = cor(subjectiveCue, trueCue),
         cueDiff = subjectiveCue - trueCue,
         absDiff = abs(cueDiff)) %>%
  ungroup()

# load in inference data
inference_df <- read.csv('../tidied_data/inference.csv') %>% 
  mutate(congCue = factor(congCue),
         noise1Resp = ifelse(respPeriod==1, 1, 0),
         cueConf_factor = factor(cueConfidence),
         subjectiveCue = subjectiveCue/100,
         trueCue = trueCue/100) %>%
  filter(subID != c(33), catch_trial==0) %>%
  group_by(subID) %>%
  mutate(cueCorr = cor(subjectiveCue, trueCue),
         cueDiff = subjectiveCue - trueCue)

#### plot data about cueCorr, cueConf ####

# exploratory correlations
plotCor <- function(x, y, data = validation_df) {
  x_name <- deparse(substitute(x))
  y_name <- deparse(substitute(y))
  
  title <- round(cor(data[[x_name]], data[[y_name]], use='complete.obs', method='spearman'), 3)
  ggplot(data, aes(x = .data[[x_name]], y = .data[[y_name]])) +
    theme_bw() +
    geom_point(position = position_jitter(width=0, height=0.0)) +
    stat_smooth(method='lm') +
    labs(title = paste('r = ', title)) 
}

(plotCor(subjectiveCue, trueCue) |
  plotCor(subjectiveCue, cueConfidence) |
  plotCor(cueDiff, cueConfidence) |
  plotCor(cueCorr, cueConfidence) |
  plotCor(trueCue, cueConfidence) |
  plotCor(cueCorr, cueDiff) |
  plotCor(absDiff, cueConfidence)) &
  theme(axis.title = element_text(size=16))


ggsave(paste0(outdir, 'cueConf_correlationsSpearman.png'), width=16, height=3)

# distributions
p1 <- validation_df %>%
  mutate(trueCue = paste('trueCue = ', trueCue)) %>%
  ggplot(aes(x=subjectiveCue)) +
  facet_wrap(~ trueCue) +
  theme_bw() +
  geom_histogram(breaks=seq(0.5,1,0.1), color='white') +
  scale_y_continuous(n.breaks = 10) +
  labs(title = 'distribution of subjectiveCue')

p2 <- validation_df %>%
  mutate(trueCue = paste('trueCue = ', trueCue)) %>%
  ggplot(aes(x=cueConfidence)) +
  facet_wrap(~ trueCue) +
  theme_bw() +
  geom_histogram(breaks=seq(0,4,1), color='white') +
  scale_y_continuous(n.breaks = 10) +
  labs(title = 'distribution of cueConf by trueCue')

p3 <- validation_df %>%
  mutate(facets = paste0('subjectiveCue =', cut(subjectiveCue, 2))) %>%
  ggplot(aes(x=cueConfidence)) +
  facet_wrap(~ facets, nrow=1) +
  theme_bw() +
  geom_histogram(breaks=seq(0,4,1), color='white') +
  scale_y_continuous(n.breaks = 10) +
  labs(title = 'distribution of cueConf by subjectiveCue')

p1 | p2 | p3

ggsave(paste0(outdir,'learnVal_histograms.png'), width=12, height=3)


#### later responses ####
#### zlogRT for resps after first noise ####
inference_post1 <- inference_df %>% 
  filter(respPeriod > 1) %>% 
  mutate(trueCongruence = factor(trueCongruence, levels=c('neutral', 'congruent', 'incongruent'))) %>%
  group_by(subID) %>%
  mutate(zlogRT = scale(log(RT)))

m1 <- lm(zlogRT ~ cueCorr, inference_post1)
m2 <- lm(zlogRT ~ cueCorr * trueCue, inference_post1)
m3 <- lm(zlogRT ~ cueCorr * cueConfidence, inference_post1)
m4 <- lm(zlogRT ~ cueCorr * cueConfidence * trueCongruence, inference_post1)
#m5 <- lm(zlogRT ~ cueCorr * cueConfidence * subjectiveCongruence, inference_post1)
m6 <- lm(zlogRT ~ cueCorr * subjectiveCue * trueCongruence, inference_post1)

compare_performance(m1, m2, m3, m4, m5)

# m3_df <- emmip(m3, cueConfidence ~ cueCorr, CIs=T, plotit=F,
#       at=list(cueConfidence = unique(inference_post1$cueConfidence,na.rm=T),
#               cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,1,0.3)))) 
# 
# m3_plot <- m3_df %>%
#   mutate(tvar = as.numeric(levels(tvar))[tvar]) %>%
#   filter(is.na(cueConfidence)==0) %>%
#   ggplot(aes(xvar, yvar, ymin=LCL, ymax=UCL, color=tvar)) +
#   theme_bw() +
#   geom_hline(yintercept = 0, color='gray') +
#   geom_pointrange() +
#   geom_line(aes(group=tvar)) +
#   labs(y='estimated zlogRT', x='cueCorr', color='cueConfidence', title = 'RTs after visual evidence onset')
# 

### post submission analysis
m4_df <- emmip(m4, cueCorr ~ cueConfidence | trueCongruence, CIs=T, plotit=F,
               at=list(cueConfidence = unique(inference_post1$cueConfidence),
                       cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,1,0.3), na.rm=T))) 

post1RT_emm <- m4_df %>%
  mutate(tvar = as.numeric(levels(tvar))[tvar]) %>%
  filter(is.na(cueConfidence)==0) %>%
  ggplot(aes(xvar, yvar)) +
  theme_bw() +
  geom_hline(yintercept = 0, color='gray') +
  geom_pointrange(aes(ymin=LCL, ymax=UCL, color=tvar)) +
  geom_line(aes(color=tvar, group=tvar)) +
  facet_wrap(~ trueCongruence) +
  scale_color_gradient2(breaks=c(-0.5, 0,  0.5, 0.9)) +
  labs(y='estimated zlogRT', x='cueConfidence', color='cueCorr', 
       title = 'RTs after visual evidence onset', subtitle='model estimates (incorporating cueCorr)')

post1RT_raw <- inference_post1 %>%
  ggplot(aes(x=cueConfidence, y=zlogRT, color=cueCorr)) +
  theme_bw() + 
  facet_wrap(~ trueCongruence) +
  geom_hline(yintercept = 0, color='gray') +
  scale_color_gradient2(breaks=c(-0.5, 0,  0.5, 0.9)) +
  geom_point(aes(x=cueConfidence, y=zlogRT, color=cueCorr), data=inference_post1, 
             position=position_jitter(width=0.3, height=0), size=0.05) +
  stat_summary(fun = 'mean', geom='line', linewidth=1.5, color='gray50') +
  stat_summary(fun.data = 'mean_se', color='gray50', size=1) +
  labs(title = 'raw data + summary stats', subtitle = 'averaging over cueCorr')

post1RT_raw + post1RT_emm + plot_layout(guides='collect', widths=c(2,1))

ggsave(paste0(outdir, 'RTs_post1.png'), width=12, height=4)

#### let's see if/how adding random effects changes the outcome of model comparison ####
m1 <- lmer(zlogRT ~ cueCorr + (1|subID), inference_post1)
m2 <- lmer(zlogRT ~ cueCorr * trueCue + (1|subID), inference_post1)
m3 <- lmer(zlogRT ~ cueCorr * cueConfidence + (1|subID), inference_post1)
m4 <- lmer(zlogRT ~ cueCorr * cueConfidence * trueCongruence + (1|subID), inference_post1)
m5 <- lmer(zlogRT ~ cueCorr * cueConfidence * subjectiveCongruence + (1|subID), inference_post1)

compare_performance(m1, m2, m3, m4, m5)
## m4 still wins, but all models struggle with singular fits

#### accuracy for resps after first noise ####
inference_post1 <- inference_post1 %>% mutate(trueCongruence=factor(trueCongruence, levels=c('neutral', 'congruent', 'incongruent')))

m1 <- glm(accuracy ~ trueCue, inference_post1, family='binomial')
m2 <- glm(accuracy ~ subjectiveCue, inference_post1, family = 'binomial')
m3 <- glm(accuracy ~ cueCorr, inference_post1, family='binomial')
m4 <- glm(accuracy ~ cueConfidence, inference_post1, family='binomial')
m5 <- glm(accuracy ~ trueCue * trueCongruence, inference_post1, family='binomial')
m6 <- glm(accuracy ~ subjectiveCue * trueCongruence, inference_post1, family = 'binomial')
m7 <- glm(accuracy ~ cueConfidence * trueCongruence, inference_post1, family = 'binomial')
m8 <- glm(accuracy ~ trueCue * cueConfidence * trueCongruence, inference_post1, family = 'binomial')
m9 <- glm(accuracy ~  cueCorr * cueConfidence * trueCongruence, inference_post1, family = 'binomial')

compare_performance(m1, m2, m3, m4, m5, m6, m7, m8, m9)


mp_df <- m9 %>% emmip(., cueCorr ~ cueConfidence | trueCongruence, CIs=T, type='response', plotit=F,
                      at = list(cueCorr = quantile(inference_post1$cueCorr, probs = seq(0,1,0.3), na.rm = T),
                                cueConfidence = unique(inference_post1$cueConfidence)))

m9 %>% emmip(., cueCorr ~ cueConfidence | trueCongruence, CIs=T, type='response',
             at = list(cueCorr = quantile(inference_post1$cueCorr, probs = seq(0,1,0.3), na.rm = T),
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
  labs(y='estimated p(correct)', x='cueConfidence', color='cueCorr', 
       title = 'Accuracy after visual evidence onset', subtitle='model estimates')

post1Acc_raw <- inference_post1 %>%
  group_by(subID, trueCongruence, cueConfidence, cueCorr) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T)) %>%
  ggplot(aes(cueConfidence, propCorrect, color=cueCorr)) +
  theme_bw() +
  geom_hline(yintercept = 0.5, color='gray') +
  facet_wrap(~ trueCongruence) +
  geom_point(position=position_jitter(width=0.25, height=0), size=2.5) +
  stat_summary(fun='mean', geom='line', linewidth=1.5, color='gray50') +
  scale_color_gradient2() + theme(legend.position = 'none') +
  labs(y='propCorrect', x='cueConfidence', color='cueCorr', 
       title = 'Accuracy after visual evidence onset', subtitle='summary stats on raw data')

post1Acc_raw + post1Acc_emm + plot_layout(guides='collect')

ggsave(paste0(outdir, 'accuracy_post1.png'), width=12, height=4)

#### noise2 interactions - RT ####

m1 <- lm(zlogRT ~ cueCorr * cueConfidence * trueCongruence, inference_post1)
m2 <-lm(zlogRT ~ cueCorr * cueConfidence * trueCongruence + noise2frames_obs, inference_post1)
m3 <- lm(zlogRT ~ cueCorr * cueConfidence * trueCongruence * noise2frames_obs, inference_post1)
m4 <- lm(zlogRT ~ cueCorr * trueCongruence * noise2frames_obs, inference_post1)
m5 <- lm(zlogRT ~ cueCorr * trueCue * trueCongruence * noise2frames_obs, inference_post1)
m6 <- lm(zlogRT ~ cueCorr * cueDiff * trueCongruence * noise2frames_obs, inference_post1)

compare_performance(m1, m2, m3, m4, m5, m6) ## MODEL 3 WINS!


### plotting interaction result
m3_df <- emmip(m3, cueCorr ~ noise2frames_obs | cueConfidence*trueCongruence, CIs=T, plotit=F,
               at=list(cueConfidence = unique(inference_post1$cueConfidence),
                       cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,1,0.3),na.rm=T),
                       noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) 

m3_df %>%
  filter(is.na(cueConfidence)==F) %>%
  ggplot(aes(x=noise2frames_obs, y=yvar, color=cueCorr)) +
  theme_bw() +
  facet_grid(trueCongruence ~ cueConfidence) +
  geom_hline(yintercept = 0) +
  geom_pointrange(aes(ymin=LCL, ymax=UCL)) +
  geom_line(aes(group=interaction(cueCorr, trueCongruence))) +
  scale_color_gradient2() +
  labs(y='estimated zlogRT', title='zlogRT ~ cueCorr * cueConf * congruent * noise2frames_obs',
       subtitle = 'columns=cueConfidence, rows=congruent')


### plotting additive result
emmip(m2, cueCorr ~ noise2frames_obs | trueCongruence*cueConfidence, CIs=T, plotit=T,
      at=list(cueConfidence = seq(1,4,1),
              cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,1,0.3)),
              noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) +
  labs(title = 'additive model', subtitle='columns=cueConfidence', y='linear prediction (zlogRT)') +
  geom_hline(yintercept=0, color='gray') +
  
  emmip(m3, cueCorr ~ noise2frames_obs | trueCongruence*cueConfidence, CIs=T, plotit=T,
        at=list(cueConfidence = seq(1,4,1),
                cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,1,0.3),na.rm=T),
                noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) +
  labs(title = 'interaction model', subtitle='columns=cueConfidence', y='linear prediction(zlogRT)') +
  geom_hline(yintercept=0, color='gray') +
  
  plot_layout(guides='collect') & theme_bw()

ggsave(paste0(outdir, 'RTs_noise2models.png'), width=12, height=4)

# plot slopes for interaction model
rtSlopes <- emtrends(m3, ~ cueConfidence*cueCorr*trueCongruence, var='noise2frames_obs',          
                     at = list(cueCorr=quantile(inference_post1$cueCorr, probs=seq(0,0.9,0.4),na.rm=T),
                               cueConfidence=seq(1,4,1))) %>% as.data.frame() 

zero <- mean(rtSlopes$noise2frames_obs.trend)

noise2_rt <- rtSlopes %>%
  ggplot(aes(x=cueConfidence, y=noise2frames_obs.trend, ymin=lower.CL, ymax=upper.CL, 
             color=cueCorr, fill=cueCorr, group=cueCorr)) +
  theme_bw() +
  facet_wrap(~trueCongruence) +
  geom_hline(yintercept = zero, color='gray20') +
  geom_ribbon(alpha=0.05, color=NA) +
  geom_pointrange(position=position_jitter(width=0, height=0)) +
  scale_color_gradient2(aes(group=cueCorr)) + scale_fill_gradient2() +
  geom_line(aes(group=cueCorr)) +
  labs(title='slope of noise2 effect: RT', subtitle='solid line=average noise2 effect')


#### looking at signal2 RTs ####
m1 <- lm(zlogRT_sig2locked ~ cueCorr * cueConfidence * trueCongruence, inference_post1)
m2 <-lm(zlogRT_sig2locked ~ cueCorr * cueConfidence * trueCongruence + noise2frames_obs, inference_post1)
m3 <- lm(zlogRT_sig2locked ~ cueCorr * cueConfidence * trueCongruence * noise2frames_obs, inference_post1)
m4 <- lm(zlogRT_sig2locked ~ cueCorr * trueCongruence * noise2frames_obs, inference_post1)
m5 <- lm(zlogRT_sig2locked ~ cueCorr * trueCue * trueCongruence * noise2frames_obs, inference_post1)

compare_performance(m1, m2, m3, m4, m5) # when outcome is sig2locked RT, the additive model is better

emmip(m2, cueCorr ~ noise2frames_obs | cueConfidence*trueCongruence, CIs=T, plotit=T,
      at=list(cueConfidence = unique(inference_post1$cueConfidence),
              cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,1,0.3),na.rm=T),
              noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) 

### looking at signal1-locked RT
m1 <- lm(zlogRT_sig1locked ~ cueCorr * cueConfidence * trueCongruence, inference_post1)
m2 <-lm(zlogRT_sig1locked ~ cueCorr * cueConfidence * trueCongruence + noise2frames_obs, inference_post1)
m3 <- lm(zlogRT_sig1locked ~ cueCorr * cueConfidence * trueCongruence * noise2frames_obs, inference_post1)
m4 <- lm(zlogRT_sig1locked ~ cueCorr * trueCongruence * noise2frames_obs, inference_post1)
m5 <- lm(zlogRT_sig1locked ~ cueCorr * trueCue * trueCongruence * noise2frames_obs, inference_post1)

compare_performance(m1, m2, m3, m4, m5) # when outcome is sig1locked RT, M3 wins again

emmip(m3, cueCorr ~ noise2frames_obs | cueConfidence*trueCongruence, CIs=T, plotit=T,
      at=list(cueConfidence = unique(inference_post1$cueConfidence),
              cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,1,0.3),na.rm=T),
              noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) 


#### noise2 interactions -- accuracy ####
m1 <- glm(accuracy ~ cueCorr * cueConfidence * trueCongruence, 'binomial', inference_post1)
m2 <- glm(accuracy ~ cueCorr * cueConfidence * trueCongruence + noise2frames_obs, 'binomial', inference_post1)
m3 <- glm(accuracy ~ cueCorr * cueConfidence * trueCongruence * noise2frames_obs, 'binomial', inference_post1)
m4 <- glm(accuracy ~ cueCorr * trueCongruence * noise2frames_obs, 'binomial', inference_post1)
m5 <- glm(accuracy ~ cueCorr * cueDiff * trueCongruence * noise2frames_obs, 'binomial', inference_post1)


compare_performance(m1, m2, m3, m4, m5) # interaction model wins again!

# plot additive & interaction models
emmip(m2, cueCorr ~ noise2frames_obs | trueCongruence*cueConfidence, type='response', CIs=T, plotit=T,
      at=list(cueConfidence = seq(1,4,1),
              cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,0.9,0.3),na.rm=T),
              noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) + 
  theme_bw() + geom_hline(yintercept = 0.5) + 
  labs(title='additive model', subtitle='columns=cueConfidence') +
  
  emmip(m3, cueCorr ~ noise2frames_obs | trueCongruence*cueConfidence, type='response', CIs=T, plotit=T,
        at=list(cueConfidence = seq(1,4,1),
                cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,0.9,0.3),na.rm=T),
                noise2frames_obs = quantile(inference_post1$noise2frames_obs, probs=seq(0,1,0.3),na.rm=T))) + 
  theme_bw() + geom_hline(yintercept = 0.5) + 
  labs(title='interaction model', subtitle='columns=cueConfidence') +
  
  plot_layout(guides = 'collect')

ggsave(paste0(outdir, 'accuracy_noise2models.png'), width=10, height=4)

# get p values for contrasts
emtrends(m3, ~cueCorr*trueCongruence*cueConfidence, var='noise2frames_obs',
         at = list(cueCorr=quantile(inference_post1$cueCorr, probs=seq(0,0.9,0.4),na.rm=T),
                   cueConfidence=c(1,4))) %>% test()

## plot trends of noise2frames_obs as a function of cueConf
accTrends <- emtrends(m3, ~cueCorr*trueCongruence*cueConfidence, var='noise2frames_obs',
                      at = list(cueCorr=quantile(inference_post1$cueCorr, probs=seq(0,1,0.5),na.rm=T),
                                cueConfidence=unique(inference_post1$cueConfidence))) %>% 
  as.data.frame() %>%
  filter(is.na(cueConfidence)==F)

noise2_acc <- accTrends %>%
  ggplot(aes(x=cueConfidence, y=noise2frames_obs.trend, ymin=asymp.LCL, ymax=asymp.UCL, 
             color=cueCorr, fill=cueCorr, group=cueCorr)) +
  theme_bw() +
  facet_wrap(~trueCongruence) +
  geom_hline(yintercept = 0, color='gray') +
  geom_ribbon(alpha=0.05, color=NA) +
  geom_pointrange(position=position_jitter(width=0, height=0)) +
  scale_color_gradient2(aes(group=cueCorr)) + scale_fill_gradient2() +
  geom_line(aes(group=cueCorr)) +
  labs(title='slope of noise2 effect: accuracy', subtitle='solid line=0')

noise2_rt + noise2_acc & theme(legend.position = 'none')

ggsave(paste0(outdir, 'noise2_slopes.png'), width=9, height=3)



#### SPAN model comparisons ####

# for accuracy
m1 <- glm(accuracy ~ trueCue, 'binomial', inference_post1)
m2 <- glm(accuracy ~ subjectiveCue, 'binomial', inference_post1)
m3 <- glm(accuracy ~ cueCorr, 'binomial', inference_post1)
m4 <- glm(accuracy ~ cueConfidence, 'binomial', inference_post1)
m5 <- glm(accuracy ~ trueCue*trueCongruence, 'binomial', inference_post1)
m6 <- glm(accuracy ~ subjectiveCue*trueCongruence, 'binomial', inference_post1)
m7 <- glm(accuracy ~ cueConfidence*trueCongruence, 'binomial', inference_post1)
m8 <- glm(accuracy ~ trueCue*cueConfidence*trueCongruence, 'binomial', inference_post1)
m9 <- glm(accuracy ~ cueCorr*cueConfidence*trueCongruence, 'binomial', inference_post1)
m10 <- glm(accuracy ~ cueCorr*cueConfidence*trueCongruence + noise2frames_obs, 'binomial', inference_post1)
m11 <- glm(accuracy ~ cueCorr*cueConfidence*trueCongruence*noise2frames_obs, 'binomial', inference_post1)


# for RT
m1 <- lm(zlogRT ~ trueCue, inference_post1)
m2 <- lm(zlogRT ~ subjectiveCue, inference_post1)
m3 <- lm(zlogRT ~ cueCorr, inference_post1)
m4 <- lm(zlogRT ~ cueConfidence, inference_post1)
m5 <- lm(zlogRT ~ trueCue*trueCongruence, inference_post1)
m6 <- lm(zlogRT ~ subjectiveCue*trueCongruence, inference_post1)
m7 <- lm(zlogRT ~ cueConfidence*trueCongruence, inference_post1)
m8 <- lm(zlogRT ~ trueCue*cueConfidence*trueCongruence, inference_post1)
m9 <- lm(zlogRT ~ cueCorr*cueConfidence*trueCongruence, inference_post1)
m10 <- lm(zlogRT ~ cueCorr*cueConfidence*trueCongruence + noise2frames_obs, inference_post1)
m11 <- lm(zlogRT ~ cueCorr*cueConfidence*trueCongruence*noise2frames_obs, inference_post1)

compare_performance(m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, metrics = 'AIC')
