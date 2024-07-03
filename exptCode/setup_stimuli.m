%% stimuli setup

% get filepaths
imageList = dir('images/S*.jpg');
maskList = dir('images/mask*_s*.jpg');
% store
imageTex = zeros(length(imageList),1);
maskTex = zeros(length(maskList),1);

% get scene images
for i = 1:length(imageList)
    tempMat = imread(['images/' imageList(i).name]);
    imageTex(i,1) = Screen('MakeTexture', mainWindow, tempMat);
end

% get masks
for m = 1:length(maskList)
    tempMat = imread(['images/' maskList(m).name]);
    maskTex(m,1) = Screen('MakeTexture', mainWindow, tempMat);
end

% randomly choose pair of images for participant
if rand < 0.5
    randImageTex(1,1) = imageTex(1);
    randImageTex(2,1) = imageTex(2);
    randMaskTex(1,1) = maskTex(1);
    randMaskTex(2,1) = maskTex(2);
    imagePath = {imageList(1).name; imageList(2).name};
else
    randImageTex(1,1) = imageTex(3);
    randImageTex(2,1) = imageTex(4);
    randMaskTex(1,1) = maskTex(3);
    randMaskTex(2,1) = maskTex(4);
    imagePath = {imageList(3).name; imageList(4).name};
end

% randomize indices to randomize key presses across participants
shuffledIdx = Shuffle([1,2]);
randImageTex = randImageTex(shuffledIdx);
imagePath = imagePath(shuffledIdx);