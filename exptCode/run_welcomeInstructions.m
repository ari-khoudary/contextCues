% displays welcome instructions

%% load in & prep instructions image

welcPath = 'images/welcomeSlide.png';
welcImg = imread(welcPath);
welcTex = Screen('MakeTexture', mainWindow, welcImg);

originalSize = size(welcImg); % Get original size of the image
aspectRatio = originalSize(2) / originalSize(1); % width / height

% Calculate new dimensions while maintaining the aspect ratio
desiredWidth = 800; % For example, fixed width
desiredHeight = desiredWidth / aspectRatio;

% Calculate the destination rectangle
% [left, top, right, bottom] = [x, y, x + width, y + height]
destRect = [0, 0, desiredWidth, desiredHeight];

% Offset the destination rectangle to center it
destRect = CenterRectOnPointd(destRect, centerX, centerY);

welcString = ['Welcome! \n\n' ...
    'This is an experiment about how people learn and make decisions. \n\n'...
    'Today''s session will consist of a few different phases that vary in length. \n' ...
    'The experiment as a whole should take no more than 90 minutes to complete. \n\n' ...
    'Use the forward arrow to learn more about each phase of the experiment. \n' ...
    'You will get more instructions about each phase as it comes up'];

%% runs welcome instructions

DrawFormattedText(mainWindow, welcString, 'center', 'center', textColor, 80);
Screen('Flip',mainWindow);
FlushEvents('keyDown');
while(1)
    [~,~,keyCode] = KbCheck(-1);
    if keyCode(rightKey)
        break;
    end
    WaitSecs(0.05);
end

% display graphic after right image key is pressed
Screen('DrawTexture', mainWindow, welcTex, [], destRect);
WaitSecs(5);
DrawFormattedText(mainWindow, 'Press spacebar when you are ready to proceed to Response Training.', centerX-350, centerY*1.5);
Screen('Flip', mainWindow);
while(1)
    [~,~,keyCode] = KbCheck(-1);
    if keyCode(spaceKey)
        break;
    end
    WaitSecs(0.05);
end