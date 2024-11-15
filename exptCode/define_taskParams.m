% define task settings for the experiment

%% high-level experiment settings

% task structure
nBlocks = 1; % number of blocks
nCues = 3; % num prior cues per block
nImages = 2; % unique images on which decisions are to be made, per block
pCatchTrial = 0.1; % what proportion of total inference trials do you want to be ADDED ON as catch trials?

% evidence reliabilities
memReliability = 0.8;
vizAccuracy = 0.7;
% vision reliability is technically given by the evidence coherence. to
% control for differences in how the images are processed by different
% people, we use QUEST staircasing to identify coherence values for each image that result in
% vizAccuracy level of performance

% visual evidence presentation rate (interflip interval)
ifi = 1/60;
waitframes = 1;

% number of brief breaks during inference
nInferenceBreaks = 4;

% maximum duration of flicker stream
maxDuration = 4; % in seconds
maxFrames = 4/ifi;

%% timing & number of trials for each experimental phase

%%% response training
criterion = 0.8; % required accuracy level on button mappings
trialsPerImage = 2;
trainTrialDuration = 1.5; % seconds
trainITI = 0.75;

%%% calibration
calibrationITI = 0.75;
if debugging
    calibrationTrialsPerImage = 4; % staircase trials per image
else
    calibrationTrialsPerImage = 40; % staircase trials per image
end
calibrationTrialN = nImages * calibrationTrialsPerImage;
feedbackDuration = 1.5; % seconds 

%%% coherence validation
cohFeedbackTotalN = 30;
pFeedbackTrial = 0.25;
nFeedbackTrial = ceil(cohFeedbackTotalN * pFeedbackTrial);
nConfidenceTrial = cohFeedbackTotalN - nFeedbackTrial;

%%% cue learning
learningCriterion = 0.8; % what level of accuracy per cue is needed to move on from cue learning
learnITI = 1;
learnImgDuration = 2;
if debugging
    learnTrialPerCue = 5;
else
    learnTrialPerCue = 25;
end
learnTrialN = nCues * learnTrialPerCue;

%%% cued inference
if debugging
    inferenceTrialPerCue = 10;
else
    inferenceTrialPerCue = 100;
end
inferenceTrialN = nCues * inferenceTrialPerCue;
halfNeutral = 1; % boolean: do you want to have half as many neutral cue trials?
flickerDuration = 3;
flickerRate = 60; % Hz
inferenceITI = 1;
inferenceISI = 0.75;
confidenceDuration = 3;
