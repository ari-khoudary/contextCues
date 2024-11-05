%
% present visual evidence of time-varying reliability inside of learned
% prior cues (colored borders), ask participants to determine which image
% dominated the stream and how confident they are in that decision
%
% ==================================================================================
% Author: Ari Khoudary (2023-2024), adapting code originally written by Aaron M. Bornstein and Mariam Aly

%% create structures to store behavior & behavior-relevant variables
responseFrames = NaN(inferenceTrialN_total, 1);
flickerFlipTimes = NaN(nFrames, inferenceTrialN_total);
infResps = NaN(inferenceTrialN_total, 1);
infRTs = NaN(inferenceTrialN_total, 1);
infAccuracy = NaN(inferenceTrialN_total, 1);
confResps = NaN(inferenceTrialN_total, 1);
confRTs = NaN(inferenceTrialN_total, 1);
trialCongruence = NaN(inferenceTrialN_total, 1);
trialCoherence = NaN(inferenceTrialN_total, 1);
trialTargets = NaN(inferenceTrialN_total, 1);

testTrialCounter = 0;
catchTrialCounter = 0;
cue1Counter = 0;
cue2Counter = 0;
cue3Counter = 0;
inference_counter_general = 0;

%% flicker trial loop
for trial = 1:inferenceTrialN_total

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
        cueIdx = inferenceCue(testTrialCounter);
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
        trialTarget = inferenceImg(cueIdx, inference_counter_general);
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

        % pull frames from integrated test & catch flicker stream
        frame = flickerAll(f, trial);

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
                    break
                end % if any...
            end % if keyIsDown
        end %if isnan
    end % for f=1:nFrames

    % document duration of each flicker stream
    realDuration = GetSecs - flickerStart;

    % record accuracy & store frame when response was made
    infAccuracy(trial) = response==trialTarget;
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
        

end % inference trial loop

% save workspace variables
save([datadir filesep 'block' num2str(block) '_inferenceVars.mat']);

% reset CPU priority
Priority(0);