Pilot analyses: version 3
================

- [model specs](#model-specs)
- [data tidying](#data-tidying)
- [RT analyses](#rt-analyses)
  - [effect of cue type on RT across all test
    trials](#effect-of-cue-type-on-rt-across-all-test-trials)
  - [effect of noise1 duration + cueType on RT for responses made after
    noise1](#effect-of-noise1-duration--cuetype-on-rt-for-responses-made-after-noise1)
  - [effect of noise2 duration + cueType on zlogRT in
    signal2](#effect-of-noise2-duration--cuetype-on-zlogrt-in-signal2)
  - [effect of noise2 duration + cueType on zlogRT in
    signal2](#effect-of-noise2-duration--cuetype-on-zlogrt-in-signal2-1)
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

# model specs

model data come from a simulation of 100 subjects performing the task.
each simulated subject completes 100 trials for the 80% cue and 50
trials for the 50% cue. RTs were log-transformed and z-scored within
subject. all choice data is forced choice (i.e., sign of the accumulator
at trial end if a boundary hadn’t been reached).

simulations were run with coherence=0.5395, thinning=12, and
threshold=5. coherence & threshold values were determined in a separate
“model calibration” analysis linked in my notebook. this combination led
to the model performing at 70% accuracy based on visual evidence only
without any noise durations, just forward & backward masking of each
signal frame with noise

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

modelData <- modelData %>% 
  mutate(cueType = factor(cue, levels=c(0.5, 0.8), labels=c('50% cue', '80% cue')),
         subID = factor(subID),
         noise1_seconds = noise1frames_behav * (1/60), 
         vizLocked_respFrame = RT - noise1frames_behav,
         vizLocked_respFrame_t = vizLocked_respFrame / 60,
         vizLocked_sig2Resp = RT - (noise1frames_behav + signal1frames_behav + noise2frames_behav),
         vizLocked_sig2Resp = vizLocked_sig2Resp/60) 
```

# RT analyses

## effect of cue type on RT across all test trials

### human data

``` r
# run model
m <- inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  lm(zlogRT ~ cueType, ., contrasts=list(cueType=contr.sum))

# compute expected marginal means
emm <- emmeans(m, eff ~ cueType)

# quick plot
# emmip(m,  ~ cueType, CIs=T, plotit=T) + 
#   theme_bw() +  geom_hline(yintercept=0, linetype='dashed')

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

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20cueType:%20humans-1.png)<!-- -->

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

### model data

``` r
# fit linear model
m <- modelData %>%
  lm(zlogRT ~ cueType, ., contrasts=list(cueType=contr.sum))

# compute expected marginal means
emm <- emmeans(m, eff ~ cueType)

# quick plot
# emmip(m,  ~ cueType, CIs=T, plotit=T) + 
#   theme_bw() +  geom_hline(yintercept=0, linetype='dashed')

# save plot-formatted emmeans
emm_df <- emmip(m,  ~ cueType, CIs=T, plotit=F)

# plot emmeans above raw data
modelData %>%
  ggplot(aes(x = cueType, y = zlogRT)) +
  theme_bw() + 
  geom_hline(yintercept=0, linetype='dashed') +
  geom_point(aes(color=cueType), alpha=0.1, color='gray50', position=position_jitter(width=0.1)) +
  # add emmeans
  geom_errorbar(aes(x=xvar, y=yvar, ymin=LCL, ymax=UCL, color=cueType), data=emm_df, width=0.05, size=1) +
  labs(title = 'marginal means over raw data: model')
```

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20cueType:%20model-1.png)<!-- -->

``` r
summary(m)
```

    ## 
    ## Call:
    ## lm(formula = zlogRT ~ cueType, data = ., contrasts = list(cueType = contr.sum))
    ## 
    ## Residuals:
    ##     Min      1Q  Median      3Q     Max 
    ## -3.2248 -0.7730 -0.0796  0.7852  3.0320 
    ## 
    ## Coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept) 0.098267   0.008289   11.85   <2e-16 ***
    ## cueType1    0.294801   0.008289   35.56   <2e-16 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 0.9572 on 14998 degrees of freedom
    ## Multiple R-squared:  0.07777,    Adjusted R-squared:  0.07771 
    ## F-statistic:  1265 on 1 and 14998 DF,  p-value: < 2.2e-16

## effect of noise1 duration + cueType on RT for responses made after noise1

### human data

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
#emmip(m,  ~ noise1frames_behav | cueType, cov.reduce=quantile, CIs=T, plotit=T)

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

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20noise1frames%20+%20cueType-1.png)<!-- -->

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
# emmeans(m, consec ~ noise1frames_behav | cueType, cov.reduce=range)$contrasts
emtrends(m, pairwise ~ cueType, var='noise1frames_behav')
```

    ## $emtrends
    ##  cueType noise1frames_behav.trend      SE   df lower.CL  upper.CL
    ##  50% cue                 -0.01055 0.00497 1601 -0.02030 -0.000802
    ##  80% cue                  0.00212 0.00276 1601 -0.00329  0.007532
    ## 
    ## Confidence level used: 0.95 
    ## 
    ## $contrasts
    ##  contrast          estimate      SE   df t.ratio p.value
    ##  50% cue - 80% cue  -0.0127 0.00568 1601  -2.230  0.0259

### model data

``` r
# run model
m <- modelData %>%
  filter(respPeriod != 'noise1') %>%
  lm(vizLocked_respFrame_t ~ noise1frames_behav * cueType, ., contrasts = list(cueType = contr.sum))

# compute expected marginal means
emm <- emmeans(m, consec ~ noise1frames_behav | cueType, cov.reduce=quantile)

# get range of x-values for plotting
noise_vals <- unique(summary(emm)$emmeans$noise1frames_behav)

# quick plot
#emmip(m,  ~ noise1frames_behav | cueType, cov.reduce=quantile, CIs=T, plotit=T)

# save plot-formatted emmeans
emm_df <- emmip(m,  ~ noise1frames_behav | cueType, CIs=T, plotit=F, cov.reduce=F)

# plot emmeans above raw data
modelData %>%
  filter(respPeriod != 'noise1', noise1frames_behav >= min(noise_vals)) %>%
  ggplot(aes(x = noise1frames_behav, y = vizLocked_respFrame_t)) +
  theme_bw() +
  geom_point(aes(color=cueType), alpha=0.5, size=0.5) +
  geom_ribbon(aes(xvar, yvar, ymin=LCL, ymax=UCL, fill=cueType), emm_df, color=NA, alpha=0.5) +
  geom_line(aes(x=xvar, y=yvar, group=cueType), data=emm_df) +
  labs(title = 'effect of cue type & noise1 duration on RTs: model',
       subtitle = 'RT locked to onset of signal1 evidence, plotted on the scale of seconds')
```

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20noise1frames%20+%20cueType:%20model-1.png)<!-- -->

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
    ## -2.1827 -1.1583 -0.3340  0.9413  7.8579 
    ## 
    ## Coefficients:
    ##                               Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)                  2.0346920  0.0635804  32.002  < 2e-16 ***
    ## noise1frames_behav          -0.0029556  0.0006914  -4.275 1.92e-05 ***
    ## cueType1                     0.2655182  0.0635804   4.176 2.98e-05 ***
    ## noise1frames_behav:cueType1  0.0016282  0.0006914   2.355   0.0185 *  
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 1.488 on 13670 degrees of freedom
    ## Multiple R-squared:  0.06743,    Adjusted R-squared:  0.06722 
    ## F-statistic: 329.5 on 3 and 13670 DF,  p-value: < 2.2e-16

``` r
# emmeans(m, consec ~ noise1frames_behav | cueType, cov.reduce=range)$contrasts
emtrends(m, consec ~ cueType, var='noise1frames_behav')
```

    ## $emtrends
    ##  cueType noise1frames_behav.trend      SE    df lower.CL  upper.CL
    ##  50% cue                 -0.00133 0.00090 13670 -0.00309  0.000437
    ##  80% cue                 -0.00458 0.00105 13670 -0.00664 -0.002527
    ## 
    ## Confidence level used: 0.95 
    ## 
    ## $contrasts
    ##  contrast          estimate      SE    df t.ratio p.value
    ##  80% cue - 50% cue -0.00326 0.00138 13670  -2.355  0.0185

## effect of noise2 duration + cueType on zlogRT in signal2

### human data

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
  geom_line(aes(x=xvar, y=yvar, group=cueType, color=cueType), data=emm_df, linewidth=1.5) +
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
#emmeans(m, pairwise ~ cueType | noise2frames_behav, cov.reduce=range)$contrasts
emtrends(m, pairwise ~ cueType, var='noise2frames_behav')
```

    ## $emtrends
    ##  cueType noise2frames_behav.trend      SE  df lower.CL upper.CL
    ##  50% cue                -0.000368 0.00436 791 -0.00892  0.00819
    ##  80% cue                -0.003808 0.00279 791 -0.00928  0.00167
    ## 
    ## Confidence level used: 0.95 
    ## 
    ## $contrasts
    ##  contrast          estimate      SE  df t.ratio p.value
    ##  50% cue - 80% cue  0.00344 0.00517 791   0.665  0.5063

## effect of noise2 duration + cueType on zlogRT in signal2

### model data

``` r
# fit model
m <- modelData %>%
  filter(respPeriod == 'signal2') %>%
  lm(vizLocked_sig2Resp ~ noise2frames_behav * cueType, ., contrasts = list(cueType = contr.sum))

# compute expected marginal means
emm <- emmeans(m, consec ~ noise2frames_behav | cueType, cov.reduce=quantile)

# get range of x-values for plotting
noise_vals <- unique(summary(emm)$emmeans$noise2frames_behav)

# quick plot
# emmip(m,  ~ noise2frames_behav | cueType, cov.reduce=quantile, CIs=T, plotit=T)

# save plot-formatted emmeans
emm_df <- emmip(m,  ~ noise2frames_behav | cueType, CIs=T, plotit=F,
                at=list(noise2frames_behav = noise_vals))

# plot emmeans above raw data
modelData %>%
  filter(respPeriod == 'signal2') %>%
  filter(noise2frames_behav >= min(noise_vals)) %>%
  ggplot(aes(x = noise2frames_behav, y = vizLocked_sig2Resp)) +
  theme_bw() +
  geom_point(aes(color=cueType), alpha=0.5, size=1) +
  geom_ribbon(aes(xvar, yvar, ymin=LCL, ymax=UCL, fill=cueType), emm_df, color=NA, alpha=0.5) +
  geom_line(aes(x=xvar, y=yvar, group=cueType), data=emm_df) +
  labs(title = 'signal2 RTs locked to onset of signal2 visual evidence')
```

![](pilot_analysis_files/figure-gfm/vizLocked_sig2Resp%20~%20noise2frames_behav%20+%20cueType:%20model-1.png)<!-- -->

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
    ## -1.3826 -0.7687 -0.3444  0.4211  6.5483 
    ## 
    ## Coefficients:
    ##                               Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)                  1.1817302  0.0788667  14.984  < 2e-16 ***
    ## noise2frames_behav          -0.0008271  0.0008601  -0.962  0.33629    
    ## cueType1                    -0.0517804  0.0788667  -0.657  0.51149    
    ## noise2frames_behav:cueType1  0.0024419  0.0008601   2.839  0.00454 ** 
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 1.097 on 5472 degrees of freedom
    ##   (106 observations deleted due to missingness)
    ## Multiple R-squared:  0.02432,    Adjusted R-squared:  0.02379 
    ## F-statistic: 45.47 on 3 and 5472 DF,  p-value: < 2.2e-16

``` r
print(emm)
```

    ## $emmeans
    ## cueType = 50% cue:
    ##  noise2frames_behav emmean     SE   df lower.CL upper.CL
    ##                  75  1.251 0.0244 5472    1.203    1.299
    ##                  79  1.258 0.0227 5472    1.213    1.302
    ##                  85  1.267 0.0211 5472    1.226    1.309
    ##                  97  1.287 0.0221 5472    1.243    1.330
    ##                 270  1.566 0.1671 5472    1.238    1.893
    ## 
    ## cueType = 80% cue:
    ##  noise2frames_behav emmean     SE   df lower.CL upper.CL
    ##                  75  0.988 0.0309 5472    0.928    1.049
    ##                  79  0.975 0.0270 5472    0.922    1.028
    ##                  85  0.956 0.0226 5472    0.911    1.000
    ##                  97  0.916 0.0232 5472    0.871    0.962
    ##                 270  0.351 0.2623 5472   -0.163    0.865
    ## 
    ## Confidence level used: 0.95 
    ## 
    ## $contrasts
    ## cueType = 50% cue:
    ##  contrast                                     estimate      SE   df t.ratio
    ##  noise2frames_behav79 - noise2frames_behav75   0.00646 0.00366 5472   1.763
    ##  noise2frames_behav85 - noise2frames_behav79   0.00969 0.00550 5472   1.763
    ##  noise2frames_behav97 - noise2frames_behav85   0.01938 0.01099 5472   1.763
    ##  noise2frames_behav270 - noise2frames_behav97  0.27937 0.15845 5472   1.763
    ##  p.value
    ##   0.0779
    ##   0.0779
    ##   0.0779
    ##   0.0779
    ## 
    ## cueType = 80% cue:
    ##  contrast                                     estimate      SE   df t.ratio
    ##  noise2frames_behav79 - noise2frames_behav75  -0.01308 0.00582 5472  -2.245
    ##  noise2frames_behav85 - noise2frames_behav79  -0.01961 0.00874 5472  -2.245
    ##  noise2frames_behav97 - noise2frames_behav85  -0.03923 0.01747 5472  -2.245
    ##  noise2frames_behav270 - noise2frames_behav97 -0.56554 0.25191 5472  -2.245
    ##  p.value
    ##   0.0248
    ##   0.0248
    ##   0.0248
    ##   0.0248
    ## 
    ## P value adjustment: mvt method for 4 tests

``` r
emtrends(m, pairwise ~ cueType, var='noise2frames_behav')
```

    ## $emtrends
    ##  cueType noise2frames_behav.trend       SE   df  lower.CL  upper.CL
    ##  50% cue                  0.00161 0.000916 5472 -0.000181  0.003410
    ##  80% cue                 -0.00327 0.001456 5472 -0.006124 -0.000414
    ## 
    ## Confidence level used: 0.95 
    ## 
    ## $contrasts
    ##  contrast          estimate      SE   df t.ratio p.value
    ##  50% cue - 80% cue  0.00488 0.00172 5472   2.839  0.0045

# Response probability analyses

## for noise 1 responses only, probability of making cue-based response as a function of noise1 duration

### human data

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
#emmip(m, ~ noise1frames_behav, type='response', CIs=T, at=list(noise1frames_behav=noise_vals))

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

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal1%20~%20noise1frames_behav-1.png)<!-- -->

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

### model data

``` r
# filter data & fit model
m <- modelData %>%
  filter(respPeriod == 'noise1', cue==0.8) %>%
  glm(forcedChoice ~ noise1frames_behav, ., family='binomial')

# compute expected marginal means
emm <- emmeans(m, consec ~ noise1frames_behav, type='response', cov.reduce=quantile)

# get noise values from emmeans call
noise_vals <- unique(summary(emm)$emmeans$noise1frames_behav)

# quick plot
#emmip(m, ~ noise1frames_behav, type='response', CIs=T, at=list(noise1frames_behav=noise_vals))

# save plot-formatted emmeans
emm_df <- emmip(m,  ~ noise1frames_behav, type='response', CIs=T, plotit=F, at=list(noise1frames_behav=noise_vals))

# plot emmeans above raw data
modelData %>%
  filter(respPeriod == 'noise1', cue==0.8) %>%
  ggplot(aes(x = noise1frames_behav, y = forcedChoice)) +
  theme_bw() + 
  geom_hline(yintercept=0.5, linetype='dashed') +
  geom_point(position=position_jitter(height=0.05)) +
  # add emmeans
  geom_ribbon(aes(x=xvar, y=yvar, ymin=LCL, ymax=UCL), data=emm_df, alpha=0.1) +
  geom_line(aes(x=xvar, y=yvar), data=emm_df) +
  labs(title = 'in noise1, probability of responding according to cue (80% cues only)')
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal1%20~%20noise1frames_behav:%20model-1.png)<!-- -->

``` r
summary(m)
```

    ## 
    ## Call:
    ## glm(formula = forcedChoice ~ noise1frames_behav, family = "binomial", 
    ##     data = .)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -1.9770   0.6250   0.6378   0.6442   0.6639  
    ## 
    ## Coefficients:
    ##                    Estimate Std. Error z value Pr(>|z|)    
    ## (Intercept)        1.331288   0.232831   5.718 1.08e-08 ***
    ## noise1frames_behav 0.001859   0.002696   0.690     0.49    
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 1098.0  on 1146  degrees of freedom
    ## Residual deviance: 1097.5  on 1145  degrees of freedom
    ##   (44 observations deleted due to missingness)
    ## AIC: 1101.5
    ## 
    ## Number of Fisher Scoring iterations: 4

``` r
print(emm)
```

    ## $emmeans
    ##  noise1frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                  25 0.799 0.0274 Inf     0.740     0.847
    ##                  61 0.809 0.0146 Inf     0.779     0.836
    ##                  73 0.813 0.0121 Inf     0.788     0.835
    ##                  97 0.819 0.0128 Inf     0.793     0.843
    ##                 265 0.861 0.0598 Inf     0.699     0.943
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale 
    ## 
    ## $contrasts
    ##  contrast                                     odds.ratio     SE  df null
    ##  noise1frames_behav61 / noise1frames_behav25        1.07 0.1038 Inf    1
    ##  noise1frames_behav73 / noise1frames_behav61        1.02 0.0331 Inf    1
    ##  noise1frames_behav97 / noise1frames_behav73        1.05 0.0676 Inf    1
    ##  noise1frames_behav265 / noise1frames_behav97       1.37 0.6188 Inf    1
    ##  z.ratio p.value
    ##    0.690  0.4905
    ##    0.690  0.4905
    ##    0.690  0.4905
    ##    0.690  0.4905
    ## 
    ## P value adjustment: mvt method for 4 tests 
    ## Tests are performed on the log odds ratio scale

## For signal 2 responses only, probability of making cue-based response as a function of noise2 duration

### human data

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
# emmip(m, ~ noise2frames_behav, type='response', at=list(noise2frames_behav=noise_vals),
#       CIs=T, cov.reduce=F)

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

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav-1.png)<!-- -->

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

### model data

``` r
# filter data & fit model
m <- modelData %>%
  filter(respPeriod == 'signal2', cue==0.8) %>%
  glm(forcedChoice ~ noise2frames_behav, ., family='binomial')

# compute expected marginal means
emm <- emmeans(m, consec ~ noise2frames_behav, type='response', cov.reduce=quantile)

# get noise values from emmeans call
noise_vals <- unique(summary(emm)$emmean$noise2frames_behav)

# quick plot
# emmip(m, ~ noise2frames_behav, type='response', at=list(noise2frames_behav=noise_vals),
#       CIs=T, cov.reduce=F)

# save plot-formatted emmeans
emm_df <- emmip(m, ~ noise2frames_behav, type='response', at=list(noise2frames_behav=noise_vals),
                CIs=T, plotit=F, cov.reduce=F)

# plot emmeans above raw data
 modelData %>%
  filter(respPeriod == 'signal2', cue==0.8) %>% 
  ggplot(aes(x = noise2frames_behav, y = forcedChoice)) +
  theme_bw() +
  geom_hline(yintercept=0.5, linetype='dashed') +
  geom_point(position=position_jitter(height=0.05), size=1) +
  # add emmeans
  geom_ribbon(aes(x=xvar, y=yvar, ymin=LCL, ymax=UCL), data=emm_df, alpha=0.1) +
  geom_line(aes(x=xvar, y=yvar), data=emm_df) +
  labs(title = 'probability of making cueCongruent signal2 response as a function of noise2 duration (80% cues only)')
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav:%20model-1.png)<!-- -->

``` r
summary(m)
```

    ## 
    ## Call:
    ## glm(formula = forcedChoice ~ noise2frames_behav, family = "binomial", 
    ##     data = .)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -2.1968   0.6850   0.7440   0.7704   0.7861  
    ## 
    ## Coefficients:
    ##                    Estimate Std. Error z value Pr(>|z|)  
    ## (Intercept)        0.514715   0.304327   1.691   0.0908 .
    ## noise2frames_behav 0.006683   0.003353   1.993   0.0462 *
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 3008.2  on 2692  degrees of freedom
    ## Residual deviance: 3004.0  on 2691  degrees of freedom
    ##   (67 observations deleted due to missingness)
    ## AIC: 3008
    ## 
    ## Number of Fisher Scoring iterations: 4

``` r
print(emm)
```

    ## $emmeans
    ##  noise2frames_behav  prob      SE  df asymp.LCL asymp.UCL
    ##                  75 0.734 0.01303 Inf     0.708     0.759
    ##                  80 0.741 0.01065 Inf     0.719     0.761
    ##                  87 0.750 0.00858 Inf     0.732     0.766
    ##                  98 0.763 0.00950 Inf     0.744     0.781
    ##                 270 0.910 0.04940 Inf     0.756     0.971
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale 
    ## 
    ## $contrasts
    ##  contrast                                     odds.ratio     SE  df null
    ##  noise2frames_behav80 / noise2frames_behav75        1.03 0.0173 Inf    1
    ##  noise2frames_behav87 / noise2frames_behav80        1.05 0.0246 Inf    1
    ##  noise2frames_behav98 / noise2frames_behav87        1.08 0.0397 Inf    1
    ##  noise2frames_behav270 / noise2frames_behav98       3.16 1.8207 Inf    1
    ##  z.ratio p.value
    ##    1.993  0.0462
    ##    1.993  0.0462
    ##    1.993  0.0462
    ##    1.993  0.0462
    ## 
    ## P value adjustment: mvt method for 4 tests 
    ## Tests are performed on the log odds ratio scale

## Effect of signal1 evidence + noise2 duration on choice probabilities in signal2: 80% cues

### human data

``` r
# fit model
m <- inferenceData_tidy %>%
    filter(catch_trial==0) %>%
    filter(respPeriod == 'signal2', cueIdx < 3) %>%
    # fit model
    glm(cueCongChoice ~ noise2frames_behav * signal1_cueEv, ., family = 'binomial')

# compute expected marginal means
emm <- emmeans(m, ~ noise2frames_behav | signal1_cueEv, type='response', cov.reduce=F)

# get predictor values from emmeans call
noise_vals <- unique(summary(emm)$noise2frames_behav)
signal_vals <- unique(summary(emm)$signal1_cueEv)

# quick plot
# emmip(m, signal1_cueEv ~ noise2frames_behav, type='response', CIs=T,
#       at = list(signal1_cueEv = signal_vals,
#                 noise2frames_behav = noise_vals))

# save plot-formatted emmeans
emm_df <- emmip(m, signal1_cueEv ~ noise2frames_behav, type='response', CIs=T, plotit=F,
                at = list(signal1_cueEv = signal_vals,
                          noise2frames_behav = noise_vals)) %>%
  mutate(signal1_cueEv = as.numeric(signal1_cueEv))

# plot emmeans over raw data
inferenceData_tidy %>%
  filter(catch_trial == 0, respPeriod=='signal2', cueIdx < 3) %>%
  ggplot(aes(x=noise2frames_behav, y=cueCongChoice)) +
  theme_bw() + geom_hline(yintercept=0.5, linetype='dashed') + 
  scale_color_gradient2() + scale_fill_gradient2() + 
  geom_point(aes(color=signal1_cueEv), size=1.5, position=position_jitter(height=0.1)) + 
  # add emmeans
  geom_line(aes(xvar, yvar, color=signal1_cueEv, group=signal1_cueEv), emm_df, linewidth=0.5) +
  labs(title = 'Probability of making a cue-congruent choice as a function of signal1 evidence & noise 2 duration')
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav%20*%20signal1Ev%20-%20continuous%20color:%20human-1.png)<!-- -->

### model data

``` r
# filter data
m <- modelData %>%
    filter(respPeriod == 'signal2', cue==0.8) %>% 
    # fit model
    glm(forcedChoice ~ noise2frames_behav * signal1_vizEv, ., family = 'binomial')

# compute expected marginal means
emm <- emmeans(m, ~ noise2frames_behav | signal1_vizEv, type='response', cov.reduce=range)

# save plot-formatted emmeans
m_df <- modelData %>% filter(respPeriod == 'signal2', cue==0.8)
emm_df <- emmip(m, signal1_vizEv ~ noise2frames_behav, type='response', CIs=T, plotit=F,
                at = list(signal1_vizEv = varRange(m_df, 'signal1_vizEv', 5),
                          noise2frames_behav = varRange(m_df, 'noise2frames_behav', 5))) %>%
  mutate(signal1_vizEv = as.numeric(signal1_vizEv))

# plot emmeans over raw data
modelData %>%
  filter(respPeriod=='signal2', cue == 0.8) %>%
  ggplot(aes(x=noise2frames_behav, y=forcedChoice)) +
  theme_bw() + geom_hline(yintercept=0.5, linetype='dashed') + 
  scale_color_gradient2() + scale_fill_gradient2() + 
  geom_point(aes(color=signal1_vizEv), size=1.5, position=position_jitter(height=0.1)) + 
  # add emmeans
  geom_line(aes(xvar, yvar, color=signal1_vizEv, group=signal1_vizEv), emm_df, linewidth=0.5) +
  labs(title = 'Probability of making a cue-congruent choice as a function of signal1 evidence & noise 2 duration')
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav%20*%20signal1Ev%20-%20continuous%20color:%20model-1.png)<!-- -->
