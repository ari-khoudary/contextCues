% set up trial structures for learning & inference

%% make matrix of transition probabilities for each cue
cueLevels = [memReliability 1-memReliability; ... % cue in favor of imgIdx1
    1-memReliability memReliability; ... % cue in favor of imgIdx 2
    0.5 0.5];

%% choose colored borders 
% randomly choose a different set of border colors for each block
if block == 1
    border_set = randi([1,2]);
else
    border_set = 3 - border_set;
end
cueColors = border_array{border_set};
cueStrings = border_array_string{border_set};
% randomize which colors are assigned to which probabilities
cueOrder = Shuffle(1:nCues);
cueColors = cueColors(cueOrder, :);
cueStrings = cueStrings(cueOrder);

%% organize learning trials
learnTrials = round(cueLevels*learnTrialN / nCues);
% make array of cue indices for learning
learnCue = [repelem(1, learnTrialN/nCues) repelem(2, learnTrialN/nCues) repelem(3, learnTrialN/nCues)];
% populate image array in proportion to cue reliability; each row corresponds to cue index
learnImg = NaN(nCues, sum(learnTrials(1,:)));

for cueIdx=1:nCues
    if cueIdx == 3
        if rand <0.5
            learnImg(cueIdx, :) = [ones(1, learnTrials(cueIdx,1)-1) repelem(2, learnTrials(cueIdx,2))];
        else
            learnImg(cueIdx, :) = [ones(1, learnTrials(cueIdx,1)) repelem(2, learnTrials(cueIdx,2)-1)];
        end
    else
        learnImg(cueIdx, :) = [ones(1, learnTrials(cueIdx,1)) repelem(2, learnTrials(cueIdx,2))];
    end
end

% randomize order of cue presentation & targets following each cue
learnCue = Shuffle(learnCue);
learnImg = Shuffle(learnImg, 1);

%% organize inference trials
% number of trials of each target for each cue 
inferenceTrials = round(cueLevels*inferenceTrialN / nCues);
% get rid of half the neutral trials
inferenceTrials(3, :) = round(inferenceTrials(3,:)/2);
% vector of trials when subject will be prompted to take a break
break_trials = round(linspace(1, inferenceTrialN, nInferenceBreaks+2));
break_trials = break_trials(2:(length(break_trials)-1));
% number of catch trials to be added onto inferenceTrialN
nCatchTrial = inferenceTrialN * pCatchTrial;
% how many catch trials per cue
catch_per_cue = round(nCatchTrial / nCues);
% analogous matrix to inferenceTrials
catchTargets = round(cueLevels*catch_per_cue);
allTargets = inferenceTrials + catchTargets;

% make array of cue indices for inference
inferenceCue = [repelem(1, sum(allTargets(1,:))) repelem(2, sum(allTargets(2,:))) repelem(3, sum(allTargets(3,:)))]; %cut number of neutral trials in half to save time

% total number of trials in inference (including catch trials)
inferenceTrialN_total = length(inferenceCue);

% set up targets for each trial
inferenceImg = NaN(nCues, sum(allTargets(1,:)));

% populate image array in proportion to cue reliability; each row corresponds to cue index
for cueIdx=1:nCues
    if cueIdx==3
        foo = sum(allTargets(cueIdx, :));
        inferenceImg(cueIdx, :) = [repelem(1, allTargets(cueIdx, 1)) repelem(2, allTargets(cueIdx,2)) zeros([1 (length(inferenceImg)-foo)])];
    else
    inferenceImg(cueIdx, :) = [repelem(1, allTargets(cueIdx,1)) repelem(2, allTargets(cueIdx,2))];
    end
end

% randomize order of trials
inferenceImg(1:2, :) = Shuffle(inferenceImg(1:2,:), 1);
inferenceImg(3, 1:allTargets(6)) = Shuffle(inferenceImg(3, 1:allTargets(6)));
inferenceCue = Shuffle(inferenceCue);

% select trials to be catch trials
catch_test = randperm(2*length(inferenceImg), 2*catch_per_cue);
catch_neutral = randperm(nnz(inferenceImg(3,:)), catch_per_cue);
