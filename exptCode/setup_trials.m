%% set up trial structures for learning & inference

%%% make matrix of transition probabilities for each cue
cueLevels = [memReliability 1-memReliability; ... % cue in favor of imgIdx1
    1-memReliability memReliability; ... % cue in favor of imgIdx 2
    0.5 0.5];

%%% choose colored borders 
% randomly choose a different set of border colors for each block
if block == 1
    border_set = randi([1,2]);
else
    border_set = 3 - border_set;
end
% randomize which colors are assigned to which probabilities
cueColors = Shuffle(border_array{border_set}, 2);

%%% organize learning trials
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

%%% organize inference trials
inferenceTrials = round(cueLevels*inferenceTrialN / nCues);
% make array of cue indices for inference
inferenceCue = [repelem(1, inferenceTrialN/nCues) repelem(2, inferenceTrialN/nCues) repelem(3, (inferenceTrialN/nCues)/2)]; %cut number of neutral trials in half to save time
% populate image array in proportion to cue reliability; each row corresponds to cue index
inferenceImg = NaN(nCues, sum(inferenceTrials(1,:)));

for cueIdx=1:nCues
    if cueIdx==3 % get rid of half the neutral trials
        if rand < 0.5
            inferenceImg(cueIdx, :) = [repelem(1, ceil(inferenceTrials(cueIdx,1)/2)) repelem(2, floor(inferenceTrials(cueIdx,2)/2)) zeros([1 inferenceTrials(cueIdx)])];
        else
            inferenceImg(cueIdx, :) = [repelem(1, floor(inferenceTrials(cueIdx,1)/2)) repelem(2, ceil(inferenceTrials(cueIdx,2)/2)) zeros([1 inferenceTrials(cueIdx)])];
        end
    else
        inferenceImg(cueIdx, :) = [repelem(1, inferenceTrials(cueIdx,1)) repelem(2, inferenceTrials(cueIdx,2))];
    end
end

% randomize order
inferenceImg(1:2, :) = Shuffle(inferenceImg(1:2,:), 1);
inferenceImg(3, 1:inferenceTrials(6)) = Shuffle(inferenceImg(3, 1:inferenceTrials(6)));
inferenceCue = Shuffle(inferenceCue);