library(tidyverse)
library(patchwork)

# load in fits
fourDrift_congIncong <- read.csv('../pyDDM/cluster_fitting/testTrial_fits/4drifts_0ndt_congIncong/results/fits.csv')
startPoint_freeDrift <- read.csv('../pyDDM/cluster_fitting/testTrial_fits/startPoint_uniform_wDrift/results/fits.csv')
fourDrift_twoBounds <- read.csv('../pyDDM/cluster_fitting/testTrial_fits/4drift_congIncong_2bound/results/fits.csv')
fourDrift_threeBounds <- read.csv('../pyDDM/cluster_fitting/testTrial_fits/4drift_congIncong_3bound/results/fits.csv')
fourDrift <- read.csv('../pyDDM/cluster_fitting/testTrial_fits/4drifts_0ndt/results/fits.csv')

# add 
fourDrift <- fourDrift %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params,
                                 model = 'fourDrift') 
fourDrift_congIncong <- fourDrift_congIncong %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params,
                                                        model = 'fourDrift_congIncong') 
startPoint_freeDrift <- startPoint_freeDrift %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params,
                                                        model = 'uniformStart_freeDrift')
fourDrift_twoBounds <- fourDrift_twoBounds %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params,
                                                      model = 'fourDrift_congIncong_trueCue')
fourDrift_threeBounds <- fourDrift_threeBounds %>% mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params,
                                                          model = 'fourDrift_congIncong_cueIdx')

#### plot performance for all subjects ####
d0 <- fourDrift %>% select(subID, model, BIC, AIC, n_params)
d1 <- fourDrift_congIncong %>% select(subID, model, BIC, AIC, n_params)
d2 <- startPoint_freeDrift %>% select(subID, model, BIC, AIC, n_params)
d3 <- fourDrift_twoBounds %>% select(subID, model, BIC, AIC, n_params)
d4 <- fourDrift_threeBounds %>% select(subID, model, BIC, AIC, n_params)

allBICs <- rbind(d0, d1, d2, d3, d4)

performance_summary <- allBICs %>%
  group_by(model) %>%
  summarise(BIC = sum(BIC),
            AIC = sum(AIC),
            n_params = unique(n_params)) %>%
  pivot_longer(cols = c(AIC, BIC), names_to = 'metric', values_to = 'score')

performance_summary %>%
  ggplot(aes(x=model, y=score)) +
  facet_wrap(~ metric, scales='free') +
  theme_bw() + geom_hline(yintercept = 0) +
  stat_summary(aes(fill=model), fun = 'sum', geom='col') +
  theme(axis.text.x = element_blank()) +
  geom_label(label = performance_summary$n_params)

ggsave('results_summer2025/modelComparison_freeThresholds.png', width=10, height=3.5, dpi='retina')

#### BIC preferences by subject ####
## load in estimates to color by cueCorr

estimates <- read.csv('../tidied_data/all_conditions/estimates.csv') %>%
  group_by(subID) %>%
  mutate(cueCorr = cor(trueCue, subjectiveCue)) %>%
  select(c(subID, cueCorr))

allBICs %>%
  filter(model == 'fourDrift' | model == 'fourDrift_congIncong_cueIdx') %>%
  select(subID, model, BIC) %>%
  pivot_wider(id_cols = subID, values_from = BIC, names_from = model) %>%
  mutate(bic_diff = fourDrift_congIncong_cueIdx - fourDrift) %>%
  left_join(., estimates, by='subID') %>%
  unique() %>%
  ggplot(aes(x=subID, y=bic_diff, fill=cueCorr)) +
  theme_bw() + scale_fill_gradient2() + geom_hline(yintercept = 0) +
  geom_col(color='gray20') + 
  scale_x_continuous(breaks = unique(allBICs$subID)) +
  labs(title = 'bic_diff = BIC_fourDrift_congIncong_cueIdx - BIC_fourDrift',
       subtitle = 'positive values = better fit by fourDrift; negative values = better fit by fourDrift_congIncong_cueIdx')

ggsave('results_summer2025/modelComparison_bySubject_withCueCorr.png', width = 10, height=3.5, dpi='retina')

#### plot BIC for above-chance subjects only ####
estimates <- read.csv('../tidied_data/all_conditions/inference.csv') 
propCorrect <- estimates %>% group_by(subID) %>% summarise(propCorrect = mean(accuracy, na.rm=T))
aboveChance_subs <- propCorrect %>% filter(propCorrect > 0.52) %>% select(subID)

performance_summary <- allBICs %>%
  filter(subID %in% aboveChance_subs$subID) %>%
  group_by(model) %>%
  summarise(BIC = sum(BIC),
            AIC = sum(AIC),
            n_params = unique(n_params)) %>%
  pivot_longer(cols = c(AIC, BIC), names_to = 'metric', values_to = 'score')

performance_summary %>%
  ggplot(aes(x=model, y=score)) +
  facet_wrap(~ metric, scales='free') +
  theme_bw() + geom_hline(yintercept = 0) +
  stat_summary(aes(fill=model), fun = 'sum', geom='col') +
  theme(axis.text.x = element_blank()) +
  geom_label(label = performance_summary$n_params) +
  labs(title = 'performance on above-chance subjects only')
ggsave('results_summer2025/modelComparison_freeThresholds_tidy.png', width=10, height=3.5, dpi='retina')
