function channels = getTopChannels( ...
    p2p_map,channel_map,n_requested,n_waveform_channels)
% Return the physical channels with the largest finite P2P amplitudes.

% The display map repeats some channels; count each physical channel once.

channel_ids = unique(double(channel_map(:)),'stable');
channel_ids = channel_ids(channel_ids >= 1 ...
    & channel_ids <= n_waveform_channels);
amplitude = nan(numel(channel_ids),1);

for index = 1:numel(channel_ids)
    values = abs(double(p2p_map(channel_map == channel_ids(index))));
    values = values(isfinite(values));

    if ~isempty(values)
        amplitude(index) = max(values);
    end
end

ranking = table(channel_ids,amplitude, ...
    'VariableNames',{'channel','amplitude'});
ranking = ranking(isfinite(ranking.amplitude),:);
ranking = sortrows(ranking,{'amplitude','channel'},{'descend','ascend'});

n_keep = min(n_requested,height(ranking));
channels = ranking.channel(1:n_keep);
end
