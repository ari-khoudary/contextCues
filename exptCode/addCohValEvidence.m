
for trial = 1:cohFeedbackTotalN
    respFrame = data_coherenceValidation.respFrame(trial);
    if isnan(respFrame)
        respFrame = nFrames;
    end
    noise1frames = noise1Frames_v(trial);
    noise2frames = noise2Frames_v(trial);
    signal1frames = signal1Frames_v(trial);
    % compute derivative variables
    signal1onset = noise1frames + 1;
    noise2onset = signal1onset + signal1frames + 1;
    signal2onset = noise2onset + noise2frames + 1;
    signal2frames = nFrames - signal2onset;
    trialEvidence = flickerStream_v(1:respFrame, trial);

    % store
    data_coherenceValidation.noise1frames_design(trial) = noise1frames;
    data_coherenceValidation.signal1Onset_design(trial) = signal1onset;
    data_coherenceValidation.signal1frames_design(trial) = signal1frames;
    data_coherenceValidation.noise2Onset_design(trial) = noise2onset;
    data_coherenceValidation.noise2frames_design(trial) = noise2frames;
    data_coherenceValidation.signal2Onset_design(trial) = signal2onset;
    data_coherenceValidation.signal2frames_design(trial) = signal2frames;

    % update evidence dynamics based on responseFrame
    if respFrame > signal2onset % if they respond anytime after the second noise period
        data_coherenceValidation.totalEv_signal1(trial) = sum(trialEvidence(1:noise2onset) > 0);
        data_coherenceValidation.targetEv_signal1(trial) = sum(trialEvidence(1:noise2onset) == trialTarget);
        data_coherenceValidation.totalEv_signal2(trial) = sum(trialEvidence(signal2onset:respFrame) > 0);
        data_coherenceValidation.targetEv_signal2(trial) = sum(trialEvidence(signal2onset:respFrame)==trialTarget);
        data_coherenceValidation.noise1frames_obs(trial) = noise1frames;
        data_coherenceValidation.signal1frames_obs(trial) = signal1frames;
        data_coherenceValidation.noise2frames_obs(trial) = noise2frames;
        data_coherenceValidation.signal2frames_obs(trial) = length(trialEvidence(signal2onset:respFrame));
    elseif respFrame > noise2onset && respFrame < signal2onset % if they respond during the second noise period
        data_coherenceValidation.noise2frames_obs(trial) = length(trialEvidence(noise2onset:respFrame));
        data_coherenceValidation.totalEv_signal1(trial) = sum(trialEvidence(1:respFrame) > 0);
        data_coherenceValidation.targetEv_signal1(trial) = sum(trialEvidence(1:respFrame) == trialTarget);
        data_coherenceValidation.totalEv_signal2(trial) = NaN;
        data_coherenceValidation.targetEv_signal2(trial) = NaN;
        data_coherenceValidation.noise1frames_obs(trial) = noise1frames;
        data_coherenceValidation.signal1frames_obs(trial) = signal1frames;
        data_coherenceValidation.signal2frames_obs(trial) = NaN;
    elseif respFrame > noise1frames && respFrame < noise2onset % if they respond during first signal period
        data_coherenceValidation.noise2frames_obs(trial) = NaN;
        data_coherenceValidation.totalEv_signal1(trial) = sum(trialEvidence(1:respFrame) > 0);
        data_coherenceValidation.targetEv_signal1(trial) = sum(trialEvidence(1:respFrame) == trialTarget);
        data_coherenceValidation.totalEv_signal2(trial) = NaN;
        data_coherenceValidation.targetEv_signal2(trial) = NaN;
        data_coherenceValidation.noise1frames_obs(trial) = noise1frames;
        data_coherenceValidation.signal1frames_obs(trial) = length(trialEvidence(signal1onset:respFrame));
        data_coherenceValidation.signal2frames_obs(trial) = NaN;
    else % if they respond during first noise period
        data_coherenceValidation.signal1frames_obs(trial) = NaN;
        data_coherenceValidation.noise1frames_obs(trial) = respFrame;
        data_coherenceValidation.noise2frames_obs(trial) = NaN;
        data_coherenceValidation.totalEv_signal1(trial) = sum(trialEvidence(1:respFrame) > 0);
        data_coherenceValidation.targetEv_signal1(trial) = sum(trialEvidence(1:respFrame) == trialTarget);
        data_coherenceValidation.totalEv_signal2(trial) = NaN;
        data_coherenceValidation.targetEv_signal2(trial) = NaN;
        data_coherenceValidation.signal2frames_obs(trial) = NaN;
    end

    if isnan(data_coherenceValidation.respFrame(trial)) && ~isnan(data_coherenceValidation.RT(trial))
        data_coherenceValidation.postFlickerResp(trial) = 1;
    else
        data_coherenceValidation.postFlickerResp(trial) = 0;
    end
end

%%
data_coherenceValidation_original = data_coherenceValidation;
data_coherenceValidation = removevars(data_coherenceValidation, ["noise1frames", "signal1Onset", "noise2Onset", "noise2frames", "signal2Onset"]);
writetable(data_coherenceValidation, [datadir filesep 'block', num2str(block), '_coherenceValidation.csv']);