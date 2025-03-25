function config = config()
    % Central configuration module for experiment settings
    
    % Screen settings
    config.screen.backgroundColor = 25;
    config.screen.textColor = 255;
    config.screen.textSize = 24;
    config.screen.skipSyncTests = 1;
    config.screen.suppressWarnings = 1;
    
    % Image settings
    config.image.sizeX = 256;
    config.image.sizeY = 256;
    
    % Timing settings
    config.timing.ifi = Screen('GetFlipInterval', max(Screen('Screens')));
    config.timing.baselineTime = 0.5;
    config.timing.stimTime = 1.0;
    config.timing.feedbackTime = 0.5;
    
    % Response settings
    KbName('UnifyKeyNames');
    config.keys.response = [KbName('1!') KbName('2@') KbName('3#') KbName('4$')];
    config.keys.quit = KbName('x');
    config.keys.space = KbName('space');
    config.keys.left = KbName('LeftArrow');
    config.keys.right = KbName('RightArrow');
    
    % Data saving settings
    config.data.rootDir = fileparts(mfilename('fullpath'));
    config.data.resultsDir = fullfile(config.data.rootDir, 'results');
    if ~exist(config.data.resultsDir, 'dir')
        mkdir(config.data.resultsDir);
    end
end 