# load in necessary packages
library(tidyverse) # for data wrangling and plotting
library(patchwork) # for combining plots into bigger figures

###### load in data ###### 
inferenceData_tidy <- read.csv('poster_data/inference_data.csv')
learningData_tidy <- read.csv('poster_data/learning_data.csv')
# specify where to save plots
outdir <- 'poster_plots/'

# remove subjects from first round of piloting
inferenceData_tidy <- inferenceData_tidy %>% filter(pilotGroup == 'group2')
nSubs <- length(unique(inferenceData_tidy$subID))

###### plot group summary statistics ###### 
## make a summary data frame
inferenceSummary_cue <- inferenceData_tidy %>% 
  group_by(cueLevel) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T),
            propCorrect_sem = (sd(accuracy, na.rm=T) / sqrt(nSubs)),
            RT = mean(zlogRT),
            RT_sem = (sd(zlogRT) / sqrt(nSubs)),
            confidence = mean(confResp, na.rm = T),
            confidence_sem = sd(confResp, na.rm=T) / sqrt(nSubs),
            confRT = mean(zlogconfRT),
            confRT_sem = sd(zlogconfRT)/sqrt(nSubs))

## plot group-level accuracy as a function of cue level
inferenceSummary_cue %>%
  ggplot(aes(x=cueLevel, y=propCorrect)) + # specify what you want on x and y axes
  ylim(c(0, 1)) + # specify your y limits
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) + # tell the x-axis where we want labels
  geom_hline(yintercept=0.5, linewidth=0.15) + # plot a horizontal line at chance
  geom_pointrange(aes(ymin = propCorrect-propCorrect_sem, ymax=propCorrect+propCorrect_sem)) + # draw points with error bars
  geom_line() + # connect the points with a line
  theme_classic() + # make the background white etc
  labs(title = 'group accuracy') + # add a title
  theme(plot.title = element_text(hjust=0.5)) # center the title 
ggsave(paste0(outdir, 'accuracy.png'), width=3, height=4, dpi='retina') # save the current figure 

## plot group-level RTs as a function of cue level
inferenceSummary_cue %>%
  ggplot(aes(x=cueLevel, y=RT)) +
  geom_hline(yintercept=0, linewidth=0.15) + 
  geom_pointrange(aes(ymin = RT-RT_sem, ymax=RT+RT_sem)) + 
  geom_line() +
  theme_classic() +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) +
  labs(y = 'log-transformed z-scored RT', title='group RTs') +
  theme(plot.title = element_text(hjust=0.5)) # center the title 
ggsave(paste0(outdir, 'RT.png'), width=3, height=4, dpi='retina') # save the current figure 

## make a dataframe to plot RT and confidence as a function of trial-accuracy & cue level
inferenceSummary_acc <- inferenceData_tidy %>%
  group_by(subID) %>%
  mutate(zconf = scale(confResp),
         accuracy = factor(accuracy, levels=c(1,0), labels=c('correct', 'incorrect'))) %>%
  ungroup() %>%
  group_by(accuracy, congruent, cueLevel) %>%
  summarise(meanRT = mean(zlogRT),
            RT_sem = sd(zlogRT) / sqrt(nSubs),
            meanZConf = mean(zconf),
            ZConf_sem = sd(zconf) / sqrt(nSubs)) 

## plot RT as a function of accuracy & cue level
inferenceSummary_acc %>%
  ggplot(aes(x=cueLevel, y=meanRT, group=accuracy, color=accuracy)) +
  geom_hline(yintercept=0, linewidth=0.15) + 
  geom_pointrange(aes(ymin = meanRT - RT_sem, ymax = meanRT + RT_sem)) +
  geom_line() +
  theme_classic() +
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) +
  scale_color_manual(values = c('forestgreen', 'darkmagenta'))+
  labs(y = 'RT (log-transformed and z-scored within subject)', title='RT as a function of accuracy and cue reliability') +
  theme(plot.title = element_text(hjust=0.5)) # center the title 
ggsave(paste0(outdir, 'speedAccuracy.png'), width=6, height=4, dpi='retina') # save the current figure 

## plot confidence as a function of accuracy & cue level
inferenceSummary_acc %>%
  ggplot(aes(x=cueLevel, y=meanZConf, group=accuracy,color=accuracy)) +
  geom_hline(yintercept=0, linewidth=0.15) + 
  geom_pointrange(aes(ymin = meanZConf - ZConf_sem, ymax = meanZConf + ZConf_sem)) +
  geom_line() +
  theme_classic() + 
  scale_x_continuous(breaks=c(0.2, 0.5, 0.8)) +
  scale_color_manual(values = c('forestgreen', 'darkmagenta')) +
  labs(y = 'confidence (z-scored within subject)', title = 'Decision confidence as a function of accuracy and cue reliability') +
  theme(plot.title = element_text(hjust=0.5)) # center the title 
ggsave(paste0(outdir, 'speedConfidence.png'), width=6, height=4, dpi='retina')

########### bar plot versions ########### 
# make some changes to inferenceData_tidy to make the plots we want
inferenceData_tidy <- inferenceData_tidy %>%
  mutate(trueCue = ifelse(cueLevel==0.2, 0.8, cueLevel),
         congruent = factor(congruent, levels=c('neutral', 'congruent', 'incongruent')))

inferenceSummary_bar <- inferenceData_tidy %>%
  group_by(subID) %>%
  mutate(zconf = scale(confResp)) %>%
  ungroup() %>%
  group_by(subID, trueCue, congruent) %>%
  summarise(propCorrect = mean(accuracy),
            meanRT = mean(zlogRT),
            meanZConf = mean(zconf)) %>%
  mutate(trueCue = factor(trueCue, levels=c(0.5, 0.8), labels=c('50% cue', '80% cue')))

groupSummary_bar <- inferenceData_tidy %>%
  group_by(subID) %>%
  mutate(zconf = scale(confResp)) %>%
  ungroup() %>%
  group_by(trueCue, congruent) %>%
  summarise(propCorrect = mean(accuracy),
            accuracy_sem = sd(accuracy) / sqrt(nSubs),
            meanRT = mean(zlogRT),
            RT_sem = sd(zlogRT) / sqrt(nSubs),
            meanZConf = mean(zconf),
            ZConf_sem = sd(zconf)/sqrt(nSubs)) %>%
  mutate(trueCue = factor(trueCue, levels=c(0.5, 0.8), labels=c('50% cue', '80% cue')))

ggplot(groupSummary_bar, aes(x=trueCue, y=propCorrect, fill=congruent)) +
  ylim(0,1) +
  theme_classic() + 
  geom_hline(yintercept=0.5, linewidth=0.15) +
  geom_col(position = position_dodge(width=0.25), width = 0.25) +
  geom_errorbar(aes(ymin=propCorrect - accuracy_sem, ymax = propCorrect + accuracy_sem), width=0.1, 
                position = position_dodge(width=0.25)) +
  geom_point(size=4, shape=8, color='gray20',position = position_dodge(width=0.25) ) +
  geom_point(aes(color=congruent), data=inferenceSummary_bar, position=position_jitterdodge(dodge.width=0.25, jitter.width = 0.1), 
             color='gray20', shape=21, size=2, alpha=0.75)









inferenceData_tidy$congruent <- factor(inferenceData_tidy$congruent, levels=c('neutral', 'congruent', 'incongruent'))
inferenceSummary_cong <- inferenceData_tidy %>% 
  group_by(congruent) %>%
  summarise(propCorrect = mean(accuracy),
            sem = sd(accuracy)/sqrt(nSubs),
            meanRT = mean(zlogRT),
            RT_sem = sd(zlogRT)/sqrt(nSubs),
            meanConf = mean(confResp),
            conf_sem = sd(confResp)/sqrt(nSubs))
  
inferenceSummary_sub <- inferenceData_tidy %>%
  group_by(subID, congruent) %>%
  summarise(propCorrect = mean(accuracy),
            meanRT = mean(zlogRT),
            meanConf = mean(confResp))

ggplot(inferenceSummary_cong, aes(x=congruent, y=propCorrect)) +
  geom_col()

########### let's get distributional (plotting RT distributions) ########### 
inferenceData_tidy %>%
  group_by(congruent) %>%
  ggplot(aes(x=RT, color=congruent, fill=congruent)) +
  theme_classic() +
  geom_density(fill=NA, linewidth=1) +
  ggtitle('RT distributions') +
  theme(plot.title = element_text(hjust=0.5)) # center the title 
ggsave(paste0(outdir, 'RT_distributions.png'), width=6, height=4)

# individual-level distributions ---- ARI PICK UP HERE
inferenceData_tidy %>%
  group_by(congruent) %>%
  ggplot(aes(x=respPeriod, color=congruent, fill=congruent)) +
  geom_histogram(aes(y=..density..), alpha=0.15, position='identity') +
  theme_classic()
ggsave(paste0(outdir, 'responsePeriod_distributions.png'), width=6, height=4)

inferenceData_tidy %>%
  filter(pilotGroup=='group2') %>%
  ggplot(aes(x=confResp, color=congruent)) +
  facet_wrap(~subID, nrow=2) +
  geom_density(fill=NA, linewidth=1) +
  theme_classic()




####################################### TIME VARYING SUMMARIES ####################################### 
firstNoise_summary <- inferenceData_tidy %>%
  group_by(firstNoise_quartile, cueLevel, pilotGroup, congruent) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T),
            accuracy_sem = sd(accuracy, na.rm=T)/sqrt(8),
            meanRT = mean(zlogRT),
            RT_sem = sd(zlogRT)/sqrt(8),
            avgConf = mean(confResp, na.rm=T),
            conf_sem = sd(confResp)/sqrt(8))

f1 <- firstNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=firstNoise_quartile, y=propCorrect, color=cueLevel)) +
  geom_hline(yintercept = 0.5) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=propCorrect-accuracy_sem, ymax=propCorrect+accuracy_sem)) + 
  geom_line()

f2 <- firstNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=firstNoise_quartile, y=meanRT, color=cueLevel)) +
  geom_hline(yintercept = 0) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=meanRT-RT_sem, ymax=meanRT+RT_sem)) + 
  geom_line() +
  labs(y='z-scored log RTs')

firstNoisePlots <- f1 + f2 
firstNoisePlots + plot_annotation(title = 'accuracy & RT as a function of first noise duration') + plot_layout(guides = 'collect')
ggsave(paste0(outdir, 'noise1_summary.png'), width=8, height=4)


secondNoise_summary <- inferenceData_tidy %>%
  group_by(secondNoise_quartile, cueLevel, pilotGroup, congruent) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T),
            accuracy_sem = sd(accuracy, na.rm=T)/sqrt(8),
            meanRT = mean(zlogRT),
            RT_sem = sd(zlogRT)/sqrt(8),
            avgConf = mean(confResp, na.rm=T),
            conf_sem = sd(confResp)/sqrt(8))

f1 <- secondNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=secondNoise_quartile, y=propCorrect, color=cueLevel)) +
  geom_hline(yintercept = 0.5) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=propCorrect-accuracy_sem, ymax=propCorrect+accuracy_sem)) + 
  geom_line()

f2 <- secondNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=secondNoise_quartile, y=meanRT, color=cueLevel)) +
  geom_hline(yintercept = 0) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=meanRT-RT_sem, ymax=meanRT+RT_sem)) + 
  geom_line() +
  labs(y='z-scored log RTs')

secondNoisePlots <- f1 + f2 
secondNoisePlots + plot_annotation(title = 'accuracy & RT as a function of second noise duration') + plot_layout(guides = 'collect')
ggsave(paste0(outdir, 'noise2_summary.png'), width=8, height=4)

totalNoise_summary <- inferenceData_tidy %>%
  group_by(totalNoise_quartile, cueLevel, pilotGroup, congruent) %>%
  summarise(propCorrect = mean(accuracy, na.rm=T),
            accuracy_sem = sd(accuracy, na.rm=T)/sqrt(8),
            meanRT = mean(zlogRT),
            RT_sem = sd(zlogRT)/sqrt(8),
            avgConf = mean(confResp, na.rm=T),
            conf_sem = sd(confResp)/sqrt(8))

f1 <- totalNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=totalNoise_quartile, y=propCorrect, color=cueLevel)) +
  geom_hline(yintercept = 0.5) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=propCorrect-accuracy_sem, ymax=propCorrect+accuracy_sem)) + 
  geom_line()

f2 <- totalNoise_summary %>%
  filter(pilotGroup == 'group2') %>%
  mutate(cueLevel = factor(cueLevel)) %>%
  ggplot(aes(x=totalNoise_quartile, y=meanRT, color=cueLevel)) +
  geom_hline(yintercept = 0) + 
  theme_classic() + 
  geom_pointrange(aes(ymin=meanRT-RT_sem, ymax=meanRT+RT_sem)) + 
  geom_line() +
  labs(y='z-scored log RTs')

totalNoisePlots <- f1 + f2 
totalNoisePlots + plot_annotation(title = 'accuracy & RT as a function of total noise duration') + plot_layout(guides = 'collect')
ggsave(paste0(outdir, 'noise2_summary.png'), width=8, height=4)