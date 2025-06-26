library(tidyverse)
library(lmerTest)
library(lme4)
library(emmeans)
library(performance)

# load & tidy fits
startPoint_freeDrift <- read.csv('../../pyDDM/cluster_fitting/testTrial_fits/startPoint_uniform_wDrift/results/fits.csv')
fourDrift_congIncong <- read.csv('../../pyDDM/cluster_fitting/testTrial_fits/4drifts_0ndt_congIncong/results/fits.csv')

fourDrift_congIncong <- fourDrift_congIncong %>% 
  mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params) 
startPoint_freeDrift <- startPoint_freeDrift %>% 
  mutate(BIC = -2*loss + n_params*log(sample_size), AIC = -2*loss + 2*n_params)

# delta BIC
sum(fourDrift_congIncong$BIC) - sum(startPoint_freeDrift$BIC)

# t-test on drifts
df <- fourDrift_congIncong %>% 
  select(noise2_cong_fitted, noise2_neut_fitted, noise2_incong_fitted) %>%
  mutate(noise2_cue = noise2_cong_fitted + noise2_incong_fitted)

sum(df$noise2_cue) - sum(df$noise2_neut_fitted)

t.test(df$noise2_cue, df$noise2_neut_fitted, var.equal = TRUE, alternative = 'greater')
t.test(df$noise2_cue, df$noise2_neut_fitted, var.equal = FALSE)



#### OLD ####
# plot all
fits_longer %>%
  mutate(parameter = factor(parameter, levels=c('noise1_cong', 'noise1_neut', 'signal1_cong', 'signal1_incong', 'signal1_neut',
                                                'noise2_cong', 'noise2_incong', 'noise2_neut', 'signal2_cong', 'signal2_incong','signal2_neut',
                                                'B'))) %>%
  ggplot(aes(x=parameter, y=value)) +
  theme_bw() + facet_wrap(~condition) +
  stat_summary(aes(fill=condition), fun.y = 'mean', geom='col') +
  stat_summary(fun.data = 'mean_se', geom='pointrange') +
  scale_fill_manual(values = c('gray70', 'gray30')) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),
        axis.title.x = element_blank(),
        legend.position = 'none') + 
  ggtitle('Model: 4drifts_0ndt_congIncong')
ggsave('results_april2025/4drifts_0ndt_congIncong/allFits.png', width=10, height=3.5, dpi='retina')

# plot noise2 as bars
fits_longer %>%
  filter(parameter %in% c('noise2_cong', 'noise2_incong', 'noise2_neut')) %>%
  mutate(condition = factor(condition, levels=c('condition_80cue', 'condition_65cue'),
                            labels = c('80% vs. 50% (n=22)', '65% vs 50% (n=22)')),
         parameter = factor(parameter, labels = c('congruent', 'incongruent', 'neutral'))) %>%
  filter(subID != 59) %>%
  ggplot(aes(x=parameter, y=value)) +
  theme_bw() + 
  facet_wrap(~condition) +
  geom_hline(yintercept = 0) +
  stat_summary(aes(fill=condition), fun.y = 'mean', geom='col') +
  geom_point(color='gray', alpha=0.75) +
  geom_line(aes(group=subID), linewidth=0.2, color='gray', alpha=0.75) +
  stat_summary(fun.data = 'mean_se', geom='errorbar', width=0.2) +
  stat_summary(aes(group=condition), fun = 'mean', geom = 'line', linewidth=0.5) +
  stat_summary(aes(group=condition), fun = 'mean', geom = 'point', size=3) +
  scale_fill_manual(values = c('forestgreen', 'lightgreen')) +
  theme(axis.title.x = element_blank(),
        strip.background = element_rect(fill = 'white'),
        strip.text = element_text(size=14, face='bold'),
        axis.text.x = element_text(size=14),
        axis.title.y = element_text(size=14),
        legend.position = 'none') +
  labs(y = 'noise2 drift')
ggsave(paste0(outdir, 'noise2bars_withSubs.png'), width=8, height=3.5, dpi='retina')

# plot noise1 as bars
fits_longer %>%
  filter(parameter %in% c('noise1_cong', 'noise1_neut')) %>%
  mutate(condition = factor(condition, levels=c('condition_80cue', 'condition_65cue'),
                            labels = c('80% vs. 50% (n=22)', '65% vs 50% (n=22)')),
         parameter = factor(parameter, labels = c('informative', 'neutral'))) %>%
  ggplot(aes(x=parameter, y=value)) +
  theme_bw() + 
  facet_wrap(~condition) +
  geom_hline(yintercept = 0) +
  stat_summary(aes(fill=condition), fun.y = 'mean', geom='col') +
  geom_point(color='gray', alpha=0.75) +
  geom_line(aes(group=subID), linewidth=0.2, color='gray', alpha=0.75) +
  stat_summary(fun.data = 'mean_se', geom='errorbar', width=0.2) +
  stat_summary(aes(group=condition), fun = 'mean', geom = 'line', linewidth=0.5) +
  stat_summary(aes(group=condition), fun = 'mean', geom = 'point', size=3) +
  scale_fill_manual(values = c('forestgreen', 'lightgreen')) +
  theme(axis.title.x = element_blank(),
        strip.background = element_rect(fill = 'white'),
        strip.text = element_text(size=14, face='bold'),
        axis.text.x = element_text(size=14),
        axis.title.y = element_text(size=14),
        legend.position = 'none') + 
  labs(y = 'noise1 drift')
ggsave(paste0(outdir, 'noise1bars.png'), width=8, height=3.5, dpi='retina')

# plot epoch means
plot_param_means(fits_longer, c('noise1_cong', 'noise1_neut'))
ggsave('results_april2025/4drifts_0ndt_congIncong/noise1.png', width=5, height=3.5, dpi='retina')

plot_param_means(fits_longer, c('signal1_cong', 'signal1_neut', 'signal1_incong'))
ggsave('results_april2025/4drifts_0ndt_congIncong/signal1.png', width=7, height=3.5, dpi='retina')

plot_param_means(fits_longer, c('noise2_cong', 'noise2_neut', 'noise2_incong'))
ggsave('results_april2025/4drifts_0ndt_congIncong/noise2.png', width=7, height=3.5, dpi='retina')

plot_param_means(fits_longer, c('signal2_cong', 'signal2_neut', 'signal2_incong'))
ggsave('results_april2025/4drifts_0ndt_congIncong/signal2.png', width=7, height=3.5, dpi='retina')

subIDs <- fits_longer %>% filter()

#### t tests ####
# within condition - 80cue
noise1_80 <- fourDrift_congIncong %>% filter(condition=='condition_80cue') %>% select(noise1_cong_fitted)
noise1_50 <- fourDrift_congIncong %>% filter(condition=='condition_80cue') %>% select(noise1_neut_fitted)
t.test(noise1_80, noise1_50)

# within condition - 65 cue
noise1_80 <- fourDrift_congIncong %>% filter(condition=='condition_65cue') %>% select(noise1_cong_fitted)
noise1_50 <- fourDrift_congIncong %>% filter(condition=='condition_65cue') %>% select(noise1_neut_fitted)
t.test(noise1_80, noise1_50)

# across conditions
noise1_80 <- fourDrift_congIncong %>% select(noise1_cong_fitted)
noise1_50 <- fourDrift_congIncong %>% select(noise1_neut_fitted)
t.test(noise1_80, noise1_50)

## second noise ##
# within condition - 80cue
noise2_80 <- fourDrift_congIncong %>% filter(condition=='condition_80cue') %>% select(noise2_cong_fitted)
noise2_50 <- fourDrift_congIncong %>% filter(condition=='condition_80cue') %>% select(noise2_neut_fitted)
noise2_20 <- fourDrift_congIncong %>% filter(condition=='condition_80cue') %>% select(noise2_incong_fitted)
t.test(noise2_80)

# within condition - 65 cue
noise1_80 <- fourDrift_congIncong %>% filter(condition=='condition_65cue') %>% select(noise1_cong_fitted)
noise1_50 <- fourDrift_congIncong %>% filter(condition=='condition_65cue') %>% select(noise1_neut_fitted)
t.test(noise1_80, noise1_50)

# across conditions
noise2_80 <- fourDrift_congIncong %>% select(noise2_cong_fitted)
noise2_50 <- fourDrift_congIncong %>% select(noise2_neut_fitted)
noise2_20 <- fourDrift_congIncong %>% select(noise2_incong_fitted)

t.test(noise2_80)
t.test(noise2_50)
t.test(noise2_20)


##### sfn test: cong + incong vs. neutral
fourDrift_congIncong %>% 
  select(noise2_cong_fitted, noise2_neut_fitted, noise2_incong_fitted, subID) %>%
  group_by(subID) %>%
  t.test(paired=TRUE)
  

