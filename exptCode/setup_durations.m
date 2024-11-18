%% define timing variables 

% visual interfilp interval / sampling rate
ifi = 1/60;
waitframes = 1;

% create a general distribution
lambda = 0.12;
noiseMin = round(0.75/ifi);
signalMin = round(0.5/ifi);
noisePDF = discrete_bounded_hazard_rate(lambda, noiseMin);
signalPDF = discrete_bounded_hazard_rate(lambda, signalMin);

%% create noise & signal durations for coherence validation

noiseDistribution_v = ceil(noisePDF * cohFeedbackTotalN);
noiseFrames_v = zeros(cohFeedbackTotalN, 1);
trialCount = cumsum(noiseDistribution_v);
for i = 1:length(noiseDistribution_v)
    if i==1
        noiseFrames_v(1:noiseDistribution_v(i))=1;
    else
        startrow = trialCount(i) - noiseDistribution_v(i);
        endrow = trialCount(i);
        noiseFrames_v(startrow:endrow) = i;
    end
end

% add baseline of noiseMin seconds, keep in frames because that's how the
% flicker stream is specified
noise1Frames_v = Shuffle(noiseFrames_v + noiseMin);
noise2Frames_v = Shuffle(noise1Frames_v);

% create signal frames
signalDistribution_v = round(signalPDF * cohFeedbackTotalN);
signal1Frames_v = zeros(cohFeedbackTotalN, 1);
trialCount = cumsum(signalDistribution_v);
for i=1:length(signalDistribution_v)
    if i==1
        signal1Frames_v(1:signalDistribution_v(i)) = 1;
    else
        startrow = trialCount(i) - signalDistribution_v(i);
        endrow = trialCount(i);
        signal1Frames_v(startrow:endrow) = i;
    end
end
signal1Frames_v = Shuffle(signal1Frames_v + signalMin);

% define max flicker durations
noise1max_v = max(noise1Frames_v*ifi);
signal1max_v = max(signal1Frames_v*ifi);
noise2max_v = max(noise2Frames_v*ifi);
minFlicker_v = noise1max_v + signal1max_v + noise2max_v;
nFrames_v = round(minFlicker_v) / ifi;

%% create cue duration distribution for learning
cueDistribution = round(noisePDF * learnTrialN);
cueDurations = zeros(learnTrialN, 1);
trialCount = cumsum(cueDistribution);
for i = 1:length(cueDistribution)
    if i==1
        cueDurations(1:cueDistribution(i))=1;
    else
        startrow = trialCount(i) - cueDistribution(i);
        endrow = trialCount(i);
        cueDurations(startrow:endrow) = i;
    end
end

% add baseline of 1.25 seconds & randomize
cueDurations = (cueDurations + noiseMin)*ifi;
cueDurations = Shuffle(cueDurations);

%% create noise1 and noise 2 distributions
noiseDistribution = round(noisePDF * inferenceTrialN);
noiseFrames = zeros(inferenceTrialN, 1);
trialCount = cumsum(noiseDistribution);
for i = 1:length(noiseDistribution)
    if i==1
        noiseFrames(1:noiseDistribution(i))=1;
    else
        startrow = trialCount(i) - noiseDistribution(i);
        endrow = trialCount(i);
        noiseFrames(startrow:endrow) = i;
    end
end

% add baseline of 1.25 seconds, keep in frames because that's how the
% flicker stream is specified
noise1Frames = Shuffle(noiseFrames + noiseMin);
noise2Frames = Shuffle(noise1Frames);

% create signal frames
signal1Frames = Shuffle(noiseFrames + signalMin);

% ensure no repetition of durations across catch & test trials
durations_rIdx = randperm(length(noise1Frames));
durations_idx_test = Shuffle(setdiff(durations_rIdx, catch_trials));
noise1Frames_test = noise1Frames(durations_idx_test);
noise2Frames_test = noise2Frames(durations_idx_test);
signal1Frames_test = signal1Frames(durations_idx_test);

% durations for catch trials
noise1Frames_catch = noise1Frames(catch_trials);
noise2Frames_catch = noise2Frames(catch_trials);
signal1Frames_catch = signal1Frames(catch_trials);

%% define max flicker duration
noise1max = max(noise1Frames*ifi);
signal1max = max(signal1Frames*ifi);
noise2max = max(noise2Frames*ifi);
minFlicker = noise1max + signal1max + noise2max;
nFrames = round(minFlicker) / ifi;