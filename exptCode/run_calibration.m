% CALIBRATION: PHASE 2 OF CONTEXT CLUES

% use interleaved QUEST staircases to identify coherence level that obtains target level of accuracy

% =================================================================================================================================
% Author: Ari Khoudary (2023), original code by Aaron M Bornstein & Mariam Aly

%% set up interleaved quest staircases

% PARAM: parameters of Weibull psychometric function
% NB: we can have different parameters for different staircases
% so we can set tGuess and tStDev separately, which will come in handy
% if we want to start out closer to what we think the right stimulus
% proportions are

% all staircase values correspond to stimulus proportion
% Beta  = Slope of weibull (2AFC = 3.5; Watson, Pelli 1983)
% Delta = Incidence of careless mistakes (0.01 by Watson, Pelli 1983)
% Gamma = probability of success at zero intensity (0.5)
beta = 3.5;
delta = 0.01;
gamma = 0.5;

% initial stepsize
grain  = 0.01;

% all possible values (combined with tGuess to make 0.5:0.01:1); tGuess+(-range/2:grain:range/2)
range  = 0.5;
tStDev = 0.25;

% set initial guess, which will be different for different desired
% accuracies; prior threshold estimate and SD; this should cover all possible values pretty generously
tGuess(1) = 0.7;
tGuess(2) = 0.55;

% Tracks # presentations of each stimulus, staircase
stair1Counter  = zeros(nImages, 1);
stair2Counter = stair1Counter;

% instantiate two staircases per image
for stimIdx = 1:nImages
    q1{stimIdx} = QuestCreate(tGuess(1), tStDev, vizAccuracy, beta, delta, gamma, grain, range);
    q2{stimIdx} = QuestCreate(tGuess(2), tStDev, vizAccuracy, beta, delta, gamma, grain, range);
 end

%% initialize flicker stream & structures to hold timing/staircase info
stim_ind = Shuffle(repelem([1 2], calibrationTrialsPerImage));
flickerStream = repmat([0; 1], nFrames/2, calibrationTrialN);
responseFrames = zeros(calibrationTrialN, 1);
flipTimes = zeros(nFrames, calibrationTrialN);
trialStair = zeros(calibrationTrialN, 1);

if exist('maxFrames', 'var')
    flickerStream = flickerStream(1:maxFrames, :);
    flipTimes = flipTimes(1:maxFrames, :);
end

%% trial loop

for trial = 1: calibrationTrialN
    target  = stim_ind(trial);
    % get coherence value from interleaved staircases
    if mod(trial,2) == 1
        stair1Counter(target) = stair1Counter(target) + 1;
        trialCoherence = squeeze(QuestQuantile(q1{target}));
        trialStair(trial) = 1;
    else
        stair2Counter(target) = stair2Counter(target) + 1;
        trialCoherence = squeeze(QuestQuantile(q2{target}));
        trialStair(trial) = 2;
    end

    % get indices of non-noise frames
    imgIdx = find(flickerStream(:, trial));
    nImgFrames = length(imgIdx);
    % use coherence to determine number of target frames
    nTargetFrames = ceil(nImgFrames*trialCoherence);
    nLureFrames = nFrames/2 - nTargetFrames;
    rIdx = randperm(nImgFrames);
    targetIdx = imgIdx(rIdx(1:nTargetFrames));
    lureIdx = setdiff(imgIdx, targetIdx);

    % populate imgFrames with target, in proportion to coherence
    flickerStream(targetIdx, trial) = target;

    % lureIdx is automatically populated when target==2; populate
    % manually when target==1
    if target == 1
        flickerStream(lureIdx, trial) = 2;
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
        frame = flickerStream(f, trial);
        if frame == 0
            Screen('DrawTexture', mainWindow, randMaskTex(randi(2,1)), imageRect, centerRect);
        else
            Screen('DrawTexture', mainWindow, randImageTex(frame), imageRect, centerRect);
        end

        % flip to screen
        vbl = Screen('Flip', mainWindow, vbl + (waitframes - 0.25) * ifi);
        flipTimes(f, trial) = vbl;

        % scan for response
        if isnan(RT)
            [keyIsDown, secs, keyCode] = KbCheck(-1);
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
                    responseFrames(trial) = f;
                    break
                end % if any...
            end % if keyIsDown
        end %if isnan
    end % for f=1:nFrames

    % document actual duration of each flicker stream
    realDuration = GetSecs - flickerStart;
    
    %% feedback 
    accuracy = resp==target;

    % display feedback
    targetString = 'The correct answer was: ';
    respString = 'Your response was: ';
    if isnan(resp)
        accString = 'You did not respond in time. \n Please respond faster on the next trial.';
    elseif accuracy==1
        accString = 'Correct!';
    else
        accString = 'Incorrect.';
    end
        
    % draw & flip to screen
    DrawFormattedText(mainWindow, targetString, 'center', centerY-imageRect(4)/1.5, textColor);
    Screen('DrawTexture',mainWindow,randImageTex(target),imageRect,centerRect);
    if ~isnan(resp)
        DrawFormattedText(mainWindow, respString, 'center', centerY+imageRect(4)-20, textColor);
        DrawFormattedText(mainWindow, accString, 'center', centerY+feedbackRect(4)*3.3, textColor);
        Screen('DrawTexture', mainWindow, randFeedbackTex(resp), feedbackRect, feedbackPos);
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
   
    % update staircases
    if mod(trial,2) == 1
        q1{target} = QuestUpdate(q1{target}, trialCoherence, accuracy);
    else  
        q2{target} = QuestUpdate(q2{target}, trialCoherence, accuracy);
    end

    % end the trial after a response during calibration
    fprintf(calibrationFile, '\n %i, %i, %i, %s, %i, %.4f, %i, %i, %i, %i, %.4f, %.4f', ...
        subID, block, trial, imagePath{target}, target, trialCoherence, trialStair(trial), responseFrames(trial), resp, accuracy, RT, realDuration);
end

clear string
%%
for stimIdx = 1:nImages
    validq1 = q1{stimIdx}.intensity(q1{stimIdx}.intensity~=0);
    validq2 = q2{stimIdx}.intensity(q2{stimIdx}.intensity~=0);
    if debugging==1 && length(validq1)==0
        endq1 = 0;
        endq2 = validq2(end);
    elseif debugging==1 && length(validq2)==0
        endq1 = validq1(end);
        endq2 = 0;
    else
        endq1 = validq1(end);
        endq2 = validq2(end);
    end
    abs(endq1 - endq2)
    sprintf('Staircase difference for stimulus is %i is %.4f', stimIdx,  abs(endq1 - endq2))
    calibratedCoherence(stimIdx) = mean([endq1 endq2], 'omitnan');
    if any(isnan([validq1 validq2]))
        warning('Hey, there are NaNs in your staircase. Consider redoing it.');
    end
end

% save workspace variables
save([datadir filesep 'block' num2str(block) '_calibrationVars.mat']);

%% plot staircase values
figure;
for stimIdx = 1:nImages
    subplot(1,2,stimIdx)
    hold on;
    validq1 = q1{stimIdx}.intensity(q1{stimIdx}.intensity~=0);
    validq2 = q2{stimIdx}.intensity(q2{stimIdx}.intensity~=0);
    ylim([0.3 0.9]);
    plot(1:length(validq1), validq1, '.-');
    plot(1:length(validq2), validq2, '.-');
    titleString = sprintf('Staircases for stimulus %i', stimIdx);
    title(titleString);
    xlabel('trial');
    ylabel('coherence');
    legend({'staircase1', 'staircase2'});
    hold off
end

