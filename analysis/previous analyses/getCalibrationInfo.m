% retrieve info about which staircase generated coherence

%% load in data
files = dir('../data/s*');

for i=1:length(files)
    data = load(['../data/' files(i).name '/block1_inferenceVars.mat']);

    % get coherence values for each stimulus
    for stimIdx = 1:2
        validq1 = data.q1{stimIdx}.intensity(data.q1{stimIdx}.intensity~=0)';
        validq2 = data.q2{stimIdx}.intensity(data.q2{stimIdx}.intensity~=0)';
        sizeDiff = length(validq1) - length(validq2);

        if sizeDiff > 0
            validq2 = [validq2; NaN(sizeDiff, 1)];
        elseif sizeDiff < 0
            validq1 = [validq1; NaN(abs(sizeDiff), 1)];
        end

        % make vector with subID
        subID = repelem(data.subID, length(validq1));
        targetIdx = repelem(stimIdx, length(validq1));
        trial = 1:length(validq1);
        image = repelem(data.imagePath(stimIdx), length(validq1));

        % store in data table
        if exist('df', 'var') == 0
            df = table(subID', trial', targetIdx', image', validq1, validq2);
        else
            tmp = table(subID', trial', targetIdx', image', validq1, validq2);
            df = [df;tmp];
        end
    end
    % store calibrated coherence in a table
    if exist('df2', 'var') == 0
        df2 = table(data.subID, data.calibratedCoherence(1), data.calibratedCoherence(2), data.imagePath(1), data.imagePath(2));
    else
        tmp2 = table(data.subID, data.calibratedCoherence(1), data.calibratedCoherence(2), data.imagePath(1), data.imagePath(2));
        df2 = [df2; tmp2];
    end
end

df = renamevars(df, ["Var1", "Var2", "Var3", "Var4", "validq1", "validq2"], ["subID", "trial", "targetIdx", "imgPath", "stair1", "stair2"]);
writetable(df, '../data/tidied/staircases.csv')

df2 = renamevars(df2, ["Var1", "Var2", "Var3", "Var4", "Var5"], ["subID", "img1", "img2", "img1Path", "img2Path"]);
writetable(df2, '../data/tidied/calibrated_coherence.csv')

