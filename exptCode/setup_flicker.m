%%  make flicker streams on each trial of cuedInference

% scripts/chunks that need to be run before this one will work: 
% - "high-level experiment settings" in mainExpt.m
% - "task settings for each phase of the experiment" in mainExpt.m
% - setup_trials.m
% - setup_durations.m
% 
% the script also assumes 3 different cues. it will need to be modified if
% there are more or fewer cues

%% define necessary variables
% put in generic coherence values if coherence is not yet specified
if exist('coherence', 'var') ==0 
    coherence = [0.51 0.51];
end

cue1Counter = 0;
cue2Counter = 0;
cue3Counter = 0;
catchTrialCounter = 0;
inference_counter_general = 0;

%% create flicker
% forward & backward mask image frames with noise
flickerStream = repmat([0; 1], nFrames/2, sum(sum(inferenceTrials)));

% make flicker stream for test trials
for trial=1:sum(sum(inferenceTrials))
    flickerStream(1:noise1Frames_test(trial), trial) = 0;
    noise2onset = noise1Frames_test(trial) + signal1Frames_test(trial);
    flickerStream(noise2onset:noise2onset+noise2Frames_test(trial), trial) = 0;

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
    rIdx = randperm(numel(imgIdx));
    targetIdx = imgIdx(rIdx(1:nTargetFrames));
    lureIdx = setdiff(imgIdx, targetIdx);

    % populate imgFrames with target, in proportion to coherence
    flickerStream(targetIdx, trial) = target;

    % lureIdx is automatically populated when target==2; populate
    % manually when target==1
    if target == 1
        flickerStream(lureIdx, trial) = 2;
    end
end

%% create catch trials

pCatchSignal = 0.1;
flickerCatch = repmat([0; 1], nFrames/2, sum(sum(catchTrials)));

for trial = 1:sum(sum(catchTrials))

    flickerCatch(1:noise1Frames_catch(trial), trial) = 0;
    noise2onset = noise1Frames_catch(trial) + signal1Frames_catch(trial);
    flickerCatch(noise2onset:noise2onset+noise2Frames_catch(trial), trial) = 0;

    cueIdx=catchCue(trial);
    target = catchImg(trial);

    % get indices of non-noise frames
    imgIdx = find(flickerCatch(:, trial));
    nImgFrames = length(imgIdx);

    % use coherence to determine number of target frames
    if target==1
        nTargetFrames = ceil(nImgFrames*coherence(1));
    else
        nTargetFrames = ceil(nImgFrames*coherence(2));
    end
    rIdx = randperm(numel(imgIdx));
    targetIdx = imgIdx(rIdx(1:nTargetFrames));
    lureIdx = setdiff(imgIdx, targetIdx);

    % populate imgFrames with target, in proportion to coherence
    flickerCatch(targetIdx, trial) = target;

    % lureIdx is automatically populated when target==2; populate
    % manually when target==1
    if target == 1
        flickerCatch(lureIdx, trial) = 2;
    end

    % randomly insert some signal frames into the noise periods
    noise1CatchFrames = round(pCatchSignal*noise1Frames_catch(trial));
    noise2CatchFrames = round(pCatchSignal*noise2Frames_catch(trial));
    noise1Catch_targetFrames = round(noise1CatchFrames*cueLevels(cueIdx, target));
    noise2Catch_targetFrames = round(noise2CatchFrames*cueLevels(cueIdx, target));
    noise1Catch_lureFrames = noise1CatchFrames - noise1Catch_targetFrames;
    noise2Catch_lureFrames = noise2CatchFrames - noise2Catch_targetFrames;

    noise1Catch_signal_idx = randperm(noise1Frames_catch(trial), noise1CatchFrames);
    noise2Catch_signal_idx = randperm(noise2Frames_catch(trial), noise2CatchFrames) + (noise1Frames_catch(trial) + signal1Frames_catch(trial));

    noise1Catch_img = Shuffle([repelem(target, noise1Catch_targetFrames) repelem(3 - target, noise1Catch_lureFrames)]);
    noise2Catch_img = Shuffle([repelem(target, noise2Catch_targetFrames) repelem(3 - target, noise2Catch_lureFrames)]);

    flickerCatch(noise1Catch_signal_idx, trial) = noise1Catch_img;
    flickerCatch(noise2Catch_signal_idx, trial) = noise2Catch_img;

end

%% insert catch trials into flickerStream

for t=1:length(catch_trials)
    trial_idx = catch_trials(t);
    if t==1
        mat1 = flickerStream(:, 1:trial_idx-1);
        mat2 = flickerStream(:, trial_idx:end);
        flickerAll = [mat1 flickerCatch(:, t) mat2];
    else
        mat1 = flickerAll(:, 1:trial_idx-1);
        mat2 = flickerAll(:, trial_idx:end);
        flickerAll = [mat1 flickerCatch(:,t) mat2];
    end
end

%% 
clear cue1Counter cue2Counter cue3Counter catchTrialCounter inference_counter_general targetIdx lureIdx rIdx


