% main script for running the experiment ContextCues

%=========================================================================================
% Author: Ari Khoudary (2023-2024), adapting code originally written by Mariam Aly, Aaron M. Bornstein, Sam Feng (2015)

%% initial setup
clc;

% get subject & block numbers
subID = input('Subject number: ');
debugging = input('debug?: ');

% use subject ID to set the random seed
rng(subID)

%% high-level experiment settings

% task structure
nBlocks = 1; % number of blocks
nCues = 3; % num prior cues per block
nImages = 2; % unique images on which decisions are to be made, per block
pCatchTrial = 0.1; % what proportion of total inference trials do you want to be ADDED ON as catch trials?

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

% number of brief breaks during inference
nInferenceBreaks = 4;

%% task settings for each phase of the experiment

%%% response training
criterion = 0.8; % required accuracy level on button mappings
trialsPerImage = 10;
trainTrialDuration = 2; % seconds
trainITI = 1;
if debugging
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
learnITI = 1;
learnImgDuration = 2;
if debugging
    learnTrialPerCue = 5;
else
    learnTrialPerCue = 25;
end
learnTrialN = nCues * learnTrialPerCue;

setup_colors; % define colored borders

%%% cued inference
if debugging
    inferenceTrialPerCue = 10;
else
    inferenceTrialPerCue = 100;
end
inferenceTrialN = nCues * inferenceTrialPerCue;
flickerDuration = 3;
flickerRate = 60; % Hz
inferenceITI = 1;
inferenceISI = 0.75;
confidenceDuration = 3;


%% psychtoolbox setups
block = 1;

% sets up
setup_ptb;

%% begin chunks of the experiment

for block = 1:nBlocks
    
    %% set up learning & inference trials for this block
    setup_trials;
    
    %% make arrows for navigating instructions
    rightString = 'more instructions ->';
    leftString = '<- previous instructions ';
    rightPosition = screenX-350;
    leftPosition = screenX - 1200;
    
    if debugging==0
        % general instructions
        welcString{1} = ['Welcome! \n\n' ...
            'This is an experiment about how people learn and make decisions. \n\n'...
            'Today''s session will consist of a few different phases that vary in length. \n' ...
            'The experiment as a whole should take no more than 90 minutes to complete. \n\n' ...
            'Use the forward arrow to learn more about each phase of the experiment. \n' ...
            'You will get more instructions about each phase as it comes up throughout the experiment.'];
        
        welcString{2} = ['The first phase is called "Response Learning" \n\n' ...
            'In this phase, you will learn the mapping between scene images and number buttons on the keyboard.\n\n' ...
            'You will use these image-button mappings to indicate your responses throughout the rest of the experiment, so make sure to pay attention!'];
        
        welcString{3} = ['The next phase is called "Flicker Training" \n\n' ...
            'You will complete a number of trials to give you practice on the main decision task in this experiment: deciding which of two scene images was presented more frequently (or "dominated") a trial'];
        
        welcString{4} = ['After Flicker Training, you will complete the "Border Learning" phase. \n\n' ...
            'During Border Learining, you will be presented with differently colored boxes followed by the scene images.\n\n' ...
            'Your task is to learn how frequently each box is followed by each scene image.'];
        
        welcString{5} = ['In the final phase, "Decision Making", you will complete several trials of the flicker task.\n\n' ...
            'This phase is the longest of the whole experiment. You will get a number of breaks.\n\n' ...
            'After you complete the Decision Making phase, we will ask you some debriefing and demographics questions before officially concluding the experimental session.\n\n'];
        
        welcString{6} = ['Please use your right hand to make all keyboard responses during the experiment. \n\n' ...
            'Do not hesitate to contact the experimenter at any time if you have questions about any of the instructions. \n\n' ...
            'If you do not have questions at this point, press spacebar to receive instructions for Response Training.'];
        
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
            if page < length(welcString) && keyCode(rightKey)
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
        responseTrainString = ['RESPONSE TRAINING INSTRUCTIONS: \n\n\n' ...
            'In this part of the experiment, your task is to learn the mapping between response keys (1 and 2) and different scene images. \n\n' ...
            'You will be presented with the images one-by-one, and your task is to press the button you are told corresponds to each image. \n\n' ...
            'Please use the top row of number keys to make all responses throughout this experiment. \n\n' ...
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
        
        %%%%%%% initiate response training %%%%%%%
        run_responseTraining;
        
        % pivot to flicker practice
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
        pracString{1} = ['FLICKER TRAINING INSTRUCTIONS: \n\n\n' ...
            'In this part of the experiment, you will practice the "flicker" part of the task: deciding which of the two images was presented more frequently in a rapidly alternating image stream. \n\n' ...
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
        
        %%%%%%% initiate flicker practice %%%%%%%
        run_flickerPractice; 
        
        % pivot to calibration
        calString1 = ['Now that you have experience with the flicker task, we are going to make things a bit harder. \n\n' ...
            'You will complete more trials of the flicker task, but without feedback on your choices and with greater variability in the difficulty levels of each decision.\n\n' ...
            'Your task is the same: press the button corresponding to the dominant image on each trial. Please try to do so as quickly and accurately as possible. \n\n' ...
            'If you have no questions, press spacebar when you feel ready to begin.'];
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
        
        %%%%%%% initiate button reminder %%%%%%%
        run_buttonReminder;
        
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
        
        %%%%%%% initiate calibration %%%%%%%
        run_calibration;
        coherence = calibratedCoherence;
        
        % phase pivot to learning
        learnString = 'Nice work! You''re all done with Flicker Practice. \n\n Press spacebar when to receive instructions for Border Learning.';
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
        
        % learning instructions
        pracString{1} = ['BORDER LEARNING INSTRUCTIONS: \n\n\n' ...
            'In this phase of the experiment, your task is to learn how frequently each colored border is followed by each of the scene images. \n\n' ...
            'Your task is to press the button that corresponds to the scene image presented on each trial. \n\n' ...
            'You will get feedback on the accuracy of your responses.'];
        pracString{2} = ['BORDER LEARNING INSTRUCTIONS: \n\n\n' ...
            'You might get really good at anticipating which image will appear when you see a particular border.\n\n' ...
            'If so, you can make your response before the image actually comes on screen. You still receive feedback if you respond before the image appears.\n\n' ...
            'If you don''t have questions, press spacebar when you feel ready to begin Border Learning.'];
        
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
        
        
        %%%%%%% initiate button mapping reminder %%%%%%%
        run_buttonReminder;
        
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
        
        %%%%%%% initiate cue learning %%%%%%%
        run_cueLearning;
        
        % phase pivot
        pivotString = 'Border Learning complete. \n\n You can use this time to take a short break before proceeding to the final phase of the experiment. \n\n Press spacebar to receive instructions.';
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
        
        % inference inference instructions
        infString{1} = ['DECISION MAKING INSTRUCTIONS: \n\n\n'...
            'In this phase of the experiment, you will perform the flicker task again. \n\n' ...
            'This time, the flickering stream will be presented inside of the colored borders. \n\n' ...
            'The correct answer on each trial is usually the one that was presented more frequently with the colored border during Border Learning.' ...
            'Again, your task is to determine which image dominated the flicker stream on each trial as quickly and accurately as possible.' ...
            'You might it helpful to integrate what you have learned about the border-image frequencies to help you make your decisions faster.'];
        
        infString{2} = ['DECISION MAKING INSTRUCTIONS: \n\n\n' ...
            'You will not receive feedback on your chioces. \n\n' ...
            'Instead, after each decision, we will ask you to rate how confident you are that you correclty identified the dominant image. \n\n' ...
            'Don''t overthink this -- just press the rating that feels right and do your best to use all the ratings in the scale: \n\n' ...
            '1=not confident, 2=somewhat confident, 3=rather confident, 4=very confident. This scale will appear onscreen for each confidence rating.'];
        
        infString{3} = ['This is the final and most important part of the experiment. It is crucial that you are alert and engaged when completing the task.\n\n' ...
            'You will get several breaks. During the breaks, we encourage you to rest your eyes, stretch a bit, and drink some water. \n\n' ...
            'Breaks are also a good time to ask the experimenter any questions that might arise during Decision Making.' ...
            'If you don''t have questions at this time, press spacebar to begin the Decision Making phase.'];
        page = 1;
        while page < length(infString) + 1
            DrawFormattedText(mainWindow, infString{page}, 'center', 'center', textColor, 80);
            if page < length(infString)
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
        
        %%%%%%% initiate button reminder %%%%%%%
        run_buttonReminder;
        
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
        
        %%%%%%% initiate cued inference %%%%%%%
        run_cuedInference;
        
    end % if debugging==0
end % for block in nBlocks

% goodbye screen
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

%% print out info for debrief
imagePath{3} = 'neither';
debrief_table = table(cueStrings', [repelem(memReliability*100, 2) 50]', imagePath);
debrief_table.Properties.VariableNames = {'cue', 'reliability', 'dominant_image'}

