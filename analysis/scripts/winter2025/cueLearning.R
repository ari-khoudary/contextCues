library(tidyverse)
library(patchwork)
library(lme4)
library(lmerTest)
library(emmeans)

learning_df <- read.csv('../tidied_data/learning.csv') %>%
  mutate(cueIdx = factor(cueIdx),
         imageIdx = factor(imageIdx),
         trueCue = case_when(cueIdx!='3' ~ '80%',
                             cueIdx=='3' ~ '50%'))

# RT effects for each subject
learning_df %>%
  ggplot(aes(x=trial, y=imgLockedRT, color=cueIdx)) +
  theme_bw() +
  geom_point(size=0.5, alpha=0.7) +
  geom_smooth(method='lm', alpha=0.3) + 
  facet_wrap(~ subID, ncol=6, scales='free_x')
ggsave(paste0(outdir, 'learningRT_bySub.png'), width=9, height=8)

# RT effects for the group, using cueIdx as a predictor
m <- learning_df %>%
  filter(trial < 100) %>%
  lm(imgLockedRT ~ cueIdx * trial, .)

p1 <- m %>%
  emmeans(., ~ trial | cueIdx, 
          at=list(trial=seq.int(1, 100, by=10))) %>%
  as.data.frame() %>%
  ggplot(aes(x=trial, y=emmean, color=cueIdx)) +
  theme_bw() +
  geom_point(aes(x=trial, y=imgLockedRT, color=cueIdx), data = learning_df[learning_df$trial<100,], size=0.5) +
  geom_hline(yintercept=0) +
  geom_ribbon(aes(ymin=lower.CL, ymax=upper.CL, group=cueIdx, fill=cueIdx), alpha=0.25, color=NA) +
  geom_line(linewidth=1.25) +
  ggtitle('group regression')

p2 <- m %>%
  emtrends(., 'cueIdx', var='trial') %>% 
  as.data.frame() %>%
  ggplot(aes(x=cueIdx, y=trial.trend, color=cueIdx)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_pointrange(aes(ymin=lower.CL, ymax=upper.CL)) +
  ggtitle('effect of trial')

p1 / p2 
ggsave(paste0(outdir, 'learningRT_all.png'), width=4, height=6)

# RT effects for the group, using trueCue as the predictor
m <- learning_df %>%
  filter(trial < 100) %>%
  lm(imgLockedRT ~ trueCue * trial, .)

p1 <- m %>%
  emmeans(., ~ trial | trueCue, 
          at=list(trial=seq.int(1, 100, by=10))) %>%
  as.data.frame() %>%
  ggplot(aes(x=trial, y=emmean, color=trueCue)) +
  theme_bw() +
  geom_point(aes(x=trial, y=imgLockedRT, color=trueCue), data = learning_df[learning_df$trial<100,], size=0.5, alpha=0.5) +
  geom_ribbon(aes(ymin=lower.CL, ymax=upper.CL, group=trueCue, fill=trueCue), alpha=0.25, color=NA) +
  geom_line(linewidth=1.25) +
  labs(title = 'lm(zlogRT ~ trueCue * trial)', y='estimated zlogRT')

p2 <- m %>%
  emtrends(., 'trueCue', var='trial') %>% 
  as.data.frame() %>%
  ggplot(aes(x=trueCue, y=trial.trend, color=trueCue)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_pointrange(aes(ymin=lower.CL, ymax=upper.CL)) +
  labs(title = 'slope values', y='')

p1 + p2 + plot_layout(widths = c(2,1.25), guides='collect')
ggsave(paste0(outdir, 'learningRT.png'), width=6, height=3)

m %>%
  emtrends(., 'trueCue', var='trial') %>%
  test()

summary(m)
