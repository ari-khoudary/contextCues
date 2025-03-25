function utils = utils()
    % Utility functions for experiment
    
    utils.waitForResponse = @waitForResponse;
    utils.checkQuit = @checkQuit;
    utils.saveData = @saveData;
    utils.validateInput = @validateInput;
end

function [response, RT] = waitForResponse(validKeys, timeout)
    % Wait for a valid response with timeout
    if nargin < 2
        timeout = inf;
    end
    
    startTime = GetSecs();
    response = 0;
    RT = nan;
    
    while GetSecs() - startTime < timeout
        [keyIsDown, secs, keyCode] = KbCheck(-1);
        if keyIsDown
            if any(keyCode(validKeys))
                response = find(keyCode(validKeys), 1);
                RT = secs - startTime;
                break;
            elseif keyCode(KbName('x'))
                error('User requested quit');
            end
            KbReleaseWait;
        end
    end
end

function checkQuit(keyCode)
    % Check if quit key was pressed
    if keyCode(KbName('x'))
        cleanup();
        error('User requested quit');
    end
end

function saveData(data, filename)
    % Save data with error checking
    try
        save(filename, 'data');
    catch e
        warning('Failed to save data: %s', e.message);
        % Try to save to a backup location
        [~, name, ext] = fileparts(filename);
        backupFile = fullfile(tempdir, [name '_backup' ext]);
        save(backupFile, 'data');
        warning('Data saved to backup location: %s', backupFile);
    end
end

function validated = validateInput(input, validRange, fieldName)
    % Input validation with detailed error messages
    if nargin < 3
        fieldName = inputname(1);
    end
    
    if ~isnumeric(input)
        error('Input %s must be numeric', fieldName);
    end
    
    if nargin > 1 && ~isempty(validRange)
        if input < validRange(1) || input > validRange(2)
            error('%s must be between %g and %g', fieldName, validRange(1), validRange(2));
        end
    end
    
    validated = input;
end 