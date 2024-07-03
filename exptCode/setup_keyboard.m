%% keyboard setup

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

% clear any presses from device memory
FlushEvents('keyDown');

% load KbCheck into memory now so later RTs are uniform
[keyIsDown, secs, keyCode] = KbCheck;