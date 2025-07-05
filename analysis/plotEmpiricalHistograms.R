library(tidyverse)
library(patchwork)
library(emmeans)

# load data
outdir <- 'empirical_histograms/'
inference_df <- read.csv('inference_tidy.csv')

find_mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

noise1_mode <- find_mode(inference_df$noise1duration)
noise2Onset_mode <- find_mode(inference_df$noise2_onset[inference_df$noise2_onset > 0])
signal2Onset_mode <- find_mode(inference_df$signal2_onset[inference_df$signal2_onset > 0])

for (subject in 1:length(unique(inference_df$subID))) {
  # get subject-specific noise info
  
  df <- inference_df %>% filter(subID == unique(inference_df$subID)[subject])
  noise1_mode <- find_mode(df$noise1duration)
  noise2Onset_mode <- find_mode(df$noise2_onset[df$noise2_onset > 0])
  signal2Onset_mode <- find_mode(df$signal2_onset[df$signal2_onset > 0])
  
  # plot
  ggplot() +
    theme_bw() +
    annotate('rect', xmin=0, xmax=noise1_mode, ymin=-1, ymax=1, alpha=0.25, fill='lightblue') + 
    annotate('rect', xmin=noise2Onset_mode, xmax=signal2Onset_mode, ymin=-1, ymax=1, alpha=0.25, fill='lightblue') +
    geom_density(data = df %>% filter(accuracy == 1), aes(x=RT, y=after_stat(density), group=trueCue, color=factor(trueCue))) +
    geom_density(data = df %>% filter(accuracy == 0), aes(x=RT, y=-after_stat(density), group=trueCue, color=factor(trueCue))) +
    geom_density(data = df %>% filter(accuracy == 1), aes(x=RT, y=after_stat(density)), linewidth=1) +
    geom_density(data = df %>% filter(accuracy == 0), aes(x=RT, y=-after_stat(density)), linewidth=1) +
    scale_y_continuous(name = "scaled density", labels = function(x) abs(x), n.breaks = 6) +
    geom_hline(yintercept = 0, linetype = "solid", color = "black") +
    labs(title = paste0('subject ', unique(inference_df$subID)[subject]), subtitle = 'boxes=mode noise durations', x='RT (s)') +
    xlim(0,4)
  
  ggsave(paste0(outdir, 's', unique(inference_df$subID)[subject], '.png'), width=5, height=3)
}
