% CUED INFERENCE: PHASE 4 OF CONTEXT CUES
%
% present visual evidence of time-varying reliability inside of learned
% prior cues (colored borders), ask participants to determine which image
% dominated the stream and how confident they are in that decision
%
% =================================================================================================================================
% Author: Ari Khoudary (2023), adapting code originally written by Aaron M. Bornstein and Mariam Aly

%% set up flicker stream

% forward & backward mask image frames with noise
inferenceTrialN = length(inferenceCue);
flickerStream = repmat([0; 1], nFrames/2, inferenceTrialN);

% add noise epochs
% noise1Frames, signal1Frames, noise2Frames all created in
% makeNoiseDistributions.m
cue1Counter = 0;
cue2Counter = 0;
cue3Counter = 0;

for trial=1:inferenceTrialN
    flickerStream(1:noise1Frames(trial), trial) = 0;
    noise2onset = noise1Frames(trial) + signal1Frames(trial);
    flickerStream(noise2onset:noise2onset+noise2Frames(trial), trial) = 0;

    % get each trial's target
    cueIdx=inferenceCue(trial);
    if cueIdx==1
        cue1Counter=cue1Counter+1;
        counter = cue1Counter;
    elseif cueIdx==2
        cue2Counter=cue2Counter+1;
        counter = cue2Counter;
    else
        cue3Counter=cue3Counter+1;
        counter = cue3Counter;
    end
    target = inferenceImg(cueIdx, counter);

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

% create structures to store behavior & behavior-relevant variables
responseFrames = zeros(inferenceTrialN, 1);
flickerFlipTimes = zeros(nFrames, inferenceTrialN);
infResps = zeros(inferenceTrialN, 1);
infRTs = zeros(inferenceTrialN, 1);
confResps = zeros(inferenceTrialN, 1);
confRTs = zeros(inferenceTrialN, 1);
trialCongruence = zeros(inferenceTrialN, 1);
trialCoherence = zeros(inferenceTrialN, 1);

%% flicker trial loop
cue1Counter = 0;
cue2Counter = 0;
cue3Counter = 0;
for trial = 1:inferenceTrialN
    % give people breaks
    takeBreak = 0;
    if trial == (inferenceTrialN * 1/4)
        instructString = ['1/4 of the way through the block. \n' ...
            'Please take a brief break. Press space when you feel ready to continue.'];
        takeBreak = 1;
    elseif trial == (inferenceTrialN * 1/2)
        instructString = ['1/2 of the way through the block. \n' ...
            'Please take a brief break. Press space when you feel ready to continue.'];
        takeBreak = 1;
    elseif trial == (inferenceTrialN * 3/4)
        instructString = ['3/4 of the way through the block. \n' ...
            'Please take a brief break. Press space when you feel ready to continue.'];
        takeBreak = 1;
    end

    if takeBreak
        DrawFormattedText(mainWindow, instructString, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        FlushEvents('keyDown');
        while(1)
            temp = GetChar;
            if (temp == ' ')
                break;
            end
            WaitSecs(0.5)
        end
    end

    % get cue from pre-shuffled cue matrix
    cueIdx = inferenceCue(trial);
    thisCue = cueColors(cueIdx, :);
    % update cue/trial counters
    if cueIdx==1
        cue1Counter=cue1Counter+1;
        counter = cue1Counter;
    elseif cueIdx==2
        cue2Counter=cue2Counter+1;
        counter = cue2Counter;
    else
        cue3Counter=cue3Counter+1;
        counter = cue3Counter;
    end

    % get target
    trialTarget = inferenceImg(cueIdx, counter);

    % determine cue/target congruence
    if cueIdx == 3
        congruent = NaN;
    elseif cueIdx ~= trialTarget
        congruent = 0;
    else
        congruent = 1;
    end

    % store in workspace var
    trialCongruence(trial) = congruent;
    trialCoherence(trial) = coherence(trialTarget);

    % reset temporary variables
    response = NaN;
    accuracy = NaN;
    RT = NaN;
    respFrame = NaN;

    % prep flicker presentation
    FlushEvents('keyDown');
    trialStart = GetSecs;

    % start with fixation for ITI
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

    for f = 1:nFrames
        frame = flickerStream(f, trial);

        % draw colored border
        Screen('FrameRect', mainWindow, thisCue, borderRect, 8);

        % insert visual evidence
        if frame == 0
            Screen('DrawTexture', mainWindow, randMaskTex(randi(2,1)), imageRect, centerRect);
        else
            Screen('DrawTexture', mainWindow, randImageTex(frame), imageRect, centerRect);
        end

        % flip to screen
        vbl = Screen('Flip', mainWindow, vbl + (waitframes - 0.5) * ifi);
        flickerFlipTimes(f, trial) = vbl;

        % scan for response
        if isnan(RT)
            [keyIsDown, secs, keyCode] = KbCheck;
            % quit if quit key is pressed
            if keyIsDown
                if keyCode(respQuit)
                    cleanupScr(mainWindow);
                    return
                end
                % record response but keep flicker on screen for full duration
                if any(keyCode(imageResponseKeys))
                    RT = secs - flickerStart;
                    infRTs(trial) = RT;
                    response = find(keyCode(imageResponseKeys));
                    infResps(trial) = response;
                    respFrame = f;
                    break
                end % if any...
            end % if keyIsDown
        end %if isnan
    end % for f=1:nFrames

    % document duration of each flicker stream
    realDuration = GetSecs - flickerStart;

    % record accuracy & store frame when response was made
    accuracy = response==trialTarget;
    responseFrames(trial) = respFrame;

    % move to ISI, collect "overflow" responses
    DrawFormattedText(mainWindow, '', 'center', centerY, textColor);
    isiFlip = Screen('Flip', mainWindow);
    while (1)
        if GetSecs > isiFlip + inferenceISI
            break
        end
        % allow response during ISI between flicker & confidence
        if isnan(RT)
            [keyIsDown, secs, keyCode] = KbCheck;
            % record response but keep flicker on screen for full duration
            if any(keyCode(imageResponseKeys))
                RT = secs - flickerStart;
                infRTs(trial) = RT;
                response = find(keyCode(imageResponseKeys));
                infResps(trial) = response;
                accuracy = response==trialTarget;
            end % if keyIsDown
        end %if isnan
    end %while 1

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
            [keyIsDown, secs, keyCode] = KbCheck;
            % quit if quit key is pressed
            if keyIsDown
                if keyCode(respQuit)
                    cleanupScr(mainWindow);
                    return
                end
                % remove screen when key is pressed
                if any(keyCode(confidenceResponseKeys))
                    confRT = secs - confFlip;
                    confRTs(trial) = confRT;
                    confResponse = find(keyCode(confidenceResponseKeys));
                    confResps(trial) = confResponse;
                    break
                end % if any...
            end % if keyIsDown
        end %if isnan
    end % while 1

    % write behavior to csv
    fprintf(inferenceFile, '\n %i, %i, %i, %s, %i, %s, %s, %i, %i, %i, %i, %.4f, %i, %.4f, %.4f,%i,%i,%i,%.4f', ...
        subID, block, trial, imagePath{trialTarget}, trialTarget, mat2str(thisCue), cueStrings(thisCue), congruent, respFrame, response, accuracy, RT, confResponse, confRT, realDuration, noise1Frames(trial), signal1Frames(trial), noise2Frames(trial), trialCoherence(trial));

end % inference trial loop

% save workspace variables
save([datadir filesep 'block' num2str(block) '_inferenceVars.mat']);

% reset CPU priority
Priority(0);