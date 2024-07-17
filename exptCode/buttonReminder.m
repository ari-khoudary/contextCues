% button mapping reminder
FlushEvents('keyDown');

remindIdx = Shuffle([1,2]);
for target = 1:length(remindIdx)
    % put reminder & target on screen
    reminderString = 'Before proceeding, please press the button associated with this scene image:';
    DrawFormattedText(mainWindow, reminderString, 'center', centerY-imageRect(4)+20, textColor);
    Screen('DrawTexture', mainWindow, randImageTex(remindIdx(target)), imageRect, centerRect);
    Screen('Flip', mainWindow);
    % collect response
    while(1)
        [keyIsDown,~,keyCode] = KbCheck;
        if find(keyCode(imageResponseKeys)) == remindIdx(target)
            feedbackString = 'Correct!';
            DrawFormattedText(mainWindow, reminderString, 'center', centerY-imageRect(4)+20, textColor);
            Screen('DrawTexture', mainWindow, randImageTex(remindIdx(target)), imageRect, centerRect);
            DrawFormattedText(mainWindow, feedbackString, 'center', centerY+imageRect(4)+30, textColor);
            Screen('Flip', mainWindow);
            WaitSecs(0.75);
            FlushEvents('keyDown');
            break
        elseif keyIsDown==1 && sum((find(keyCode(imageResponseKeys))) ~= remindIdx(target))
            feedbackString = 'Incorrect, please try again.';
            DrawFormattedText(mainWindow, reminderString, 'center', centerY-imageRect(4)+20, textColor);
            Screen('DrawTexture', mainWindow, randImageTex(remindIdx(target)), imageRect, centerRect);
            DrawFormattedText(mainWindow, feedbackString, 'center', centerY+imageRect(4)+30, textColor);
            Screen('Flip', mainWindow);
        end
        WaitSecs(0.05);
    end
    FlushEvents('keyDown');
end