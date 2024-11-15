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
    sID = ['s', num2str(subID)];
    datadir = ['..' filesep 'data' filesep sID];
    if ~exist(datadir, 'dir')
        mkdir(datadir);
    end
    
    % define task parameters
    define_taskParams;
    
    % setup psychtoolbox
    setup_ptb;
    
    % load in & setup stimuli
    setup_stimuli;

    % setup outfiles
    setup_output;
    
    % organize & randomize trial types
    setup_trials;
    
    % create probabilistic trial durations
    setup_durations;
    
    %% run experiment
    
    for block = 1:nBlocks
    
        try 
    
        % turn off keyboard responses in the command window
        ListenChar(2);
    
        % make arrow keys for navigating instructions
        rightString = 'more instructions ->';
        leftString = '<- previous instructions ';
        rightPosition = screenX-350;
        leftPosition = screenX - 1200;
    
        if debugging==0
            %%% present general instructions %%%%
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
                'During Border Learining, you will be presented with differently colored borders followed by the scene images.\n\n' ...
                'Your task is to learn how reliably each colored border predicts each scene image.'];
    
            welcString{5} = ['In the final phase, "Decision Making", you will complete several trials of the flicker task.\n\n' ...
                'This phase is the longest of the whole experiment. You will get a number of breaks.\n\n' ...
                'After you complete the Decision Making phase, we will ask you some debriefing and demographics questions before officially concluding the experimental session.\n\n'];
    
            welcString{6} = ['Please use your right hand to make all keyboard responses during the experiment. \n\n' ...
                'Do not hesitate to contact the experimenter at any time if you have questions about any of the instructions. \n\n' ...
                'If you do not have questions at this point, press spacebar to receive instructions for Response Training.'];
    
            % collect responses 
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
                [~,~,keyCode] = KbCheck(-1);
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
    
            %%%% display response training instructions %%%%
            responseTrainString = ['RESPONSE TRAINING INSTRUCTIONS: \n\n\n' ...
                'Your task in this part of the experiment is to learn which keyboard button corresponds to which scene image. \n'...
                'After being shown each image and its corresponding number key, continue to make the keypresses that correspond to ' ...
                'the images until presented with new instructions.'];
            DrawFormattedText(mainWindow, responseTrainString, 'center', 'center', textColor, 80);
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
    
            %%%% run response training %%%%
            run_responseTraining;
    
            %%%% pivot to "flicker practice" (calibration) & give instructions %%%%
            pivotString = ['Nice work! You learned the correct response mappings. \n\n' ...
                'Press spacebar to proceed to the next part of the experiment'];
            DrawFormattedText(mainWindow, pivotString, 'center', 'center', textColor, 80);
            Screen('Flip', mainWindow);
            FlushEvents('keyDown');
            while(1)
                [~,~,keyCode] = KbCheck(-1);
                if keyCode(spaceKey)
                    break;
                end
                WaitSecs(0.05);
            end
    
            %%%% present calibration instructions %%%%
            pracString{1} = ['FLICKER TRAINING INSTRUCTIONS: \n\n\n' ...
                'In this part of the experiment, you will practice the "flicker" part of the task: deciding which of the two images was presented more frequently in a rapidly alternating image stream. \n\n' ...
                'Do your best to respond as quickly and accurately as possible. You will get feedback about your respeonses on each trial. \n'];
    
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
                [~,~,keyCode] = KbCheck(-1);
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
       % end % if debugging==0
    
        %%%% run "flicker training" aka CALIBRATION %%%
        run_calibration;
        coherence = calibratedCoherence;
        setup_flicker;
    
        %%%% pivot to coherenceValidation and give instructions %%%
        calString1 = ['Now that you have experience with the flicker task, we are going to make it a bit harder by introducing more noise. \n\n' ...
            'You will perform the same task: determining which image dominated the flickering stream. \n\n'...
            'After a few trials with the feedback, we will ask you instead to rate your confidence that you made the correct decision on each trial. \n\n' ...
            'You can rate your confidence on a scale of 1-4: \n\n' ...
            '1=not confident, 2=somewhat confident, 3=rather confident, 4=very confident. \n\n' ...
            'This rating scale will appear onscreen each time you have to make a confidence rating. Please make sure to use all the numbers on the scale. \n\n'...
            'Press spacebar to continue.'];
        DrawFormattedText(mainWindow, calString1, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        FlushEvents('keyDown');
    
        while(1)
            [~, ~, keyCode] = KbCheck(-1);
            if keyCode(spaceKey)
                break
            end
            WaitSecs(0.05);
        end
    
        %%%%%%% initiate button reminder %%%%%%%
        run_buttonReminder;
    
        % initiate calibration validation with spacebar press
        instructString = 'Press spacebar to begin the flicker task.';
        DrawFormattedText(mainWindow, instructString, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        while(1)
            temp = GetChar;
            if (temp == ' ')
                break;
            end
            WaitSecs(0.05);
        end
    
        %%%% run coherenceValidation %%%%
        run_coherenceValidation;
    
        %%%% phase pivot to learning & give instructions %%%%
        learnString = 'Nice work! For the next phase of the experiment, you will get a break from doing the flicker task. \n\n Press spacebar when to receive instructions for Border Learning.';
        DrawFormattedText(mainWindow, learnString, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        FlushEvents('keyDown');
        while(1)
            temp = GetChar;
            if (temp == ' ')
                break;
            end
            WaitSecs(0.05);
        end
    
        % learning instructions
        pracString{1} = ['BORDER LEARNING INSTRUCTIONS: \n\n\n' ...
            'In this phase of the experiment, your main task is to learn the predictive relationship between colored borders and the 2 scene images. \n\n' ...
            'Each border carries an independent probability of observing each scene image. \n' ...
            'This means that each border independently predicts the likelihood of observing one of the two scene images.\n\n' ...
            'To learn these probabilities, you will observe a series of border-image pairings. \n' ...
            'On each trial, your task is to press the button corresponding to the image that appears on screen.\n\n' ...
            'You will get feedback on the accuracy of your responses.'];
        pracString{2} = ['BORDER LEARNING INSTRUCTIONS: \n\n\n' ...
            'You might get really good at anticipating which image will appear when you see a particular border.\n\n' ...
            'If so, you can make your response before the image actually comes on screen. You still receive feedback if you respond before the image appears.\n\n' ...
            'Remember: your task is to learn how reliably each colored border predicts each scene image. \n\n' ...
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
            [~,~,keyCode] = KbCheck(-1);
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
            WaitSecs(0.05);
        end
    
        %%%% run cue learning %%%
        run_cueLearning;
        end % if debugging
    
        %%%% phase pivot and display learning validation instructions
        pivotString = ['We would now like to know what you learned about the predictiveness of each border. \n\n' ...
            'You will be presented with each border and asked to use a slider to indicate how predictive that border is for the image pair. \n' ...
            'Use the arrow keys to move the slider around and press spacebar when you are satisfied with your answer. \n\n' ...
            'After locking in your answer, you will be asked to rate how confident you are in your estimate. \n\n' ...
            'This portion is self-timed. Make sure to ask the experimenter if anything is unclear.\n\n' ...
            'Press space when you are ready to proceed.'];
        DrawFormattedText(mainWindow, pivotString, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        FlushEvents('keyDown');
       while(1)
            [~,~,keyCode] = KbCheck(-1);
            if keyCode(spaceKey)
                break;
            end
            WaitSecs(0.05);
       end

       FlushEvents('keyDown');
    
        %%%% run learning validation %%%%
        run_learningValidation;
    
        %%% phase pivot and display inference instructions %%%%
        pivotString = ['All done with learning! \n\n'...
            'You can use this time to take a short break before proceeding to the final phase of the experiment. \n\n' ...
            'Press spacebar to receive instructions.'];
        DrawFormattedText(mainWindow, pivotString, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
       while(1)
            [~,~,keyCode] = KbCheck(-1);
            if keyCode(spaceKey)
                break;
            end
            WaitSecs(0.05);
       end
    
        %%%% inference instructions
        infString{1} = ['DECISION MAKING INSTRUCTIONS: \n\n\n'...
            'In this phase of the experiment, you will perform the flicker task again: determining which of the images dominated the flicker stream. \n\n' ...
            'The flickering stream will be presented inside of the colored borders, and the correct answer on each trial is *usually* the one that more frequently followed that color border during Border Learning. \n\n' ...
            'Again, your task is to determine which image dominated the flicker stream as quickly and accurately as possible.' ...
            'You might it helpful to integrate what you have learned about the border-image frequencies to help you make your decisions faster.'];
    
        infString{2} = ['DECISION MAKING INSTRUCTIONS: \n\n\n' ...
            'You will not receive feedback on your chioces. \n\n' ...
            'Instead, after each decision, we will ask you to rate how confident you are that you correclty identified the dominant image. \n\n' ...
            'Don''t overthink this. Just press the rating that feels right. \n\n...' ...
            'This rating scale will appear onscreen each time you have to make a confidene rating: \n\n' ...
            '1=not confident, 2=somewhat confident, 3=rather confident, 4=very confident. \n\n ...' ...
            'Please make sure to use all of the responses on the scale when rating confidence in this part of the experiment.'];
    
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
    
            [~,~,keyCode] = KbCheck(-1);
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
        %end
    
        %%%%%%% initiate button reminder %%%%%%%
        run_buttonReminder;
    
        % initiate cued inference with spacebar press
        instructString = 'Press spacebar to begin the task.';
        DrawFormattedText(mainWindow, instructString, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        while(1)
            [~,~,keyCode] = KbCheck(-1);
            if keyCode(spaceKey)
                break;
            end
            WaitSecs(0.05);
        end
    
        %%%% run cued inference %%%%
        run_cuedInference;
    
        % display goodbye screen
        goodbyeString = 'Experiment complete! Thanks for your participation. \n\n Please get the experimenter.';
        DrawFormattedText(mainWindow, goodbyeString, 'center', 'center', textColor, 80);
        Screen('Flip', mainWindow);
        while(1)
            temp = GetChar;
            if (temp == ' ')
                break
            end
            WaitSecs(0.05);
        end
        sca;
    
        catch
            ListenChar(1);
        end
    
    end % for block in nBlocks
   

