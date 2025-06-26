library(tidyverse)
library(patchwork)

# get cueCorr value for each subject
estimates <- read.csv('../tidied_data/all_conditions/estimates.csv')
cueCorrs <- estimates %>%
  group_by(subID) %>%
  mutate(cueCorr = cor(trueCue, subjectiveCue),
         condition = ifelse(subID < 55, 'condition_80cue', 'condition_65cue')) %>%
  filter(is.na(cueCorr)==0) %>%
  select(subID, cueCorr, condition) %>%
  unique()

#### helper functions
# elongate fits
tidy_fits <- function(df) {
  fits_longer <- df %>%
    # Select columns that don't end with "_min" or "_max" to avoid those columns
    select(-ends_with("_min"), -ends_with("_max")) %>%
    # Pivot longer all columns that end with "_fitted"
    pivot_longer(
      cols = ends_with("_fitted"),
      names_to = "parameter",
      values_to = "value"
    ) %>%
    # Remove the "_fitted" suffix from the parameter names
    mutate(parameter = gsub("_fitted$", "", parameter))
  return(fits_longer)
}

# plot individual parameters
plot_param_means <- function(data, parameters_to_filter) {
  p <- ggplot(
    data = data %>% filter(parameter %in% parameters_to_filter),
    mapping = aes(x = parameter, y = value)) +
    theme_bw() + 
    facet_wrap(~condition) +
    geom_boxplot(outliers = FALSE) +
    geom_point(aes(color = cueCorr), size=2) +
    geom_line(aes(group = subID, color = cueCorr), size = 0.25, alpha = 0.5) +
    scale_color_gradient2()
  return(p)
}

#### 4drifts_0ndt ####
# read in fit CSV, add cueCorr
fits <- read.csv('../pyDDM/cluster_fitting/testTrial_fits/4drifts_0ndt/results/fits.csv') %>%
  left_join(., cueCorrs)

plot_param_means(tidy_fits(fits), c('noise1', 'noise1_50'))
ggsave('results_april2025/4drifts_0ndt/noise1.png', width=5, height=3.5, dpi='retina')

plot_param_means(fits_longer, c('signal1', 'signal1_50'))
ggsave('results_april2025/4drifts_0ndt/signal1.png', width=5, height=3.5, dpi='retina')

plot_param_means(fits_longer, c('noise2', 'noise2_50'))
ggsave('results_april2025/4drifts_0ndt/noise2.png', width=5, height=3.5, dpi='retina')

plot_param_means(fits_longer, c('signal2', 'signal2_50')) 
ggsave('results_april2025/4drifts_0ndt/signal2.png', width=5, height=3.5, dpi='retina')

plot_param_means(fits_longer, c('B')) 
ggsave('results_april2025/4drifts_0ndt/bound.png', width=5, height=3.5, dpi='retina')

tidy_fits(fits) %>%
  mutate(parameter = factor(parameter, levels=c('noise1', 'noise1_50', 'signal1', 'signal1_50',
                                                'noise2', 'noise2_50', 'signal2', 'signal2_50',
                                                'B'))) %>%
  ggplot(aes(x=parameter, y=value)) +
  theme_bw() + facet_wrap(~condition) +
  stat_summary(aes(fill=condition), fun.y = 'mean', geom='col') +
  stat_summary(fun.data = 'mean_se', geom='pointrange') +
  scale_fill_manual(values = c('gray70', 'gray30')) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),
        axis.title.x = element_blank()) +
  ggtitle('Model: 4drifts_0ndt')
ggsave('results_april2025/4drifts_0ndt/allFits.png', width=8, height=3.5, dpi='retina')

tidy_fits(fits) %>%
  filter(parameter %in% c('noise2', 'noise2_50')) %>%
  ggplot(aes(x=parameter, y=value)) +
  theme_bw() + facet_wrap(~condition) +
  stat_summary(aes(fill=condition), fun.y = 'mean', geom='col') +
  stat_summary(fun.data = 'mean_se', geom='pointrange') +
  scale_fill_manual(values = c('gray70', 'gray40')) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),
        axis.title.x = element_blank()) + ggtitle('Model: 4drifts_0ndt')
ggsave('results_april2025/4drifts_0ndt/noise2bars.png', width=6, height=3.5, dpi='retina')


#### 4drifts_0ndt_congIncong ####
fits <- read.csv('../pyDDM/cluster_fitting/testTrial_fits/4drifts_0ndt_congIncong/results/fits.csv') %>%
  left_join(., cueCorrs)
fits_longer <- tidy_fits(fits)

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
        axis.title.x = element_blank()) + ggtitle('Model: 4drifts_0ndt_congIncong')
ggsave('results_april2025/4drifts_0ndt_congIncong/allFits.png', width=8, height=3.5, dpi='retina')

# plot noise2 as bars
fits_longer %>%
  filter(parameter %in% c('noise2_cong', 'noise2_incong', 'noise2_neut')) %>%
  ggplot(aes(x=parameter, y=value)) +
  theme_bw() + facet_wrap(~condition) +
  stat_summary(aes(fill=condition), fun.y = 'mean', geom='col') +
  stat_summary(fun.data = 'mean_se', geom='pointrange') +
  scale_fill_manual(values = c('gray70', 'gray40')) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),
        axis.title.x = element_blank()) + ggtitle('Model: 4drifts_0ndt_congIncong')
ggsave('results_april2025/4drifts_0ndt_congIncong/noise2bars.png', width=6, height=3.5, dpi='retina')

# plot epoch means
plot_param_means(fits_longer, c('noise1_cong', 'noise1_neut'))
ggsave('results_april2025/4drifts_0ndt_congIncong/noise1.png', width=5, height=3.5, dpi='retina')

plot_param_means(fits_longer, c('signal1_cong', 'signal1_neut', 'signal1_incong'))
ggsave('results_april2025/4drifts_0ndt_congIncong/signal1.png', width=7, height=3.5, dpi='retina')

plot_param_means(fits_longer, c('noise2_cong', 'noise2_neut', 'noise2_incong'))
ggsave('results_april2025/4drifts_0ndt_congIncong/noise2.png', width=7, height=3.5, dpi='retina')

plot_param_means(fits_longer, c('signal2_cong', 'signal2_neut', 'signal2_incong'))
ggsave('results_april2025/4drifts_0ndt_congIncong/signal2.png', width=7, height=3.5, dpi='retina')


#### plot binned fits ####
# simple 4 drift
fits <- read.csv('../pyDDM/cluster_fitting/testTrial_fits/4drifts_shortSig1/results/fits.csv') %>%
  left_join(., cueCorrs)
fits_longer <- tidy_fits(fits)

fits_longer %>%
  filter(parameter %in% c('noise2', 'noise2_50', 'noise2_shortS1', 'noise2_50_shortS1')) %>%
  ggplot(aes(x=parameter, y=value)) +
  theme_bw() + facet_wrap(~condition) +
  stat_summary(aes(fill=condition), fun.y = 'mean', geom='col') +
  stat_summary(fun.data = 'mean_se', geom='pointrange') +
  scale_fill_manual(values = c('gray70', 'gray40')) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),
        axis.title.x = element_blank()) + 
  labs(title = 'Model: 4drifts binned by Signal1 length', subtitle = 'ShortS1 = S1 < 0.61ms')
ggsave('results_april2025/binned_fits/4drift.png', width=7, height=3.5, dpi='retina')


# congInccong
fits <- read.csv('../pyDDM/cluster_fitting/testTrial_fits/4drifts_congIncong_shortSig1/results/fits.csv') %>%
  left_join(., cueCorrs)
fits_longer <- tidy_fits(fits)

fits_longer %>%
  filter(parameter %in% c('noise2_cong', 'noise2_incong', 'noise2_neut',
  'noise2_cong_shortS1', 'noise2_incong_shortS1', 'noise2_neut_shortS1')) %>%
  mutate(parameter = factor(parameter, levels=c('noise2_cong', 'noise2_cong_shortS1',
                                                'noise2_incong', 'noise2_incong_shortS1',
                                                'noise2_neut', 'noise2_neut_shortS1'))) %>%
  ggplot(aes(x=parameter, y=value)) +
  theme_bw() + facet_wrap(~condition) +
  stat_summary(aes(fill=condition), fun.y = 'mean', geom='col') +
  stat_summary(fun.data = 'mean_se', geom='pointrange') +
  geom_point() +
  geom_line(aes(group=subID), linewidth=0.25, color='gray') +
  scale_fill_manual(values = c('gray70', 'gray40')) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),
        axis.title.x = element_blank()) + 
  labs(title = 'Model: 4drifts_congIncong binned by Signal1 length', subtitle = 'ShortS1 = S1 < 0.61ms')
ggsave('results_april2025/binned_fits/4drifts_congIncong_wPoints.png', width=7, height=3.5, dpi='retina')
