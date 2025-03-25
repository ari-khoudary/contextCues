library(tidyverse)
library(lmerTest)
library(lme4)
library(patchwork)
library(emmeans)
library(performance)

#### setup ####
outdir <- '../figures/cogsci/'
find_mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

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
  filter(subID != 33, catch_trial==0) %>%
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
  labs(y='cueCorr', title = 'cueCorr = cor(subjectiveCue, trueCue)')

#p1 + p2 + plot_annotation(tag_levels = 'A')
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
inference_post1 <- inference_df %>% filter(respPeriod > 1) %>% 
  mutate(trueCongruence = factor(trueCongruence, levels=c('neutral', 'congruent', 'incongruent')))

m1 <- lm(zlogRT ~ cueCorr, inference_post1)
m2 <- lm(zlogRT ~ cueCorr * trueCue, inference_post1)
m3 <- lm(zlogRT ~ cueCorr * cueConfidence, inference_post1)
m4 <- lm(zlogRT ~ cueCorr * cueConfidence * trueCongruence, inference_post1)
m5 <- lm(zlogRT ~ cueCorr * cueConfidence * subjectiveCongruence, inference_post1)

compare_performance(m1, m2, m3, m4, m5)

m3_df <- emmip(m3, cueConfidence ~ cueCorr, CIs=T, plotit=F,
      at=list(cueConfidence = unique(inference_post1$cueConfidence,na.rm=T),
              cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,1,0.3)))) 

m3_plot <- m3_df %>%
  mutate(tvar = as.numeric(levels(tvar))[tvar]) %>%
  filter(is.na(cueConfidence)==0) %>%
  ggplot(aes(xvar, yvar, ymin=LCL, ymax=UCL, color=tvar)) +
  theme_bw() +
  geom_hline(yintercept = 0, color='gray') +
  geom_pointrange() +
  geom_line(aes(group=tvar)) +
  labs(y='estimated zlogRT', x='cueCorr', color='cueConfidence', title = 'RTs after visual evidence onset')


### post submission analysis
m4_df <- emmip(m4, cueCorr ~ cueConfidence | trueCongruence, CIs=T, plotit=T,
               at=list(cueConfidence = unique(inference_post1$cueConfidence,na.rm=T),
                       cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,1,0.3)))) + 
  theme_bw() + geom_hline(yintercept = 0)

m4_df %>%
  mutate(tvar = as.numeric(levels(tvar))[tvar]) %>%
  filter(is.na(cueConfidence)==0) %>%
  ggplot(aes(xvar, yvar, ymin=LCL, ymax=UCL, color=tvar)) +
  theme_bw() +
  geom_hline(yintercept = 0, color='gray') +
  geom_pointrange() +
  geom_line(aes(group=tvar)) +
  facet_wrap(~ trueCongruence) +
  labs(y='estimated zlogRT', x='cueCorr', color='cueConfidence', title = 'RTs after visual evidence onset')

emmip(m4, cueCorr ~ cueConfidence | trueCongruence, CIs=T, plotit=T,
      at=list(cueConfidence = unique(inference_post1$cueConfidence,na.rm=T),
              cueCorr = quantile(inference_post1$cueCorr, probs=seq(0,1,0.3)))) + 
  theme_bw() + geom_hline(yintercept = 0)




inference_post1 <- inference_post1 %>% mutate(trueCongruence=factor(trueCongruence, levels=c('neutral', 'congruent', 'incongruent')))
#### accuracy for resps after first noise ####
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

p200 <- mp_df %>%
  mutate(tvar = as.numeric(levels(tvar))[tvar]) %>%
  ggplot(aes(cueConfidence, yvar, ymin=LCL, ymax=UCL, color=tvar)) +
  theme_bw() +
  geom_hline(yintercept = 0.5, color='gray') +
  facet_wrap(~ trueCongruence) +
  geom_pointrange() +
  geom_line(aes(group=tvar)) +
  scale_color_gradient2() +
  labs(y='estimated p(correct)', x='cueConfidence', color='cueCorr', title = 'Accuracy after visual evidence onset')


p100 + p200 + plot_annotation(tag_levels='A') + plot_layout(widths = c(1,2.75))
ggsave(paste0(outdir, 'fig6.png'), width=10, height=4)

p100
ggsave(paste0(outdir, 'signalRTs.png'), width=5, height=3)

p200
ggsave(paste0(outdir, 'fig7.png'), width=6, height=3)


#### TBD ####
glm(noise1Resp ~ trueCue * noise1frames_design, inference_df, family='binomial') %>%
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


glm(noise1Resp ~ cueConf_factor * noise1frames_design, inference_df, family='binomial') %>% #summary()
  emmip(., cueConf_factor ~ noise1frames_design, type='response', CI=T,
        at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                cueConf_factor = unique(inference_df$cueConf_factor))) + 
  theme_bw() + 
  ggtitle('probability of noise1 response')



glm(noise1Resp ~ cueCorr * noise1frames_design, inference_df, family='binomial') %>% #summary()
  emmip(., cueCorr ~ noise1frames_design, type='response', CI=T,
        at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                cueCorr = quantile(inference_df$cueCorr, probs=seq(0,1,0.25)))) + 
  theme_bw() + 
  ggtitle('probability of noise1 response')












# probability of making a response in the first noise period 
inference_df %>%
  mutate(noise1resp = ifelse(respFrame <= noise1frames_design, 1, 0)) %>%
  glm(noise1resp ~ trueCue * noise1frames_design, ., family='binomial') %>%
  emmip(., trueCue ~ noise1frames_design, type='response', CI=T,
        at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                trueCue = unique(inference_df$trueCue))) + 
  theme_bw() + 
  ggtitle('probability of noise1 response') +
  
inference_df %>%
  mutate(noise1resp = ifelse(respFrame <= noise1frames_design, 1, 0),
         cueConfidence = factor(cueConfidence)) %>%
  glm(noise1resp ~ cueConfidence * noise1frames_design, ., family='binomial') %>%
  emmip(., cueConfidence ~ noise1frames_design, type='response', CI=T,
        at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)))) + 
  theme_bw() + 
  ggtitle('probability of noise1 response')


# probability of making a response in the first signal period
inference_df %>%
  mutate(signal2resp = ifelse(respPeriod==2, 1, 0)) %>%
  glm(signal2resp ~ congCue * noise1frames_design, ., family='binomial') %>%
  emmip(., congCue ~ noise1frames_design, type='response', CI=T,
        at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                congCue = unique(inference_df$congCue))) + 
  theme_bw() +
  ggtitle('probability of signal1 response') +

# probability of making a response in the second noise period
inference_df %>%
  mutate(resp = ifelse(respPeriod==3, 1, 0)) %>%
  glm(resp ~ congCue * noise1frames_design * signal1frames_design, ., family='binomial') %>%
  emmip(., congCue ~ noise1frames_design | signal1frames_design, type='response', CI=T,
        at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                signal1frames_design=quantile(inference_df$signal1frames_design, na.rm=T, probs=seq(0, 1, 0.4)), 
                congCue = unique(inference_df$congCue))) + 
  theme_bw() +
  ggtitle('probability of noise2 response by signal1frames') +
  

inference_df %>%
  mutate(resp = ifelse(respPeriod==4, 1, 0)) %>%
  glm(resp ~ congCue * noise1frames_design * signal1frames_design, ., family='binomial') %>%
  emmip(., congCue ~ noise1frames_design | signal1frames_design, type='response', CI=T,
        at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                signal1frames_design=quantile(inference_df$signal1frames_design, na.rm=T, probs=seq(0, 1, 0.4)), 
                congCue = unique(inference_df$congCue))) + 
  theme_bw() +
  ggtitle('probability of signal2 response by signal1 frames') 
  
# inference_df %>%
#   mutate(resp = ifelse(respPeriod==4, 1, 0)) %>%
#   glm(resp ~ congCue * noise2frames_design * signal1frames_design, ., family='binomial') %>%
#   emmip(., congCue ~ noise2frames_design | signal1frames_design, type='response', CI=T,
#         at=list(noise2frames_design=quantile(inference_df$noise2frames_design, na.rm=T, probs=seq(0,1,0.1)),
#                 signal1frames_design=quantile(inference_df$signal1frames_design, na.rm=T, probs=seq(0, 1, 0.4)), 
#                 congCue = unique(inference_df$congCue))) + 
#   theme_bw() +
#   ggtitle('probability of signal2 response by signal1 frames')

## looking at signal1 response data

inference_df %>%
  mutate(signal2resp = ifelse(respPeriod==2, 1, 0)) %>%
  glm(signal2resp ~ congCue * noise1frames_design, ., family='binomial') %>%
  emtrends(., ~ congCue, var='noise1frames_design',
           at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)))) %>%
  pairs()
  
  emmip(., congCue ~ noise1frames_design  type='response', CI=T,
        at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                #targetEv_signal1=quantile(inference_df$targetEv_signal1, na.rm=T, probs=seq(0.1,1,0.4)), 
                congCue = unique(inference_df$congCue))) + 
  theme_bw() +
  ggtitle('probability of signal1 response')

#### 
  
inference_df %>%
    mutate(resp = ifelse(respPeriod==3, 1, 0)) %>%
    glm(resp ~ congCue * noise1frames_design * signal1frames_design, ., family='binomial') %>% summary()
    emtrends(., ~ congCue | signal1frames_design, var='noise1frames_design', 
    # emmip(., congCue ~ noise1frames_design | signal1frames_design, type='response', CI=T,
           at=list(noise1frames_design=quantile(inference_df$noise1frames_design, na.rm=T, probs=seq(0,1,0.1)),
                   signal1frames_design=quantile(inference_df$signal1frames_design, na.rm=T, probs=seq(0, 1, 0.4)), 
                   congCue = unique(inference_df$congCue))) 
    # theme_bw() +
    # ggtitle('probability of noise2 response by signal1frames') 
  
    