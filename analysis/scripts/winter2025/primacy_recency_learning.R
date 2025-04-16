library(tidyverse)
library(patchwork)
library(lme4)
library(lmerTest)
library(emmeans)
outdir <- '../figures/'

learning_df <- read.csv('../tidied_data/learning.csv') %>%
  mutate(cueIdx = factor(cueIdx),
         imageIdx = factor(imageIdx),
         trueCue = case_when(cueIdx!='3' ~ '80%',
                             cueIdx=='3' ~ '50%'))

# sanity check frequency plot
frequency_check <- learning_df %>%
  group_by(cueIdx, imageIdx, subID) %>% 
  count()

frequency_check %>%
  ggplot(aes(x=subID, y=n, color=imageIdx, fill=imageIdx)) +
  theme_bw() +
  facet_wrap(~ cueIdx, labeller = labeller(.cols = function(x) paste0("cueIdx = ", x))) +
  geom_col(position=position_dodge()) +
  scale_y_continuous(n.breaks = 10) +
  scale_x_continuous(n.breaks = length(unique(frequency_check$subID)))
ggsave(paste0(outdir, 'learning_frequencies.png'), width=15, height=6)


# primacy / recency raster plots
learning_df %>%
  filter(trial < 100) %>%
  ggplot(aes(x = trial, y = cueIdx, color = imageIdx)) +
  theme_bw() +
  geom_point(shape='|', size=5) + 
  facet_wrap(~ subID, nrow=5, labeller = labeller(.cols = function(x) paste0("subID = ", x))) +
  scale_y_discrete(limits=rev)
ggsave(paste0(outdir, 'learning_rasters_tall.png'), width=10, height=8)
