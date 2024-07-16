%% compute probabilistic noise periods that achieve a fixed hazard rate across trials 

% create a general distribution
lambda = 0.05;
maxFrames = 2/ifi;
noisePDF = discrete_bounded_hazard_rate(lambda, maxFrames);
noiseMin = round(1.25/ifi);

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
noiseDistribution = round(noisePDF * inferenceTrialN_total);
noiseFrames = zeros(inferenceTrialN_total, 1);
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
signalMin = round(0.375/ifi);
signal1Frames = Shuffle(noiseFrames + signalMin);

%% define max flicker duration
noise1max = max(noise1Frames*ifi);
signal1max = max(signal1Frames*ifi);
noise2max = max(noise2Frames*ifi);
minFlicker = noise1max + signal1max + noise2max;
nFrames = round(minFlicker) / ifi;


