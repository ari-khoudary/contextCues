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

flickerStream_v = flickerStream_v(1:maxFrames, :);

% randomize targets across trials
trialTargets_v = repmat([1 2], [1 cohFeedbackTotalN/2]);
rIdx = Shuffle(1:cohFeedbackTotalN);
trialTargets_v = trialTargets_v(rIdx);
flickerStream_v = flickerStream_v(:, rIdx);
noise1Frames_v = noise1Frames_v(rIdx);
signal1Frames_v = signal1Frames_v(rIdx);
noise2Frames_v = noise2Frames_v(rIdx);

%% initialize table to store data

varNames = {'subID', 'block', 'trial', 'targetName', 'targetIdx', 'response', 'accuracy', 'RT', 'respFrame', ...
    'noise1frames', 'signal1Onset', 'totalEv_signal1', 'targetEv_signal1', 'noise2Onset', 'noise2frames', 'signal2Onset', 'totalEv_signal2', 'targetEv_signal2', ...
    'confidence', 'confRT', 'flickerDuration', 'coherence'};
varTypes = cell([1, length(varNames)]);
varTypes(:) = {'double'};
varTypes(4) = {'cell'};

data_coherenceValidation = table('Size', [cohFeedbackTotalN length(varNames)], ...
    'VariableNames', varNames, ...
    'VariableTypes', varTypes);

validationFlipTimes = NaN([length(flickerStream_v) cohFeedbackTotalN]);
validationEvidence = validationFlipTimes;

%% run trials

for trial = 1:cohFeedbackTotalN

    % reset temporary variables
    response = NaN;
    RT = NaN;
    respFrame = NaN;
    confResponse = NaN;
    confRT = NaN;
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
        vbl = Screen('Flip', mainWindow, vbl + (waitframes - 0.5) * ifi);
        validationFlipTimes(f, trial) = vbl;

        % scan for response
        if isnan(RT)
            [keyIsDown, secs, keyCode] = KbCheck(-1);
            % record response
            if any(keyCode(imageResponseKeys))
                RT = secs - flickerStart;
                response = find(keyCode(imageResponseKeys));
                respFrame = f;
                flickerDuration = GetSecs - flickerStart;
                break % terminate flicker with keypress
            end % if any...
        end % if keyIsDown
    end % for f=1:nFrames

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
        labels = '\n\n not confident                                                              highly confident';
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

    % record evidence dynamics
    trialEvidence = flickerStream_v(1:f, trial);
    validationEvidence(1:length(trialEvidence), trial) = trialEvidence;
    noise2Onset = noise1Frames_v(trial) + signal1Frames_v(trial);
    signal2Onset = noise2Onset + noise2Frames_v(trial);


    %%% write data to table %%%
    data_coherenceValidation.trial(trial) = trial;
    data_coherenceValidation.targetName(trial) = imagePath(trialTargets_v(trial));
    data_coherenceValidation.targetIdx(trial) = trialTargets_v(trial);
    data_coherenceValidation.response(trial) = response;
    data_coherenceValidation.accuracy(trial) = accuracy;
    data_coherenceValidation.RT(trial) = RT;
    data_coherenceValidation.respFrame(trial) = respFrame;
    data_coherenceValidation.flickerDuration(trial) = flickerDuration;
    data_coherenceValidation.coherence(trial) = coherence(target);
    % evidence dynamics 
    data_coherenceValidation.noise1frames(trial) = noise1Frames_v(trial);
    data_coherenceValidation.totalEv_signal1(trial) = sum(trialEvidence > 0);
    data_coherenceValidation.targetEv_signal1(trial) = sum(trialEvidence == target);
    data_coherenceValidation.signal1Onset(trial) = noise1Frames_v(trial) + 1;
    data_coherenceValidation.noise2frames(trial) = noise2Frames_v(trial);
    data_coherenceValidation.totalEv_signal2(trial) = sum(trialEvidence(signal2Onset:f) > 0);
    data_coherenceValidation.targetEv_signal2(trial) = sum(trialEvidence(signal2Onset:f) == target);
    data_coherenceValidation.noise2Onset(trial) = noise2Onset;
    data_coherenceValidation.signal2Onset(trial) = signal2Onset;
    % adjust values depending on when participant responded
    if respFrame >= noise2Onset && f < signal2Onset % response during second noise period 
        data_coherenceValidation.noise2frames(trial) = length(trialEvidence(noise2Onset:f));
        data_coherenceValidation.signal2Onset(trial) = NaN;
        data_coherenceValidation.totalEv_signal2(trial) = NaN;
        data_coherenceValidation.targetEv_signal2(trial) = NaN;
    elseif  respFrame > noise1Frames_v(trial) && respFrame < noise2Onset % response during first signal period
        data_coherenceValidation.targetEv_signal1(trial) = sum(trialEvidence == target);   
        data_coherenceValidation.noise2frames(trial) = NaN;
        data_coherenceValidation.signal2Onset(trial) = NaN;
        data_coherenceValidation.totalEv_signal2(trial) = NaN;
        data_coherenceValidation.targetEv_signal2(trial) = NaN;
    else % if response during first noise period
        data_coherenceValidation.noise1frames(trial) = length(trialEvidence(1:f));
        data_coherenceValidation.signal1Onset(trial) = NaN;
        data_coherenceValidation.totalEv_signal1(trial) = NaN;
        data_coherenceValidation.targetEv_signal1(trial) = NaN;
        data_coherenceValidation.noise2Onset(trial) = NaN;
        data_coherenceValidation.noise2frames(trial) = NaN;
        data_coherenceValidation.signal2Onset(trial) = NaN;
        data_coherenceValidation.totalEv_signal2(trial) = NaN;
        data_coherenceValidation.targetEv_signal2(trial) = NaN;
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

data_coherenceValidation.subID = repelem(subID, cohFeedbackTotalN)';
data_coherenceValidation.block = repelem(block, cohFeedbackTotalN)';
writetable(data_coherenceValidation, [datadir filesep 'block', num2str(block), '_coherenceValidation.csv']);
