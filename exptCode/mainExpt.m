function mainExpt(debug)

% ContextCues: cued perceptual decision-making
% phase 1 (response training): participants learn to identify scene images with keyboard buttons
% phase 2 (calibration): participants decide which of two possible images dominated (was presented more frequently) a stream of noisy visual
% evidence; evidence coherence is staircased to identify the coherence level that results in 55% accuracy for that participant
% phase 3 (cue learning): participants learn, through experience, probabilisitic associations  between context/prior cues (colored borders) and observing a scene image.
% phase 4 (cued inference): participants decide which of two scene images
% dominated (was presented more frequently) a stream of noisy visual evidence presented inside the learned prior cues
%

%=========================================================================================
% Author: Ari Khoudary (2023-2024), adapting code originally written by Mariam Aly, Aaron M. Bornstein, Sam Feng (2015)

%% initial setup

clc;

% reset random seed
seed = sum(100*clock);
rng('twister',seed);

% get subject & block numbers
subID = input('Subject number: ');
block = input('Block: ');
%oneScreen = input('One screen?: ');

% double-check assign subID and block -- come back and clean
%         if (nargin < 2)
%             subjectNumber = 0;
%             datalist = dir([datadir 'combray_*.txt']);
%             if (~isempty(datalist))
%                 lastsubj = datalist(end).name;
%                 seps = strfind(lastsubj, '_');
%                 subjectNumber = str2num(lastsubj(seps(1)+1:seps(2)-1))+1;
%             end
%
%             subNumStr = input(['Enter the subject number, or return for ' num2str(subjectNumber,'%.2d') ': '], 's');
%             subNumStr = str2num(subNumStr);
%             if (~isempty(subNumStr))
%                 subjectNumber = subNumStr;
%             end
%
%             subjectName = input(['Enter the subject''s initials: '], 's');
%         end

%% output setup

% create folder to contain each subject's files
sID = ['s', num2str(subID)];
datadir = ['..' filesep 'data' filesep sID];
if ~exist(datadir, 'dir')
    mkdir(datadir);
end

% make file for training
trainingFileName = [datadir filesep 'block', num2str(block), '_training.csv'];
trainingFile = fopen(trainingFileName, 'wt+');
fprintf(trainingFile, ...
    '%s,%s,%s,%s,%s,%s,%s',  ...
    'subID', 'block', 'trial', 'image', 'actualResponse', 'correctResponse', 'RT');

% make file for practice
practiceFileName = [datadir filesep 'block', num2str(block), '_flickerPractice.csv'];
practiceFile = fopen(practiceFileName, 'wt+');
fprintf(practiceFile, ...
    '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',  ...
    'subID', 'block', 'trial', 'targetImage', 'targetIdx', 'coherence', 'respFrame', 'response', 'accuracy', 'RT', 'flickerDuration', 'repeatedTrial');

% make file for calibration
calibrationFileName = [datadir filesep 'block', num2str(block), '_calibration.csv'];
calibrationFile = fopen(calibrationFileName, 'wt+');
fprintf(calibrationFile, ...
    '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',  ...
    'subID', 'block', 'trial', 'targetImage', 'targetIdx', 'coherence', 'respFrame', 'response', 'accuracy', 'RT', 'flickerDuration');

% make file for learning
learnFileName = [datadir, filesep 'block', num2str(block), '_learning.csv'];
learnFile = fopen(learnFileName, 'wt+');
fprintf(learnFile, ...
    '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',  ...
    'subID', 'block', 'trial', 'image', 'imageIdx', 'cue', 'congruent', 'response', 'accuracy', 'RT', 'cueDuration');

% make file for inference
inferenceFileName = [datadir, filesep 'block', num2str(block), '_inference.csv'];
inferenceFile = fopen(inferenceFileName, 'wt+');
fprintf(inferenceFile, ...
    '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',  ...
    'subID', 'block', 'trial', 'targetImg', 'targetIdx', 'cue', 'congruent', 'respFrame', 'response', 'accuracy', 'RT', 'confResp', 'confRT', 'flickerDuration', 'noise1frames', 'signal1frames', 'noise2frames', 'coherence');
%% keyboard setup

% unify responses across operating systems
KbName('UnifyKeyNames');

% response keys
resps         = [KbName('1!') KbName('2@') KbName('3#') KbName('4$')];
respQuit    = KbName('x');
actKeys     = [resps respQuit];
imageResponseKeys = resps(1:2);
confidenceResponseKeys = resps;
rightKey = KbName('RightArrow');
leftKey = KbName('LeftArrow');
spaceKey = KbName('space');

% clear any presses from device memory
FlushEvents('keyDown');

% load KbCheck into memory now so later RTs are uniform
[keyIsDown, secs, keyCode] = KbCheck;

%% screen setup

% general preferences
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'Verbosity', 0);
%Screen('Preference', 'VisualDebugLevel', 1);

% aesthetics
backgroundColor = 0;
textColor = 255;

% make farthest screen display
screenNumber = max(Screen('Screens'));

% get display dimensions
screenDims = Screen('Rect', screenNumber);
screenX = screenDims(3);
screenY = screenDims(4);
% define open window
mainWindow = Screen(screenNumber, 'OpenWindow',backgroundColor);%, screenDims);
centerX  = screenX/2;
centerY = screenY/2;

% manually specify refresh rate (interflip interval)
ifi = 1/60;
waitframes = 1;

% retrieve maximum priority number
topPriorityLevel = MaxPriority(mainWindow);

% text settings for display screen
Screen('TextSize', mainWindow, 24);

% place-holders / positions for images
imageSizeX  = 256;
imageSizeY = 256;
imageRect  = [0,0,imageSizeX,imageSizeY];
centerRect  = [centerX - imageSizeX/2, centerY - imageSizeY/2, centerX + imageSizeX/2, centerY + imageSizeY/2];
% position for prior cue
borderRect = [centerX - imageSizeX/2 - 10, centerY - imageSizeY/2 - 10, centerX + imageSizeX/2 + 10, centerY + imageSizeY/2 + 10];

%% load & prep stimuli

% get filepaths
imageList = dir('images/S*.jpg');
maskList = dir('images/mask*_s*.jpg');
% store
imageTex = zeros(length(imageList),1);
maskTex = zeros(length(maskList),1);

% get scene images
for i = 1:length(imageList)
    tempMat = imread(['images/' imageList(i).name]);
    imageTex(i,1) = Screen('MakeTexture', mainWindow, tempMat);
end

% get masks
for m = 1:length(maskList)
    tempMat = imread(['images/' maskList(m).name]);
    maskTex(m,1) = Screen('MakeTexture', mainWindow, tempMat);
end

% define stimulus pairs (i.e., stimPairs(1)==2, stimPairs(4)==3)
stimPairs = [2,1,4,3];

% randomly choose pair of images for participant
%if randi([1,2]) == 1
    randImageTex(1,1) = imageTex(1);
    randImageTex(2,1) = imageTex(2);
    randMaskTex(1,1) = maskTex(1);
    randMaskTex(2,1) = maskTex(2);
    imagePath = {imageList(1).name; imageList(2).name};
% else
%     randImageTex(1,1) = imageTex(3);
%     randImageTex(2,1) = imageTex(4);
%     randMaskTex(1,1) = maskTex(3);
%     randMaskTex(2,1) = maskTex(4);
%     imagePath = {imageList(3).name; imageList(4).name};
% end

% randomize indices to randomize key presses across participants
shuffledIdx = Shuffle([1,2]);
randImageTex = randImageTex(shuffledIdx);
imagePath = imagePath(shuffledIdx);

%% task parameters

%%% high-level
numBlocks = 1; % number of blocks
numCues = 3; % num prior cues per block
numImages = 2; % unique images on which decisions are to be made, per block
learnTrialN = 5*numCues; % num learning trials
inferenceTrialN  = 10*numCues; % num inference trials
blockN = learnTrialN + inferenceTrialN;
highMemReliability = 0.8;
vizAccuracy = 0.65;
cueLevels = [highMemReliability 1-highMemReliability; ... % cue in favor of imgIdx1
    1-highMemReliability highMemReliability; ... % cue in favor of imgIdx 2
    0.5 0.5]; % neutral cue
% colors of non-neutral cues
redBlue = [[255 0 0]; [0 0 255]];

%%% response training
% criterion for response training
criterion = 0.8;
trialsPerImage = 10;
trainTrialDuration = 2;
trainITI = 1;

%%% flicker practice
practiceCoherences = 0.95:-0.05:0.5;
practiceTrialN = 2*length(practiceCoherences);
feedbackDuration = 3;

%%% calibration
calibrationITI = 1;
calibrationTrialsPerImage = 50; % staircase trials per image
calibrationTrialN = calibrationTrialsPerImage * numImages;

%%% cue learning
learnITI = 1;
learnImgDuration = 2;

%%% cued inference
flickerDuration  = 3;
flickerRate = 60; % Hz
inferenceITI = calibrationITI;
inferenceISI = 0.5;
confidenceDuration = 2;

%% create learning & inference trial structures

% randomize cue indices to be used in both phases
cueIdx = Shuffle([1,2]);
cueColors = redBlue(cueIdx,:);
cueColors = [cueColors; 195 0 255]; % append neutral cue color

% distribution of learning trials
learnTrials = uint8(cueLevels*learnTrialN / numCues);
% make array of cue indices for learning
learnCue = [repmat(1, 1, learnTrialN/numCues) repmat(2,1,learnTrialN/numCues) repmat(3,1,learnTrialN/numCues)];
% populate image array in proportion to cue reliability; each row corresponds to cue index
learnImg = [];

for cueIdx=1:numCues
    learnImg(cueIdx, :) = [repmat(1, 1, learnTrials(cueIdx,1)) repmat(2,1,learnTrials(cueIdx,2))];
end

% randomize order
randImg = Shuffle(1:learnTrialN/numCues);
learnImg = learnImg(:, randImg);
learnTrialOrder = Shuffle(1:learnTrialN);
learnCue = learnCue(learnTrialOrder);

% distribution of inference trials
inferenceTrials = uint8(cueLevels*inferenceTrialN / numCues);
% make array of cue indices for learning
inferenceCue = [repmat(1, 1, inferenceTrialN/numCues) repmat(2,1,inferenceTrialN/numCues) repmat(3,1,(inferenceTrialN/numCues)/2)]; %cut number of neutral trials in half to save time
% populate image array in proportion to cue reliability; each row corresponds to cue index
inferenceImg = [];

for cueIdx=1:numCues
    if cueIdx==3 % get rid of half the neutral trials
        inferenceImg(cueIdx, :) = [repmat(1, 1, inferenceTrials(cueIdx,1)/2) repmat(2,1,inferenceTrials(cueIdx,2)/2) zeros([1 inferenceTrials(cueIdx)])];
    else
        inferenceImg(cueIdx, :) = [repmat(1, 1, inferenceTrials(cueIdx,1)) repmat(2,1,inferenceTrials(cueIdx,2))];
    end
end

% randomize order
randImg = Shuffle(1:inferenceTrialN/numCues);
randImgNeut = [Shuffle(1:inferenceTrials(6)) inferenceTrials(6)+1:length(inferenceImg)];
inferenceImg(1,:) = inferenceImg(1,randImg);
inferenceImg(2,:) = inferenceImg(2,randImg);
inferenceImg(3,:) = inferenceImg(3,randImgNeut);
inferenceTrialOrder = Shuffle(1:length(inferenceCue));
inferenceCue = inferenceCue(inferenceTrialOrder);

% generate probabilistic cue & noise durations
makeNoiseDistributions;

%% block loop

for block = 1:numBlocks

    % make arrows for navigating instructions
    rightString = 'more instructions ->';
    leftString = '<- previous instructions ';
    rightPosition = screenX-350;
    leftPosition = screenX - 1200;

    % make welcome screen
    welcString{1} = ['Welcome! \n\n' ...
        'This is an experiment about how people make decisions on the basis of noisy evidence. \n\n'...
        'Today''s session will consist of a few different parts. \n\n' ...
        'Use the forward arrow to learn more.'];

    welcString{2} = ['First, you will learn the mapping between keyboard buttons and decision options. \n\n' ...
        'Then, you will practice making the primary decision in this task: determining which of two scene images was presented more frequently in a rapidly changing visual evidence stream. \n\n' ...
        'After completing some post-practice decision trials, you will switch gears for a little to learn associations between colored borders and the scene images. \n\n' ...
        'Finally, you will perform more visual decision trials, this time with the help of the colored borders. \n\n'];

    welcString{3} = ['Each phase will have its own instruction screens, and you are encouraged to take brief breaks during this time. \n\n' ...
        'Use the break time to rest your eyes, stretch, drink water, etc; please do not use your phone during this time so as to keep the experiment on track. \n\n' ... 
        'If you have questions at any point, please do not hesitate to ask the experimenter. The whole experiment will take no longer than 1 hour to complete. \n\n' ...
        'Press spacebar to receive instructions for the first phase of the experiment.'];

    page = 1;
    while page < length(welcString) + 1
        DrawFormattedText(mainWindow, welcString{page}, 'center', 'center', textColor, 80);
        if page<max(size(welcString))
            DrawFormattedText(mainWindow, rightString, rightPosition, screenY-100, textColor);
        end
        if page > 1
            DrawFormattedText(mainWindow, leftString, leftPosition, screenY-100, textColor);
        end
        Screen('Flip', mainWindow);
        WaitSecs(0.05);
        [~,~,keyCode] = KbCheck;
        if page < 3 && keyCode(rightKey)
            page = page + 1;
            FlushEvents('keyDown');
            WaitSecs(0.5);
        elseif page > 1 && keyCode(leftKey)
            page = page - 1;
            FlushEvents('keyDown');
            WaitSecs(0.5);
        elseif page==max(size(welcString)) && keyCode(spaceKey)
            break
        end
    end

    % response training instructions
    responseTrainString = ['In this part of the experiment, your task is to learn the mapping between response keys (1 and 2) and different scene images. \n\n' ...
        'You will be presented with the images one-by-one, and your task is to press the button you are told corresponds to each image. \n\n' ...
        'You will receive feedback on the accuracy of your responses. \nThe experiment will not proceed until you reach a desired level of accuracy. \n\n' ...
        'Please ask the experimenter if you have any questions. \n' ...
        'Once you feel ready to begin, press spacebar to start training.'];
    DrawFormattedText(mainWindow, responseTrainString, 'center', 'center', textColor, 80);
    Screen('Flip',mainWindow);
    FlushEvents('keyDown');
    WaitSecs(3);
    while(1)
        [~,~,keyCode] = KbCheck;
        if keyCode(spaceKey)
            break;
        end
        WaitSecs(0.05);
    end

    % initiate response training
    responseTraining;

    % phase pivot
    pivotString = ['Nice work! You learned the correct response mappings. \n\n' ...
        'Press spacebar to proceed to the next part of the experiment'];
    DrawFormattedText(mainWindow, pivotString, 'center', 'center', textColor, 80);
    Screen('Flip', mainWindow);
    FlushEvents('keyDown');
    while(1)
        [~,~,keyCode] = KbCheck;
        if keyCode(spaceKey)
            break;
        end
        WaitSecs(0.05);
    end

    % flicker practice instructions
    pracString{1} = ['In this part of the experiment, you will practice the "flicker" part of the task: deciding which of the two images was presented more frequently in a rapidly alternating image stream. \n\n' ...
        'Indicate which image you think was dominant by pressing the button you just learned to associate with that image. \n'];
    pracString{2} = ['To make sure you are comfortable with this task, we will start off quite easy and give you feedback on your responses.\n\n' ...
        'Press spacebar when you feel ready to begin.'];

    page = 1;
    while page < length(pracString) + 1
        DrawFormattedText(mainWindow, pracString{page}, 'center', 'center', textColor, 80);
        if page == 1
            DrawFormattedText(mainWindow, rightString, rightPosition, screenY-100, textColor);
        end
        if page > 1
            DrawFormattedText(mainWindow, leftString, leftPosition, screenY-100, textColor);
        end
        Screen('Flip', mainWindow);
        WaitSecs(0.05);
        [~,~,keyCode] = KbCheck;
        if page < 3 && keyCode(rightKey)
            page = page + 1;
            FlushEvents('keyDown');
            WaitSecs(0.5);
        elseif page > 1 && keyCode(leftKey)
            page = page - 1;
            FlushEvents('keyDown');
            WaitSecs(0.5);
        elseif page==max(size(pracString)) && keyCode(spaceKey)
            break
        end
    end

    % initiate flicker practice
    flickerPractice;

    % phase pivot
    instructString = 'Practice complete! Press spacebar to continue to the next phase of the experiment.';
    DrawFormattedText(mainWindow, instructString, 'center', 'center', textColor, 80);
    Screen('Flip', mainWindow);
    FlushEvents('keyDown');
    while(1)
        temp = GetChar;
        if (temp == ' ')
            break;
        end
        WaitSecs(0.05)
    end

    % calibration instructions
    calString1 = ['You will now complete more trials of the flicker task. \n\n' ...
        'You will no longer receive feedback on your responses, and the difficulty will continue to change from trial to trial. \n\n' ...
        'Please do your best to respond as accurately and quickly as possible.'];
    DrawFormattedText(mainWindow, calString1, 'center', 'center', textColor, 80);
    DrawFormattedText(mainWindow, rightString, rightPosition, screenY-100, textColor);
    Screen('Flip', mainWindow);
    FlushEvents('keyDown');

    while(1)
        [~, ~, keyCode] = KbCheck;
        if keyCode(rightKey)
            break
        end
        WaitSecs(0.05);
    end

    % pre-calibration button reminder
    buttonReminder;

    % initiate calibration with spacebar press
    instructString = 'Press spacebar to begin the flicker task.';
    DrawFormattedText(mainWindow, instructString, 'center', 'center', textColor, 80);
    Screen('Flip', mainWindow);
    while(1)
        temp = GetChar;
        if (temp == ' ')
            break;
        end
        WaitSecs(0.05)
    end

   % calibration;
    coherence = calibratedCoherence;
    % coherence = [0.5 0.5];

    % phase pivot screen & learning instructions
    learnString = ['Nice work! In the next phase, you will get a small break from doing the flicker task. \n\n' ...
        'Instead, you will learn associations between colored borders and scene images. \n' ...
        'You will see colored borders followed by scene images, and your task is to press the button that corresponds to the scene image. \n\n' ...
        'Press spacebar when you feel ready to begin.'];
    DrawFormattedText(mainWindow, learnString, 'center', 'center', textColor, 80);
    Screen('Flip', mainWindow);
    FlushEvents('keyDown');
    while(1)
        temp = GetChar;
        if (temp == ' ')
            break;
        end
        WaitSecs(0.05)
    end

    % pre-learning button mapping reminder
    buttonReminder;

    % initiate cue learning with spacebar press
    instructString = 'Press spacebar to begin the task.';
    DrawFormattedText(mainWindow, instructString, 'center', 'center', textColor, 80);
    Screen('Flip', mainWindow);
    while(1)
        temp = GetChar;
        if (temp == ' ')
            break;
        end
        WaitSecs(0.05)
    end

    % then initiate cue learning
    cueLearning;

    % phase pivot
    pivotString = 'Nice work! You can use this time to take a short break before proceeding with the final phase of the experiment. \n\n When you are ready, press spacebar to receive instructions.';
    DrawFormattedText(mainWindow, pivotString, 'center', 'center', textColor, 80);
    Screen('Flip', mainWindow);
    FlushEvents('keyDown');
    while(1)
        temp = GetChar;
        if (temp == ' ')
            break;
        end
        WaitSecs(0.05)
    end

    % inference instructions
    infString{1} = ['In this phase of the experiment, you will perform the flicker task again. \n\n' ...
        'This time, it will be inside the colored borders that you just experienced in the previous phase, and there will be more visual noise. \n\n' ...
        'Usually, the dominant image will be the one predicted by the colored border.'];

    infString{2} = ['Again, your task is to indicate which image was presented more frequently by pressing the button associated with it. \n\n' ...
        'You will also be asked to rate your confidence on a scale of 1-4. \n' ...
        'Don''t overthink this - just press the button that feels right, and make sure to use all the buttons in the range. \n'];

    infString{3} = ['You will not receive feedback on your responses. \n\n' ...
        'You will get 3 breaks. These are to allow you to rest your eyes and stretch; please refrain from using your phone during this time. \n\n' ...
        'Press spacebar to proceed to the pre-task response mapping reminders.'];
    page = 1;
    while page < length(infString) + 1
        DrawFormattedText(mainWindow, infString{page}, 'center', 'center', textColor, 80);
        if page < 3
            DrawFormattedText(mainWindow, rightString, rightPosition, screenY-100, textColor);
        end
        if page > 1
            DrawFormattedText(mainWindow, leftString, leftPosition, screenY-100, textColor);
        end
        Screen('Flip', mainWindow);
        WaitSecs(0.05);

        [~,~,keyCode] = KbCheck;
        if page < 3 && keyCode(rightKey)
            page = page + 1;
            FlushEvents('keyDown');
            WaitSecs(0.5);
        elseif page > 1 && keyCode(leftKey)
            page = page - 1;
            FlushEvents('keyDown');
            WaitSecs(0.5);
        elseif page==3 && keyCode(spaceKey)
            break
        end
    end

    % pre-inference button reminder
    buttonReminder;

    % initiate cued inference with spacebar press
    instructString = 'Press spacebar to begin the task.';
    DrawFormattedText(mainWindow, instructString, 'center', 'center', textColor, 80);
    Screen('Flip', mainWindow);
    while(1)
        temp = GetChar;
        if (temp == ' ')
            break;
        end
        WaitSecs(0.05)
    end

    cuedInference;

end % for block in nBlocks

goodbyeString = 'Experiment complete! Thanks for your participation. \n\n Please get the experimenter.';
DrawFormattedText(mainWindow, goodbyeString, 'center', 'center', textColor, 80);
Screen('Flip', mainWindow);
while(1)
    temp = GetChar;
    if (temp == ' ')
        break
    end
    WaitSecs(0.05)
end


end % function