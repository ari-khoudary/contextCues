% set up psychtoolbox variables

%% keyboard

% unify responses across operating systems
KbName('UnifyKeyNames');

% response keys
resps         = [KbName('1!') KbName('2@') KbName('3#') KbName('4$')];
respQuit    = KbName('x');
actKeys     = [resps respQuit];
imageResponseKeys = resps(1:2);
confidenceResponseKeys = resps;
rightKey = KbName('RightArrow');
leftKey = KbName('LeftArrow');
spaceKey = KbName('space');

% load KbCheck into memory now so later RTs are uniform
[keyIsDown, secs, keyCode] = KbCheck(-1);


%% screen
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'Verbosity', 0);

% aesthetics
backgroundColor = 25;
textColor = 255;

% make farthest screen display
screenNumber = max(Screen('Screens'));

% get display dimensions
screenDims = Screen('Rect', screenNumber);
screenX = screenDims(3);
screenY = screenDims(4);
% compute center of display
centerX  = screenX/2;
centerY = screenY/2;

% define open window
mainWindow = Screen(screenNumber, 'OpenWindow', backgroundColor);

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
% position for feedback image
feedbackRect = [0, 0, imageSizeX/2, imageSizeY/2];
feedbackPos = [centerX - feedbackRect(3)/2, screenY/1.23-feedbackRect(4)/2, centerX + feedbackRect(3)/2, screenY/1.23 + feedbackRect(4)/2];