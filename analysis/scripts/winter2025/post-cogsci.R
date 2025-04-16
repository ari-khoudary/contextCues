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
  filter(subID != 33) %>%
  mutate(trueCue = case_when(cueIdx!='3' ~ 0.8,
                             cueIdx=='3' ~ 0.5),
         subjectiveCue = subjectiveCue/100,
         subID = ifelse(subID==32, 34, subID)) %>% # change subID value for nicer plots
  group_by(subID) %>%
  mutate(cueCorr = cor(subjectiveCue, trueCue),
         cueDiff = subjectiveCue - trueCue) %>%
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




#### compute accuracy of subjective cue estimates ####
# violin & boxplots 
p1 <- validation_df %>%
  mutate(trueCue = factor(trueCue)) %>%
  ggplot(aes(x=trueCue, y=cueDiff,)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_violin(alpha=0.3, scale='count') + 
  geom_boxplot(width=0.25, fill=NA, color='black', outliers=FALSE) +
  geom_point(position = position_jitter(width=0.03), alpha=0.5, size=1) +
  geom_line(aes(group=subID), alpha=0.25, color='gray20') +
  labs(y = 'cueDiff', title = 'cueDiff = subjectiveCue - trueCue') +
  theme(legend.position = 'none')

# regression results
lm(cueDiff ~ trueCue, validation_df) %>% summary()

p2 <- validation_df %>%
  distinct(subID, cueCorr) %>%
  ggplot(aes(x=subID, y=cueCorr)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_col() +
  scale_x_continuous(breaks=unique(validation_df$subID)) +
  labs(y='cueCorr', title = 'cueCoff = cor(subjectiveCue, trueCue)')

#p1 / p2 + plot_annotation(tag_levels = 'A')
#ggsave(paste0(outdir, 'cueEstimates.png'),width=4, height=6)


#### compare models of confidence in cue estimates ####
# different sources of probability information
m1 <- lm(cueConfidence ~ trueCue, validation_df)

m2 <- lm(cueConfidence ~ subjectiveCue, validation_df)

m3 <- lm(cueConfidence ~ trueCue + subjectiveCue, validation_df)

m4 <- lm(cueConfidence ~ trueCue + subjectiveCue + trueCue:subjectiveCue, validation_df)

compare_performance(m1, m2, m3, m4)

# plot TC and MC 
m2_df <- emmip(m2, ~ subjectiveCue , CI=T,
      at = list(subjectiveCue = quantile(validation_df$subjectiveCue, probs=seq(0,1,0.25))), plotit = F)

p3 <- validation_df %>% 
  ggplot(aes(subjectiveCue, cueConfidence)) +
  theme_bw() +
  geom_point(position=position_jitter(width=0.002)) +
  geom_ribbon(aes(xvar, yvar, ymin=LCL, ymax=UCL), data=m2_df, alpha=0.2, color=NA) +
  geom_line(aes(xvar, yvar), data=m2_df, size=2) +
  labs(title = 'subjective cue effect')

#p1 + p2 + p3
#ggsave(paste0(outdir, 'cueConfidence.png'), width=6, height=3)

# different measures of learning accuracy
m <- lm(cueConfidence ~ cueCorr + cueDiff + cueCorr:cueDiff, validation_df) 
summary(m)

cueCorr_df <- emmip(m, ~ cueCorr, CI=T, plotit=F, at=list('cueCorr'=quantile(validation_df$cueCorr, probs=seq(0,1,0.25))))
cueAcc_df <- emmip(m, ~ cueDiff, CI=T, plotit=F, at=list('cueDiff'=quantile(validation_df$cueDiff, probs=seq(0,1,0.25))))

p4 <- validation_df %>%
  ggplot(aes(x=cueCorr, y=cueConfidence)) +
  theme_bw() +
  geom_point(position=position_jitter(width=0.01, height=0)) +
  geom_ribbon(aes(xvar, yvar, ymin=LCL, ymax=UCL), data=cueCorr_df, alpha=0.2) +
  geom_line(aes(xvar, yvar), data=cueCorr_df, size=2) +
  labs(title = 'main effect of cueCorr on cueConfidence')

p5 <- validation_df %>%
  ggplot(aes(x=cueDiff, y=cueConfidence)) +
  theme_bw() +
  geom_point(position=position_jitter(width=0.01, height=0)) +
  geom_ribbon(aes(xvar, yvar, ymin=LCL, ymax=UCL), data=cueAcc_df, alpha=0.2) +
  geom_line(aes(xvar, yvar), data=cueAcc_df, size=2) +
  labs(title = 'main effect of cueDiff on cueConfidence')

p1 + p2 + plot_annotation(tag_levels = 'A') + plot_layout(widths=c(0.5, 1))
ggsave(paste0(outdir, 'fig2.png'), width=8, height=4)

p5 + p4 + plot_annotation(tag_levels = 'A')
ggsave(paste0(outdir, 'fig3.png'), width=8, height=4)

#### plot data about cueCorr, cueConf ####

# exploratory correlations
plotCor <- function(x, y, data = validation_df) {
  x_name <- deparse(substitute(x))
  y_name <- deparse(substitute(y))
  
  title <- round(cor(data[[x_name]], data[[y_name]], use='complete.obs'), 3)
  ggplot(data, aes(x = .data[[x_name]], y = .data[[y_name]])) +
    theme_bw() +
    geom_point(position = position_jitter(width=0, height=0.0)) +
    stat_smooth(method='lm') +
    labs(title = paste('r = ', title)) 
}

plotCor(subjectiveCue, trueCue) + 
plotCor(subjectiveCue, cueConfidence) +
plotCor(cueDiff, cueConfidence) + 
plotCor(cueCorr, cueConfidence) +
plotCor(trueCue, cueConfidence) +
plotCor(cueCorr, cueDiff)

ggsave(paste0(outdir, 'cueConf_correlationsPearson.png'), width=6, height=4)

validation_df <- mutate(validation_df, absDiff = abs(cueDiff))
plotCor(absDiff, cueConfidence)
ggsave(paste0(outdir, 'absDiff_confCorr.png'), width=3, height=3)

# distributions
p1 <- validation_df %>%
  mutate(trueCue = paste('trueCue = ', trueCue)) %>%
  ggplot(aes(x=subjectiveCue)) +
  facet_wrap(~ trueCue) +
  theme_bw() +
  geom_histogram(breaks=seq(0.5,1,0.1), color='white') +
  scale_y_continuous(n.breaks = 10) +
  labs(title = 'subjectiveCue by trueCue')

p2 <- validation_df %>%
  mutate(trueCue = paste('trueCue = ', trueCue)) %>%
  ggplot(aes(x=cueConfidence)) +
  facet_wrap(~ trueCue) +
  theme_bw() +
  geom_histogram(breaks=seq(0,4,1), color='white') +
  scale_y_continuous(n.breaks = 10) +
  labs(title = 'cueConfidence by trueCue')

p3 <- validation_df %>%
  mutate(facets = paste0('subjectiveCue =', cut(subjectiveCue, 2))) %>%
  ggplot(aes(x=cueConfidence)) +
  facet_wrap(~ facets, nrow=1) +
  theme_bw() +
  geom_histogram(breaks=seq(0,4,1), color='white') +
  scale_y_continuous(n.breaks = 10) +
  labs(title = 'cueConfidence by subjectiveCue')

(p1 / p2) | p3

ggsave(paste0(outdir,'learnVal_histograms.png'), width=8, height=4)

# raw data visualizations
validation_df %>%
  ggplot(aes(x=cueConfidence, y=subjectiveCue, color=cueCorr)) +
  facet_wrap(~ trueCue) +
  theme_bw() +
  geom_point(size=3, position=position_jitter(width=0.25, height=0)) +
  scale_color_gradient2() 
  
#### INFERENCE ANALYSES ####
#### early responses ####
#### single-factor predictors of noise1 resp
m1 <- glm(noise1Resp ~ trueCue, inference_df, family='binomial')

m2 <- glm(noise1Resp ~ subjectiveCue, inference_df, family='binomial')

m3 <- glm(noise1Resp ~ cueConfidence, inference_df, family='binomial')

m4 <- glm(noise1Resp ~ cueCorr, inference_df, family='binomial')

m5 <- glm(noise1Resp ~ cueDiff, inference_df, family='binomial')

compare_performance(m1, m2, m3, m4, m5)

#### interaction with noise1frames to predict noise1 resp
m1 <- glm(noise1Resp ~ trueCue * noise1frames_design, inference_df, family='binomial')

m2 <- glm(noise1Resp ~ subjectiveCue * noise1frames_design, inference_df, family='binomial')

m3 <- glm(noise1Resp ~ cueConfidence * noise1frames_design, inference_df, family='binomial')

m4 <- glm(noise1Resp ~ cueCorr * noise1frames_design, inference_df, family='binomial')

m5 <- glm(noise1Resp ~ cueDiff * noise1frames_design, inference_df, family='binomial')

compare_performance(m1, m2, m3, m4, m5)

# summarize & plot winning model
summary(m4)
m4_df <- emmip(m4, cueCorr ~ noise1frames_design, type='response', plotit=F, CIs=T,
               at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                       cueCorr = quantile(inference_df$cueCorr, digits=4)))

p1 <- m4_df %>%
  mutate(tvar = as.numeric(levels(tvar))[tvar]) %>%
  ggplot(aes(xvar/72 * 100, yvar, ymin=LCL, ymax=UCL, color=tvar)) +
  theme_bw() +
  geom_pointrange() +
  geom_line(aes(group=cueCorr)) +
  scale_colour_gradient2() +
  labs(y = 'estimated p(earlyResponse)', x = 'anticipation duration (ms)', color='cueCorr', title='probability of early response')

#ggsave(paste0(outdir, 'noise1Resp.png'), width=5, height=3)

#### what did people choose when they responded during noise1?
noise1_resp <- inference_df %>% 
  filter(respPeriod == 1) %>%
  mutate(cueCongResponse_subj = ifelse(response==imgIdx_subjective, 1, 0))

m1 <- glm(cueCongResponse_obj ~ congCue, noise1_resp, family='binomial')
m2 <- glm(cueCongResponse_obj ~ congCue + cueCorr, noise1_resp, family='binomial')
m3 <- glm(cueCongResponse_obj ~ congCue + cueCorr + cueConfidence, noise1_resp, family='binomial')
m4 <- glm(cueCongResponse_subj ~ subjectiveCue, noise1_resp, family='binomial') 
m5 <- glm(cueCongResponse_subj ~ subjectiveCue + cueCorr, noise1_resp, family='binomial') 
m6 <- glm(cueCongResponse_subj ~ subjectiveCue + cueCorr + cueConfidence, noise1_resp, family='binomial')
compare_performance(m1, m2, m3, m4, m5, m6)

summary(m3)

glm(accuracy ~ trueCue + subjectiveCue + cueCorr, noise1_resp, family='binomial') %>% summary()

noise1acc_df <- glm(accuracy ~ trueCue + subjectiveCue + cueCorr, noise1_resp, family='binomial') %>% 
  emmip(., ~ trueCue, CIs=T, type='response', plotit=F) 

p2 <- noise1acc_df %>%
  ggplot(aes(xvar, yvar, ymin=LCL, ymax=UCL)) +
  theme_bw() +
  geom_hline(yintercept=0.5, linetype='dashed') +
  geom_pointrange() +
  geom_line() +
  labs(y='estimated p(correct)', x='trueCue', title='probability of correct early response')

p1 + p2 + plot_annotation(tag_levels = 'A')

ggsave(paste0(outdir, 'fig5.png'), width=8, height=4)

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
m5 <- lm(zlogRT ~ cueCorr * cueConfidence * subjectiveCongruence, inference_post1)

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
