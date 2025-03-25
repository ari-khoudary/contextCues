% set up stimuli for the task

%% colored borders
red = [240 37 33];
blue = [10 144 240];
yellow = [240 239 10];
borders1 = [red; blue; yellow];
borders1_string = {'red', 'blue', 'yellow'};

purple = [181 10 240];
green = [10 240 94];
orange = [240 168 10];
borders2 = [purple; green; orange];
borders2_string = {'purple', 'green', 'orange'};

border_array = {borders1, borders2};
border_array_string = {borders1_string, borders2_string};

%% scene images
% get filepaths
imageList = dir('images/S*.jpg');
maskList = dir('images/mask*_s*.jpg');
feedbackList = dir('images/feedback_*.jpg');
% store
imageTex = zeros(length(imageList),1);
maskTex = zeros(length(maskList),1);
feedbackTex = zeros(length(feedbackList),1);

% get scene images
for i = 1:length(imageList)
    % regular images
    tempMat1 = imread(['images/' imageList(i).name]);
    imageTex(i,1) = Screen('MakeTexture', mainWindow, tempMat1);

    % small feedback images
    tempMat2 = imread(['images/' feedbackList(i).name]);
    feedbackTex(i,1) = Screen('MakeTexture', mainWindow, tempMat2);
end

% get masks
for m = 1:length(maskList)
    tempMat = imread(['images/' maskList(m).name]);
    maskTex(m,1) = Screen('MakeTexture', mainWindow, tempMat);
end

% randomly choose pair of images for participant
if mod(subID, 2) == 1
    randImageTex(1,1) = imageTex(1);
    randImageTex(2,1) = imageTex(2);
    randFeedbackTex(1,1) = feedbackTex(1);
    randFeedbackTex(2,1) = feedbackTex(2);
    randMaskTex(1,1) = maskTex(1);
    randMaskTex(2,1) = maskTex(2);
    imagePath = {imageList(1).name; imageList(2).name};
else
    randImageTex(1,1) = imageTex(3);
    randImageTex(2,1) = imageTex(4);
    randFeedbackTex(1,1) = feedbackTex(3);
    randFeedbackTex(2,1) = feedbackTex(4);
    randMaskTex(1,1) = maskTex(3);
    randMaskTex(2,1) = maskTex(4);
    imagePath = {imageList(3).name; imageList(4).name};
end

% randomize indices to randomize key presses across participants
shuffledIdx = Shuffle([1,2]);
randImageTex = randImageTex(shuffledIdx);
randFeedbackTex = randFeedbackTex(shuffledIdx);
imagePath = imagePath(shuffledIdx);