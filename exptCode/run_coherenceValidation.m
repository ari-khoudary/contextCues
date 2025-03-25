% measures behavior on time-varying flicker stream ONLY

%% setup flicker

% forward & backward mask image frames with noise
flickerStream_v = repmat([0; 1], nFrames_v/2, cohFeedbackTotalN);

% make flicker stream
for trial=1:cohFeedbackTotalN
    flickerStream_v(1:noise1Frames_v(trial), trial) = 0;
    noise2onset = noise1Frames_v(trial) + signal1Frames_v(trial);
    flickerStream_v(noise2onset:noise2onset+noise2Frames_v(trial), trial) = 0;

    if mod(trial, 2)
        target=1;
    else
        target=2;
    end

    % get indices of non-noise frames
    imgIdx = find(flickerStream_v(:, trial));
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
    flickerStream_v(targetIdx, trial) = target;

    % lureIdx is automatically populated when target==2; populate
    % manually when target==1
    if target == 1
        flickerStream_v(lureIdx, trial) = 2;
    end
end

if exist('maxFrames', 'var')
    flickerStream_v = flickerStream_v(1:maxFrames, :);
end

% randomize targets across trials
trialTargets_v = repmat([1 2], [1 cohFeedbackTotalN/2]);
rIdx = Shuffle(1:cohFeedbackTotalN);
trialTargets_v = trialTargets_v(rIdx);
flickerStream_v = flickerStream_v(:, rIdx);
noise1Frames_v = noise1Frames_v(rIdx);
signal1Frames_v = signal1Frames_v(rIdx);
noise2Frames_v = noise2Frames_v(rIdx);

%% initialize table to store data

varNames = {'subID', 'block', 'trial', 'targetName','targetIdx', 'response', 'accuracy', 'RT', 'respFrame', 'postFlickerResp',...
    'noise1frames_design', 'noise1frames_obs', 'signal1Onset_design', 'signal1frames_design', 'signal1frames_obs', ...
    'noise2Onset_design', 'noise2frames_design', 'noise2frames_obs', 'signal2Onset_design', 'signal2frames_design', 'signal2frames_obs' ...
    'totalEv_signal1', 'targetEv_signal1', 'totalEv_signal2', 'targetEv_signal2', ...
    'confidence', 'confRT', 'flickerDuration', 'coherence'};
varTypes = cell([1, length(varNames)]);
varTypes(:) = {'double'};
varTypes(4) = {'cell'};

data_coherenceValidation = table('Size', [cohFeedbackTotalN length(varNames)], ...
    'VariableNames', varNames, ...
    'VariableTypes', varTypes);

cohValidationFlipTimes = NaN([length(flickerStream_v) cohFeedbackTotalN]);
cohValidationEvidence = cohValidationFlipTimes;
cohValidationResponseFrames = NaN([cohFeedbackTotalN 1]);

%% run trials

for trial = 1:cohFeedbackTotalN

    if trial == nFeedbackTrial + 1
        string = ['Thats it for the feedback! \n\n For the rest of this phase, we will ask you to report your confidence that you made the right choice on each trial. \n\n'  ...
            'This rating will come immediately after your decision on each trial.\n\n  Make sure you continue to make the primary response: determining which image dominated the stream. \n\n' ...
            'Press spacebar to proceed.'];
        DrawFormattedText(mainWindow, string, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        while(1)
            [~,~,keyCode] = KbCheck(-1);
            if keyCode(spaceKey) 
                break;
            end
            WaitSecs(0.05);
        end
    end
    clear string

    % reset temporary variables
    response = NaN;
    RT = NaN;
    respFrame = NaN;
    confResponse = NaN;
    confRT = NaN;
    flickerDuration = NaN;
    target = trialTargets_v(trial);
    FlushEvents('keyDown');

    % start with fixation for ITI
    trialStart = GetSecs;
    DrawFormattedText(mainWindow, '+', 'center', centerY, textColor);
    Screen('Flip', mainWindow);
    while (1)
        if GetSecs > trialStart + inferenceITI
            break
        end
    end

    % prep for rapid viz evidence presentation
    Priority(topPriorityLevel);
    flickerStart = GetSecs;
    vbl = flickerStart;

    for f = 1:length(flickerStream_v)

        % pull frames from flicker stream
        frame = flickerStream_v(f, trial);

        % insert visual evidence
        if frame == 0
            Screen('DrawTexture', mainWindow, randMaskTex(randi(2,1)), imageRect, centerRect);
        else
            Screen('DrawTexture', mainWindow, randImageTex(frame), imageRect, centerRect);
        end

        % flip to screen
        vbl = Screen('Flip', mainWindow, vbl + (waitframes - 0.25) * ifi);
        cohValidationFlipTimes(f, trial) = vbl;

        % scan for response
        if isnan(RT)
            [keyIsDown, secs, keyCode] = KbCheck(-1);
            % record response
            if any(keyCode(imageResponseKeys))
                RT = secs - flickerStart;
                response = find(keyCode(imageResponseKeys));
                respFrame = f;
                flickerDuration = GetSecs - flickerStart;
                postFlickerResp = 0;
                break % terminate flicker with keypress
            end % if any...
        end % if keyIsDown
    end % for f=1:nFrames

    if isnan(flickerDuration)
        flickerDuration = GetSecs - flickerStart;
    end

    % move to ISI, collect "overflow" responses
    DrawFormattedText(mainWindow, '', 'center', centerY, textColor);
    isiFlip = Screen('Flip', mainWindow);
    while (1)
        if GetSecs > isiFlip + inferenceISI
            break
        end
        % allow response during ISI between flicker & confidence
        if isnan(RT)
            [keyIsDown, secs, keyCode] = KbCheck(-1);
            % record response but keep flicker on screen for full duration
            if any(keyCode(imageResponseKeys))
                RT = secs - flickerStart;
                response = find(keyCode(imageResponseKeys));
                if size(response, 2) > 1
                    response = 0;
                end
                postFlickerResp = 1;
            end % if keyIsDown
        end %if isnan
    end %while 1

    % compute choice accuracy
    accuracy = response==target;
    if isnan(response)
        accuracy = NaN;
    end


    %%% pivot either to feedback or confidence depending on trial number %%%
    if trial > nFeedbackTrial
        % prep for confidence rating
        FlushEvents('keyDown');
        confResponse = NaN;
        confRT = NaN;

        % draw & display confidence screen
        scale = '1                          2                          3                          4';
        labels = '\n\n not confident                                                              quite confident';
        DrawFormattedText(mainWindow, 'Confidence?', 'center', screenY*0.35, textColor, 70);
        DrawFormattedText(mainWindow, [scale, labels], 'center', screenY*0.55, textColor);
        confFlip = Screen('Flip', mainWindow);

        % keep it on for confidenceDuration amount of time
        while (1)
            if GetSecs > confFlip + confidenceDuration
                break
            end
            % scan for response
            if isnan(confRT) && GetSecs > isiFlip + inferenceISI
                [keyIsDown, secs, keyCode] = KbCheck(-1);
                % remove screen when key is pressed
                if any(keyCode(confidenceResponseKeys))
                    confRT = secs - confFlip;
                    confResponse = find(keyCode(confidenceResponseKeys));
                    break
                end % if any...
            end % if isnan
        end % while

        if size(confResponse, 2) > 1
            confResponse = mean(confResponse);
        end

    else % display feedback
        targetString = 'The correct answer was: ';
        respString = 'Your response was: ';
        if isnan(response)
            accString = 'You did not respond in time. \n Please respond faster on the next trial.';
        elseif accuracy==1
            accString = 'Correct!';
        else
            accString = 'Incorrect.';
        end

        % draw & flip to screen
        DrawFormattedText(mainWindow, targetString, 'center', centerY-imageRect(4)/1.5, textColor);
        Screen('DrawTexture',mainWindow,randImageTex(target),imageRect,centerRect);
        if ~isnan(response)
            DrawFormattedText(mainWindow, respString, 'center', centerY+imageRect(4)-20, textColor);
            DrawFormattedText(mainWindow, accString, 'center', centerY+feedbackRect(4)*3.3, textColor);
            Screen('DrawTexture', mainWindow, randFeedbackTex(response), feedbackRect, feedbackPos);
        else
            DrawFormattedText(mainWindow, accString, 'center', centerY+imageRect(4)-20, textColor);
        end

        feedbackStart = Screen('Flip', mainWindow);

        % display for feedbackDuration seconds
        while (1)
            if GetSecs > feedbackStart + feedbackDuration
                break
            end
        end
    end

    %%% write data to table %%%
    trialTarget = trialTargets_v(trial);
    data_coherenceValidation.subID(trial) = subID;
    data_coherenceValidation.block(trial) = block;
    data_coherenceValidation.trial(trial) = trial;
    data_coherenceValidation.targetName(trial) = imagePath(trialTargets_v(trial));
    data_coherenceValidation.targetIdx(trial) = trialTarget;
    data_coherenceValidation.response(trial) = response;
    data_coherenceValidation.accuracy(trial) = accuracy;
    data_coherenceValidation.RT(trial) = RT;
    data_coherenceValidation.respFrame(trial) = respFrame;
    data_coherenceValidation.postFlickerResp(trial) = postFlickerResp;
    data_coherenceValidation.coherence(trial) = coherence(target);
    data_coherenceValidation.flickerDuration(trial) = flickerDuration;

    % get duration information
    noise1frames = noise1Frames_v(trial);
    noise2frames = noise2Frames_v(trial);
    signal1frames = signal1Frames_v(trial);
    % compute derivative variables
    signal1onset = noise1frames + 1;
    noise2onset = signal1onset + signal1frames + 1;
    signal2onset = noise2onset + noise2frames + 1;
    signal2frames = nFrames - signal2onset;
    trialEvidence = flickerStream_v(1:f, trial);

    % store 
    cohValidationEvidence(1:length(trialEvidence), trial) = trialEvidence; 
    data_coherenceValidation.noise1frames_design(trial) = noise1frames;
    data_coherenceValidation.signal1Onset_design(trial) = signal1onset;
    data_coherenceValidation.signal1frames_design(trial) = signal1frames;
    data_coherenceValidation.noise2Onset_design(trial) = noise2onset;
    data_coherenceValidation.noise2frames_design(trial) = noise2frames;
    data_coherenceValidation.signal2Onset_design(trial) = signal2onset;
    data_coherenceValidation.signal2frames_design(trial) = signal2frames;

   % update evidence dynamics based on responseFrame
    if isnan(respFrame)
        respFrame = nFrames;
    end
    if respFrame > signal2onset % if they respond anytime after the second noise period
        data_coherenceValidation.totalEv_signal1(trial) = sum(trialEvidence(1:noise2onset) > 0);
        data_coherenceValidation.targetEv_signal1(trial) = sum(trialEvidence(1:noise2onset) == trialTarget);
        data_coherenceValidation.totalEv_signal2(trial) = sum(trialEvidence(signal2onset:respFrame) > 0);
        data_coherenceValidation.targetEv_signal2(trial) = sum(trialEvidence(signal2onset:respFrame)==trialTarget);
        data_coherenceValidation.noise1frames_obs(trial) = noise1frames;
        data_coherenceValidation.signal1frames_obs(trial) = signal1frames;
        data_coherenceValidation.noise2frames_obs(trial) = noise2frames;
        data_coherenceValidation.signal2frames_obs(trial) = length(trialEvidence(signal2onset:respFrame));
    elseif respFrame > noise2onset && respFrame < signal2onset % if they respond during the second noise period
        data_coherenceValidation.noise2frames_obs(trial) = length(trialEvidence(noise2onset:respFrame));
        data_coherenceValidation.totalEv_signal1(trial) = sum(trialEvidence(1:respFrame) > 0);
        data_coherenceValidation.targetEv_signal1(trial) = sum(trialEvidence(1:respFrame) == trialTarget);
        data_coherenceValidation.totalEv_signal2(trial) = NaN;
        data_coherenceValidation.targetEv_signal2(trial) = NaN;
        data_coherenceValidation.noise1frames_obs(trial) = noise1frames;
        data_coherenceValidation.signal1frames_obs(trial) = signal1frames;
        data_coherenceValidation.signal2frames_obs(trial) = NaN;
    elseif respFrame > noise1frames && respFrame < noise2onset % if they respond during first signal period
        data_coherenceValidation.noise2frames_obs(trial) = NaN;
        data_coherenceValidation.totalEv_signal1(trial) = sum(trialEvidence(1:respFrame) > 0);
        data_coherenceValidation.targetEv_signal1(trial) = sum(trialEvidence(1:respFrame) == trialTarget);
        data_coherenceValidation.totalEv_signal2(trial) = NaN;
        data_coherenceValidation.targetEv_signal2(trial) = NaN;
        data_coherenceValidation.noise1frames_obs(trial) = noise1frames;
        data_coherenceValidation.signal1frames_obs(trial) = length(trialEvidence(signal1onset:respFrame));
        data_coherenceValidation.signal2frames_obs(trial) = NaN;
    else % if they respond during first noise period
        data_coherenceValidation.signal1frames_obs(trial) = NaN;
        data_coherenceValidation.noise1frames_obs(trial) = respFrame;
        data_coherenceValidation.noise2frames_obs(trial) = NaN;
        data_coherenceValidation.totalEv_signal1(trial) = sum(trialEvidence(1:respFrame) > 0);
        data_coherenceValidation.targetEv_signal1(trial) = sum(trialEvidence(1:respFrame) == trialTarget);
        data_coherenceValidation.totalEv_signal2(trial) = NaN;
        data_coherenceValidation.targetEv_signal2(trial) = NaN;
        data_coherenceValidation.signal2frames_obs(trial) = NaN;
    end

    % store confidence
    if trial > nFeedbackTrial
        data_coherenceValidation.confidence(trial) = confResponse;
        data_coherenceValidation.confRT(trial) = confRT;
    else
        data_coherenceValidation.confidence(trial) = NaN;
        data_coherenceValidation.confRT(trial) = NaN;
    end
end % trial loop

writetable(data_coherenceValidation, [datadir filesep 'block', num2str(block), '_coherenceValidation.csv']);
