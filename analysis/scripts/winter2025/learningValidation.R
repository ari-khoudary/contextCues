library(tidyverse)
library(patchwork)

# load & tidy data
outdir <- '../figures/'
validation_df <- read.csv('../tidied_data/learningValidation.csv') %>% 
  mutate(trueCue = case_when(cueIdx!='3' ~ 0.8,
                             cueIdx=='3' ~ 0.5),
         subjectiveCue = subjectiveCue/100,
         cueChar =  case_when(cueIdx == 1 ~ '80% A',
                              cueIdx == 2 ~ '80% B',
                              cueIdx == 3 ~ '50%'),
         cueChar = factor(cueChar, levels=c('80% A', '80% B', '50%')),
         CI = (5 - cueConfidence)/100) %>% 
  group_by(subID) %>%
  mutate(cueCorr = cor(subjectiveCue, trueCue),
         cueDiff = subjectiveCue - trueCue,
         cueCorr_spearman = cor(subjectiveCue, trueCue, method='spearman')) %>%
  ungroup()


# plot raw estimates
validation_df %>%
  ggplot(aes(x=subID, y=subjectiveCue, color=cueChar, fill=cueChar)) +
  theme_bw() +
  geom_col(position=position_dodge(width=0.75), width=0.5) +
  geom_errorbar(aes(ymin=subjectiveCue - CI, ymax=subjectiveCue + CI), color='black', position=position_dodge(width=0.75), width=0.1) +
  scale_x_continuous(breaks = unique(validation_df$subID)) +
  geom_hline(yintercept = 0.5, linetype='dashed') + 
  ggtitle('errorbars reflect cue estimate confidence')

ggsave(paste0(outdir, 'learnVal_bars.png'), width=8, height=4)

# plot pearson correlation of estimates with true cue value 
validation_df %>%
  distinct(subID, cueCorr) %>%
  ggplot(aes(x=subID, y=cueCorr)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_col() +
  scale_x_continuous(breaks=unique(validation_df$subID)) +
  labs(y='cueCorr', title = 'cueCorr = cor(subjectiveCue, trueCue, method=pearson)')
ggsave(paste0(outdir, 'cueCorr.png'), width=8, height=4)

# plot spearman correlation
validation_df %>%
  distinct(subID, cueCorr_spearman) %>%
  ggplot(aes(x=subID, y=cueCorr_spearman)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_col() +
  scale_x_continuous(breaks=unique(validation_df$subID)) +
  labs(y='cueCorr', title = 'cueCorr = cor(subjectiveCue, trueCue, method=spearman)')
ggsave(paste0(outdir, 'cueCorr_spearman.png'), width=8, height=4)


# compute accuracy of cue estimates
validation_df %>%
  mutate(trueCue = factor(trueCue)) %>%
  ggplot(aes(x=trueCue, y=cueDiff,)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_violin(alpha=0.3, scale='count') + 
  geom_boxplot(width=0.25, fill=NA, color='black', outliers=FALSE) +
  geom_point(position = position_jitter(width=0.03), alpha=0.5, size=1) +
  geom_line(aes(group=subID), alpha=0.25, color='gray20') +
  labs(y = 'cueDiff', title = 'cueDiff = subjectiveCue - trueCue') +
  theme(legend.position = 'none')

# regression results
lm(cueDiff ~ trueCue, validation_df) %>% summary()

ggsave(paste0(outdir, 'cueDiff.png'), width=5, height=5)




