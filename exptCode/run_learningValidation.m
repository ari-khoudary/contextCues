% measures participants learned cue probabilities

%% setup output

varNames = {'subID', 'block', 'cueString', 'cueIdx', 'congImgIdx', 'estimate', 'RT', 'sliderValue', 'confidence', 'confRT', 'rightImageIdx', 'leftImageIdx'};
varTypes = cell([1, length(varNames)]);
varTypes(:) = {'double'};
varTypes(3) = {'cell'};

data_learningValidation = table('Size', [nCues length(varNames)], ...
    'VariableNames', varNames, ...
    'VariableTypes', varTypes);

data_learningValidation.subID = repelem(subID, nCues)';
data_learningValidation.block = repelem(block, nCues)';

%% settings

% slider parameters
minValue = 0;         % minimum value of the slider
maxValue = 100;       % maximum value of the slider
currentValue = 50;    % initial value of the slider
sliderLength = 200;   % length of the slider line
sliderWidth = 5;     % width of the slider line
sliderHeight = 20;    % height of the slider thumb
sliderStep = 1;         % units with which to increment the slider
rightImageIdx = 2;
leftImageIdx = 1;

% randomized cue orders
rIdx = Shuffle(1:nCues);

for i = 1:nCues

    % initialize responses
    estimate = NaN;
    confidence = NaN;
    currentValue = 50;    % initial value of the slider

    % choose one cue at random
    thisCue = cueColors(rIdx(i),:);

    FlushEvents('keyDown');
    trialStart = GetSecs;
    arrowPress = 0;
    % display cue + slider
    while isnan(estimate) 

        % draw the prompt
        DrawFormattedText(mainWindow, 'What does this border predict?', 'center', screenY*0.3, textColor, 70);

        % draw the cue
        Screen('FrameRect', mainWindow, thisCue, borderRect, 10);

        % Draw the slider
        drawSlider(mainWindow, centerY, centerX, minValue, maxValue, currentValue, sliderLength, sliderWidth, sliderHeight, rightImageIdx, leftImageIdx, feedbackRect, randFeedbackTex, thisCue);

        % Check for keyboard input
        [keyIsDown, ~, keyCode] = KbCheck(-1);

        if keyIsDown
            if keyCode(KbName('LeftArrow'))  % Move thumb left
                currentValue = max(minValue, currentValue - sliderStep);
                arrowPress = 1;
            elseif keyCode(KbName('RightArrow'))  % Move thumb right
                currentValue = min(maxValue, currentValue + sliderStep);
                arrowPress = 1;
            elseif keyCode(KbName('C'))  % Exit when C is pressed
                if arrowPress==1
                    break;
                end
            end
        end
        WaitSecs(0.05);
    end
    RT = GetSecs - trialStart;

    % make estimate relative to cue -- THIS ONLY WORKS IF THE 1 CUE/TARGET
    % COMBO IS ON THE LEFT OF THE SLIDER. 
    if rIdx(i) == 1
        estimate = 100-currentValue;
    else
        estimate = currentValue;
    end

    
    % prep for confidence rating
    FlushEvents('keyDown');

    % draw & display confidence screen
    scale = '1                          2                          3                          4';
    labels = '\n\n not confident                                                              quite confident';
    DrawFormattedText(mainWindow, 'Confidence?', 'center', screenY*0.35, textColor, 70);
    DrawFormattedText(mainWindow, [scale, labels], 'center', screenY*0.55, textColor);
    confFlip = Screen('Flip', mainWindow);

    % keep it on for confidenceDuration amount of time
    while (1)
        % scan for response
        if isnan(confidence)
            [keyIsDown, secs, keyCode] = KbCheck(-1);
            % remove screen when key is pressed
            if any(keyCode(confidenceResponseKeys))
                confRT = secs - confFlip;
                confidence = find(keyCode(confidenceResponseKeys));
                if size(confidence, 2) > 1
                    confidence = mean(confidence);
                end
                break
            end % if any...
        end % if isnan()
    end % while(1)

    % write trial data
    data_learningValidation.cueString(i) = cueStrings(rIdx(i));
    data_learningValidation.cueIdx(i) = rIdx(i);
    if rIdx(i) < 3
        data_learningValidation.congImgIdx(i) = rIdx(i);
    else
        data_learningValidation.congImgIdx(i) = NaN;
    end
    data_learningValidation.rightImageIdx(i) = 2;
    data_learningValidation.leftImageIdx(i) = 1;
    data_learningValidation.estimate(i) = estimate;
    data_learningValidation.sliderValue(i) = currentValue;
    data_learningValidation.confidence(i) = confidence;
    data_learningValidation.confRT(i) = confRT;
    data_learningValidation.RT(i) = RT;

end % for i=1:nCues

writetable(data_learningValidation, [datadir filesep 'block', num2str(block), '_learningValidation.csv']);



