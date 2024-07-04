%% set up screen settings

% general preferences
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'Verbosity', 0);
%Screen('Preference', 'VisualDebugLevel', 1);

% aesthetics
backgroundColor = 0;
textColor = 255;

% make farthest screen display
screenNumber = max(Screen('Screens'));

% get display dimensions
screenDims = Screen('Rect', screenNumber);
screenX = screenDims(3);
screenY = screenDims(4);
% define open window
mainWindow = Screen(screenNumber, 'OpenWindow',backgroundColor);
centerX  = screenX/2;
centerY = screenY/2;

% retrieve maximum priority number
topPriorityLevel = MaxPriority(mainWindow);

% text settings for display screen
Screen('TextSize', mainWindow, 24);

% place-holders / positions for images
imageSizeX  = 256;
imageSizeY = 256;
imageRect  = [0,0,imageSizeX,imageSizeY];
centerRect  = [centerX - imageSizeX/2, centerY - imageSizeY/2, centerX + imageSizeX/2, centerY + imageSizeY/2];
% position for prior cue
borderRect = [centerX - imageSizeX/2 - 10, centerY - imageSizeY/2 - 10, centerX + imageSizeX/2 + 10, centerY + imageSizeY/2 + 10];