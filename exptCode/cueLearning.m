% CUE LEARNING: PHASE 3 OF CONTEXT CLUES
%
% teach participants probabilistic border-image pairings to serve as priors
% for cued inference

%% create variables to store behavior & behavior-relevant vars
learnResps = zeros(learnTrialN, 1);
learnAcc = zeros(learnTrialN, 1);
learnRTs = zeros(learnTrialN, 1);
learnISIs = zeros(learnTrialN, 1);
learnCong = zeros(learnTrialN, 1);
learnCueOnsets = zeros(learnTrialN, 1);
learnImgOnsets = zeros(learnTrialN, 1);
skippedImgTrials = zeros(learnTrialN, 1);

%% loop through trials

cue1Counter = 0;
cue2Counter = 0;
cue3Counter = 0;

for trial = 1:learnTrialN

    % pick cue & image from already-randomized matrices
    cueIdx = learnCue(trial);
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

    imgIdx = learnImg(cueIdx, counter);
    thisCue = cueColors(cueIdx, :);
    thisImg = randImageTex(imgIdx);

    % reset temporary variables
    response = NaN;
    accuracy = NaN;
    learnRT = NaN;

    % timestamp trialstart
    trialStart = GetSecs;

    % show fixation dot before trial onset
    DrawFormattedText(mainWindow, '+', 'center', centerY, textColor);
    fixFlip = Screen('Flip', mainWindow);
    while (1)
        if GetSecs > fixFlip + learnITI
            break
        end
    end

    % show prior cue with fixation cross
    FlushEvents('keyDown');
    Screen('FrameRect', mainWindow, thisCue, borderRect, 8);
    DrawFormattedText(mainWindow, '+', 'center', centerY, textColor);
    cueFlip = Screen('Flip',mainWindow);
    learnCueOnsets(trial) = cueFlip;
    cueDurations(trial)
    while (1)
        if GetSecs > cueFlip + cueDurations(trial)
            break
        end
        % allow for responding during cue-only period
        if isnan(learnRT)
            [keyIsDown, secs, keyCode] = KbCheck;

            if (keyIsDown)
                if (keyCode(respQuit))
                    cleanupScr(mainWindow);
                    return
                end

                if (any(keyCode(imageResponseKeys)))
                    learnRT = secs - cueFlip;
                    response = find(keyCode(imageResponseKeys));
                end % if any(keyCode)
            end % if (keyIsDown)
        end %if isnan
    end

    % replace fixation with image
    Screen('FrameRect', mainWindow, thisCue, borderRect, 8);
    Screen('DrawTexture',mainWindow,thisImg,imageRect,centerRect);
    % give feedback on button press if they responded during cue-only period
    if ~isnan(learnRT)
        if response==imgIdx
                feedbackString = 'Correct!';
            else
                feedbackString = 'Incorrect.';
        end
    end
    % flip image to screen
    imgFlip = Screen('Flip', mainWindow);
    while (1)
        if GetSecs > imgFlip + learnImgDuration
            break
        end
        % scan for response
        if isnan(learnRT)
            [keyIsDown, secs, keyCode] = KbCheck;

            if (any(keyCode(imageResponseKeys)))
                learnRT = secs - cueFlip;
                response = find(keyCode(imageResponseKeys));
            end % if any(keyCode)
        end % if (keyIsDown)
        if isnan(response)
            feedbackString='';
        elseif response==imgIdx
            feedbackString='Correct!';
        else
            feedbackString='Incorrect.';
        end
        Screen('FrameRect', mainWindow, thisCue, borderRect, 8);
        Screen('DrawTexture',mainWindow,thisImg,imageRect,centerRect);
        DrawFormattedText(mainWindow, feedbackString, 'center', centerY-imageRect(4)-10, textColor);
        Screen('Flip', mainWindow);
    end

if isnan(learnRT)
    string = 'Please remember to make a response when a scene image is presented.';
    DrawFormattedText(mainWindow, string, 'center', centerY, textColor);
    Screen('Flip',mainWindow);
    WaitSecs(2);
end

% document accuracy & congruence
accuracy = response==imgIdx;
if cueIdx == 3
    congruent = NaN;
elseif cueIdx ~= imgIdx
    congruent = 0;
else
    congruent = 1;
end

% save behavior to workspace vars
learnResps(trial) = response;
learnAcc(trial) = accuracy;
learnRTs(trial) = learnRT;
learnISIs(trial) = cueDurations(trial);
learnCong(trial) = congruent;

% write data to file
fprintf(learnFile, '\n %i, %i, %i, %s, %i, %s, %i, %i, %i, %.4f, %.4f', ...
    subID, block, trial, imagePath{imgIdx}, imgIdx, mat2str(thisCue), congruent, response, accuracy, learnRT, cueDurations(trial));
end % trial

save([datadir filesep 'block' num2str(block) '_learningVars.mat']);