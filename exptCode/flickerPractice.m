% FLICKER PRACTICE: PHASE 1.5 OF CONTEXT CUES
% give participants practice making the flicker stream decisions with
% feedback prior to calibration

%% setup

% initialize flicker stream & structures to hold timing info
flickerStream = repmat([0; 1], nFrames/2, practiceTrialN);
responseFrames = zeros(practiceTrialN, 1);
flipTimes = zeros(nFrames, practiceTrialN);
trialCounter = 1;

%% run flicker

for cohLevel = 1:length(practiceCoherences)
    for t = 1:nImages

        % pick random target 
        target = Shuffle([1 2]);
        target = target(t);

        % get indices of non-noise frames
        imgIdx = find(flickerStream(:, trialCounter));
        nImgFrames = length(imgIdx);
        % use coherence to determine number of target frames
        coherence = practiceCoherences(cohLevel);
        nTargetFrames = ceil(nImgFrames*coherence);
        nLureFrames = nFrames/2 - nTargetFrames;
        targetIdx = RandSample(imgIdx, [nTargetFrames 1]);
        lureIdx = setdiff(imgIdx, targetIdx);

        % populate imgFrames with target
        flickerStream(targetIdx, trialCounter) = target;
        if target == 1
            flickerStream(lureIdx, trialCounter) = 2;
        end

        % reset temporary variables
        resp = NaN;
        accuracy = NaN;
        RT = NaN;
        respFrame = NaN;
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

        % run flicker stream
        for f = 1:nFrames
            frame = flickerStream(f, trialCounter);
            if frame == 0
                Screen('DrawTexture', mainWindow, randMaskTex(randi(2,1)), imageRect, centerRect);
            else
                Screen('DrawTexture', mainWindow, randImageTex(frame), imageRect, centerRect);
            end

            % flip to screen
            vbl = Screen('Flip', mainWindow, vbl + (waitframes - 0.5) * ifi);
            flipTimes(f, trialCounter) = vbl;

            % scan for response
            if isnan(RT)
                [keyIsDown, secs, keyCode] = KbCheck;
                % quit if quit key is pressed
                if keyIsDown
                    if keyCode(respQuit)
                        cleanupScr(mainWindow);
                        return
                    end
                    % end flicker with button press
                    if any(keyCode(imageResponseKeys))
                        RT = secs - flickerStart;
                        resp = find(keyCode(imageResponseKeys));
                        respFrame = f;
                        break
                    end % if any...
                end % if keyIsDown
            end %if isnan
        end % for f=1:nFrames

        % document duration of each flicker stream
        realDuration = GetSecs - flickerStart;

        % record accuracy & store frame when response was made
        accuracy = resp==target;
        responseFrames(trialCounter) = respFrame;

        % display target & give feedback on accuracy
        targetString = 'The target image was: ';
        respString = sprintf('Your response was: %i', resp);
        if isnan(resp)
            respString = 'You did not respond in time.';
            accuracyString = 'Press spacebar to repeat the trial.';
        elseif accuracy==1
            accuracyString = 'Nice work! Press spacebar to continue.';
        elseif accuracy==0
            accuracyString = 'Remember: your task is to press the button of the most frequent image. \n Press spacebar to continue';
        end

        % draw & flip to screen
        DrawFormattedText(mainWindow, targetString, 'center', centerY-imageRect(4)+20, textColor);
        DrawFormattedText(mainWindow, respString, 'center', centerY+imageRect(4), textColor);
        DrawFormattedText(mainWindow, accuracyString, 'center', centerY+imageRect(4)+30, textColor);
        Screen('DrawTexture', mainWindow, randImageTex(target), imageRect, centerRect);
        feedbackStart = Screen('Flip', mainWindow);

        while(1)
            temp = GetChar;
            if (temp == ' ' )
                break;
            end
            WaitSecs(0.5);
        end

        if ~isnan(resp)
            % update trial counter & write data to file
            repeatedTrial = 0;
            fprintf(practiceFile, '\n %i, %i, %i, %s, %i, %.2f, %i, %i, %i, %.4f, %.4f', ...
                subID, block, trialCounter, imagePath{target}, target, coherence, respFrame, resp, accuracy, RT, realDuration);
            trialCounter = trialCounter + 1;

        else % repeat trial
            repeatedTrial = 1;
            % get indices of non-noise frames
            imgIdx = find(flickerStream(:, trialCounter));
            nImgFrames = length(imgIdx);
            % use coherence to determine number of target frames
            coherence = practiceCoherences(cohLevel);
            nTargetFrames = ceil(nImgFrames*coherence);
            nLureFrames = nFrames/2 - nTargetFrames;
            targetIdx = randsample(imgIdx, nTargetFrames);
            lureIdx = setdiff(imgIdx, targetIdx);

            % populate imgFrames with target
            flickerStream(targetIdx, trialCounter) = target;
            if target == 1
                flickerStream(lureIdx, trialCounter) = 2;
            end

            % reset temporary variables
            resp = NaN;
            accuracy = NaN;
            RT = NaN;
            respFrame = NaN;
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

            % run flicker stream
            for f = 1:nFrames
                frame = flickerStream(f, trialCounter);
                if frame == 0
                    Screen('DrawTexture', mainWindow, randMaskTex(randi(2,1)), imageRect, centerRect);
                else
                    Screen('DrawTexture', mainWindow, randImageTex(frame), imageRect, centerRect);
                end

                % flip to screen
                vbl = Screen('Flip', mainWindow, vbl + (waitframes - 0.5) * ifi);
                flipTimes(f, trialCounter) = vbl;

                % scan for response
                if isnan(RT)
                    [keyIsDown, secs, keyCode] = KbCheck;
                    % quit if quit key is pressed
                    if keyIsDown
                        if keyCode(respQuit)
                            cleanupScr(mainWindow);
                            return
                        end
                        % end flicker with button press
                        if any(keyCode(imageResponseKeys))
                            RT = secs - flickerStart;
                            resp = find(keyCode(imageResponseKeys));
                            respFrame = f;
                            break
                        end % if any...
                    end % if keyIsDown
                end %if isnan
            end % for f=1:nFrames

            % document duration of each flicker stream
            realDuration = GetSecs - flickerStart;

            % record accuracy & store frame when response was made
            accuracy = resp==target;
            responseFrames(trialCounter) = respFrame;

            % display target & give feedback on accuracy
            targetString = 'The target image was: ';
            respString = sprintf('Your response was: %i', resp);
            if isnan(resp)
                respString = 'You still did not respond in time.';
                accuracyString = 'Remember: your task is to press the button of the most frequent image. \n Press spacebar to continue.';
            elseif accuracy==1
                accuracyString = 'Nice work! Press spacebar to continue.';
            elseif accuracy==0
                accuracyString = 'Remember: your task is to press the button of the most frequent image. \n Press spacebar to continue';
            end

            % draw & flip to screen
            DrawFormattedText(mainWindow, targetString, 'center', centerY-imageRect(4)+20, textColor);
            DrawFormattedText(mainWindow, respString, 'center', centerY+imageRect(4), textColor);
            DrawFormattedText(mainWindow, accuracyString, 'center', centerY+imageRect(4)+30, textColor);
            Screen('DrawTexture', mainWindow, randImageTex(target), imageRect, centerRect);
            feedbackStart = Screen('Flip', mainWindow);

            while(1)
                temp = GetChar;
                if (temp == ' ' )
                    break;
                end
                WaitSecs(0.5);
            end

            fprintf(practiceFile, '\n %i, %i, %i, %s, %i, %.2f, %i, %i, %i, %.4f, %.4f, %i', ...
                subID, block, trialCounter, imagePath{target}, target, coherence, respFrame, resp, accuracy, RT, realDuration, repeatedTrial);
            trialCounter = trialCounter + 1;

        end % repeat trial if response is NaN; only repeating a trial once because otherwise the code gets messy
    end
end





