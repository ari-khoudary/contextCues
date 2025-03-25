%% timing & number of trials for each experimental phase

%%% response training
criterion = 0.8; % required accuracy level on button mappings
trialsPerImage = 2;
trainTrialDuration = 1.5; % seconds
trainITI = 0.75;

%%% calibration
if debugging
    calibrationTrialsPerImage = 4; % staircase trials per image
else
    calibrationTrialsPerImage = 40; % staircase trials per image
end
calibrationTrialN = nImages * calibrationTrialsPerImage;
feedbackDuration = 1.5; % seconds 

%%% coherence validation
if debugging
    cohFeedbackTotalN = 8;
else
    cohFeedbackTotalN = 40;
end
pFeedbackTrial = 0.25;
nFeedbackTrial = ceil(cohFeedbackTotalN * pFeedbackTrial);
nConfidenceTrial = cohFeedbackTotalN - nFeedbackTrial;

%%% cue learning
learningCriterion = 0.6; % what level of accuracy per cue is needed to move on from cue learning
learnImgDuration = 1.5;
if debugging
    learnTrialPerCue = 6;
else
    learnTrialPerCue = 30;
end
learnTrialN = nCues * learnTrialPerCue;

%%% cued inference
if debugging
    inferenceTrialPerCue = 10;
else
    inferenceTrialPerCue = 150;
end
halfNeutral = 1; % boolean: do you want to have half as many neutral cue trials?
inferenceITI = 1;
inferenceISI = 0.75;
confidenceDuration = 3;
nInferenceBreaks = 4;
