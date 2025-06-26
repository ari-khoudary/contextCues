library(tidyverse)

inference <- read.csv('../tidied_data/all_conditions/inference.csv') %>% filter(subID > 0)

inference %>%
  group_by(subID, condition) %>% 
  summarise(propCorrect = mean(accuracy),
            cueCorr = cor(trueCue,subjectiveCue)) %>%
  ggplot(aes(x=subID, y=propCorrect)) +
  geom_hline(yintercept = 0.5) +
  geom_hline(yintercept = 0.7, linetype='dashed') +
  ylim(0,1) +
  geom_segment(aes(x=subID, xend=subID, y=0, yend=propCorrect)) +
  geom_point(aes(shape=condition, fill=cueCorr), size=5, stroke=1, color='gray20') +
  scale_shape_manual(values = c(23, 21)) + scale_fill_gradient2() +
  scale_x_continuous(n.breaks = length(unique(inference$subID))) + theme_bw() 
ggsave('results_april2025/propCorrect_bySubject.png', width=12, height=4, dpi='retina')