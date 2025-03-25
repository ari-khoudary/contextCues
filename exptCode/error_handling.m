function errorHandling = error_handling()
    % Central error handling module for experiment
    
    errorHandling.handlePTBError = @handlePTBError;
    errorHandling.handleKeyboardError = @handleKeyboardError;
    errorHandling.handleStimulusError = @handleStimulusError;
    errorHandling.cleanup = @cleanup;
end

function handlePTBError(e)
    % Handle Psychtoolbox specific errors
    fprintf('PTB Error: %s\n', e.message);
    Screen('CloseAll');
    ShowCursor;
    Priority(0);
    psychrethrow(psychlasterror);
end

function handleKeyboardError(e)
    % Handle keyboard related errors
    fprintf('Keyboard Error: %s\n', e.message);
    KbReleaseWait;
    ListenChar(0);
    ShowCursor;
end

function handleStimulusError(e)
    % Handle stimulus presentation errors
    fprintf('Stimulus Error: %s\n', e.message);
    Screen('Close');
end

function cleanup()
    % General cleanup function
    try
        Screen('CloseAll');
        ShowCursor;
        Priority(0);
        ListenChar(0);
        KbReleaseWait;
    catch
        % If cleanup fails, at least try to restore basic functionality
        ShowCursor;
        ListenChar(0);
    end
end 