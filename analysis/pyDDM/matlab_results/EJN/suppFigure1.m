%% load in files
hanks_trials = [1 3 9 3 3 5 5 9 5 6];
bornstein_trials = [4 7 9 8 6 3 1 9 9 2];
thinning_levels = [4:4:40];

%% this is dumb but it works
figure;
f1 = tiledlayout(5, 2);  
for gamma = 1:length(thinning_levels)
    load(['extended_results/hanks_' num2str(thinning_levels(gamma)) 'thin.mat']);
    t = hanks_trials(gamma);
    % plot
    nexttile;
    hold on
    yline(0);
    plot(1:data.nFrames, data.memoryAccumulator(:, t));
    plot(1:data.nFrames, data.visionAccumulator(:, t));
    plot(1:data.nFrames, data.decisionVariable(:, t));
    title(['gamma = ' num2str(thinning_levels(gamma))]);
end

figure;
f2 = tiledlayout(5, 2);
for gamma = 1:length(thinning_levels)
    load(['extended_results/bornstein_' num2str(thinning_levels(gamma)) 'thin.mat']);
    t = bornstein_trials(gamma);
    vizOnset = data.trialDelays(t);
    % plot
    nexttile;
    hold on
    yline(0);
    xline(0)
    xline(vizOnset);
    plot(1:data.nFrames, data.memoryAccumulator(:, t));
    plot(1:data.nFrames, data.visionAccumulator(:, t));
    plot(1:data.nFrames, data.decisionVariable(:, t));
    title(['gamma = ' num2str(thinning_levels(gamma))]);
end

%% plot drift rates

figure;
f3 = tiledlayout(5, 2);  
for gamma = 1:length(thinning_levels)
    load(['extended_results/hanks_' num2str(thinning_levels(gamma)) 'thin.mat']);
    t = hanks_trials(gamma);
    % plot
    nexttile;
    hold on
    yline(0);
    plot(1:data.nFrames, data.memoryDrifts(:, t));
    plot(1:data.nFrames, data.visionDrifts(:, t));
    plot(1:data.nFrames, ((data.memoryDrifts(:,t) + data.visionDrifts(:,t))/2));
    title(['gamma = ' num2str(thinning_levels(gamma))]);
end 