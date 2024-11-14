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
learnCue = [repelem(1, learnTrialPerCue) repelem(2, learnTrialPerCue) repelem(3, learnTrialPerCue)];
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
learnImg = learnImg(:, randperm(size(learnImg,2)));

%% organize inference trials

% compute how many trials in each condition
inferenceTrials = round(cueLevels*inferenceTrialN / nCues);
% get rid of half the neutral trials
inferenceTrials(3,:) = round(inferenceTrials(3,:)/2);

% compute how many catch trials
nCatchTrial = pCatchTrial * inferenceTrialN;
catch_per_cue = nCatchTrial / nCues;
% catch trials per condition
catchTrials = round(cueLevels * catch_per_cue);
% match the proportion of neutral non-catch trials 
if catch_per_cue > 2
    catchTrials(3,:) = round(catchTrials(3,:) / 2);
else
    catchTrials(3,:) = Shuffle([0 1]);
end
nCatchTrial = sum(sum(catchTrials));

% total amount of trials per cue
totalTrials = catchTrials + inferenceTrials;
inferenceTrialN_total = sum(sum(totalTrials));

% create cue arrays
inferenceCue = [repelem(1, sum(inferenceTrials(1,:))) repelem(2, sum(inferenceTrials(2,:))) repelem(3, sum(inferenceTrials(3,:)))]; 
catchCue = [repelem(1, sum(catchTrials(1,:))) repelem(2, sum(catchTrials(2,:))) repelem(3, sum(catchTrials(3,:)))];

% populate image array in proportion to cue reliability; each row corresponds to cue index
inferenceImg = NaN(nCues, sum(inferenceTrials(1,:)));
catchImg = NaN(nCues, sum(catchTrials(1,:)));

for cueIdx=1:nCues
    if cueIdx==3
        inferenceImg(cueIdx, :) = [repelem(1, inferenceTrials(cueIdx,1)) repelem(2, inferenceTrials(cueIdx,2)) zeros([1 (length(inferenceImg)-sum(inferenceTrials(cueIdx,:)))])];
        if catch_per_cue==1
            catchImg(cueIdx, :) = randi([1 2]);
        elseif catch_per_cue==2
            catchImg(cueIdx, :) = [1 2];
        else
            catchImg(cueIdx, :) = [repelem(1, catchTrials(cueIdx,1)) repelem(2, catchTrials(cueIdx,2)) zeros([1 (length(catchImg)-sum(catchTrials(cueIdx,:)))])];
        end
    else
        inferenceImg(cueIdx, :) = [repelem(1, inferenceTrials(cueIdx,1)) repelem(2, inferenceTrials(cueIdx,2))];
        catchImg(cueIdx, :) = [repelem(1, catchTrials(cueIdx,1)) repelem(2, catchTrials(cueIdx,2))];
    end
end

% randomize order
inferenceImg(1:2, :) = inferenceImg(1:2, randperm(size(inferenceImg, 2))); % non-neutral cues
inferenceImg(3, 1:nnz(inferenceImg(3,:))) = inferenceImg(3, randperm(nnz(inferenceImg(3,:))));
inferenceCue = Shuffle(inferenceCue);

% randomly determine which trials will be catch
catch_trials = sort(randperm(inferenceTrialN_total, sum(sum(catchTrials))));
% randomize order of catch trials
catch_rIdx = randperm(nnz(catchImg));
% randomize cues & targets by the same order
catchCue = catchCue(catch_rIdx);
foo = catchImg';
catchImg = foo(catch_rIdx);

%% set up break trials

break_trials = round(linspace(1, inferenceTrialN, nInferenceBreaks+2));
break_trials = break_trials(2:(length(break_trials)-1));
