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

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20cueType:%20humans-1.png)<!-- -->

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

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20cueType:%20model-1.png)<!-- -->

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

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20noise1frames%20+%20cueType-1.png)<!-- -->

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

![](pilot_analysis_files/figure-gfm/zlogRT%20~%20noise1frames%20+%20cueType:%20model-1.png)<!-- -->

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

![](pilot_analysis_files/figure-gfm/vizLocked_sig2Resp%20~%20noise2frames_behav%20+%20cueType:%20humans-1.png)<!-- -->

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

![](pilot_analysis_files/figure-gfm/vizLocked_sig2Resp%20~%20noise2frames_behav%20+%20cueType:%20model-1.png)<!-- -->

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

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal1%20~%20noise1frames_behav:%20humans-1.png)<!-- -->

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

    ## $emmeans
    ##  noise1frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                   4 0.846 0.0461 Inf     0.733     0.917
    ##                 161 0.901 0.0654 Inf     0.684     0.975
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale 
    ## 
    ## $contrasts
    ##  contrast                                    odds.ratio   SE  df null z.ratio
    ##  noise1frames_behav161 / noise1frames_behav4       1.66 1.72 Inf    1   0.490
    ##  p.value
    ##   0.6240
    ## 
    ## Tests are performed on the log odds ratio scale

### model data

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal1%20~%20noise1frames_behav:%20model-1.png)<!-- -->

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

    ## $emmeans
    ##  noise1frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                  25 0.799 0.0274 Inf     0.740     0.847
    ##                 265 0.861 0.0598 Inf     0.699     0.943
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale 
    ## 
    ## $contrasts
    ##  contrast                                     odds.ratio   SE  df null z.ratio
    ##  noise1frames_behav265 / noise1frames_behav25       1.56 1.01 Inf    1   0.690
    ##  p.value
    ##   0.4905
    ## 
    ## Tests are performed on the log odds ratio scale

## For signal 2 responses only, probability of making cue-based response as a function of noise2 duration

### human data

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav:%20humans-1.png)<!-- -->

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

    ## $emmeans
    ##  noise2frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                  75 0.628 0.0284 Inf      0.57     0.681
    ##                 195 0.735 0.1015 Inf      0.50     0.885
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale 
    ## 
    ## $contrasts
    ##  contrast                                     odds.ratio    SE  df null z.ratio
    ##  noise2frames_behav195 / noise2frames_behav75       1.65 0.992 Inf    1   0.828
    ##  p.value
    ##   0.4079
    ## 
    ## Tests are performed on the log odds ratio scale

### model data

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav:%20model-1.png)<!-- -->

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

    ## $emmeans
    ##  noise2frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                  75 0.734 0.0130 Inf     0.708     0.759
    ##                 270 0.910 0.0494 Inf     0.756     0.971
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale 
    ## 
    ## $contrasts
    ##  contrast                                     odds.ratio   SE  df null z.ratio
    ##  noise2frames_behav270 / noise2frames_behav75       3.68 2.41 Inf    1   1.993
    ##  p.value
    ##   0.0462
    ## 
    ## Tests are performed on the log odds ratio scale

## Effect of signal1 evidence + noise2 duration on choice probabilities in signal2: 80% cues

### human data

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav%20*%20signal1Ev%20-%20continuous%20color:%20human-1.png)<!-- -->

    ## $emmeans
    ## signal1_cueEv = -12:
    ##  noise2frames_behav   prob     SE  df asymp.LCL asymp.UCL
    ##                  75 0.4885 0.1042 Inf   0.29671     0.684
    ##                 195 0.9872 0.0235 Inf   0.66678     1.000
    ## 
    ## signal1_cueEv =  14:
    ##  noise2frames_behav   prob     SE  df asymp.LCL asymp.UCL
    ##                  75 0.7569 0.0817 Inf   0.56593     0.881
    ##                 195 0.0755 0.1309 Inf   0.00206     0.763
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale 
    ## 
    ## $contrasts
    ## signal1_cueEv = -12:
    ##  contrast                     odds.ratio    SE  df null z.ratio p.value
    ##  noise2frames_behav75 effect       0.111 0.120 Inf    1  -2.037  0.0416
    ##  noise2frames_behav195 effect      8.990 9.692 Inf    1   2.037  0.0416
    ## 
    ## signal1_cueEv = 14:
    ##  contrast                     odds.ratio    SE  df null z.ratio p.value
    ##  noise2frames_behav75 effect       6.176 6.762 Inf    1   1.663  0.0963
    ##  noise2frames_behav195 effect      0.162 0.177 Inf    1  -1.663  0.0963
    ## 
    ## P value adjustment: fdr method for 2 tests 
    ## Tests are performed on the log odds ratio scale

### model data

![](pilot_analysis_files/figure-gfm/cueCongChoice_signal2%20~%20noise2frames_behav%20*%20signal1Ev%20-%20continuous%20color:%20model-1.png)<!-- -->

    ## $emmeans
    ## signal1_vizEv = -23.6:
    ##  noise2frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                  75 0.426 0.0795 Inf   0.28201     0.584
    ##                 270 0.815 0.4458 Inf   0.01327     0.999
    ## 
    ## signal1_vizEv =  29.2:
    ##  noise2frames_behav  prob     SE  df asymp.LCL asymp.UCL
    ##                  75 0.955 0.0221 Inf   0.88537     0.983
    ##                 270 0.980 0.0942 Inf   0.00447     1.000
    ## 
    ## Confidence level used: 0.95 
    ## Intervals are back-transformed from the logit scale 
    ## 
    ## $contrasts
    ## signal1_vizEv = -23.5863865880377:
    ##  contrast                     odds.ratio    SE  df null z.ratio p.value
    ##  noise2frames_behav75 effect       0.411 0.654 Inf    1  -0.559  0.5765
    ##  noise2frames_behav270 effect      2.434 3.877 Inf    1   0.559  0.5765
    ## 
    ## signal1_vizEv = 29.2487909523756:
    ##  contrast                     odds.ratio    SE  df null z.ratio p.value
    ##  noise2frames_behav75 effect       0.660 1.683 Inf    1  -0.163  0.8707
    ##  noise2frames_behav270 effect      1.514 3.860 Inf    1   0.163  0.8707
    ## 
    ## P value adjustment: fdr method for 2 tests 
    ## Tests are performed on the log odds ratio scale
