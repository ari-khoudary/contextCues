%
% present visual evidence of time-varying reliability inside of learned
% prior cues (colored borders), ask participants to determine which image
% dominated the stream and how confident they are in that decision
%
% ==================================================================================
% Author: Ari Khoudary (2023-2024), adapting code originally written by Aaron M. Bornstein and Mariam Aly

%% create structures to store behavior & behavior-relevant variables
if exist('maxFrames', 'var')
    nFrames = maxFrames;
end
responseFrames = NaN(inferenceTrialN, 1);
flickerFlipTimes = NaN(nFrames, inferenceTrialN);
inferenceEvidence = flickerFlipTimes;
infResps = NaN(inferenceTrialN, 1);
infRTs = NaN(inferenceTrialN, 1);
infAccuracy = NaN(inferenceTrialN, 1);
confResps = NaN(inferenceTrialN, 1);
confRTs = NaN(inferenceTrialN, 1);
trialCongruence = NaN(inferenceTrialN, 1);
trialCoherence = NaN(inferenceTrialN, 1);
trialTargets = NaN(inferenceTrialN, 1);

testTrialCounter = 0;
catchTrialCounter = 0;
cue1Counter = 0;
cue2Counter = 0;
cue3Counter = 0;
inference_counter_general = 0;

%% create table to store data

varNames = {'subID', 'block', 'trial', 'cueName',  'targetName','cueIdx', 'targetIdx', 'congruent', 'response', 'accuracy', 'RT', 'respFrame', 'postFlickerResp',...
    'noise1frames_design', 'noise1frames_obs', 'signal1Onset_design', 'signal1frames_design', 'signal1frames_obs', ...
    'noise2Onset_design', 'noise2frames_design', 'noise2frames_obs', 'signal2Onset_design', 'signal2frames_design', 'signal2frames_obs' ...
    'totalEv_signal1', 'targetEv_signal1', 'totalEv_signal2', 'targetEv_signal2', ...
    'confidence', 'confRT', 'flickerDuration', 'coherence', 'catch_trial'};
varTypes = cell([1, length(varNames)]);
varTypes(:) = {'double'};
varTypes(4:5) = {'cell'};

data_cuedInference = table('Size', [inferenceTrialN length(varNames)], ...
    'VariableNames', varNames, ...
    'VariableTypes', varTypes);

%% flicker trial loop
for trial = 1:inferenceTrialN

    %%%% give breaks & give feedback on performance %%%%
    takeBreak = 0; 
    if sum(trial==break_trials) == 1
        takeBreak = 1;
        percent_correct = 100*mean(infAccuracy, 'omitnan');
        avg_rt = mean(infRTs, 'omitnan');
        instructString = 'Time for a break! Press spacebar when you feel ready to continue.';
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
    %%%% end section on breaks %%%%

    %%%% run trial %%%%
    catch_trial = ismember(trial, catch_trials);

    if catch_trial==0 % if a trial is not a catch trial
        testTrialCounter = testTrialCounter + 1;
        cueIdx = testCue(testTrialCounter);
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
        trialTarget = testImg(cueIdx, inference_counter_general);
    else % if a trial is a catch trial
        catchTrialCounter = catchTrialCounter + 1;
        cueIdx = catchCue(catchTrialCounter);
        trialTarget = catchImg(catchTrialCounter);
    end

    % save trial target
    trialTargets(trial) = trialTarget;

    % pull colored border corresonding to cue
    thisCue = cueColors(cueIdx, :);

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

         % draw colored border
         Screen('FrameRect', mainWindow, thisCue, borderRect, 10);

        % pull frames from integrated test & catch flicker stream
        frame = flickerAll(f, trial);

        % insert visual evidence
        if frame == 0
            Screen('DrawTexture', mainWindow, randMaskTex(randi(2,1)), imageRect, centerRect);
        else
            Screen('DrawTexture', mainWindow, randImageTex(frame), imageRect, centerRect);
        end

        % flip to screen
        vbl = Screen('Flip', mainWindow, vbl + (waitframes - 0.25) * ifi);
        flickerFlipTimes(f, trial) = vbl;

        % scan for response
        if isnan(RT)
            [keyIsDown, secs, keyCode] = KbCheck(-1);
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
                    if size(response, 2) > 1
                        response = 0;
                    end
                    infResps(trial) = response;
                    respFrame = f;
                    postFlickerResp = 0;
                    break
                end % if any...
            end % if keyIsDown
        end %if isnan
    end % for f=1:infFrames

    if isnan(RT)
        respFrame = nFrames;
    end

    % document duration of each flicker stream
    realDuration = GetSecs - flickerStart;

    % record accuracy, store frame when response was made, store observed
    % evidence
    infAccuracy(trial) = response==trialTarget;
    responseFrames(trial) = respFrame;
    inferenceEvidence(1:respFrame, trial) = flickerAll(1:respFrame, trial);

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
                infRTs(trial) = RT;
                response = find(keyCode(imageResponseKeys));
                if size(response, 2) > 1
                    response = 0;
                end
                infResps(trial) = response;
                infAccuracy(trial) = response==trialTarget;
                postFlickerResp = 1;
            end % if keyIsDown
        end %if isnan
    end %while 1

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
                    if size(confResponse, 2) > 1
                        confResponse = mean(confResponse);
                    end
                    confResps(trial) = confResponse;
                    break
                end % if any...
            end % if keyIsDown
        end %if isnan
    end % while 1

    % write behavior to csv
    if catch_trial==0 
        fprintf(inferenceFile, '\n %i, %i, %i, %s, %i, %s, %s, %i, %i, %i, %i, %.4f, %i, %.4f, %.4f,%i,%i,%i,%.4f,%i', ...
            subID, block, trial, imagePath{trialTarget}, trialTarget, mat2str(thisCue), cueStrings{cueIdx}, congruent, respFrame, response, infAccuracy(trial), RT, confResponse, confRT, realDuration, noise1Frames_test(testTrialCounter), signal1Frames_test(testTrialCounter), noise2Frames_test(testTrialCounter), trialCoherence(trial), catch_trial);
    else
        fprintf(inferenceFile, '\n %i, %i, %i, %s, %i, %s, %s, %i, %i, %i, %i, %.4f, %i, %.4f, %.4f,%i,%i,%i,%.4f,%i', ...
            subID, block, trial, imagePath{trialTarget}, trialTarget, mat2str(thisCue), cueStrings{cueIdx}, congruent, respFrame, response, infAccuracy(trial), RT, confResponse, confRT, realDuration, noise1Frames_catch(catchTrialCounter), signal1Frames_catch(catchTrialCounter), noise2Frames_catch(catchTrialCounter), trialCoherence(trial), catch_trial);
    end

    %%% write data to table %%%
    data_cuedInference.subID(trial) = subID;
    data_cuedInference.block(trial) = block;
    data_cuedInference.trial(trial) = trial;
    data_cuedInference.cueName(trial) = cueStrings(cueIdx);
    data_cuedInference.targetName(trial) = imagePath(trialTarget);
    data_cuedInference.cueIdx(trial) = cueIdx;
    data_cuedInference.targetIdx(trial) = trialTarget;
    data_cuedInference.congruent(trial) = congruent;
    data_cuedInference.response(trial) = response;
    data_cuedInference.accuracy(trial) = infAccuracy(trial);
    data_cuedInference.RT(trial) = RT;
    data_cuedInference.respFrame(trial) = respFrame;
    data_cuedInference.flickerDuration(trial) = realDuration;
    data_cuedInference.coherence(trial) = coherence(trialTarget);
    data_cuedInference.catch_trial(trial) = catch_trial;
    data_cuedInference.confidence(trial) = confResponse;
    data_cuedInference.confRT(trial) = confRT;
    data_cuedInference.postFlickerResp(trial) = postFlickerResp;

    % get different durations for different trial types
    if catch_trial == 0
        noise1frames = noise1Frames_test(testTrialCounter);
        noise2frames = noise2Frames_test(testTrialCounter);
        signal1frames = signal1Frames_test(testTrialCounter);
    else
        noise1frames = noise1Frames_catch(catchTrialCounter);
        noise2frames = noise2Frames_catch(catchTrialCounter);
        signal1frames = signal1Frames_catch(catchTrialCounter);
    end

    % compute derivative variables
    signal1onset = noise1frames + 1;
    noise2onset = signal1onset + signal1frames + 1;
    signal2onset = noise2onset + noise2frames + 1;
    signal2frames = nFrames - (signal2onset);
    trialEvidence = inferenceEvidence(1:nFrames, trial);

    % store
    data_cuedInference.noise1frames_design(trial) = noise1frames;
    data_cuedInference.signal1Onset_design(trial) = signal1onset;
    data_cuedInference.signal1frames_design(trial) = signal1frames;
    data_cuedInference.noise2Onset_design(trial) = noise2onset;
    data_cuedInference.noise2frames_design(trial) = noise2frames;
    data_cuedInference.signal2Onset_design(trial) = signal2onset;
    data_cuedInference.signal2frames_design(trial) = signal2frames;

    % store evidence dynamics
    if respFrame > signal2onset % if they respond anytime after the second noise period
        data_cuedInference.totalEv_signal1(trial) = sum(trialEvidence(1:noise2onset) > 0);
        data_cuedInference.targetEv_signal1(trial) = sum(trialEvidence(1:noise2onset) == trialTarget);
        data_cuedInference.totalEv_signal2(trial) = nansum(trialEvidence(signal2onset:respFrame));
        data_cuedInference.targetEv_signal2(trial) = nansum(trialEvidence(signal2onset:respFrame)==trialTarget);
        data_cuedInference.noise1frames_obs(trial) = noise1frames;
        data_cuedInference.signal1frames_obs(trial) = signal1frames;
        data_cuedInference.noise2frames_obs(trial) = noise2frames;
        data_cuedInference.signal2frames_obs(trial) = length(trialEvidence(signal2onset:respFrame));
    elseif respFrame > noise2onset && respFrame < signal2onset % if they respond during the second noise period
        data_cuedInference.noise2frames_obs(trial) = length(trialEvidence(noise2onset:respFrame));
        data_cuedInference.totalEv_signal1(trial) = sum(trialEvidence(1:respFrame) > 0);
        data_cuedInference.targetEv_signal1(trial) = sum(trialEvidence(1:respFrame) == trialTarget);
        data_cuedInference.totalEv_signal2(trial) = NaN;
        data_cuedInference.targetEv_signal2(trial) = NaN;
        data_cuedInference.noise1frames_obs(trial) = noise1frames;
        data_cuedInference.signal1frames_obs(trial) = signal1frames;
        data_cuedInference.signal2frames_obs(trial) = NaN;
    elseif respFrame > noise1frames && respFrame < noise2onset % if they respond during first signal period
        data_cuedInference.noise2frames_obs(trial) = NaN;
        data_cuedInference.totalEv_signal1(trial) = sum(trialEvidence(1:respFrame) > 0);
        data_cuedInference.targetEv_signal1(trial) = sum(trialEvidence(1:respFrame) == trialTarget);
        data_cuedInference.totalEv_signal2(trial) = NaN;
        data_cuedInference.targetEv_signal2(trial) = NaN;
        data_cuedInference.noise1frames_obs(trial) = noise1frames;
        data_cuedInference.signal1frames_obs(trial) = length(trialEvidence(signal1onset:respFrame));
        data_cuedInference.signal2frames_obs(trial) = NaN;
    else % if they respond during first noise period
        data_cuedInference.signal1frames_obs(trial) = NaN;
        data_cuedInference.noise1frames_obs(trial) = respFrame;
        data_cuedInference.noise2frames_obs(trial) = NaN;
        data_cuedInference.totalEv_signal1(trial) = sum(trialEvidence(1:respFrame) > 0);
        data_cuedInference.targetEv_signal1(trial) = sum(trialEvidence(1:respFrame) == trialTarget);
        data_cuedInference.totalEv_signal2(trial) = NaN;
        data_cuedInference.targetEv_signal2(trial) = NaN;
        data_cuedInference.signal2frames_obs(trial) = NaN;
    end
        
end % inference trial loop

% save workspace variables
save([datadir filesep 'block' num2str(block) '_workspace.mat']);
writetable(data_cuedInference, [datadir filesep 'block', num2str(block), '_cuedInference_table.csv']);

% reset CPU priority
Priority(0);