%% load in .mat files
if ~exist('outDir', 'var')
    dataDir = 'contextCues_steadyState';
else
    dataDir = outDir;
end
files = (dir([pwd filesep dataDir filesep '*.mat']));
allData = load([dataDir filesep files(1).name]).data;
allData = repmat(allData, length(files), 1);
for i=2:length(files)
    allData(i) = load([dataDir filesep files(i).name]).data;
end

%% compute vizEv during signal1 and signal2

for i = 1:length(allData)
        % extract evidence dynamics
        noise1Frames = allData(i).noise1Frames;
        noise2Frames = allData(i).noise2Frames;
        noise2Onset = allData(i).noise2Onsets;
        signal1Onset = allData(i).signal1Onsets;
        signal2Onset = allData(i).signal2Onsets;

        % compute evidence values during signal1 and signal2
        allData(i).signal1_vizEv = sum(allData(i).visionEvidence(1:noise2Onset, :));
        allData(i).signal2_vizEv = sum(allData(i).visionEvidence(signal2Onset:end, :));

        % store trial target 
        congruent = allData(i).congruent;
        allData(i).trialTarget = 2 - congruent;
end

%% make long structure (each trial is one row) -- this should be a function
longData = repmat(struct('cue', [], 'coherence', [], 'congruent', [], 'threshold', [], 'memoryThinning', [], ...
    'noise1Frames', [], 'signal1Onsets', [], 'signal1Frames', [], 'noise2Onsets', [], 'noise2Frames', [], 'signal2Onsets', [], 'signal2Frames', [], ...
    'signal1_vizEv', [], 'signal2_vizEv', [], ...
    'rawChoice', [], 'forcedChoice', [], 'RT', [], 'startPoint1', [], 'startPoint2', [], ...
    'subID', [], 'nTrial', [], 'nFrames', []), sum([allData.nTrial]), 1);
trialCounter = [0 cumsum([allData.nTrial])];

for i=1:length(allData)
    sid = repmat(num2cell(allData(i).subID), allData(i).nTrial, 1); 
    [longData(trialCounter(i)+1:trialCounter(i+1)).subID] = sid{:};

    trials = repmat(num2cell(allData(i).nTrial), allData(i).nTrial, 1);
    [longData(trialCounter(i)+1:trialCounter(i+1)).nTrial] = trials{:};

    cues = repmat(num2cell(allData(i).cue), allData(i).nTrial, 1);
    [longData(trialCounter(i)+1:trialCounter(i+1)).cue] = cues{:};

    cohs = repmat(num2cell(allData(i).coherence), allData(i).nTrial, 1);
    [longData(trialCounter(i)+1:trialCounter(i+1)).coherence] = cohs{:};

    threshs = repmat(num2cell(allData(i).threshold), allData(i).nTrial, 1);
    [longData(trialCounter(i)+1:trialCounter(i+1)).threshold] = threshs{:};

    thins = repmat(num2cell(allData(i).memoryThinning), allData(i).nTrial, 1);
    [longData(trialCounter(i)+1:trialCounter(i+1)).memoryThinning] = thins{:};

    frames = repmat(num2cell(allData(i).nFrames), allData(i).nTrial, 1);
    [longData(trialCounter(i)+1:trialCounter(i+1)).nFrames] = frames{:};

    cong = num2cell(allData(i).congruent);
    [longData(trialCounter(i)+1:trialCounter(i+1)).congruent] = cong{:};

    noise1 = num2cell(allData(i).noise1Frames);
    [longData(trialCounter(i)+1:trialCounter(i+1)).noise1Frames] = noise1{:};

    sig1o = num2cell(allData(i).signal1Onsets);
    [longData(trialCounter(i)+1:trialCounter(i+1)).signal1Onsets] = sig1o{:};

    sig1 = num2cell(allData(i).signal1Frames);
    [longData(trialCounter(i)+1:trialCounter(i+1)).signal1Frames] = sig1{:};

    noise2o = num2cell(allData(i).noise2Onsets);
    [longData(trialCounter(i)+1:trialCounter(i+1)).noise2Onsets] = noise2o{:};

    noise2 = num2cell(allData(i).noise2Frames);
    [longData(trialCounter(i)+1:trialCounter(i+1)).noise2Frames] = noise2{:};

    sig2o = num2cell(allData(i).signal2Onsets);
    [longData(trialCounter(i)+1:trialCounter(i+1)).signal2Onsets] = sig2o{:};

    sig2 = num2cell(allData(i).signal2Frames);
    [longData(trialCounter(i)+1:trialCounter(i+1)).signal2Frames] = sig2{:};

    s1_vizE = num2cell(allData(i).signal1_vizEv);
    [longData(trialCounter(i)+1:trialCounter(i+1)).signal1_vizEv] = s1_vizE{:};

    s2_vizE = num2cell(allData(i).signal2_vizEv);
    [longData(trialCounter(i)+1:trialCounter(i+1)).signal2_vizEv] = s2_vizE{:};

    rawC = num2cell(allData(i).choices(:,1));
    [longData(trialCounter(i)+1:trialCounter(i+1)).rawChoice] = rawC{:};

    forcedC = num2cell(allData(i).choices(:,2));
    [longData(trialCounter(i)+1:trialCounter(i+1)).forcedChoice] = forcedC{:};

    rt = num2cell(allData(i).RT);
    [longData(trialCounter(i)+1:trialCounter(i+1)).RT] = rt{:};

    sp1 = num2cell(allData(i).startPoints(:,1));
    [longData(trialCounter(i)+1:trialCounter(i+1)).startPoint1] = sp1{:}; % DV at start of trial

    sp2 = num2cell(allData(i).startPoints(:,2));
    [longData(trialCounter(i)+1:trialCounter(i+1)).startPoint2] = sp2{:}; % DV at onset of second signal period

    target = num2cell(allData(i).trialTarget);
    [longData(trialCounter(i) + 1:trialCounter(i+1)).trialTarget] = target{:};

end

clear sid trials cues cohs threshs thins frames cong noise1 sig1o sig1 noise2o noise2 sig2o sig2 s1_vizE s2_vizE rawC forcedC rt sp1 sp2 target trialCounter

%% convert to table & write to CSV
dataTable = struct2table(longData);

writetable(dataTable, '../contextCues/analysis/tidied_data/steadyState_modelBehavior.csv')