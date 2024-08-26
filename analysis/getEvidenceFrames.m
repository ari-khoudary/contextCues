% get evidence frames

%% load in data
files = dir('../data/s*');

for i = 1:length(files)
    if i==5
        continue
    end
    data = load([files(i).name '/block1_inferenceVars.mat']);

    % define onsets
    % signal1Onsets= data.noise1Frames + 1;
    % noise2Onsets = signal1Onsets + data.signal1Frames;
    % signal2Onsets = data.noise1Frames + data.signal1Frames + data.noise2Frames + 1;
    % pull out relevant variables
    response_frames = data.responseFrames;
    catch_trials = data.catch_trials;
    subID = data.subID;
    congruent = data.trialCongruence;
    flicker_all = data.flickerAll;
    target1 = sum(flicker_all==1, 1);
    target2 = sum(flicker_all==2, 1);
    targets = double(target1 > target2);
    targets(targets==0) = 2;
    responses = data.infResps;


    %  loop over trials
    for trial = 1:length(response_frames)
        signal1Onset = find(flicker_all(:, trial), 1);
        noise2Idx = signal1Onset + strfind(flicker_all(signal1Onset:end, trial)', [0 0]);
        noise2Onset = noise2Idx(1);
        signal2Onset = max(noise2Idx) + 1;
        if ismember(trial, catch_trials) || response_frames(trial) < signal1Onset
            signal1_target1 = NaN;
            signal1_target2 = NaN;
            signal2_target1 = NaN;
            signal2_target2 = NaN;
        elseif response_frames(trial) < signal2Onset
            signal1_target1 = sum(flicker_all(signal1Onset:noise2Onset, trial)==1);
            signal1_target2 = sum(flicker_all(signal1Onset:noise2Onset, trial)==2);
            signal2_target1 = NaN;
            signal2_target2 = NaN;
        else
            signal1_target1 = sum(flicker_all(signal1Onset:noise2Onset, trial)==1);
            signal1_target2 = sum(flicker_all(signal1Onset:noise2Onset, trial)==2);
            signal2_target1 = sum(flicker_all(signal2Onset:end, trial)==1);
            signal2_target2 = sum(flicker_all(signal2Onset:end, trial)==2);
        end

        if i == 1 && trial == 1
            df = table(subID, trial, ismember(trial, catch_trials), congruent(trial), response_frames(trial), targets(trial), responses(trial), ...
                signal1_target1, signal1_target2, signal2_target1, signal2_target2);
        else
            tmp = table(subID, trial, ismember(trial, catch_trials), congruent(trial), response_frames(trial), targets(trial), responses(trial), ...
                signal1_target1, signal1_target2, signal2_target1, signal2_target2);
            df = [df;tmp];
        end
    end
end


df = renamevars(df, ["Var3", "Var4", "Var5", "Var6", "Var7"], ["catch_trial", 'congruent', 'response_frame', 'target', 'response']);
writetable(df, '../data/tidied/evidenceFrames.csv')






