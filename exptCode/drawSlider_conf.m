function drawSlider_conf(w, centerY, centerX, minValue, maxValue, thumbValue, confValue, sliderLength, sliderWidth, sliderHeight, rightImageIdx, leftImageIdx, feedbackRect, randFeedbackTex, thisCue)

% define coordinates
    sliderY = centerY*1.5;
    sliderStartX = centerX - sliderLength;
    sliderEndX = centerX + sliderLength;

    % Image parameters
    imageWidth = feedbackRect(3);     % Width of the images
    imageHeight = feedbackRect(4);    % Height of the images
    leftImageX = sliderStartX - imageWidth - 20;  % Position of the left image
    rightImageX = sliderEndX + 20; 

    % Draw the slider line
    Screen('DrawLine', w, [200 200 200], sliderStartX, sliderY, sliderEndX, sliderY, sliderWidth); 
                  
    % draw the midway point
     Screen('DrawLine', w, [150 150  150], centerX, centerY*1.5 - sliderHeight/2, centerX, centerY*1.5+sliderHeight/2, 2);

    % Calculate thumb position
    thumbX = sliderStartX + ((thumbValue - minValue) / (maxValue - minValue)) * (sliderEndX - sliderStartX);
    thumbPosition = [thumbX - sliderWidth/2, sliderY - sliderHeight/2, thumbX + sliderWidth/2, sliderY + sliderHeight/2];

    % Define text properties
    if confValue < 50
        valueText = num2str(100-confValue);
    else
        valueText = num2str(confValue); 
    end
    textX = thumbX-10;   % Center text above thumb
    textY = sliderY+30;                % Position text above the slider
    
    % Draw the text
    Screen('DrawText', w, [valueText '%'], textX, textY, [225 225 225]);  % thumb value
    Screen('DrawText', w, '100% Scene 1', sliderStartX-150, sliderY - imageHeight/1.25); % slider left anchor
    Screen('DrawText', w, '100% Scene 2', sliderEndX+15, sliderY - imageHeight/1.25); % slider right anchor
    Screen('DrawText', w, 'Press C to confirm', centerX-85, sliderY + imageHeight); % confirmation button

    % draw the images
    Screen('DrawTexture', w, randFeedbackTex(leftImageIdx), [], [leftImageX, sliderY - imageHeight/2, leftImageX + imageWidth, sliderY + imageHeight/2]);
    Screen('DrawTexture', w, randFeedbackTex(rightImageIdx), [], [rightImageX, sliderY - imageHeight/2, rightImageX + imageWidth, sliderY + imageHeight/2]);

    % Draw the thumb
    Screen('FillRect', w, thisCue, thumbPosition);
    
    % Flip to the screen
    Screen('Flip', w);
end