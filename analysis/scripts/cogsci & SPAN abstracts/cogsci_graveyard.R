#### effect of trueCue on learning RTs ####
m <- learning_df %>%
  filter(trial < 100) %>%
  lm(imgLockedRT ~ trueCue + trial, .)

p1 <- m %>%
  emmeans(., ~ trial | trueCue, 
          at=list(trial=seq.int(1, 100, by=10))) %>%
  as.data.frame() %>%
  ggplot(aes(x=trial, y=emmean, color=trueCue)) +
  theme_bw() +
  geom_point(aes(x=trial, y=imgLockedRT, color=trueCue), data = learning_df[learning_df$trial<100,], size=0.25, alpha=0.5) +
  geom_ribbon(aes(ymin=lower.CL, ymax=upper.CL, group=trueCue, fill=trueCue), alpha=0.25, color=NA) +
  geom_line(linewidth=1.25) +
  labs(title = 'Image-locked RTs during learning', y='estimated zlogRT') +
  theme(legend.position = 'none')

p2 <- m %>%
  emtrends(., 'trueCue', var='trial') %>% 
  as.data.frame() %>%
  ggplot(aes(x=trueCue, y=trial.trend, color=trueCue)) +
  theme_bw() +
  geom_hline(yintercept = 0) +
  geom_pointrange(aes(ymin=lower.CL, ymax=upper.CL)) +
  labs(title = 'slope values', y='')

m %>%
  emtrends(., 'trueCue', var='trial') %>%
  test()

summary(m)

p1 + p2 + plot_layout(widths = c(2,1.25), guides='collect')
ggsave(paste0(outdir, 'learningRT.png'), width=6, height=3)