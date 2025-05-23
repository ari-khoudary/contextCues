library(tidyverse)
library(patchwork)

# load in fits
#startPoint_freeNDT <- read.csv('../pyDDM/cluster_fitting/startPoint_freeNDT/results/fits.csv')
startPoint_0ndt <- read.csv('../pyDDM/cluster_fitting/startPoint_0ndt/results/fits.csv')
startPoint_uniform <- read.csv('../pyDDM/cluster_fitting/startPoint_uniform/results/fits.csv')
signedCue_fixedCoh <- read.csv('../pyDDM/cluster_fitting/signedCue_0ndt_0.7coh/results/fits.csv')
signedCue_freeCoh <- read.csv('../pyDDM/cluster_fitting/signedCue_0ndt_freeCoh/results/fits.csv')
subjectiveCue <- read.csv('../pyDDM/cluster_fitting/subjectiveCue_0ndt_0.7coh/results/fits.csv')
fourDrift_congIncong <- read.csv('../pyDDM/cluster_fitting/4drifts_0ndt_congIncong/results/fits.csv')
fourDrift <- read.csv('../pyDDM/cluster_fitting/4drifts_0ndt/results/fits.csv')
startPoint_freeDrift <- read.csv('../pyDDM/cluster_fitting/startPoint_uniform_wDrift/results/fits.csv')


#startPoint_freeNDT <- startPoint_freeNDT %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params)
startPoint_0ndt <- startPoint_0ndt %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params)
startPoint_uniform <- startPoint_uniform %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params)
signedCue_fixedCoh <- signedCue_fixedCoh %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params)
signedCue_freeCoh <- signedCue_freeCoh %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params)
subjectiveCue <- subjectiveCue %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params)
fourDrift_congIncong <- fourDrift_congIncong %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params)
fourDrift <- fourDrift %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params)
startPoint_freeDrift <- startPoint_freeDrift %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params)

#### plot performance for all subjects ####
d2 <- startPoint_0ndt %>% select(subID, model, BIC, AIC, n_params)
d3 <- startPoint_uniform %>% select(subID, model, BIC, AIC, n_params)
d4 <- signedCue_fixedCoh %>% select(subID, model, BIC, AIC, n_params)
d5 <- subjectiveCue %>% select(subID, model, BIC, AIC, n_params)
d6 <- fourDrift_congIncong %>% select(subID, model, BIC, AIC, n_params)
d7 <- fourDrift %>% select(subID, model, BIC, AIC, n_params)
d8 <- signedCue_freeCoh %>% select(subID, model, BIC, AIC, n_params)
d9 <- startPoint_freeDrift %>% select(subID, model, BIC, AIC, n_params)


allBICs <- rbind(d3, d4, d5, d6, d7, d8, d9)

performance_summary <- allBICs %>%
  group_by(model) %>%
  summarise(BIC = sum(BIC),
            AIC = sum(AIC),
            n_params = unique(n_params)) %>%
  pivot_longer(cols = c(AIC, BIC), names_to = 'metric', values_to = 'score')

performance_summary %>%
  ggplot(aes(x=model, y=score)) +
  facet_wrap(~ metric) +
  theme_bw() + geom_hline(yintercept = 0) +
  stat_summary(aes(fill=model), fun = 'sum', geom='col') +
  theme(axis.text.x = element_blank()) +
  geom_label(label = performance_summary$n_params)

p2 <- performance_summary %>%
  ggplot(aes(x=model, y=AIC)) +
  theme_bw() + geom_hline(yintercept = 0) +
  stat_summary(aes(fill=model), fun = 'sum', geom='col') +
  theme(axis.text.x = element_blank()) +
  geom_label(label = performance_summary$n_params)

p1 + p2 + plot_layout(guides = 'collect')
ggsave('results_april2025/modelcomparison_allSubjects_3paramSP.png', width=10, height=4)



#### performance only for above chance subjects ####
inference_data <- read.csv('../tidied_data/all_conditions/inference.csv')
subs_to_exclude <- inference_data %>% filter(subID > 0) %>%
  group_by(subID) %>% summarise(propCorrect = mean(accuracy, na.rm=T)) %>%
  filter(propCorrect < 0.51) 

d2 <- d2 %>% filter(subID != c(subs_to_exclude$subID)) %>% select(subID, model, BIC, AIC, n_params)
d3 <- d3 %>% filter(subID != c(subs_to_exclude$subID)) %>% select(subID, model, BIC, AIC, n_params)
d4 <- d4 %>% filter(subID != c(subs_to_exclude$subID)) %>% select(subID, model, BIC, AIC, n_params)
d5 <- d5 %>% filter(subID != c(subs_to_exclude$subID)) %>% select(subID, model, BIC, AIC, n_params)
d6 <- d6 %>% filter(subID != c(subs_to_exclude$subID)) %>% select(subID, model, BIC, AIC, n_params)
d7 <- d7 %>% filter(subID != c(subs_to_exclude$subID)) %>% select(subID, model, BIC, AIC, n_params)
d8 <- d8 %>% filter(subID != c(subs_to_exclude$subID)) %>% select(subID, model, BIC, AIC, n_params)


allBICs <- rbind(d3, d4, d5, d6, d7, d8)
performance_summary <- allBICs %>%
  group_by(model) %>%
  summarise(BIC = sum(BIC),
            AIC = sum(AIC),
            n_params = unique(n_params))

p1 <- performance_summary %>%
  ggplot(aes(x=model, y=BIC)) +
  theme_bw() + geom_hline(yintercept = 0) +
  stat_summary(aes(fill=model), fun = 'sum', geom='col') +
  theme(axis.text.x = element_blank()) +
  geom_label(label = performance_summary$n_params)

p2 <- performance_summary %>%
  ggplot(aes(x=model, y=AIC)) +
  theme_bw() + geom_hline(yintercept = 0) +
  stat_summary(aes(fill=model), fun = 'sum', geom='col') +
  theme(axis.text.x = element_blank()) +
  geom_label(label = performance_summary$n_params)

p1 + p2 + plot_layout(guides = 'collect')

ggsave('results_april2025/performance_aboveChanceSubs.png', width=8, height=3)
