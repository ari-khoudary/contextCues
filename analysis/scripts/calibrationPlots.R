library(tidyverse)
library(patchwork)

calibration_df <- read.csv('../tidied_data/calibration.csv')
cohVal_df <- read.csv('../tidied_data/coherenceValidation.csv')
outdir <- '../figures/'

calibration_df %>%
  mutate(subID = paste0('sub', subID),
         targetIdx = paste0('img', targetImage),
         staircase = factor(staircase)) %>% 
  ggplot(aes(x=trial, y=coherence, color=staircase, shape = targetIdx)) +
  facet_wrap( ~ subID, ncol=6) +
  geom_line(linewidth=0.5) +
  geom_point(size=2) +
  theme_bw() +
  geom_hline(yintercept = 0.7) +
  geom_hline(yintercept = 0.5, linetype='dashed') +
  ggtitle('solid line=target coherence, dashed line=0.5')

ggsave(paste0(outdir, 'staircases.png'), width=10, height=5)
  

cohVal_df %>% 
  group_by(subID, targetIdx, targetName) %>%
  summarise(calibratedCoherence = round(unique(coherence), 2)) %>%
  ggplot(aes(x=subID, y=calibratedCoherence, color=targetName, fill=targetName)) +
  geom_col(position=position_dodge()) +
  geom_hline(yintercept = 0.5, linetype='dashed') +
  theme_bw() +
  scale_x_continuous(breaks=unique(cohVal_df$subID)) +
  theme(text = element_text(size=18)) +
  scale_y_continuous(n.breaks=10)

ggsave(paste0(outdir, 'calibratedCoherences.png'))
