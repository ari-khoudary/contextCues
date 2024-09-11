Pilot analyses: version 3
================

- [data tidying](#data-tidying)
- [RT analyses](#rt-analyses)
  - [effect of cue type on RT across all test
    trials](#effect-of-cue-type-on-rt-across-all-test-trials)
  - [for responses made after noise1, effect of noise1 duration +
    cueType on
    RT](#for-responses-made-after-noise1-effect-of-noise1-duration--cuetype-on-rt)
  - [for signal 2 responses only, effect of noise2 duration + cueType on
    zlogRT](#for-signal-2-responses-only-effect-of-noise2-duration--cuetype-on-zlogrt)
- [Response probability analyses](#response-probability-analyses)
  - [for noise 1 responses only, probability of making cue-based
    response as a function of noise1
    duration](#for-noise-1-responses-only-probability-of-making-cue-based-response-as-a-function-of-noise1-duration)
  - [For signal 2 responses only, probability of making cue-based
    response as a function of noise2
    duration](#for-signal-2-responses-only-probability-of-making-cue-based-response-as-a-function-of-noise2-duration)

# data tidying

``` r
inferenceData_tidy <- inferenceData %>%
  filter(is.na(response)==F) %>%
  mutate(cueType = factor(cueType),
         subID = factor(subID),
         resp1 = ifelse(response==1, 1, 0),
         resp2 = ifelse(response==1, 0, 1),
         respFinger = ifelse(resp1==1, '1', '2'),
         # signal1_rawEv = case_when(response==1 ~ signal1_target1,
         #                           response==2 ~ signal1_target2),
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

## for responses made after noise1, effect of noise1 duration + cueType on RT

``` r
# run model
m <- inferenceData_tidy %>%
  filter(respPeriod != 'noise1') %>%
  lm(vizLocked_respFrame_t ~ noise1frames_behav + cueType, ., contrasts = list(cueType = contr.sum))

# extract coefficient values
estimates <- as.data.frame(stack(coef(m)))

# compute expected marginal means
emm <- emmeans(m, eff ~ noise1frames_behav | cueType, cov.reduce=range)

# quick plot
emmip(m,  ~ noise1frames_behav | cueType, cov.reduce=quantile, CIs=T, plotit=T)
```

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20noise1frames%20+%20cueType-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m,  ~ noise1frames_behav | cueType, CIs=T, plotit=F,
                at=list(noise1frames_behav = unique(inferenceData_tidy$noise1frames_behav)))

# plot emmeans above raw data
inferenceData_tidy %>%
  ggplot(aes(x = noise1frames_behav, y = zlogRT)) +
  theme_bw() +
  facet_wrap(~ cueType, scales = 'free') +
  geom_hline(yintercept=0) +
  geom_point(aes(color=cueType), alpha=0.15, color='black') +
  geom_ribbon(aes(xvar, yvar, ymin=LCL, ymax=UCL, fill=cueType), emm_df, color=NA, alpha=0.5) +
  geom_line(aes(x=xvar, y=yvar), data=emm_df) +
  labs(title = 'effect of cue type & noise1 duration on RTs')
```

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20noise1frames%20+%20cueType-2.png)<!-- -->

``` r
summary(m)
```

    ## 
    ## Call:
    ## lm(formula = vizLocked_respFrame_t ~ noise1frames_behav + cueType, 
    ##     data = ., contrasts = list(cueType = contr.sum))
    ## 
    ## Residuals:
    ##     Min      1Q  Median      3Q     Max 
    ## -2.5324 -1.3524 -0.3342  1.1996  5.0998 
    ## 
    ## Coefficients:
    ##                      Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)         2.5402930  0.2201861  11.537   <2e-16 ***
    ## noise1frames_behav -0.0002238  0.0022983  -0.097    0.922    
    ## cueType1           -0.0280396  0.0478469  -0.586    0.558    
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 1.693 on 1772 degrees of freedom
    ## Multiple R-squared:  0.0002001,  Adjusted R-squared:  -0.0009284 
    ## F-statistic: 0.1773 on 2 and 1772 DF,  p-value: 0.8375

## for signal 2 responses only, effect of noise2 duration + cueType on zlogRT

``` r
# fit model
m <- inferenceData_tidy %>%
  filter(respPeriod == 'signal2') %>%
  lm(vizLocked_sig2Resp ~ noise2frames_behav + cueType, ., contrasts = list(cueType = contr.sum))


# extract coefficient values
estimates <- as.data.frame(stack(coef(m)))

# compute expected marginal means
emm <- emmeans(m, eff ~ noise2frames_behav | cueType, cov.reduce=quantile)

# quick plot
emmip(m,  ~ noise2frames_behav | cueType, cov.reduce=quantile, CIs=T, plotit=T)
```

![](pilot_analysis_files/figure-gfm/vizLocked_sig2Resp%20~%20noise2frames_behav%20+%20cueType-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m,  ~ noise2frames_behav | cueType, CIs=T, plotit=F,
                at=list(noise2frames_behav = unique(inferenceData_tidy$noise2frames_behav)))

# plot emmeans above raw data
inferenceData_tidy %>%
  ggplot(aes(x = noise2frames_behav, y = zlogRT)) +
  theme_bw() +
  facet_wrap(~ cueType, scales = 'free') +
  geom_hline(yintercept=0) +
  geom_point(aes(color=cueType), alpha=0.15, color='black') +
  geom_ribbon(aes(xvar, yvar, ymin=LCL, ymax=UCL, fill=cueType), emm_df, color=NA, alpha=0.5) +
  geom_line(aes(x=xvar, y=yvar), data=emm_df) +
  labs(title = 'signal2 RTs locked to onset of signal2 visual evidence')
```

![](pilot_analysis_files/figure-gfm/vizLocked_sig2Resp%20~%20noise2frames_behav%20+%20cueType-2.png)<!-- -->

``` r
summary(m)
```

    ## 
    ## Call:
    ## lm(formula = vizLocked_sig2Resp ~ noise2frames_behav + cueType, 
    ##     data = ., contrasts = list(cueType = contr.sum))
    ## 
    ## Residuals:
    ##     Min      1Q  Median      3Q     Max 
    ## -1.7842 -0.9492 -0.2359  0.7227  3.9880 
    ## 
    ## Coefficients:
    ##                     Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)         1.948175   0.219745   8.866   <2e-16 ***
    ## noise2frames_behav -0.002726   0.002279  -1.196    0.232    
    ## cueType1           -0.062531   0.048679  -1.285    0.199    
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 1.198 on 865 degrees of freedom
    ## Multiple R-squared:  0.003685,   Adjusted R-squared:  0.001381 
    ## F-statistic:   1.6 on 2 and 865 DF,  p-value: 0.2026

``` r
print(emm)
```

    ## $emmeans
    ## cueType = 50% cue:
    ##  noise2frames_behav emmean     SE  df lower.CL upper.CL
    ##                  75   1.68 0.0968 865    1.491     1.87
    ##                  81   1.66 0.0912 865    1.486     1.84
    ##                  88   1.65 0.0870 865    1.475     1.82
    ##                 101   1.61 0.0868 865    1.440     1.78
    ##                 195   1.35 0.2439 865    0.875     1.83
    ## 
    ## cueType = 80% cue:
    ##  noise2frames_behav emmean     SE  df lower.CL upper.CL
    ##                  75   1.81 0.0621 865    1.684     1.93
    ##                  81   1.79 0.0540 865    1.684     1.90
    ##                  88   1.77 0.0477 865    1.677     1.86
    ##                 101   1.74 0.0495 865    1.638     1.83
    ##                 195   1.48 0.2366 865    1.015     1.94
    ## 
    ## Confidence level used: 0.95 
    ## 
    ## $contrasts
    ## cueType = 50% cue:
    ##  contrast                     estimate     SE  df t.ratio p.value
    ##  noise2frames_behav75 effect    0.0900 0.0752 865   1.196  0.2321
    ##  noise2frames_behav81 effect    0.0736 0.0615 865   1.196  0.2321
    ##  noise2frames_behav88 effect    0.0545 0.0456 865   1.196  0.2321
    ##  noise2frames_behav101 effect   0.0191 0.0160 865   1.196  0.2321
    ##  noise2frames_behav195 effect  -0.2371 0.1983 865  -1.196  0.2321
    ## 
    ## cueType = 80% cue:
    ##  contrast                     estimate     SE  df t.ratio p.value
    ##  noise2frames_behav75 effect    0.0900 0.0752 865   1.196  0.2321
    ##  noise2frames_behav81 effect    0.0736 0.0615 865   1.196  0.2321
    ##  noise2frames_behav88 effect    0.0545 0.0456 865   1.196  0.2321
    ##  noise2frames_behav101 effect   0.0191 0.0160 865   1.196  0.2321
    ##  noise2frames_behav195 effect  -0.2371 0.1983 865  -1.196  0.2321
    ## 
    ## P value adjustment: fdr method for 5 tests

# Response probability analyses

## for noise 1 responses only, probability of making cue-based response as a function of noise1 duration

``` r
# filter data & fit model
m <- inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod == 'noise1') %>%
  glm(cueCongChoice ~ noise1frames_behav, ., family='binomial')

# compute expected marginal means
emm <- emmeans(m, ~ noise1frames_behav, type='response', cov.reduce=quantile)

# quick plot
emmip(m, ~ noise1frames_behav, type='response', CIs=T, cov.reduce=F)
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal1%20~%20noise1frames_behav-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m,  ~ noise1frames_behav, type='response', CIs=T, plotit=F, cov.reduce=F)

# plot emmeans above raw data
inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod == 'noise1') %>%
  ggplot(aes(x = noise1frames_behav, y = cueCongChoice)) +
  theme_bw() + 
  geom_hline(yintercept=0.5, linetype='dashed') +
  geom_point(shape = '|') +
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

    ##  noise1frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                   4 0.846 0.0461 Inf     0.733     0.917
    ##                  34 0.858 0.0241 Inf     0.804     0.899
    ##                  46 0.863 0.0193 Inf     0.820     0.897
    ##                  70 0.872 0.0221 Inf     0.822     0.909
    ##                 161 0.901 0.0654 Inf     0.684     0.975
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale

## For signal 2 responses only, probability of making cue-based response as a function of noise2 duration

``` r
# filter data & fit model
m <- inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod == 'signal2') %>%
  glm(cueCongChoice ~ noise2frames_behav, ., family='binomial')

# compute expected marginal means
emm <- emmeans(m, ~ noise2frames_behav, type='response', cov.reduce=quantile)

# quick plot
emmip(m, ~ noise2frames_behav, type='response', at=quantile,
      CIs=T, cov.reduce=F)
```

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav-1.png)<!-- -->

``` r
# save plot-formatted emmeans
emm_df <- emmip(m, ~ noise2frames_behav, type='response', at=quantile,
                CIs=T, plotit=F, cov.reduce=F)

# plot emmeans above raw data
 inferenceData_tidy %>%
  filter(catch_trial == 0) %>%
  filter(respPeriod == 'signal2') %>% 
  ggplot(aes(x = noise2frames_behav, y = cueCongChoice)) +
  theme_bw() +
  geom_hline(yintercept=0.5, linetype='dashed') +
  geom_point(shape = '|') +
  # add emmeans
  geom_ribbon(aes(x=xvar, y=yvar, ymin=LCL, ymax=UCL), data=emm_df, alpha=0.1) +
  geom_line(aes(x=xvar, y=yvar), data=emm_df) +
  labs(title = 'for signal2 responses only, probability of making cueCongruent response as a function of noise2 duration (80% cues only)')
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

    ##  noise2frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                  75 0.628 0.0284 Inf     0.570     0.681
    ##                  80 0.632 0.0244 Inf     0.583     0.679
    ##                  88 0.640 0.0200 Inf     0.600     0.678
    ##                 100 0.652 0.0208 Inf     0.610     0.691
    ##                 195 0.735 0.1015 Inf     0.500     0.885
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale
