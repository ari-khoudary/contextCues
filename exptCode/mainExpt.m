% main script for running the experiment ContextCues

%=========================================================================================
% Author: Ari Khoudary (2023-2024), adapting code originally written by Mariam Aly, Aaron M. Bornstein, Sam Feng (2015)

%% initial setup
clear;
PsychJavaTrouble;
clc;

% get subject & block numbers
subID = input('Subject number: ');
debugging = input('debug?: ');
block = input('block?: ');

% use subject ID to set the random seed
rng(subID)

% make sure random seed is unique across blocks for the same participant
if block > 1
    rng(subID + randn)
end

% generate directory for subject's data
exptID ='condition_65cue';
sID = ['s', num2str(subID)];
datadir = ['..' filesep 'data' filesep exptID filesep sID];
if ~exist(datadir, 'dir')
    mkdir(datadir);
end

% define task parameters
% task structure
nBlocks = 1; % number of blocks
nCues = 3; % num prior cues per block
nImages = 2; % unique images on which decisions are to be made, per block
pCatchTrial = 0.1; % what proportion of total inference trials do you want to be ADDED ON as catch trials?

% evidence reliabilities
memReliability = 0.65;
vizAccuracy = 0.7;
% vision reliability is technically given by the evidence coherence. to
% control for differences in how the images are processed by different
% people, we use QUEST staircasing to identify coherence values for each image that result in
% vizAccuracy level of performance

% phase-specific parameters
define_taskParams;

%% setup scripts
setup_output;
setup_ptb;
setup_stimuli; % needs to be called after setup_ptb because it loads images in as textures to be displayed on mainWindow

% organize & randomize trial types
setup_trials;

% create probabilistic trial durations
setup_durations;

%% run experiment
% turn off keyboard responses in the command window
ListenChar(2);

% make arrow keys for navigating instructions
rightString = 'more instructions ->';
leftString = '<- previous instructions ';
rightPosition = screenX-350;
leftPosition = screenX - 1200;

dbstop if error

for block = 1:nBlocks

    try

            %%% present general instructions %%%%
            run_welcomeInstructions; 

            clear string
            %%%% display response training instructions %%%%
            string = ['RESPONSE TRAINING INSTRUCTIONS: \n\n\n' ...
                'Your task in this part of the experiment is to learn which keyboard button corresponds to which scene image. \n\n'...
                'Press the corresponding button when the scene image is presented. \n\n' ...
                'Press spacebar to begin.'];
            DrawFormattedText(mainWindow, string, 'center', 'center', textColor, 80);
            Screen('Flip',mainWindow);
            FlushEvents('keyDown');
            WaitSecs(3);
            while(1)
                [~,~,keyCode] = KbCheck(-1);
                if keyCode(spaceKey)
                    break;
                end
                WaitSecs(0.05);
            end
            clear string

            %%%% run response training %%%%
            FlushEvents('keyDown');
            run_responseTraining;

            %%%% pivot to "flicker practice" (calibration) & give instructions %%%%
            clear string
            string = ['Nice work! You learned the correct response mappings. \n\n' ...
                'Moving onto the next phase...'];
            DrawFormattedText(mainWindow, string, 'center', 'center', textColor, 80);
            Screen('Flip', mainWindow);
            WaitSecs(2.5);
            Screen('FillRect', mainWindow, backgroundColor);


            %%%% present calibration instructions %%%%
            clear string
            string = ['FLICKER PRACTICE INSTRUCTIONS: \n\n\n' ...
                'In this part of the experiment, you will practice the "flicker" part of the task: deciding which of the two images was presented more frequently in a rapidly alternating image stream. \n\n' ...
                'You should make this decision as quickly and accurately as you can. \n\n' ...
                'You have up to 4 seconds to make a response on each trial.\n\n\n' ...
                'Press spacebar when you are ready to begin.'];

            DrawFormattedText(mainWindow, string, 'center', 'center', textColor, 80);
            Screen('Flip',mainWindow);
            FlushEvents('keyDown');
            WaitSecs(3);
            while(1)
                [~,~,keyCode] = KbCheck(-1);
                if keyCode(spaceKey)
                    break;
                end
                WaitSecs(0.05);
            end

        %%%% run "flicker training" aka CALIBRATION %%%
        clear string
        run_calibration;
        coherence = calibratedCoherence;
        setup_flicker;

        %%%% pivot to coherenceValidation and give instructions %%%
        clear string
        string{1} = ['Now that you have experience with the flicker task, we are going to make it a bit harder by introducing more noise. \n\n' ...
            'You will perform the same task: determining which image dominated the flickering stream. \n\n'...
            'Again, you should respond as soon as you feel you have an answer -- the goal is to respond as quickly and accurately as possible.'];

        string{2} = ['For the first handful of trials, you will get feedback immediately after you make your decision.\n\n' ...
            'Eventually this feedback will replaced by a confidence judgment -- instead of us telling you whether you were right, we want to know how confident you are that you made the right decision on each trial.'];

        string{3} = ['You will rate your confidence on a scale of 1-4: \n\n' ...
            '1=not confident, 2=somewhat confident, 3=rather confident, 4=very confident. \n\n' ...
            'This rating scale will appear onscreen each time you have to make a confidence rating. Please make sure to use all the numbers on the scale. \n\n'...
            'Press spacebar when you are ready to begin.'];

        page = 1;
        while page < length(string) + 1
            DrawFormattedText(mainWindow, string{page}, 'center', 'center', textColor, 80);
            if page<max(size(string))
                DrawFormattedText(mainWindow, rightString, rightPosition, screenY-100, textColor);
            end
            if page > 1
                DrawFormattedText(mainWindow, leftString, leftPosition, screenY-100, textColor);
            end
            Screen('Flip', mainWindow);
            WaitSecs(0.05);
            [~,~,keyCode] = KbCheck(-1);
            if page < length(string) && keyCode(rightKey)
                page = page + 1;
                FlushEvents('keyDown');
                WaitSecs(0.5);
            elseif page > 1 && keyCode(leftKey)
                page = page - 1;
                FlushEvents('keyDown');
                WaitSecs(0.5);
            elseif page==max(size(string)) && keyCode(spaceKey)
                break
            end
        end
        clear string

        %%%%%%% initiate button reminder %%%%%%%
        run_buttonReminder;

        % initiate calibration validation with spacebar press
        clear string
        string = 'Press spacebar to begin the flicker task.';
        DrawFormattedText(mainWindow, string, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        FlushEvents('keyDown');
        while(1)
            temp = GetChar;
            if (temp == ' ')
                break;
            end
            WaitSecs(0.05);
        end
        clear string

        % run coherenceValidation %%%%
        run_coherenceValidation;

        %% phase pivot to learning & give instructions %%%%
        clear string
        string = 'Flicker training complete';
        DrawFormattedText(mainWindow, string, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        WaitSecs(2);
        Screen('FillRect', mainWindow, backgroundColor);


        %%%% learning instructions %%%%
        clear string
        string{1} = ['BORDER LEARNING INSTRUCTIONS: \n\n\n' ...
            'In this phase of the experiment, you will be introduced to 3 different colored borders. \n\n' ...
            'Each border makes a prediction about the probability of observing one scene image relative to the other. \n\n' ...
            'Your goal is to learn what prediction each border makes about the upcoming scene image.'];

        string{2} = ['BORDER LEARNING INSTRUCTIONS: \n\n\n' ...
            'Your task on each trial is to press the button that corresponds to the presented scene image. \n\n' ...
            'But remember: your ultimate goal is to learn how predictive each border is for each image. \n\n' ...
            'One way to do this is estimating how frequently each border is followed by each image.'];

        string{3} = ['BORDER LEARNING INSTRUCTIONS: \n\n\n' ...
            'You might get really good at anticipating which image will appear when you see a particular border.\n\n' ...
            'If so, you can make your response before the image actually comes on screen. \n\n' ...
            'Remember: your main goal is to figure out what prediction each border makes about the probability of observering one scene instead of the other.\n\n\n' ...
            'Press spacebar when you feel ready to begin.'];

        FlushEvents('keyDown');
        page = 1;
        while page < length(string) + 1
            DrawFormattedText(mainWindow, string{page}, 'center', 'center', textColor, 80);
            if page < length(string)
                DrawFormattedText(mainWindow, rightString, rightPosition, screenY-100, textColor);
            end
            if page > 1
                DrawFormattedText(mainWindow, leftString, leftPosition, screenY-100, textColor);
            end
            Screen('Flip', mainWindow);
            WaitSecs(0.05);
            [~,~,keyCode] = KbCheck(-1);
            if page < length(string) && keyCode(rightKey)
                page = page + 1;
                FlushEvents('keyDown');
                WaitSecs(0.5);
            elseif page > 1 && keyCode(leftKey)
                page = page - 1;
                FlushEvents('keyDown');
                WaitSecs(0.5);
            elseif page==max(size(string)) && keyCode(spaceKey)
                break
            end
        end
        clear string

        %%%% run cue learning %%%
        run_cueLearning;
        
        clear string
        string{1} = ['Almost done with Border Learning! \n\n\n' ...
            'Before you begin the last part of this experiment, we would like to know what you learned about each border.'];

        string{2} = ['You will be presented with each border and a slider with each scene image at the endpoints. \n\n' ...
            'The image corresponding to the 1 key is at the left endpoint and the image corresponding to the 2 key is at the right endpoint. \n\n' ...
            'Use the left and right arrow keys to indicate what prediction each border makes about the probability of observing one scene image vs. another. \n\n' ...
            'For example, if one of the cues always predicts seeing scene image 1, you would move the slider all the way to the left endpoint. \n\n'];

        string{3} = ['Once you are satisfied with your answer, press C to lock it in. \n\n' ...
            'You must move the slider at least once in order for the experiment to lock in your response. \n\n' ...
            'After you make each estimate, we will ask you to rate how confident you are that you correctly estimated the predictiveness of that border. \n\n' ...
            'This portion is self-timed. Make sure to ask the experimenter if you have any questions. \n\n' ...
            'Press spacebar when you are ready to begin.'];

        FlushEvents('keyDown');
        page = 1;
        while page < length(string) + 1
            DrawFormattedText(mainWindow, string{page}, 'center', 'center', textColor, 80);
            if page >= 1 && page < length(string)
                DrawFormattedText(mainWindow, rightString, rightPosition, screenY-100, textColor);
            end
            if page > 1
                DrawFormattedText(mainWindow, leftString, leftPosition, screenY-100, textColor);
            end
            Screen('Flip', mainWindow);
            WaitSecs(0.05);
            [~,~,keyCode] = KbCheck(-1);
            if page < 3 && keyCode(rightKey)
                page = page + 1;
                FlushEvents('keyDown');
                WaitSecs(0.5);
            elseif page > 1 && keyCode(leftKey)
                page = page - 1;
                FlushEvents('keyDown');
                WaitSecs(0.5);
            elseif page==max(size(string)) && keyCode(spaceKey)
                break
            end
        end
        clear string

        % run learning validation %%%%
        FlushEvents('keyDown');
        run_learningValidation;

        %% phase pivot and display inference instructions %%%%
        clear string
        string = ['All done with Border Learning! \n\n'...
            'Use this time to take a short break before reading the instructions for Decision Making.'];
        DrawFormattedText(mainWindow, string, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        WaitSecs(2);
        Screen('FillRect', mainWindow, backgroundColor);

        %  inference instructions
        clear string
        string{1} = ['DECISION MAKING INSTRUCTIONS: \n\n\n'...
            'In this phase of the experiment, you will perform the flicker task again: determining which of the images dominated the flicker stream. \n\n' ...
            'Again, your task is to determine which image dominates the flicker stream as quickly and accurately as you can. \n\n' ...
            'This time, you will have some help from the colored borders.'];

        string{2} = ['DECISION MAKING INSTRUCTIONS: \n\n\n'...
            'On each trial, the flickering stream will be presented inside of the colored borders.\n\n' ...
            'The borders make the same predictions about which image is likely to dominate as they did about which image you would perceive during learning. \n\n'];

        string{3} = ['DECISION MAKING INSTRUCTIONS: \n\n\n' ...
            'After you make your decision, we will ask you to rate how confident you are that you made the correct answer using the same scale as before. \n\n' ...
            'Please make sure to use the whole range of confidence ratings when responding.'];

        string{4} = ['DECISION MAKING INSTRUCTIONS: \n\n\n' ...
            'This is the final and most important part of the experiment. It is crucial that you are alert and engaged when completing the task.\n\n' ...
            'You will get several breaks. During the breaks, we encourage you to rest your eyes, stretch a bit, and drink some water. \n\n' ...
            'Remember: your goal is to respond as quickly and accurately as you can. \n\n\n' ...
            'If you don''t have questions at this time, press spacebar to begin the Decision Making phase.'];
        FlushEvents('keyDown');
        page = 1;
        while page < length(string) + 1
            DrawFormattedText(mainWindow, string{page}, 'center', 'center', textColor, 80);
            if page < length(string)
                DrawFormattedText(mainWindow, rightString, rightPosition, screenY-100, textColor);
            end
            if page > 1
                DrawFormattedText(mainWindow, leftString, leftPosition, screenY-100, textColor);
            end
            Screen('Flip', mainWindow);
            WaitSecs(0.05);

            [~,~,keyCode] = KbCheck(-1);
            if page < length(string) && keyCode(rightKey)
                page = page + 1;
                FlushEvents('keyDown');
                WaitSecs(0.5);
            elseif page > 1 && keyCode(leftKey)
                page = page - 1;
                FlushEvents('keyDown');
                WaitSecs(0.5);
            elseif page== length(string) && keyCode(spaceKey)
                break
            end
        end
        clear string

        %  initiate button reminder %%%%%%%
        run_buttonReminder;

        % initiate cued inference with spacebar press
        clear string
        string = 'Press spacebar to begin the task.';
        DrawFormattedText(mainWindow, string, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        while(1)
            [~,~,keyCode] = KbCheck(-1);
            if keyCode(spaceKey)
                break;
            end
            WaitSecs(0.05);
        end

        %%%% run cued inference %%%%
        clear string
        run_cuedInference;

        % what to do if this script bugs out at any point -
    catch
        % save response training CSV
        if exist('data_responseTraining', 'var')
            writetable(data_responseTraining, [datadir filesep 'block', num2str(block), '_responseTrainingTable.csv']);
        end

        % save calibration CSV
        if exist('data_calibration', 'var')
            writetable(data_calibration, [datadir filesep 'block', num2str(block), '_calibrationTable.csv']);
        end

        % save calibration validation CSV
        if exist('data_coherenceValiation',  'var')
            writetable(data_coherenceValidation, [datadir filesep 'block', num2str(block), '_coherenceValidationTable.csv']);
        end

        % save learning CSV
        if exist('data_learning', 'var')
            writetable(data_learning, [datadir filesep 'block', num2str(block), '_learningTable.csv']);
        end

        % save learning validation CSV
        if exist('data_learningValidation', 'var')
            writetable(data_learningValidation, [datadir filesep 'block', num2str(block), '_learningValidationTable.csv']);
        end

        % save inference CSV
        if exist('data_inference', 'var')
            writetable(data_inference, [datadir filesep 'block', num2str(block), '_inferenceTable.csv']);
        end

        % save trial-by-trial inference evidence
        if exist('inferenceEvidence', 'var')
            save('inferenceEvidence.mat', "inferenceEvidence");
        else
            continue;
        end

        % save the whole matlab workspace
        save([datadir filesep 'block' num2str(block) 'workspace.mat']);

        % turn ListenChar ba23ck on
        ListenChar(1);

    end % try             b                                                                                                                         
                                                                                                                                                                                                                                                                                                                                          
end % for block = 1:nBlocks..

ListenChar(1);