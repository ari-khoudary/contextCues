% get evidence frames

%% load in data
files = dir('../data/s*');

for i = 1:length(files)
    if i==5
        continue
    end
    data = load(['../data/' files(i).name '/block1_inferenceVars.mat']);

    % pull out relevant variables
    response_frames = data.responseFrames;
    catch_trials = data.catch_trials;
    subID = data.subID;
    congruent = data.trialCongruence;
    flicker_all = data.flickerAll;
    responses = data.infResps;
    % durations on test trials
    noise1Frames_test = data.noise1Frames_test;
    signal1Frames_test = data.signal1Frames_test;
    noise2Frames_test = data.noise2Frames_test;
    % durations on catch trials
    noise1Frames_catch = data.noise1Frames_catch;
    signal1Frames_catch = data.signal1Frames_catch;
    noise2Frames_catch = data.noise2Frames_catch;
    % counters
    test_counter = 0;
    catch_counter = 0;

    % loop over trials
    for trial = 1:length(response_frames)
        if ismember(trial, catch_trials)
            catch_counter = catch_counter + 1;
            noise1frames_design = noise1Frames_catch(catch_counter);
            signal1frames_design = signal1Frames_catch(catch_counter);
            noise2frames_design = noise2Frames_catch(catch_counter);
        else
            test_counter = test_counter + 1;
            noise1frames_design = noise1Frames_test(test_counter);
            signal1frames_design = signal1Frames_test(test_counter);
            noise2frames_design = noise2Frames_test(test_counter);
        end

        % define changepoints --- THIS WILL CHANGE IN THE NEXT EXPT; FLICKER PATTERN WILL BE [1 0] INSTEAD OF [0 1]
        signal1Onset = noise1frames_design + 1;
        noise2Onset = noise1frames_design + signal1frames_design;
        signal2Onset = noise1frames_design + signal1frames_design + noise2frames_design + 1;

        endIdx = response_frames(trial);
        if isnan(endIdx)
            endIdx = size(flicker_all, 1);
        end

        % compute evidence amounts
        if  endIdx < signal1Onset
            if ismember(trial, catch_trials)
                signal1_target1 = sum(flicker_all(1:endIdx, trial)==1);
                signal1_target2 = sum(flicker_all(1:endIdx, trial)==2);
            else
                signal1_target1 = NaN;
                signal1_target2 = NaN;
            end
            signal2_target1 = NaN;
            signal2_target2 = NaN;
        elseif endIdx < signal2Onset
            signal1_target1 = sum(flicker_all(1:endIdx, trial)==1);
            signal1_target2 = sum(flicker_all(1:endIdx, trial)==2);
            signal2_target1 = NaN;
            signal2_target2 = NaN;
        else
            signal1_target1 = sum(flicker_all(1:noise2Onset, trial)==1);
            signal1_target2 = sum(flicker_all(1:noise2Onset, trial)==2);
            signal2_target1 = sum(flicker_all(noise2Onset:endIdx, trial)==1);
            signal2_target2 = sum(flicker_all(noise2Onset:endIdx, trial)==2);
        end

        % define durations based on when responses are made
        if endIdx < signal1Onset
            noise1frames_behav = endIdx;
            signal1frames_behav = NaN;
            noise2frames_behav = NaN;
            signal2frames_behav = NaN;
        elseif endIdx >= noise1frames_design && endIdx < noise2Onset
            noise1frames_behav = noise1frames_design;
            signal1frames_behav = endIdx - noise1frames_design;
            noise2frames_behav = NaN;
            signal2frames_behav = NaN;
        elseif endIdx >= noise2Onset && endIdx < signal2Onset
            noise1frames_behav = noise1frames_design;
            signal1frames_behav = signal1frames_design;
            noise2frames_behav = endIdx - (noise1frames_design + signal1frames_design);
            signal2frames_behav = NaN;
        else
            noise1frames_behav = noise1frames_design;
            signal1frames_behav = signal1frames_design;
            noise2frames_behav = noise2frames_design;
            signal2frames_behav = endIdx - (noise1frames_design + signal1frames_design + noise2frames_design);
        end

        if exist('df', 'var') == 0
            df = table(subID, trial, ismember(trial, catch_trials), congruent(trial), response_frames(trial), responses(trial), ...
                noise1frames_design, signal1frames_design, noise2frames_design, ...
                noise1frames_behav, signal1frames_behav, noise2frames_behav, signal2frames_behav, ...
                signal1Onset, noise2Onset, signal2Onset, ...
                signal1_target1, signal1_target2, signal2_target1, signal2_target2);
        else
            tmp = table(subID, trial, ismember(trial, catch_trials), congruent(trial), response_frames(trial), responses(trial), ...
                noise1frames_design, signal1frames_design, noise2frames_design, ...
                noise1frames_behav, signal1frames_behav, noise2frames_behav, signal2frames_behav, ...
                signal1Onset, noise2Onset, signal2Onset, ...
                signal1_target1, signal1_target2, signal2_target1, signal2_target2);
            df = [df;tmp];
        end
    end
end


df = renamevars(df, ["Var3", "Var4", "Var5", "Var6"], ["catch_trial", 'congruent', 'response_frame', 'response']);
writetable(df, '../data/tidied/evidenceFrames.csv')






