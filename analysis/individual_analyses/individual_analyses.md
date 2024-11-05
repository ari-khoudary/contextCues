visualizing individual subjects data
================

- [calibration data](#calibration-data)
- [learning data](#learning-data)
- [inference data](#inference-data)

this notebook is devoted to investigating how individual subjects
performed during calibration, learning, and inference. key questions
that it aims to address are:

1.  what do the staircases look like during calibration?
2.  what coherence levels did each subject observe for each stimulus?
3.  how accurately were they making button presses during learning?
4.  what do their RTs look like during learning?
5.  are the learned choice probabilities reflected in decision accuracy?

## calibration data

### what do the staircases look like during calibration?

solid line indicates the level of decision accuracy we are calibrating
to.
![](individual_analyses_files/figure-gfm/plot%20calibration%20data-1.png)<!-- -->

### what coherence levels did each subject observe for each stimulus?

coherence values that obtained 70% accuracy for each image for each
subject:

| subID | img1Path  | img1Coh | img2Path  | img2Coh |
|------:|:----------|--------:|:----------|--------:|
|    12 | S1-15.jpg |    0.77 | S2-19.jpg |    0.76 |
|    13 | S3-12.jpg |    0.78 | S4-20.jpg |    0.70 |
|    14 | S3-12.jpg |    0.78 | S4-20.jpg |    0.72 |
|    15 | S3-12.jpg |    0.78 | S4-20.jpg |    0.76 |
|    17 | S1-15.jpg |    0.74 | S2-19.jpg |    0.74 |
|    18 | S3-12.jpg |    0.78 | S4-20.jpg |    0.77 |
|    19 | S1-15.jpg |    0.77 | S2-19.jpg |    0.68 |
|    20 | S3-12.jpg |    0.77 | S4-20.jpg |    0.78 |
|    22 | S1-15.jpg |    0.69 | S2-19.jpg |    0.52 |
|    23 | S3-12.jpg |    0.58 | S4-20.jpg |    0.55 |
|    24 | S3-12.jpg |    0.68 | S4-20.jpg |    0.55 |
|    25 | S3-12.jpg |    0.74 | S4-20.jpg |    0.54 |
|    26 | S1-15.jpg |    0.59 | S2-19.jpg |    0.68 |
|    27 | S2-19.jpg |    0.58 | S1-15.jpg |    0.68 |

<img src="../../imageGrid.png" width="350px" style="display: block; margin: auto;" />

------------------------------------------------------------------------

## learning data

### how accurately were they making button presses during learning?

![](individual_analyses_files/figure-gfm/learning%20accuracy-1.png)<!-- -->

### what do their RTs look like during learning?

![](individual_analyses_files/figure-gfm/learning%20RTs-1.png)<!-- -->

------------------------------------------------------------------------

## inference data

### what can learning RTs for each cue tell us about how those cues affect decision performance?

![](individual_analyses_files/figure-gfm/group%20inference%20summary-1.png)<!-- -->

![](individual_analyses_files/figure-gfm/individual%20learnRTs%20+%20decision%20accuracy-1.png)<!-- -->
