% RESPONSE TRAINING: PHASE 1 OF CONTEXT CLUES
%
% train subjects on button-image mappings until they get >90% accuracy
%
% the following are defined/created in mainExpt.m
% - task parameters: numImages, criterion, trialPerImage, trainTrialDuration, trainITI
% - instructions
% - output file
%
% this script runs the response training phase until criterion accuracy is reached
% it outputs a CSV with behavior and .mat with parameters
%
%==========================================================================
% Author: Ari Khoudary (2023), original code by Mariam Aly & Aaron M Bornstein

%% initialize counters
% to keep track of how many practices they had to do
numPrac  = 1;
% initialize training while-loop
needToTrain  = 1;
% file name for saving counters
pracFileName = [datadir filesep 'block' num2str(block) '_responseTraining.mat'];

%% start training

while needToTrain

    % reset counters
    imageCount = zeros(1,nImages);
    numCorrect = zeros(1,nImages);
    accByImage = zeros(1,nImages);

    % randomize images for presentation
    imagesForTraining = [ones(1,trialsPerImage) repmat(2,1,trialsPerImage)];
    imagesForTraining = Shuffle(imagesForTraining);

    % start with explicit instruction on mappings
    for imgIdx = 1:max(imagesForTraining)
        thisImage = randImageTex(imgIdx, block);

        % give images with instruction, once each
        Screen('DrawTexture',mainWindow,thisImage,imageRect,centerRect);
        instructString  = ['The key for this image is ' num2str(imgIdx) '.\n\nPress ' num2str(imgIdx) ' to continue.'];
        DrawFormattedText(mainWindow, instructString, 'center', centerY-imageRect(4)-20, textColor);
        Screen('Flip', mainWindow);

        % get response
        FlushEvents('keyDown');
        while(1)
            temp = GetChar;
            if (temp == '0'+imgIdx)
                instructEnd = GetSecs;
                break;
            end
        end
    end
    FlushEvents('keyDown');

    while GetSecs < instructEnd + trainITI
        DrawFormattedText(mainWindow, '+', 'center', centerY, textColor);
        Screen('Flip', mainWindow);
    end

    % then shuffle & obtain responses without instructions on screen
    for trainTrial = 1:length(imagesForTraining)

        trainResp = NaN;
        trainRT = NaN;

        % get trial-specific image and correct response, increment image counter
        thisTrainImage = imagesForTraining(trainTrial);
        trainCorrResp = thisTrainImage;
        tmpTrainImage = randImageTex(thisTrainImage, block);
        imageCount(thisTrainImage) = imageCount(thisTrainImage) + 1;

        % present image & store time of presentation
        Screen('DrawTexture',mainWindow,tmpTrainImage,imageRect,centerRect);
        imageTime = Screen('Flip',mainWindow);

        % wait for response
        while GetSecs < imageTime + trainTrialDuration

            % scan keyboard until press is detected
            if isnan(trainRT)
                [keyIsDown, secs, keyCode] = KbCheck(-1);

                % quit expt if respQuit button is pressed
                if (keyIsDown)
                    if (keyCode(respQuit))
                        cleanupScr(mainWindow);
                        return;
                    end

                    % record RT & response if one of the image keys is pressed
                    if (any(keyCode(imageResponseKeys)))
                        trainRT = secs - imageTime;
                        trainResp = find(keyCode(imageResponseKeys));

                        % add to counter of correct responses
                        if trainResp == trainCorrResp
                            numCorrect(thisTrainImage) = numCorrect(thisTrainImage) + 1;
                        end

                    end % if any(keyCode...
                end % if (keyIsDown)
            end % if isnan...

            % provide textual feedback
            if isnan(trainResp)
                feedbackString = '';
            elseif trainResp == trainCorrResp
                feedbackString = 'Correct!';
            else
                feedbackString = 'Incorrect, please try again.';
            end
            DrawFormattedText(mainWindow, feedbackString, 'center', centerY-imageRect(4)-10, textColor);
            Screen('DrawTexture',mainWindow,tmpTrainImage,imageRect,centerRect);
            Screen('Flip', mainWindow);


            % save their first response
            firstTrainResp = trainResp;

            % if incorrect, give them chance to respond again
            if trainResp ~= trainCorrResp
                % scan for a new press
                [keyIsDown, secs, keyCode] = KbCheck(-1);

                % quit if that press is the quit key
                if (keyIsDown)
                    if (keyCode(respQuit))
                        cleanupScr(mainWindow);
                        return;
                    end

                    if (any(keyCode(imageResponseKeys)))
                        trainResp = find(keyCode(imageResponseKeys));

                        % give feedback & end trial
                        if trainResp == trainCorrResp
                            feedbackString = 'Correct.';
                            Screen('DrawTexture', mainWindow, tmpTrainImage, imageRect, centerRect);
                            DrawFormattedText(mainWindow, feedbackString, 'center', centerY-imageRect(4)-20, textColor);
                            Screen('Flip',mainWindow);
                            % else
                            %    feedbackString = 'Incorrect. Moving to next trial.';
                        end
                    end % if (any(keyCode...
                end % if (keyIsDown)
            end % if trainResp ~= trainCorrResp
        end % image presentation for that trial

        if isnan(trainRT)
            DrawFormattedText(mainWindow, 'Please press the buttons corresponding to the scene images.', 'center', centerY, textColor);
            Screen('Flip', mainWindow);
            WaitSecs(2);
        end
        
        accuracy = trainResp==trainCorrResp;

        % ISI
        while GetSecs < imageTime + trainTrialDuration + trainITI
            %Screen('FillRect',mainWindow,0);
            DrawFormattedText(mainWindow, '+', 'center', centerY, textColor);
            Screen('Flip',mainWindow);
        end

        % write stuff in text file
        fprintf(trainingFile, '\n %i, %i, %i, %s, %i, %i, %i, %i, %.5f', ...
            subID, block, trainTrial, imageList(thisTrainImage).name, firstTrainResp, trainCorrResp, accuracy, trainRT);
    end % for trainTrial ...


    % now see if they met criterion
    accByImage = numCorrect./imageCount;

    % end phase if they did
    if min(accByImage) >= criterion
        needToTrain = 0;
        fclose(trainingFile);
        save(pracFileName);

        % restart if they didn't
    elseif min(accByImage) < criterion
        fclose(trainingFile);
        save(pracFileName);
        needToTrain = 1;
        numPrac = numPrac + 1;
        trialsPerImage = 5; % this time only 5 trials per image

        % make a new csv & .mat files
        trainingFileName = [datadir filesep 'block', num2str(block),'_training' num2str(numPrac) ,'.csv'];
        trainingFile = fopen(trainingFileName, 'wt+');
        fprintf(trainingFile, ...
            '%s,%s,%s,%s,%s,%s,%s,%s',  ...
            'subID', 'block', 'trial', 'image', 'actualResponse', 'correctResponse', 'accuracy', 'RT');
        pracFileName = [datadir filesep 'responseTrainingCounters' num2str(numPrac) '.mat'];

        % give instructions
        instructString = 'You did not meet criterion. Press spacebar to try again.';
        DrawFormattedText(mainWindow, instructString, 'center', 'center', textColor);
        Screen('Flip',mainWindow);
        FlushEvents('keyDown');

        while(1)
            temp = GetChar;
            if temp == ' '
                break;
            elseif (temp == 'c') % to continue with experiment despite not reaching criterion
                needToTrain = 0;
                break;
            end 
        end % while(1)...
    end % if acc >= criterion
end % needToTrain

DrawFormattedText(mainWindow, 'all done!', 'center', textColor);
Screen('Flip', mainWindow);
