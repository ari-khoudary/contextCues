% plot precisions, drift rates, accumulators for single trials

%% load & tidy data
load('results/0.8cue_0.51coh_5thresh_12thin_10trial_sub1.mat');

if threshold < 2*max(max(decisionVariable))
    plotThresh = 1;
else
    plotThresh=0;
end

%%  prep for plotting

struct2vars(data);
trial = 1;
% "thin out" memory evidence
memEvidence = NaN(nFrames, 1);
memEvidence(mod(1:nFrames, memoryThinning)==1) = ...
    memoryEvidence(mod(1:nFrames, memoryThinning)==1, trial);

% create dvEvidence
foo = memEvidence;
foo(isnan(foo)) = 1;
dvEvidence = ((foo.*memoryDrifts) + (visionEvidence(:,trial).*visionDrifts(:, trial)));

% convert frames to seconds
time = (1:nFrames)/72;
fooTime = time;
for i=2:length(fooTime)
    if mod(i, memoryThinning)>0
        fooTime(i) = NaN;
    end
end

if noisePeriods == 1
    noise1Frames = noise1Frames ./ 72;
    noise2Onsets = noise2Onsets ./ 72;
    signal2Onsets = signal2Onsets ./ 72;
end

%% 

% specify target trial
trial = 4;
plotThresh = 0;
% prep for plotting time-evolving betas
memoryAlphas = counters(:, 1, trial);
memoryBetas = counters(:, 2, trial);
visionAlphas = counters(:, 3, trial);
visionBetas = counters(:, 4, trial);
x = linspace(0,1,length(time));

% define colors
colors = get(gca, 'colororder');
close;
alpha = 0.15;
blue = colors(1,:);
red = colors(2,:);
yellow = colors(3,:);
purple = colors(4, :);
green = colors(5,:);

% make tiled plot
t = tiledlayout(4,2);
% plot raw evidence first (eqs 1 & 8)
% memory
nexttile;
hold on
yline(0, 'LineStyle', ':');
plot(time, memEvidence, '.', 'MarkerSize', 5, 'Color', blue);
validIdx = ~isnan(memEvidence);
plot(time(validIdx), memEvidence(validIdx), '-', 'LineWidth', 1, 'Color', blue);
if noisePeriods == 1
    xregion(0, noise1Frames(trial));
    xregion(noise2Onsets(trial), signal2Onsets(trial));
end
%legend({'', '', '', 'memory', 'vision', 'weighted sum'}, 'Location', 'northwest');
title('memory evidence (o_{mem_{t}})');
ylabel('sample (a.u.)');

% vision
nexttile(3);
hold on
yline(0, 'LineStyle', ':');
plot(time, visionEvidence(:,trial), '.', 'MarkerSize', 5, 'Color', yellow);
plot(time, visionEvidence(:,trial), '-', 'LineWidth', 1, 'Color', yellow);
if noisePeriods == 1
    xregion(0, noise1Frames(trial));
    xregion(noise2Onsets(trial), signal2Onsets(trial));
end
title('vision evidence (o_{viz_{t}})');
ylabel('sample (a.u.)');

% then plot their accumulated evidence (equation 6)
nexttile(2, [2 1]);
hold on
plot(time, memoryAccumulator(:,trial), 'LineWidth', 2, 'Color', blue);
plot(time, visionAccumulator(:, trial), 'LineWidth', 2, 'Color', yellow);
plot(time, decisionVariable(:, trial), 'LineWidth', 2, 'Color', green);
if noisePeriods == 1
    xregion(0, noise1Frames(trial));
    xregion(noise2Onsets(trial), signal2Onsets(trial));
end
if plotThresh
    yline([threshold, -threshold], 'LineWidth', 3);
    yline(0, 'LineStyle', ':');
    legend({'memory', 'vision', 'DV', '', '', 'threshold'}, 'Location', 'northwest');
else
    legend({'memory', 'vision', 'DV'}, 'Location', 'northwest');
end
title('precision-weighted accumulated evidence');
ylabel('accumulator value (a.u.)');

% plot time-evolving betas (equations 2 & 3)
nexttile(5);
if noisePeriods == 1
    xregion(0, noise1Frames(trial));
    xregion(noise2Onsets(trial), signal2Onsets(trial));
end
options = struct('title', 'time-evolving belief about source reliability (g_{s}(t))');
h1 = plotBetaTimeEvolution(time, memoryAlphas, memoryBetas, memoryThinning, blue);
h2 = plotBetaTimeEvolution(time, visionAlphas, visionBetas, memoryThinning, yellow, options);
legend([h1, h2], {'memory', 'vision'}, 'Location', 'southeast');

% then precision estimates
nexttile(7);
hold on
plot(time, memoryPrecisions(:,trial), 'Color', blue, 'LineWidth', 2);
plot(time, visionPrecisions(:,trial), 'Color', yellow, 'LineWidth', 2);
plot(time, (memoryPrecisions(:,trial) + visionPrecisions(:,trial))/2, 'Color', green, 'LineWidth', 2);
% plot(time, memoryPrecisions(:,trial), '.', 'MarkerSize', 5, 'Color', blue);
% plot(time, visionPrecisions(:,trial), '.', 'MarkerSize', 5, 'Color', yellow);
% plot(time, (memoryPrecisions(:,trial) + visionPrecisions(:,trial))/2, '.', 'MarkerSize', 5, 'Color', green);
if noisePeriods == 1
    xregion(0, noise1Frames(trial));
    xregion(noise2Onsets(trial), signal2Onsets(trial));
end
legend({'memory', 'vision','(mem+viz)/2', ''}, 'Location', 'southeast');
title('precision estimate (\lambda_{s_{t}} = H(g_{s}(t)^{-1})');
ylabel('precision (bans)');

% then drift rates 
nexttile(6, [2 1]);
hold on
plot(time, memoryDrifts(:, trial), 'LineWidth', 2, 'Color', blue);
plot(time, visionDrifts(:, trial), 'LineWidth', 2, 'Color', yellow);
%plot(time, (visionDrifts(:,trial) + memoryDrifts(:,trial)) / 2, 'LineWidth', 2, 'Color', green);
%plot(time, visionDrifts(:,trial) + memoryDrifts(:,trial), 'LineWidth', 2, 'Color', red);
if noisePeriods == 1
    xregion(0, noise1Frames(trial));
    xregion(noise2Onsets(trial), signal2Onsets(trial));
end
%legend({'memory', 'vision', '(mem+viz)/2', 'mem+viz',}, 'Location', 'northwest');
legend({'memory', 'vision'}, 'Location', 'southeast');
title('evidence weights (w_{s})');
ylabel('weight (a.u.)');

% add title 
sgtitle(t, ['example trial (#' num2str(trial) '): \theta_{mem} = ' num2str(cue) ',  \theta_{viz} = ' num2str(round(coherence, 2)) ',  \gamma = ' num2str(memoryThinning) ',  a = '  num2str(threshold)])
subtitle(t, ['valid/congruent trial == ', num2str(congruent(trial))]);
xlabel(t, 'time (s)');