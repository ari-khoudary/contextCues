% plot precisions, drift rates, accumulators for single trials

%% unwrap structure if loading in data
if ~exist('decisionVariable', 'var')
    struct2vars(data);
end
if threshold < 2*max(max(decisionVariable))
    plotThresh = 1;
else
    plotThresh=0;
end

%%  
trial = 5;

% make dummy mem evidence variable for unweighted accumulator plot
memEvidence = zeros(nFrames, 1);
memEvidence(mod(1:nFrames, memoryThinning)==1) = ...
    memoryEvidence(mod(1:nFrames, memoryThinning)==1, trial);

% set up figure
time = 1:nFrames;
alpha = 0.15;
t = tiledlayout('flow');

% estimated precision
nexttile;
hold on
plot(time, memoryPrecisions(:,trial));
plot(time, visionPrecisions(:,trial));
plot(time, (memoryPrecisions(:, trial) + visionPrecisions(:,trial)) / 2)
if delayPeriod
    xline(trialDelays(trial), ':')
end
legend({'memory precision', 'vision precision', 'avg precision'});
if delayPeriod
    legend({'memory precision', 'vision precision', 'avg precision', 'onset of viz ev'});
end
title('estimated precision');

% drift rates
nexttile;
hold on
plot(time, memoryDrifts(:, trial));
plot(time, visionDrifts(:, trial));
plot(time, visionDrifts(:,trial) + memoryDrifts(:,trial));
if delayPeriod
    xline(trialDelays(trial), ':')
end
legend({'memory drift', 'vision drift', 'DV drift (mem+viz)'});
title('drift rates')

% accumulators
nexttile;
hold on
plot(time, memoryAccumulator(:,trial));
plot(time, visionAccumulator(:, trial));
plot(time, decisionVariable(:, trial));
if delayPeriod
    xline(trialDelays(trial), ':')
end
if plotThresh
    yline(threshold);
    legend({'memory accumulator', 'vision accumulator', 'DV', '', '', 'threshold'}, 'Location', 'northwest');
else
    legend({'memory accumulator', 'vision accumulator', 'DV'}, 'Location', 'northwest');
end
title('reliability-weighted accumulators')

% cumsum
nexttile;
hold on
plot(time, cumsum(memEvidence));
plot(time, cumsum(visionEvidence(:, trial)));
plot(time, decisionVariable(:, trial));
if delayPeriod
    xline(trialDelays(trial), ':')
end
if plotThresh
    yline(threshold);
    legend({'memory', 'vision', 'DV (from model)', '', '', 'threshold'}, 'Location', 'northwest');
else
    legend({'memory', 'vision', 'DV (from model)'}, 'Location', 'northwest');
end
title('unweighted cumulative sum of samples')

sgtitle(t, ['example trial (#' num2str(trial) '): ' num2str(cue) ' cue, ' num2str(coherence) ' coh, 1:' num2str(memoryThinning) ' mem:viz, threshold=' num2str(threshold)])
subtitle(t, ['congruent=', num2str(congruent(trial))]);

allLines = findobj(gcf, 'Type', 'line');
set(allLines, 'LineWidth', 1)
