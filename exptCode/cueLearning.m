% CUE LEARNING: PHASE 3 OF CONTEXT CUES
%
% teach participants probabilistic border-image pairings to serve as
% expectations in cued inference

% variable tracking whether they passed learning criterion
needToLearn = 1;
learningRound = 1;

%% loop through trials

while needToLearn == 1
    % create vectors to store responses
    if learningRound == 1
        learnAcc1 = zeros(learnTrialN, 1);
    else
        learnAcc2 = zeros(learnTrialN, 1);
    end
    learnResps = zeros(learnTrialN, 1);
    learnRTs = zeros(learnTrialN, 1);
    learnISIs = zeros(learnTrialN, 1);
    learnCong = zeros(learnTrialN, 1);
    learnCueOnsets = zeros(learnTrialN, 1);
    learnImgOnsets = zeros(learnTrialN, 1);
    skippedImgTrials = zeros(learnTrialN, 1);

    % create counters
    cue1Counter = 0;
    cue2Counter = 0;
    cue3Counter = 0;

    % loop over trials
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
        if learningRound==1
                learnAcc1(trial) = accuracy;
        else
                learnAcc2(trial) = accuracy;
        end
        learnResps(trial) = response;
        learnRTs(trial) = learnRT;
        learnISIs(trial) = cueDurations(trial);
        learnCong(trial) = congruent;

        % write data to file
        if learningRound == 1
            fprintf(learnFile, '\n %i, %i, %i, %s, %i, %s, %s, %i, %i, %i, %.4f, %.4f, %i', ...
                subID, block, trial, imagePath{imgIdx}, imgIdx, mat2str(thisCue), cueStrings(thisCue), congruent, response, accuracy, learnRT, cueDurations(trial), learningRound);
        else
            fprintf(learnFile2, '\n %i, %i, %i, %s, %i, %s, %s, %i, %i, %i, %.4f, %.4f, %i', ...
                subID, block, trial, imagePath{imgIdx}, imgIdx, mat2str(thisCue), cueStrings(thisCue), congruent, response, accuracy, learnRT, cueDurations(trial), learningRound);
        end

        % check if accuracy has reached criterion level by the end of the phase
        if trial == learnTrialN && learningRound == 1
            needToLearn = mean(learnAcc1) <= learningCriterion;

            % display 10 more trials for each cue if performance did not
            % meet criterion
            if needToLearn == 1
                learningRound = learningRound+1;
                learnTrialN = 10 * nCues;
                learnTrials = round(cueLevels*learnTrialN / nCues);

                % re-make stimuli
                learnCue = [repelem(1, learnTrialN/nCues) repelem(2, learnTrialN/nCues) repelem(3, learnTrialN/nCues)];
                learnImg = NaN(nCues, sum(learnTrials(1,:)));
                for cueIdx=1:nCues
                    learnImg(cueIdx, :) = [ones(1, learnTrials(cueIdx,1)) repelem(2, learnTrials(cueIdx,2))];
                end
                learnCue = Shuffle(learnCue);
                learnImg = Shuffle(learnImg, 1);
                setup_durations;

                % make new file to save results
                learnFileName2 = [datadir, filesep 'block', num2str(block), '_learning2.csv'];
                learnFile2 = fopen(learnFileName2, 'wt+');
                fprintf(learnFile2, ...
                    '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',  ...
                    'subID', 'block', 'trial', 'image', 'imageIdx', 'cue', 'congruent', 'response', 'accuracy', 'RT', 'cueDuration', 'learningRound');

                % tell them that they didn't meet criterion and remind them
                % of the instructions
                reminderString = ['It looks like you were not able to learn the relationship between the borders and images. \n\n', ...
                    'Remember, your task is to press the button that corresponds to the scene image once it comes on screen. \n\n', ...
                    'Press spacebar to re-start this phase of the experiment.'];
                DrawFormattedText(mainWindow, reminderString, 'center', 'center', textColor, 80);
                Screen('Flip', mainWindow);
                while(1)
                    temp = GetChar;
                    if (temp == ' ')
                        break;
                    end
                    WaitSecs(0.05)
                end
            end % re-setting phase for round2

        elseif trial == learnTrialN && learningRound == 2
            needToLearn = mean([learnAcc1; learnAcc2]) <= learningCriterion;
            % kick them out if they haven't learned after round 2
            if needToLearn == 1
                endString = ['It looks like you were not able to learn the relationship between the borders and images. \n\n' ...
                    'Unfortunately, that means we cannot continue with this experiment. Please get the experimenter to receive your pro-rated compensation.'];
                DrawFormattedText(mainWindow, endString, 'center', 'center', textColor, 80);
                Screen('Flip', mainWindow);
            end
        end

    end % trial loop

    % save workspace vars
    if needToLearn==0
        save([datadir filesep 'block' num2str(block) '_learningVars_final.mat']);
    else
        save([datadir filesep 'block' num2str(block) '_learningVars_firstRound.mat']);
    end

end % while needToLearn

