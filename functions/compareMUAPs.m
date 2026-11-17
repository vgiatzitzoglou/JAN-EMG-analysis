function [score,best_lag,selected_channels,top_a,top_b,used_channels] = ...
    compareMUAPs(muap_a,muap_b,map_a,map_b,channel_map)
% Compare MUAPs with normalised cross-correlation over selected channels.

% Use the union of the strongest physical channels from both MUs.

n_top_channels = 10;
n_waveform_channels = min(size(muap_a,1),size(muap_b,1));
top_a = getTopChannels( ...
    map_a,channel_map,n_top_channels,n_waveform_channels);
top_b = getTopChannels( ...
    map_b,channel_map,n_top_channels,n_waveform_channels);
selected_channels = unique([top_a(:);top_b(:)],'stable');
used_channels = zeros(0,1);

n_samples = min(size(muap_a,2),size(muap_b,2));
if isempty(selected_channels) || n_samples < 2
    score = NaN;
    best_lag = NaN;
    return
end

n_lags = 2*n_samples-1;
minimum_valid_samples = 10;
channel_correlations = nan(numel(selected_channels),n_lags);

for index = 1:numel(selected_channels)
    channel = selected_channels(index);
    x = double(muap_a(channel,1:n_samples));
    y = double(muap_b(channel,1:n_samples));
    valid = isfinite(x) & isfinite(y);

    if nnz(valid) < minimum_valid_samples
        continue
    end

    x = x - mean(x(valid));
    y = y - mean(y(valid));
    x(~valid) = 0;
    y(~valid) = 0;

    if norm(x) == 0 || norm(y) == 0
        continue
    end

    channel_correlations(index,:) = xcorr(x,y,'coeff');
end

lags = -(n_samples-1):(n_samples-1);
lag_scores = mean(channel_correlations,1,'omitnan');
score = max(lag_scores,[],'omitnan');

if ~isfinite(score)
    best_lag = NaN;
    return
end

best = find(abs(lag_scores-score) <= 10*eps(max(1,abs(score))));
[~,nearest_zero] = min(abs(lags(best)));
best_index = best(nearest_zero);
best_lag = lags(best_index);
used_channels = selected_channels(isfinite(channel_correlations(:,best_index)));
end
