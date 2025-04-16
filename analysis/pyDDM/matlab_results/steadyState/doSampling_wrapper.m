%% specify simulation settings
clear
nSub = 1;
nTrial = 10; % per cue
cue = [0.5 0.8];
coherence = [0.52];
% coherence = [0.5395];
threshold = [5];
memoryThinning = 12;
visionThinning = 1;
vizPresentationRate = 1/72;

% noise periods
noisePeriods = 1; % logical: do you want 2 noise periods?
noNoiseTrialDuration = 3; % in seconds: how long do you want trials to be if there are no noise periods?
% parameters of the noise periods
expLambda = 0.12; % parameter of the exponential defining the hazard rates 
maxNoiseDuration = 1.25; % seconds
minNoiseDuration = 0.75; % seconds
minSignalDuration = 0.5; % seconds
secondSignalMin = 0.5; % value to be added to signalMin to create a second signal period of additional length

% half neutral trials (boolean)
halfNeutralTrials = 1;

% visual evidence noise
flickerAdditiveNoise = 1;  % logical; do you want to add noise to each sample of visual evidence?
flickerAdditiveNoiseValue = 'gaussian';  % string; what kind of noise do you want to add to each visual evidence sample? gaussian=zero-centered gaussian
flickerPadding = 1;  % logical; do you want to pad each signal frame with a noise frame?
flickerPaddingValue = 'zero'; % string; how do you want to model noise frames? options are zeros, zero-centered gaussian, more to come

% do you want to save frame-by-frame information for each trial?
saveEvidence = 1;
saveFlickerNoise = 0;
saveAccumulators = 1;
saveDV = 1;
saveCounters = 1;
savePrecisions = 1;
saveDrifts = 1;

% where do you want to save the results? (subdirectory of current dir)
outDir = 'results/';
outFile = '';

%% create cell array to store config files
nCombo = length(coherence)*length(cue)*length(threshold)*length(memoryThinning);
allConfigs = repmat({struct('myfield', {})}, 1, nCombo);


%% create config files

counter=0;
for a = 1:length(coherence)
    for b = 1:length(cue)
        for c = 1:length(threshold)
            for d = 1:length(memoryThinning)

                counter=counter+1;
                
                config.nTrial = nTrial;
                config.nSub = nSub;
                config.coherence = coherence(a);
                config.cue = cue(b);
                config.threshold = threshold(c);
                config.memoryThinning = memoryThinning(d);
                config.visionThinning = visionThinning;
                config.vizPresentationRate = vizPresentationRate;
                config.noisePeriods = noisePeriods;
                config.noNoiseTrialDuration = noNoiseTrialDuration;
                
                config.maxNoiseDuration = maxNoiseDuration;
                config.minNoiseDuration = minNoiseDuration;
                config.minSignalDuration = minSignalDuration;
                config.secondSignalMin = secondSignalMin;
                config.expLambda = expLambda;
                
                config.halfNeutralTrials = halfNeutralTrials;
                config.flickerAdditiveNoise = flickerAdditiveNoise;
                config.flickerAdditiveNoiseValue = flickerAdditiveNoiseValue;
                config.flickerNoisePadding = flickerPadding;
                config.flickerPaddingValue = flickerPaddingValue;
                config.saveEvidence = saveEvidence;
                config.saveFlickerNoise = saveFlickerNoise;
                config.saveAccumulators = saveAccumulators;
                config.saveDV = saveDV;
                config.saveCounters = saveCounters;
                config.savePrecisions = savePrecisions;
                config.saveDrifts = saveDrifts;
                config.outDir = outDir;
                config.outFile = outFile;

                allConfigs{counter} = config;
            end
        end
    end
end

%% run simulation
tic
counter=0;
for a = 1:length(coherence)
    for b = 1:length(cue)
        for c = 1:length(threshold)
            for d = 1:length(memoryThinning)
                counter=counter+1;
                thisConfig = allConfigs{counter};
                sprintf(['running coherence=' num2str(coherence(a)) ', cue=' num2str(cue(b)) ', threshold=' num2str(threshold(c)) ' and thinning=' num2str(memoryThinning(d))])
                for subj = 1:nSub
                    thisConfig.subID = subj;
                    doSampling(thisConfig);
                end
            end
        end
    end
end
toc

%% plot results
% plotTrialParams;
%doSampling_summaryPlots;









