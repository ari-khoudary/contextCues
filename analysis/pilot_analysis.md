Pilot analyses: version 3
================

- [data tidying](#data-tidying)
- [RT analyses](#rt-analyses)
  - [effect of cue type on RT across all test
    trials](#effect-of-cue-type-on-rt-across-all-test-trials)
  - [effect of noise1 duration + cueType on RT for responses made after
    noise1](#effect-of-noise1-duration--cuetype-on-rt-for-responses-made-after-noise1)
  - [effect of noise2 duration + cueType on zlogRT in
    signal2](#effect-of-noise2-duration--cuetype-on-zlogrt-in-signal2)
- [Response probability analyses](#response-probability-analyses)
  - [for noise 1 responses only, probability of making cue-based
    response as a function of noise1
    duration](#for-noise-1-responses-only-probability-of-making-cue-based-response-as-a-function-of-noise1-duration)
  - [For signal 2 responses only, probability of making cue-based
    response as a function of noise2
    duration](#for-signal-2-responses-only-probability-of-making-cue-based-response-as-a-function-of-noise2-duration)
  - [Effect of signal1 evidence + noise2 duration on choice
    probabilities in signal2: 80%
    cues](#effect-of-signal1-evidence--noise2-duration-on-choice-probabilities-in-signal2-80-cues)

hello! if you are looking for the source code to produce the results
displayed below, you should navigate to the `.Rmd` version of this
document.

# data tidying

``` r
inferenceData_tidy <- inferenceData %>%
  filter(is.na(response)==F) %>%
  mutate(cueType = factor(cueType),
         subID = factor(subID),
         resp1 = ifelse(response==1, 1, 0),
         resp2 = ifelse(response==1, 0, 1),
         respFinger = ifelse(resp1==1, '1', '2'),
         signal1_cueEv = case_when(cueIdx==1 ~ signal1_target1 - signal1_target2,
                                   cueIdx==2 ~ signal1_target2 - signal1_target1),
         # signal1_relEv = case_when(response==1 ~ signal1_target1 - signal1_target2,
         #                           response==2 ~ signal1_target2 - signal1_target1),
         # signal1_relEv_z = scale(signal1_relEv),
         # signal1_cueCong = case_when(cueIdx==1 & (signal1_target1 > signal1_target2) ~ '0.8 cue: congruent vizEv',
         #                             cueIdx==1 & (signal1_target1 < signal1_target2) ~ '0.8 cue: incongruent vizEv',
         #                             cueIdx==2 & (signal1_target1 > signal1_target2) ~ '0.8 cue: incongruent vizEv',
         #                             cueIdx==2 & (signal1_target1 < signal1_target2) ~ '0.8 cue: congruent vizEv',
         #                             cueIdx<3 & (signal1_target1 == signal1_target2) ~ '0.8 cue: equal vizEv',
         #                             cueIdx==3 & (signal1_target1 > signal1_target2) ~ '0.5 cue: imgA vizEv',
         #                             cueIdx==3 & (signal1_target1 < signal1_target2) ~ '0.5 cue: imgB vizEv',
         #                             cueIdx==3 & (signal1_target1 == signal1_target2) ~ '0.5 cue: equal vizEv'),
         # signal1_evCongChoice = case_when(signal1_target1 > signal1_target2 & response==1 ~ 1,
         #                                  signal1_target1 < signal1_target2 & response==2 ~ 1,
         #                                  signal1_target1 < signal1_target2 & response==1 ~ 0,
         #                                  signal1_target1 > signal1_target2 & response==2 ~ 0),
         # signal2_cueCong = case_when(cueIdx==1 & (signal2_target1 > signal2_target2) ~ '0.8 cue: congruent vizEv',
         #                             cueIdx==1 & (signal2_target1 < signal2_target2) ~ '0.8 cue: incongruent vizEv',
         #                             cueIdx==2 & (signal2_target1 > signal2_target2) ~ '0.8 cue: incongruent vizEv',
         #                             cueIdx==2 & (signal2_target1 < signal2_target2) ~ '0.8 cue: congruent vizEv',
         #                             cueIdx<3 & (signal2_target1 == signal2_target2) ~ '0.8 cue: equal vizEv',
         #                             cueIdx==3 & (signal2_target1 > signal2_target2) ~ '0.5 cue: imgA ev',
         #                             cueIdx==3 & (signal2_target1 < signal2_target2) ~ '0.5 cue: imgB ev',
         #                             cueIdx==3 & (signal2_target1 == signal2_target2) ~ '0.5 cue: equal ev'),
         # signal2_cueCong = factor(signal2_cueCong),
         # signal1_cueCong = factor(signal1_cueCong),
         noise1_seconds = noise1frames_behav * (1/60), 
         signal1RT = RT - noise1_seconds,
         vizLocked_respFrame = respFrame - noise1frames_behav,
         vizLocked_respFrame_t = vizLocked_respFrame / 60,
         vizLocked_sig2Resp = respFrame - (noise1frames_behav + signal1frames_behav + noise2frames_behav),
         vizLocked_sig2Resp = vizLocked_sig2Resp/60) %>% 
  group_by(subID) %>%
  mutate(zlog_sig1RT = log(signal1RT),
         zlog_sig1RT = scale(zlog_sig1RT))%>%
  ungroup()
```

# RT analyses

## effect of cue type on RT across all test trials

``` r
# run model
m <- inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  lm(zlogRT ~ cueType, ., contrasts=list(cueType=contr.sum))

# compute expected marginal means
emm <- emmeans(m, eff ~ cueType)

# quick plot
emmip(m,  ~ cueType, CIs=T, plotit=T) + 
  theme_bw() +  geom_hline(yintercept=0, linetype='dashed')
```

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20cueType-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m,  ~ cueType, CIs=T, plotit=F)

# plot emmeans above raw data
inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  ggplot(aes(x = cueType, y = zlogRT)) +
  theme_bw() + 
  geom_hline(yintercept=0, linetype='dashed') +
  geom_point(aes(color=cueType), alpha=0.1, color='gray50', position=position_jitter(width=0.1)) +
  # add emmeans
  geom_errorbar(aes(x=xvar, y=yvar, ymin=LCL, ymax=UCL, color=cueType), data=emm_df, width=0.05, size=1) +
  labs(title = 'marginal means over raw data')
```

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20cueType-2.png)<!-- -->

``` r
summary(m)
```

    ## 
    ## Call:
    ## lm(formula = zlogRT ~ cueType, data = ., contrasts = list(cueType = contr.sum))
    ## 
    ## Residuals:
    ##     Min      1Q  Median      3Q     Max 
    ## -4.0655 -0.7562  0.0842  0.7780  2.5244 
    ## 
    ## Coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)  0.09634    0.02794   3.448 0.000576 ***
    ## cueType1     0.16182    0.02794   5.792 8.06e-09 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 0.9915 on 1976 degrees of freedom
    ## Multiple R-squared:  0.0167, Adjusted R-squared:  0.0162 
    ## F-statistic: 33.55 on 1 and 1976 DF,  p-value: 8.058e-09

## effect of noise1 duration + cueType on RT for responses made after noise1

``` r
# run model
m <- inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod != 'noise1') %>%
  lm(vizLocked_respFrame_t ~ noise1frames_behav * cueType, ., contrasts = list(cueType = contr.sum))

# compute expected marginal means
emm <- emmeans(m, consec ~ noise1frames_behav | cueType, cov.reduce=quantile)

# get range of x-values for plotting
noise_vals <- unique(summary(emm)$emmeans$noise1frames_behav)

# quick plot
emmip(m,  ~ noise1frames_behav | cueType, cov.reduce=quantile, CIs=T, plotit=T)
```

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20noise1frames%20+%20cueType-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m,  ~ noise1frames_behav | cueType, CIs=T, plotit=F, cov.reduce=F)

# plot emmeans above raw data
inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod != 'noise1', noise1frames_behav >= min(noise_vals)) %>%
  ggplot(aes(x = noise1frames_behav, y = vizLocked_respFrame_t)) +
  theme_bw() +
  geom_point(aes(color=cueType), alpha=0.5, size=1) +
  geom_ribbon(aes(xvar, yvar, ymin=LCL, ymax=UCL, fill=cueType), emm_df, color=NA, alpha=0.5) +
  geom_line(aes(x=xvar, y=yvar, group=cueType), data=emm_df) +
  labs(title = 'effect of cue type & noise1 duration on RTs',
       subtitle = 'RT locked to onset of signal1 evidence, plotted on the scale of seconds')
```

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20noise1frames%20+%20cueType-2.png)<!-- -->

``` r
summary(m)
```

    ## 
    ## Call:
    ## lm(formula = vizLocked_respFrame_t ~ noise1frames_behav * cueType, 
    ##     data = ., contrasts = list(cueType = contr.sum))
    ## 
    ## Residuals:
    ##     Min      1Q  Median      3Q     Max 
    ## -2.5942 -1.3510 -0.2961  1.1926  5.1142 
    ## 
    ## Coefficients:
    ##                              Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)                  2.917794   0.270872  10.772   <2e-16 ***
    ## noise1frames_behav          -0.004215   0.002842  -1.483   0.1383    
    ## cueType1                     0.553840   0.270872   2.045   0.0411 *  
    ## noise1frames_behav:cueType1 -0.006337   0.002842  -2.230   0.0259 *  
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 1.686 on 1601 degrees of freedom
    ## Multiple R-squared:  0.003564,   Adjusted R-squared:  0.001697 
    ## F-statistic: 1.909 on 3 and 1601 DF,  p-value: 0.1262

``` r
print(emm)
```

    ## $emmeans
    ## cueType = 50% cue:
    ##  noise1frames_behav emmean     SE   df lower.CL upper.CL
    ##                  75   2.68 0.1289 1601    2.427     2.93
    ##                  80   2.63 0.1122 1601    2.408     2.85
    ##                  88   2.54 0.0932 1601    2.360     2.73
    ##                 101   2.41 0.0955 1601    2.219     2.59
    ##                 195   1.41 0.5106 1601    0.413     2.42
    ## 
    ## cueType = 80% cue:
    ##  noise1frames_behav emmean     SE   df lower.CL upper.CL
    ##                  75   2.52 0.0690 1601    2.388     2.66
    ##                  80   2.53 0.0598 1601    2.416     2.65
    ##                  88   2.55 0.0498 1601    2.453     2.65
    ##                 101   2.58 0.0526 1601    2.475     2.68
    ##                 195   2.78 0.2853 1601    2.218     3.34
    ## 
    ## Confidence level used: 0.95 
    ## 
    ## $contrasts
    ## cueType = 50% cue:
    ##  contrast                                      estimate     SE   df t.ratio
    ##  noise1frames_behav80 - noise1frames_behav75    -0.0528 0.0249 1601  -2.123
    ##  noise1frames_behav88 - noise1frames_behav80    -0.0844 0.0398 1601  -2.123
    ##  noise1frames_behav101 - noise1frames_behav88   -0.1372 0.0646 1601  -2.123
    ##  noise1frames_behav195 - noise1frames_behav101  -0.9918 0.4672 1601  -2.123
    ##  p.value
    ##   0.0339
    ##   0.0339
    ##   0.0339
    ##   0.0339
    ## 
    ## cueType = 80% cue:
    ##  contrast                                      estimate     SE   df t.ratio
    ##  noise1frames_behav80 - noise1frames_behav75     0.0106 0.0138 1601   0.769
    ##  noise1frames_behav88 - noise1frames_behav80     0.0170 0.0221 1601   0.769
    ##  noise1frames_behav101 - noise1frames_behav88    0.0276 0.0359 1601   0.769
    ##  noise1frames_behav195 - noise1frames_behav101   0.1995 0.2593 1601   0.769
    ##  p.value
    ##   0.4418
    ##   0.4418
    ##   0.4418
    ##   0.4418
    ## 
    ## P value adjustment: mvt method for 4 tests

The emmeans contrast allows us to see that RTs get significantly faster
as a function of noise1 duration on 50% cue trials, but that noise1
duration doesn’t really affect RTs on 80% cue trials \[probably the
effect is masked by lumping congruent & incongruent trials together\]

Before incorporating cue-evidence congruence, I wanted to think about
another way of contrasting the trends produced by the linear model.
Instead of testing how RTs change as a function of noise1 within each
cue, I can test pairwise differences in RTs at desired values of noise1
frames. Here’s what that looks like:

``` r
emmeans(m, pairwise ~ cueType | noise1frames_behav, cov.reduce=quantile)
```

    ## $emmeans
    ## noise1frames_behav =  75:
    ##  cueType emmean     SE   df lower.CL upper.CL
    ##  50% cue   2.68 0.1289 1601    2.427     2.93
    ##  80% cue   2.52 0.0690 1601    2.388     2.66
    ## 
    ## noise1frames_behav =  80:
    ##  cueType emmean     SE   df lower.CL upper.CL
    ##  50% cue   2.63 0.1122 1601    2.408     2.85
    ##  80% cue   2.53 0.0598 1601    2.416     2.65
    ## 
    ## noise1frames_behav =  88:
    ##  cueType emmean     SE   df lower.CL upper.CL
    ##  50% cue   2.54 0.0932 1601    2.360     2.73
    ##  80% cue   2.55 0.0498 1601    2.453     2.65
    ## 
    ## noise1frames_behav = 101:
    ##  cueType emmean     SE   df lower.CL upper.CL
    ##  50% cue   2.41 0.0955 1601    2.219     2.59
    ##  80% cue   2.58 0.0526 1601    2.475     2.68
    ## 
    ## noise1frames_behav = 195:
    ##  cueType emmean     SE   df lower.CL upper.CL
    ##  50% cue   1.41 0.5106 1601    0.413     2.42
    ##  80% cue   2.78 0.2853 1601    2.218     3.34
    ## 
    ## Confidence level used: 0.95 
    ## 
    ## $contrasts
    ## noise1frames_behav =  75:
    ##  contrast          estimate    SE   df t.ratio p.value
    ##  50% cue - 80% cue  0.15718 0.146 1601   1.075  0.2825
    ## 
    ## noise1frames_behav =  80:
    ##  contrast          estimate    SE   df t.ratio p.value
    ##  50% cue - 80% cue  0.09381 0.127 1601   0.738  0.4607
    ## 
    ## noise1frames_behav =  88:
    ##  contrast          estimate    SE   df t.ratio p.value
    ##  50% cue - 80% cue -0.00758 0.106 1601  -0.072  0.9429
    ## 
    ## noise1frames_behav = 101:
    ##  contrast          estimate    SE   df t.ratio p.value
    ##  50% cue - 80% cue -0.17233 0.109 1601  -1.580  0.1143
    ## 
    ## noise1frames_behav = 195:
    ##  contrast          estimate    SE   df t.ratio p.value
    ##  50% cue - 80% cue -1.36363 0.585 1601  -2.331  0.0199

## effect of noise2 duration + cueType on zlogRT in signal2

``` r
# fit model
m <- inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod == 'signal2') %>%
  lm(vizLocked_sig2Resp ~ noise2frames_behav * cueType, ., contrasts = list(cueType = contr.sum))

# compute expected marginal means
emm <- emmeans(m, consec ~ noise2frames_behav | cueType, cov.reduce=quantile)

# get range of x-values for plotting
noise_vals <- unique(summary(emm)$emmeans$noise2frames_behav)

# quick plot
emmip(m,  ~ noise2frames_behav | cueType, cov.reduce=quantile, CIs=T, plotit=T)
```

![](pilot_analysis_files/figure-gfm/vizLocked_sig2Resp%20~%20noise2frames_behav%20+%20cueType-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m,  ~ noise2frames_behav | cueType, CIs=T, plotit=F,
                at=list(noise2frames_behav = noise_vals))

# plot emmeans above raw data
inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod == 'signal2') %>%
  filter(noise2frames_behav >= min(noise_vals)) %>%
  ggplot(aes(x = noise2frames_behav, y = vizLocked_sig2Resp)) +
  theme_bw() +
  geom_point(aes(color=cueType), alpha=0.5, size=1) +
  geom_ribbon(aes(xvar, yvar, ymin=LCL, ymax=UCL, fill=cueType), emm_df, color=NA, alpha=0.5) +
  geom_line(aes(x=xvar, y=yvar, group=cueType, color=cueType), data=emm_df) +
  labs(title = 'signal2 RTs locked to onset of signal2 visual evidence')
```

![](pilot_analysis_files/figure-gfm/vizLocked_sig2Resp%20~%20noise2frames_behav%20+%20cueType-2.png)<!-- -->

``` r
summary(m)
```

    ## 
    ## Call:
    ## lm(formula = vizLocked_sig2Resp ~ noise2frames_behav * cueType, 
    ##     data = ., contrasts = list(cueType = contr.sum))
    ## 
    ## Residuals:
    ##     Min      1Q  Median      3Q     Max 
    ## -1.7862 -0.9417 -0.2138  0.7100  3.9881 
    ## 
    ## Coefficients:
    ##                              Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)                  1.878223   0.250382   7.501  1.7e-13 ***
    ## noise2frames_behav          -0.002088   0.002587  -0.807    0.420    
    ## cueType1                    -0.217896   0.250382  -0.870    0.384    
    ## noise2frames_behav:cueType1  0.001720   0.002587   0.665    0.506    
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 1.185 on 791 degrees of freedom
    ## Multiple R-squared:  0.004018,   Adjusted R-squared:  0.0002401 
    ## F-statistic: 1.064 on 3 and 791 DF,  p-value: 0.3638

``` r
print(emm)
```

    ## $emmeans
    ## cueType = 50% cue:
    ##  noise2frames_behav emmean     SE  df lower.CL upper.CL
    ##                  75   1.63 0.1269 791    1.384     1.88
    ##                  81   1.63 0.1101 791    1.414     1.85
    ##                  88   1.63 0.0959 791    1.440     1.82
    ##                 101   1.62 0.0932 791    1.440     1.81
    ##                 195   1.59 0.4428 791    0.719     2.46
    ## 
    ## cueType = 80% cue:
    ##  noise2frames_behav emmean     SE  df lower.CL upper.CL
    ##                  75   1.81 0.0690 791    1.675     1.95
    ##                  81   1.79 0.0580 791    1.674     1.90
    ##                  88   1.76 0.0495 791    1.664     1.86
    ##                 101   1.71 0.0526 791    1.608     1.81
    ##                 195   1.35 0.2886 791    0.787     1.92
    ## 
    ## Confidence level used: 0.95 
    ## 
    ## $contrasts
    ## cueType = 50% cue:
    ##  contrast                                      estimate     SE  df t.ratio
    ##  noise2frames_behav81 - noise2frames_behav75   -0.00221 0.0261 791  -0.085
    ##  noise2frames_behav88 - noise2frames_behav81   -0.00258 0.0305 791  -0.085
    ##  noise2frames_behav101 - noise2frames_behav88  -0.00479 0.0566 791  -0.085
    ##  noise2frames_behav195 - noise2frames_behav101 -0.03463 0.4096 791  -0.085
    ##  p.value
    ##   0.9326
    ##   0.9326
    ##   0.9326
    ##   0.9326
    ## 
    ## cueType = 80% cue:
    ##  contrast                                      estimate     SE  df t.ratio
    ##  noise2frames_behav81 - noise2frames_behav75   -0.02285 0.0167 791  -1.366
    ##  noise2frames_behav88 - noise2frames_behav81   -0.02666 0.0195 791  -1.366
    ##  noise2frames_behav101 - noise2frames_behav88  -0.04951 0.0363 791  -1.366
    ##  noise2frames_behav195 - noise2frames_behav101 -0.35799 0.2622 791  -1.366
    ##  p.value
    ##   0.1725
    ##   0.1725
    ##   0.1725
    ##   0.1725
    ## 
    ## P value adjustment: mvt method for 4 tests

``` r
emmeans(m, pairwise ~ cueType | noise2frames_behav, cov.reduce=quantile)$contrasts
```

    ## noise2frames_behav =  75:
    ##  contrast          estimate    SE  df t.ratio p.value
    ##  50% cue - 80% cue  -0.1778 0.144 791  -1.231  0.2188
    ## 
    ## noise2frames_behav =  81:
    ##  contrast          estimate    SE  df t.ratio p.value
    ##  50% cue - 80% cue  -0.1571 0.124 791  -1.263  0.2071
    ## 
    ## noise2frames_behav =  88:
    ##  contrast          estimate    SE  df t.ratio p.value
    ##  50% cue - 80% cue  -0.1331 0.108 791  -1.233  0.2178
    ## 
    ## noise2frames_behav = 101:
    ##  contrast          estimate    SE  df t.ratio p.value
    ##  50% cue - 80% cue  -0.0883 0.107 791  -0.825  0.4095
    ## 
    ## noise2frames_behav = 195:
    ##  contrast          estimate    SE  df t.ratio p.value
    ##  50% cue - 80% cue   0.2350 0.529 791   0.445  0.6567

# Response probability analyses

## for noise 1 responses only, probability of making cue-based response as a function of noise1 duration

``` r
# filter data & fit model
m <- inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod == 'noise1') %>%
  glm(cueCongChoice ~ noise1frames_behav, ., family='binomial')

# compute expected marginal means
emm <- emmeans(m, consec ~ noise1frames_behav, type='response', cov.reduce=quantile)

# get noise values from emmeans call
noise_vals <- unique(summary(emm)$emmeans$noise1frames_behav)

# quick plot
emmip(m, ~ noise1frames_behav, type='response', CIs=T, at=list(noise1frames_behav=noise_vals))
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal1%20~%20noise1frames_behav-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m,  ~ noise1frames_behav, type='response', CIs=T, plotit=F, at=list(noise1frames_behav=noise_vals))

# plot emmeans above raw data
inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod == 'noise1') %>%
  ggplot(aes(x = noise1frames_behav, y = cueCongChoice)) +
  theme_bw() + 
  geom_hline(yintercept=0.5, linetype='dashed') +
  geom_point(position=position_jitter(height=0.05)) +
  # add emmeans
  geom_ribbon(aes(x=xvar, y=yvar, ymin=LCL, ymax=UCL), data=emm_df, alpha=0.1) +
  geom_line(aes(x=xvar, y=yvar), data=emm_df) +
  labs(title = 'in noise1, probability of responding according to cue (80% cues only)')
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal1%20~%20noise1frames_behav-2.png)<!-- -->

``` r
summary(m)
```

    ## 
    ## Call:
    ## glm(formula = cueCongChoice ~ noise1frames_behav, family = "binomial", 
    ##     data = .)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -2.1151   0.5146   0.5370   0.5512   0.5688  
    ## 
    ## Coefficients:
    ##                    Estimate Std. Error z value Pr(>|z|)    
    ## (Intercept)        1.691186   0.378074   4.473 7.71e-06 ***
    ## noise1frames_behav 0.003228   0.006586   0.490    0.624    
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 270.08  on 341  degrees of freedom
    ## Residual deviance: 269.84  on 340  degrees of freedom
    ##   (31 observations deleted due to missingness)
    ## AIC: 273.84
    ## 
    ## Number of Fisher Scoring iterations: 4

``` r
print(emm)
```

    ## $emmeans
    ##  noise1frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                   4 0.846 0.0461 Inf     0.733     0.917
    ##                  34 0.858 0.0241 Inf     0.804     0.899
    ##                  46 0.863 0.0193 Inf     0.820     0.897
    ##                  70 0.872 0.0221 Inf     0.822     0.909
    ##                 161 0.901 0.0654 Inf     0.684     0.975
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale 
    ## 
    ## $contrasts
    ##  contrast                                     odds.ratio     SE  df null
    ##  noise1frames_behav34 / noise1frames_behav4         1.10 0.2177 Inf    1
    ##  noise1frames_behav46 / noise1frames_behav34        1.04 0.0822 Inf    1
    ##  noise1frames_behav70 / noise1frames_behav46        1.08 0.1708 Inf    1
    ##  noise1frames_behav161 / noise1frames_behav70       1.34 0.8040 Inf    1
    ##  z.ratio p.value
    ##    0.490  0.6240
    ##    0.490  0.6240
    ##    0.490  0.6240
    ##    0.490  0.6240
    ## 
    ## P value adjustment: mvt method for 4 tests 
    ## Tests are performed on the log odds ratio scale

## For signal 2 responses only, probability of making cue-based response as a function of noise2 duration

``` r
# filter data & fit model
m <- inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod == 'signal2') %>%
  glm(cueCongChoice ~ noise2frames_behav, ., family='binomial')

# compute expected marginal means
emm <- emmeans(m, consec ~ noise2frames_behav, type='response', cov.reduce=quantile)

# get noise values from emmeans call
noise_vals <- unique(summary(emm)$emmean$noise2frames_behav)

# quick plot
emmip(m, ~ noise2frames_behav, type='response', at=list(noise2frames_behav=noise_vals),
      CIs=T, cov.reduce=F)
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m, ~ noise2frames_behav, type='response', at=list(noise2frames_behav=noise_vals),
                CIs=T, plotit=F, cov.reduce=F)

# plot emmeans above raw data
 inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod == 'signal2') %>% 
  ggplot(aes(x = noise2frames_behav, y = cueCongChoice)) +
  theme_bw() +
  geom_hline(yintercept=0.5, linetype='dashed') +
  geom_point(position=position_jitter(height=0.05), size=1) +
  # add emmeans
  geom_ribbon(aes(x=xvar, y=yvar, ymin=LCL, ymax=UCL), data=emm_df, alpha=0.1) +
  geom_line(aes(x=xvar, y=yvar), data=emm_df) +
  labs(title = 'probability of making cueCongruent signal2 response as a function of noise2 duration (80% cues only)')
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav-2.png)<!-- -->

``` r
summary(m)
```

    ## 
    ## Call:
    ## glm(formula = cueCongChoice ~ noise2frames_behav, family = "binomial", 
    ##     data = .)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -1.6299  -1.4167   0.9210   0.9493   0.9652  
    ## 
    ## Coefficients:
    ##                    Estimate Std. Error z value Pr(>|z|)
    ## (Intercept)        0.210443   0.472188   0.446    0.656
    ## noise2frames_behav 0.004154   0.005020   0.828    0.408
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 809.43  on 621  degrees of freedom
    ## Residual deviance: 808.74  on 620  degrees of freedom
    ##   (173 observations deleted due to missingness)
    ## AIC: 812.74
    ## 
    ## Number of Fisher Scoring iterations: 4

``` r
print(emm)
```

    ## $emmeans
    ##  noise2frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                  75 0.628 0.0284 Inf     0.570     0.681
    ##                  80 0.632 0.0244 Inf     0.583     0.679
    ##                  88 0.640 0.0200 Inf     0.600     0.678
    ##                 100 0.652 0.0208 Inf     0.610     0.691
    ##                 195 0.735 0.1015 Inf     0.500     0.885
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale 
    ## 
    ## $contrasts
    ##  contrast                                      odds.ratio     SE  df null
    ##  noise2frames_behav80 / noise2frames_behav75         1.02 0.0256 Inf    1
    ##  noise2frames_behav88 / noise2frames_behav80         1.03 0.0415 Inf    1
    ##  noise2frames_behav100 / noise2frames_behav88        1.05 0.0633 Inf    1
    ##  noise2frames_behav195 / noise2frames_behav100       1.48 0.7076 Inf    1
    ##  z.ratio p.value
    ##    0.828  0.4079
    ##    0.828  0.4079
    ##    0.828  0.4079
    ##    0.828  0.4079
    ## 
    ## P value adjustment: mvt method for 4 tests 
    ## Tests are performed on the log odds ratio scale

## Effect of signal1 evidence + noise2 duration on choice probabilities in signal2: 80% cues

``` r
# filter data
m <- inferenceData_tidy %>%
    filter(catch_trial==0) %>%
    filter(respPeriod == 'signal2', cueIdx < 3) %>% 
    # fit model
    glm(cueCongChoice ~ noise2frames_behav * signal1_cueEv, ., family = 'binomial')

# compute expected marginal means, including a contrast for the effect of noise at each quantile of signal1_cueEv
emm <-emmeans(m, consec ~ noise2frames_behav | signal1_cueEv, type='response', cov.reduce=quantile)

# get noise values from emmeans call
noise_vals <- unique(summary(emm)$emmeans$noise2frames_behav)

# quick plot
emmip(m, signal1_cueEv ~ noise2frames_behav, type='response', CIs=T,
      at = list(signal1_cueEv = quantile(inferenceData_tidy$signal1_cueEv, na.rm=T)[c(1,3,5)],
                noise2frames_behav = noise_vals))
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav%20*%20signal1Ev-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m, signal1_cueEv ~ noise2frames_behav, type='response', CIs=T, plotit=F,
      at = list(signal1_cueEv = quantile(inferenceData_tidy$signal1_cueEv, na.rm=T)[c(1,3,5)],
                noise2frames_behav = noise_vals)) %>%
  mutate(signal1_cueEvidence = factor(signal1_cueEv, labels=c('max incongruent', 'approx equal', 'max congruent')))

# plot emmeans over raw data
inferenceData_tidy %>%
  filter(catch_trial==0, respPeriod=='signal2', cueIdx < 3) %>%
  filter(noise2frames_behav > min(noise_vals), noise2frames_behav < max(noise_vals)) %>%
  mutate(signal1_cueEvidence = factor(cut(signal1_cueEv, breaks=c(-19, 0, 1, 19), include.lowest=T),
                                       labels = c('max incongruent', 'approx equal', 'max congruent'))) %>%
  ggplot(aes(x=noise2frames_behav, y=cueCongChoice)) +
  theme_bw() + geom_hline(yintercept=0.5, linetype='dashed') + 
  geom_point(position=position_jitter(height=0.05), size=0.5) +
  # add emmeans
  geom_ribbon(aes(x=xvar, y=yvar, ymin=LCL, ymax=UCL, fill=signal1_cueEvidence), emm_df, color=NA, alpha=0.2) +
  geom_line(aes(xvar, yvar, color=signal1_cueEvidence), emm_df, linewidth=1.5) +
  facet_wrap( ~ signal1_cueEvidence) +
  labs(title = 'Probability of making a cue-congruent choice as a function of signal1 evidence & noise 2 duration')
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav%20*%20signal1Ev-2.png)<!-- -->

### same data, different way of plotting/labeling

``` r
# compute expected marginal means
emm <- emmeans(m, ~ noise2frames_behav | signal1_cueEv, type='response', cov.reduce=F)

# get predictor values from emmeans call
noise_vals <- unique(summary(emm)$noise2frames_behav)
signal_vals <- unique(summary(emm)$signal1_cueEv)

# quick plot
emmip(m, signal1_cueEv ~ noise2frames_behav, type='response', CIs=T,
      at = list(signal1_cueEv = signal_vals,
                noise2frames_behav = noise_vals))
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav%20*%20signal1Ev%20-%20different%20style-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m, signal1_cueEv ~ noise2frames_behav, type='response', CIs=T, plotit=F,
                at = list(signal1_cueEv = signal_vals,
                          noise2frames_behav = noise_vals)) %>%
  mutate(signal1_cueEv = as.numeric(signal1_cueEv))

# plot emmeans over raw data
inferenceData_tidy %>%
  filter(catch_trial==0, respPeriod=='signal2', cueIdx < 3) %>%
  ggplot(aes(x=noise2frames_behav, y=cueCongChoice)) +
  theme_bw() + geom_hline(yintercept=0.5, linetype='dashed') + 
  scale_color_gradient2() + scale_fill_gradient2() + 
  geom_point(aes(color=signal1_cueEv), size=1.5, position=position_jitter(height=0.1)) + 
  # add emmeans
  geom_line(aes(xvar, yvar, color=signal1_cueEv, group=signal1_cueEv), emm_df, linewidth=0.5) +
  labs(title = 'Probability of making a cue-congruent choice as a function of signal1 evidence & noise 2 duration')
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav%20*%20signal1Ev%20-%20different%20style-2.png)<!-- -->
