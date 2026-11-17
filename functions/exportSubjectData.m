function dataset = exportSubjectData(membership,track_summary,subj)
% Collect scalar MU metadata, spike times and force traces for one participant.

membership = sortrows(membership, ...
    {'track_id','digit','force','profile','rep','file','unit_index'});
n_observations = height(membership);
files = unique(membership.file,'stable');
n_trials = numel(files);

observation_id = "P" + subj + "_OBS_" + ...
    compose('%06d',(1:n_observations)');
trial_id = strings(n_observations,1);
fs = nan(n_observations,1);
n_samples = nan(n_observations,1);
trial_duration_sec = nan(n_observations,1);
export_spike_count = nan(n_observations,1);
spike_times_sec = cell(n_observations,1);

trials = table();
force_traces = cell(n_trials,1);

for trial_number = 1:n_trials
    filename = files(trial_number);
    rows = find(membership.file == filename);
    data = load(filename,'Spikes','metadata');

    trial_fs = double(data.metadata.fs);
    trial_samples = size(data.Spikes,1);
    trial_duration = trial_samples / trial_fs;
    id = "P" + subj + "_TRIAL_" + compose('%03d',trial_number);

    force_traces{trial_number} = double(data.Spikes(:,end));

    for row = rows'
        mu = double(membership.unit_index(row));

        spike_samples = find(data.Spikes(:,mu) > 0);
        spike_times_sec{row} = (double(spike_samples) - 1) / trial_fs;
        export_spike_count(row) = numel(spike_samples);
        trial_id(row) = id;
        fs(row) = trial_fs;
        n_samples(row) = trial_samples;
        trial_duration_sec(row) = trial_duration;

    end

    trial_row = table(id,string(subj),membership.digit(rows(1)), ...
        membership.force_label(rows(1)),membership.force(rows(1)), ...
        membership.profile(rows(1)),membership.rep(rows(1)),filename, ...
        trial_fs,trial_samples,trial_duration,trial_number, ...
        'VariableNames',{'trial_id','participant','digit','force_label', ...
        'force','profile','rep','file','fs','n_samples', ...
        'duration_sec','force_trace_index'});

    trials = [trials;trial_row];
end

observations = addvars(membership,observation_id,trial_id,fs,n_samples, ...
    trial_duration_sec,export_spike_count, ...
    'Before','node_id','NewVariableNames',{'observation_id','trial_id', ...
    'fs','n_samples','trial_duration_sec','export_spike_count'});

dataset.description = ...
    "Each observations row aligns with spike_times_sec at the same index. " + ...
    "Each trials row aligns with force_traces using force_trace_index. " + ...
    "MUAPs and Maps remain in the source file identified by file and unit_index.";
dataset.observations = observations;
dataset.spike_times_sec = spike_times_sec;
dataset.trials = trials;
dataset.force_traces = force_traces;
dataset.track_summary = track_summary;
end
