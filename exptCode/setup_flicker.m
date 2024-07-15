%%  make flicker streams on each trial of cuedInference

% scripts/chunks that need to be run before this one will work: 
% - "high-level experiment settings" in mainExpt.m
% - "task settings for each phase of the experiment" in mainExpt.m
% - setup_trials.m
% - setup_durations.m
% 
% the script also assumes 3 different cues. it will need to be modified if
% there are more or fewer cues

%% 
% put in generic coherence values if coherence is not yet specified
if exist('coherence', 'var') ==0 
    coherence = [0.51 0.51];
end

% forward & backward mask image frames with noise
inferenceTrialN = length(inferenceCue);
flickerStream = repmat([0; 1], nFrames/2, inferenceTrialN);

% initialize counters
cue1Counter = 0;
cue2Counter = 0;
cue3Counter = 0;
inference_counter_general = 0;

% make flicker stream for each trial
for trial=1:inferenceTrialN
    flickerStream(1:noise1Frames(trial), trial) = 0;
    noise2onset = noise1Frames(trial) + signal1Frames(trial);
    flickerStream(noise2onset:noise2onset+noise2Frames(trial), trial) = 0;

    % get each trial's target
    cueIdx=inferenceCue(trial);
    if cueIdx==1
        cue1Counter=cue1Counter+1;
        inference_counter_general = cue1Counter;
    elseif cueIdx==2
        cue2Counter=cue2Counter+1;
        inference_counter_general = cue2Counter;
    else
        cue3Counter=cue3Counter+1;
        inference_counter_general = cue3Counter;
    end
    target = inferenceImg(cueIdx, inference_counter_general);

    % get indices of non-noise frames
    imgIdx = find(flickerStream(:, trial));
    nImgFrames = length(imgIdx);

    % use coherence to determine number of target frames
    if target==1
        nTargetFrames = ceil(nImgFrames*coherence(1));
    else
        nTargetFrames = ceil(nImgFrames*coherence(2));
    end
    targetIdx = randsample(imgIdx, nTargetFrames);
    lureIdx = setdiff(imgIdx, targetIdx);

    % populate imgFrames with target, in proportion to coherence
    flickerStream(targetIdx, trial) = target;

    % lureIdx is automatically populated when target==2; populate
    % manually when target==1
    if target == 1
        flickerStream(lureIdx, trial) = 2;
    end
end