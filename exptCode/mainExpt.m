% main script for running the experiment ContextCues

%=========================================================================================
% Author: Ari Khoudary (2023-2024), adapting code originally written by Mariam Aly, Aaron M. Bornstein, Sam Feng (2015)

%% initial setup
clc;

% get subject & block numbers
subID = input('Subject number: ');
block = input('Block: ');
debug = input('debug?: ');

% use subject ID to set the random seed
rng(subID)

%% high-level experiment settings

% task structure
nBlocks = 1; % number of blocks
nCues = 3; % num prior cues per block
nImages = 2; % unique images on which decisions are to be made, per block

% evidence reliabilities
memReliability = 0.8;
vizAccuracy = 0.7;
% vision reliability is technically given by the evidence coherence. to
% control for differences in how the images are processed by different
% people, we use QUEST staircasing to identify coherence values for each image that result in
% vizAccuracy level of performance

% visual evidence presentation rate (interflip interval)
ifi = 1/60;
waitframes = 1;

%% output setup

setup_output;

%% keyboard setup

setup_keyboard;

%% screen setup

setup_screen;

%% load & prep stimuli

setup_stimuli;

%% task settings for each phase of the experiment

%%% response training
criterion = 0.8; % required accuracy level on button mappings
trialsPerImage = 10;
trainTrialDuration = 2; % seconds
trainITI = 1;
if debug
    trialsPerImage = 1;
end

%%% flicker practice
practiceCoherences = 0.95:-0.05:0.5;
practiceTrialN = nImages*length(practiceCoherences);
feedbackDuration = 3;

%%% calibration
calibrationITI = 1;
calibrationTrialsPerImage = 50; % staircase trials per image
calibrationTrialN = nImages * calibrationTrialsPerImage;

%%% cue learning
learningCriterion = 0.8; % what level of accuracy per cue is needed to move on from cue learning
learnTrialN = nCues * 25;
learnITI = 1;
learnImgDuration = 2;
if debug
    learnTrialN = nCues * 5;
end
setup_colors;

%%% cued inference
inferenceTrialN = nCues * 100;
flickerDuration = 3;
flickerRate = 60; % Hz
inferenceITI = 1;
inferenceISI = 0.75;
confidenceDuration = 3;
if debug
    inferenceTrialN = nCues * 10;
end

%% set up trial structures for learning & inference

setup_trials;


%% generate probabilistic durations for learning & inference

setup_durations;

%% block loop

for block = 1:nBlocks

    % make arrows for navigating instructions
    rightString = 'more instructions ->';
    leftString = '<- previous instructions ';
    rightPosition = screenX-350;
    leftPosition = screenX - 1200;

    if debug==0
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
    end

    % initiate response training
    responseTraining;

    if debug==0
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
    
            calibration;
            coherence = calibratedCoherence;
        else % if debug==1
            coherence = [0.5 0.5];
    end

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