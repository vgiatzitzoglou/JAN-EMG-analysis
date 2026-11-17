function activePeriods = findMUActivePeriods(spikes,threshold_hz,fs, ...
    restThresh,min_duration)
% Identify active periods using find_MU_active_periods_v2.m logic.
nMUs = size(spikes,2);
activePeriods = cell(nMUs,1);

for mu = 1:nMUs
    spike_samples = find(spikes(:,mu));
    if numel(spike_samples) < 2
        continue
    end

    isi = diff(spike_samples) / fs;
    if threshold_hz == 0
        active = true(size(isi));
    else
        active = isi < 1 / threshold_hz;
    end

    starts = [];
    ends = [];
    start_sample = spike_samples(1);

    for interval = 1:numel(active)
        if active(interval)
            if isempty(starts) || spike_samples(interval) > ends(end)
                starts = [starts;start_sample];
                ends = [ends;spike_samples(interval + 1)];
            else
                ends(end) = spike_samples(interval + 1);
            end
        else
            start_sample = spike_samples(interval + 1);
        end
    end

    if isempty(starts)
        continue
    end

    starts = (starts - 1) / fs;
    ends = (ends - 1) / fs;
    merged_start = starts(1);
    merged_end = ends(1);

    for period = 2:numel(starts)
        if starts(period) - merged_end <= restThresh
            merged_end = ends(period);
        else
            if merged_end - merged_start >= min_duration
                activePeriods{mu} = [activePeriods{mu}; ...
                    merged_start,merged_end];
            end
            merged_start = starts(period);
            merged_end = ends(period);
        end
    end

    if merged_end - merged_start >= min_duration
        activePeriods{mu} = [activePeriods{mu}; ...
            merged_start,merged_end];
    end
end
end
