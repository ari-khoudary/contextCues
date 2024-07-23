% debugging cue learning

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
    presentedCue = cell(learnTrialN, 1);
    presentedTarget = zeros(learnTrialN, 1);

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

        % reset temporary variables
        response = NaN;
        accuracy = NaN;
        learnRT = NaN;

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

        presentedCue(trial) = cueStrings(cueIdx);
        presentedTarget(trial) = imgIdx;


    end % trial loop

    learn_data = table(presentedCue, presentedTarget, learnCong);

    % save workspace vars
    if needToLearn==0
        save([datadir filesep 'block' num2str(block) '_learningVars_final.mat']);
    else
        save([datadir filesep 'block' num2str(block) '_learningVars_firstRound.mat']);
    end

    needToLearn=0;
end % while needToLearn

