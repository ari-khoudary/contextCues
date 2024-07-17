%% set up files to save behavioral responses

% create folder to contain each subject's files
sID = ['s', num2str(subID)];
datadir = ['..' filesep 'data' filesep sID];
if ~exist(datadir, 'dir')
    mkdir(datadir);
end

% make file for training
trainingFileName = [datadir filesep 'block', num2str(block), '_training.csv'];
trainingFile = fopen(trainingFileName, 'wt+');
fprintf(trainingFile, ...
    '%s,%s,%s,%s,%s,%s,%s,%s',  ...
    'subID', 'block', 'trial', 'image', 'actualResponse', 'correctResponse', 'accuracy', 'RT');

% make file for practice
practiceFileName = [datadir filesep 'block', num2str(block), '_flickerPractice.csv'];
practiceFile = fopen(practiceFileName, 'wt+');
fprintf(practiceFile, ...
    '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',  ...
    'subID', 'block', 'trial', 'targetImage', 'targetIdx', 'coherence', 'respFrame', 'response', 'accuracy', 'RT', 'flickerDuration', 'repeatedTrial');

% make file for calibration
calibrationFileName = [datadir filesep 'block', num2str(block), '_calibration.csv'];
calibrationFile = fopen(calibrationFileName, 'wt+');
fprintf(calibrationFile, ...
    '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',  ...
    'subID', 'block', 'trial', 'targetImage', 'targetIdx', 'coherence', 'respFrame', 'response', 'accuracy', 'RT', 'flickerDuration');

% make file for learning
learnFileName = [datadir, filesep 'block', num2str(block), '_learning.csv'];
learnFile = fopen(learnFileName, 'wt+');
fprintf(learnFile, ...
    '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s, %s,%s, %s',  ...
    'subID', 'block', 'trial', 'image', 'imageIdx', 'cue_rgb', 'cue_string', 'congruent', 'response', 'accuracy', 'RT', 'cueDuration', 'learningRound');

% make file for inference
inferenceFileName = [datadir, filesep 'block', num2str(block), '_inference.csv'];
inferenceFile = fopen(inferenceFileName, 'wt+');
fprintf(inferenceFile, ...
    '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',  ...
    'subID', 'block', 'trial', 'targetImg', 'targetIdx', 'cue_rgb','cue_string', 'congruent', 'respFrame', 'response', 'accuracy', 'RT', 'confResp', 'confRT', 'flickerDuration', 'noise1frames', 'signal1frames', 'noise2frames', 'coherence', 'catch_trial');