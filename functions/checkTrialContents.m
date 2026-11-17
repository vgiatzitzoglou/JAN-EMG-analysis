function [nMUs,n_samples,fs,n_channels,n_muap_samples,problem] = ...
    checkTrialContents(data,subj,digit,force,trialType,rep,problem)
% Check the variables and dimensions stored in one trial.

issues = string(problem);
nMUs = numel(data.MUAPs);
n_samples = size(data.Spikes,1);
fs = NaN;
n_channels = NaN;
n_muap_samples = NaN;

if nMUs == 0
    issues(end+1,1) = "no motor units";
end

if ~iscell(data.MUAPs)
    issues(end+1,1) = "MUAPs is not a cell array";
else
    bad_muap_size = 0;
    empty_muap = 0;

    for mu = 1:nMUs
        waveform = data.MUAPs{mu};
        if ~isnumeric(waveform) || isempty(waveform) || ...
                ~any(isfinite(waveform),'all')
            empty_muap = empty_muap + 1;
            continue
        end

        if isnan(n_channels)
            n_channels = size(waveform,1);
            n_muap_samples = size(waveform,2);
        end

        if size(waveform,1) ~= 192 || ...
                size(waveform,2) ~= n_muap_samples
            bad_muap_size = bad_muap_size + 1;
        end
    end

    if empty_muap > 0
        issues(end+1,1) = string(compose('%d empty MUAPs',empty_muap));
    end
    if bad_muap_size > 0
        issues(end+1,1) = ...
            string(compose('%d MUAPs have inconsistent dimensions',bad_muap_size));
    end
end

if ~isnumeric(data.Maps) || size(data.Maps,1) ~= nMUs || ...
        size(data.Maps,2) ~= 13 || size(data.Maps,3) ~= 15
    issues(end+1,1) = "Maps dimensions do not match MUAPs";
elseif nMUs > 0
    maps = reshape(data.Maps,nMUs,[]);
    n_empty_maps = sum(~any(isfinite(maps),2));
    if n_empty_maps > 0
        issues(end+1,1) = string(compose('%d empty Maps',n_empty_maps));
    end
end

names = ["grid_id","SIL","CoV","SpikeCount"];
for name = names
    if numel(data.(name)) ~= nMUs
        issues(end+1,1) = name + " length does not match MUAPs";
    end
end

if numel(data.grid_id) == nMUs && ...
        any(~ismember(double(data.grid_id(:)),1:3))
    issues(end+1,1) = "grid_id contains values outside 1 to 3";
end

if numel(data.SIL) == nMUs && any(~isfinite(double(data.SIL(:))))
    issues(end+1,1) = "SIL contains missing values";
end

if numel(data.SpikeCount) == nMUs && ...
        any(~isfinite(double(data.SpikeCount(:))))
    issues(end+1,1) = "SpikeCount contains missing values";
end

if size(data.Spikes,2) ~= nMUs + 1
    issues(end+1,1) = "Spikes must contain one column per MU plus force";
elseif ~isnumeric(data.Spikes) || isempty(data.Spikes)
    issues(end+1,1) = "Spikes is empty or nonnumeric";
else
    spike_data = data.Spikes(:,1:nMUs);
    if any(~isfinite(spike_data),'all')
        issues(end+1,1) = "Spikes contains missing values";
    end

    if numel(data.SpikeCount) == nMUs
        calculated = sum(spike_data > 0,1);
        if any(calculated(:) ~= double(data.SpikeCount(:)))
            issues(end+1,1) = "SpikeCount does not match Spikes";
        end
    end

    force_trace = double(data.Spikes(:,end));
    finite_force = force_trace(isfinite(force_trace));
    if isempty(finite_force) || max(finite_force) == min(finite_force)
        issues(end+1,1) = "force trace is missing or constant";
    end
end

metadata_fields = ["subj","digit_label","force_val", ...
    "trial_type","rep","fs"];
missing_metadata = metadata_fields(~isfield(data.metadata,metadata_fields));
if ~isempty(missing_metadata)
    issues(end+1,1) = "missing metadata: " + ...
        strjoin(missing_metadata,',');
else
    fs = double(data.metadata.fs);
    if ~isscalar(fs) || ~isfinite(fs) || fs <= 0
        issues(end+1,1) = "invalid sampling rate";
    end
    if string(data.metadata.subj) ~= subj
        issues(end+1,1) = "participant metadata does not match folder";
    end
    if string(data.metadata.digit_label) ~= digit
        issues(end+1,1) = "digit metadata does not match folder";
    end
    if double(data.metadata.force_val) ~= force
        issues(end+1,1) = "force metadata does not match folder";
    end
    if string(data.metadata.trial_type) ~= trialType
        issues(end+1,1) = "profile metadata does not match folder";
    end
    if double(data.metadata.rep) ~= rep
        issues(end+1,1) = "repetition metadata does not match filename";
    end
end
problem = strjoin(issues(strlength(issues)>0),'; ');

end
