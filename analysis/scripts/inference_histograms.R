library(tidyverse)
library(patchwork)

outdir <- 'results_april2025/'
inference <- read.csv('../tidied_data/all_conditions/inference.csv') %>% filter(subID > 0)

# compute cueCorr & cueDiff
inference <- inference %>%
  group_by(subID) %>% 
  mutate(propCorrect = mean(accuracy),
            cueCorr = cor(trueCue,subjectiveCue))

#### accuracy colored by cueCorr ####
inference %>%
  group_by(subID) %>%
  select(subID, propCorrect, cueCorr, condition) %>%
  distinct() %>%
  ggplot(aes(x=subID, y=propCorrect)) +
  geom_hline(yintercept = 0.5) +
  geom_hline(yintercept = 0.7, linetype='dashed') +
  ylim(0,1) +
  geom_segment(aes(x=subID, xend=subID, y=0, yend=propCorrect)) +
  geom_point(aes(shape=condition, fill=cueCorr), size=5, stroke=1, color='gray20') +
  scale_shape_manual(values = c(23, 21)) + scale_fill_gradient2() +
  scale_x_continuous(breaks = unique(inference$subID)) + theme_bw() 
ggsave(paste0(outdir, 'propCorrect_bySubject.png'), width=15, height=4, dpi='retina')


#### individual RT histograms ####
for (subject in 1:length(unique(inference$subID))) {
  
  df <- inference %>% filter(subID == unique(inference$subID)[subject])
  
  ggplot() +
    theme_bw() +
    annotate('rect', xmin=median(df$signal1_onset, na.rm=T), xmax=median(df$noise2_onset, na.rm=T), 
             ymin=-1, ymax=1, alpha=0.25, fill='lightblue') + 
    annotate('rect', xmin=median(df$signal2_onset, na.rm=T), xmax=(median(df$signal2_onset, na.rm=T) + max(df$signal2_duration, na.rm=T)), 
             ymin=-1, ymax=1, alpha=0.25, fill='lightpink') +
    annotate('rect', xmin=median(df$signal2_onset, na.rm=T), xmax=(median(df$signal2_onset, na.rm=T) + median(df$signal2_duration, na.rm=T)), 
             ymin=-1, ymax=1, alpha=0.25, fill='lightblue') +
    geom_density(data = df %>% filter(accuracy == 1), aes(x=RT, y=after_stat(density), group=trueCongruence, color=factor(trueCongruence)), linewidth=0.75) +
    geom_density(data = df %>% filter(accuracy == 0), aes(x=RT, y=-after_stat(density), group=trueCongruence, color=factor(trueCongruence)), linewidth=0.75) +
    #geom_density(data = inference %>% filter(accuracy == 1), aes(x=RT, y=after_stat(density)), linewidth=0.5) +
    #geom_density(data = inference %>% filter(accuracy == 0), aes(x=RT, y=-after_stat(density)), linewidth=0.5) +
    scale_y_continuous(name = "scaled density", labels = function(x) abs(x), n.breaks = 6) +
    geom_hline(yintercept = 0, linetype = "solid", color = "black") +
    labs(title = paste0('subject ', unique(inference$subID)[subject]), subtitle = 'boxes=median signal durations', x='RT (s)') +
    xlim(0,4) 
  
  ggsave(paste0(outdir, 'individual_RTs_byCongruence/s', unique(inference$subID)[subject], '.png'), width=5, height=3)
  
}

for (subject in 1:length(unique(inference$subID))) {
  # get subject-specific noise info
  
  df <- inference %>% filter(subID == unique(inference$subID)[subject])
  noise1_mode <- find_mode(df$noise1_duration)
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
  
  ggsave(paste0(outdir, 's', unique(inference$subID)[subject], '.png'), width=5, height=3)
}


#### all hists in one figure + group ####
rect_data <- inference %>%
  group_by(subID) %>%
  summarize(
    rect1_xmin = median(signal1_onset, na.rm = TRUE),
    rect1_xmax = median(noise2_onset, na.rm = TRUE),
    rect2_xmin = median(signal2_onset, na.rm = TRUE),
    rect2_xmax = median(signal2_onset, na.rm = TRUE) + max(signal2_duration, na.rm = TRUE),
    rect3_xmin = median(signal2_onset, na.rm = TRUE),
    rect3_xmax = median(signal2_onset, na.rm = TRUE) + median(signal2_duration, na.rm = TRUE)
  )

# Create a single plot with facets
p1 <- ggplot() +
  theme_bw() +
  geom_rect(data = rect_data, aes(xmin = rect1_xmin, xmax = rect1_xmax, ymin = -1, ymax = 1),
            alpha = 0.5, fill = 'lightblue') +
  geom_rect(data = rect_data, aes(xmin = rect2_xmin, xmax = rect2_xmax, ymin = -1, ymax = 1),
            alpha = 0.5, fill = 'lightpink') +
  geom_rect(data = rect_data, aes(xmin = rect3_xmin, xmax = rect3_xmax, ymin = -1, ymax = 1),
            alpha = 0.5, fill = 'lightblue') +
  # Add density plots
  geom_density(data = inference %>% filter(accuracy == 1), aes(x = RT, y = after_stat(density), group = trueCongruence, color = factor(trueCongruence)), linewidth = 0.5) +
  geom_density(data = inference %>% filter(accuracy == 0), aes(x = RT, y = -after_stat(density), group = trueCongruence, color = factor(trueCongruence)), linewidth = 0.5) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  scale_y_continuous(name = "scaled density", labels = function(x) abs(x), n.breaks = 6) +
  xlim(0, 4) +
  facet_wrap(~ subID, nrow=4, labeller = labeller(subID = function(x) paste0("s", x))) +
  theme(strip.text = element_text(size = 10)) +
  labs(title = 'RT densities',
         subtitle = 'blue box = median signal1; second blue/purple box = median signal2; red box = max signal2. sub>54 have 65% cue, else 80% cue', x = 'RT (s)')

p2 <- ggplot() +
  theme_bw() + theme(legend.position = 'none') +
  annotate('rect', xmin=median(inference$signal1_onset, na.rm=T), xmax=median(inference$noise2_onset, na.rm=T), 
           ymin=-1, ymax=1, alpha=0.25, fill='lightblue') + 
  annotate('rect', xmin=median(inference$signal2_onset, na.rm=T), xmax=(median(inference$signal2_onset, na.rm=T) + median(inference$signal2_duration, na.rm=T)), 
           ymin=-1, ymax=1, alpha=0.25, fill='lightblue') +
  geom_density(data = inference %>% filter(accuracy == 1), aes(x=RT, y=after_stat(density), group=trueCongruence, color=factor(trueCongruence)), linewidth=0.75) +
  geom_density(data = inference %>% filter(accuracy == 0), aes(x=RT, y=-after_stat(density), group=trueCongruence, color=factor(trueCongruence)), linewidth=0.75) +
  scale_y_continuous(name = "scaled density", labels = function(x) abs(x), n.breaks = 6) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  labs(title = 'group RTs', subtitle = 'boxes=median signal durations', x='RT (s)') +
  xlim(0,4) #+ facet_wrap(~condition)

p3 <- ggplot() +
  theme_bw() + theme(legend.position = 'none') +
  annotate('rect', xmin=median(inference$signal1_onset, na.rm=T), xmax=median(inference$noise2_onset, na.rm=T), 
           ymin=-1, ymax=1, alpha=0.25, fill='lightblue') + 
  annotate('rect', xmin=median(inference$signal2_onset, na.rm=T), xmax=(median(inference$signal2_onset, na.rm=T) + median(inference$signal2_duration, na.rm=T)), 
           ymin=-1, ymax=1, alpha=0.25, fill='lightblue') +
  geom_density(data = inference %>% filter(accuracy == 1), aes(x=RT, y=after_stat(density), group=trueCongruence, color=factor(trueCongruence)), linewidth=0.75) +
  geom_density(data = inference %>% filter(accuracy == 0), aes(x=RT, y=-after_stat(density), group=trueCongruence, color=factor(trueCongruence)), linewidth=0.75) +
  scale_y_continuous(name = "scaled density", labels = function(x) abs(x), n.breaks = 6) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  labs(title = 'group RTs', subtitle = 'boxes=median signal durations', x='RT (s)') +
  xlim(0,4) + facet_wrap(~condition)

p1 + (p2 / p3) + plot_layout(guides = 'collect', widths = c(5,1))
ggsave(paste0(outdir, 'individualRTs_byCongruence.png'), width=20, height=8)




#### noise2 RTs only ####
p1 <- ggplot() + theme_bw() + xlim(0, 4) +
  geom_density(data = inference %>% filter(accuracy == 1, RT >= noise2_onset, is.na(signal2_onset)==T), 
                                           aes(x = RT, y = after_stat(density), group = trueCongruence, color = factor(trueCongruence)), 
                                           linewidth = 0.5) +
  geom_density(data = inference %>% filter(accuracy == 0, RT >= noise2_onset, is.na(signal2_onset)==T), 
               aes(x = RT, y = -after_stat(density), group = trueCongruence, color = factor(trueCongruence)), linewidth = 0.5) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  scale_y_continuous(name = "scaled density", labels = function(x) abs(x), n.breaks = 4) +
  facet_wrap(~ subID, nrow=4, labeller = labeller(subID = function(x) paste0("s", x)), scales='free_y') +
  theme(strip.text = element_text(size = 10)) +
  labs(title = 'RTs in noise2 only',
       subtitle = 'correct RTs on top, error RTs on bottom', x = 'RT (s)')

p2 <- ggplot() + theme_bw() + xlim(0, 4) +
  geom_density(data = inference %>% filter(accuracy == 1, RT >= noise2_onset, is.na(signal2_onset)==T), 
               aes(x = RT, y = after_stat(density), group = trueCongruence, color = factor(trueCongruence)), 
               linewidth = 0.5) +
  geom_density(data = inference %>% filter(accuracy == 0, RT >= noise2_onset, is.na(signal2_onset)==T), 
               aes(x = RT, y = -after_stat(density), group = trueCongruence, color = factor(trueCongruence)), linewidth = 0.5) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  scale_y_continuous(name = "scaled density", labels = function(x) abs(x), n.breaks = 4) +
  theme(strip.text = element_text(size = 10)) +
  labs(title = 'group RTs', subtitle = 'correct RTs on top, error RTs on bottom', x = 'RT (s)')

p1 + p2 + plot_layout(guides = 'collect', widths = c(5,1))
ggsave(paste0(outdir, 'individualRTs_noise2_byCongruence.png'), width=20, height=8)
