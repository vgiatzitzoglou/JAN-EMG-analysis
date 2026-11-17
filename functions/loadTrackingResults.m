function r = loadTrackingResults(root,subj,variant,threshold)
r.participant = subj;
r.variant = variant;
r.sil_threshold = threshold;
inventory = readResultsTable(fullfile(fileparts(root),'trial_inventory.csv'));
r.trials = inventory(inventory.file_exists & inventory.load_ok & ~inventory.has_issue,:);
r.qc = readResultsTable(fullfile(root,'mu_qc.csv'));
r.accepted = r.qc(logical(r.qc.valid_after_qc),:);
r.accepted_keys = r.accepted.file + "::MU" + string(r.accepted.unit_index);
r.membership = r.accepted;
r.membership.track_id = strings(height(r.accepted),1);
r.membership.track_n_trials = zeros(height(r.accepted),1);
r.tracks = table(zeros(0,1),zeros(0,1),'VariableNames',{'n_nodes','n_trials'});
r.exported_files = strings(0,1);
r.exported_spikes = 0;
r.pairs = table(strings(0,1),zeros(0,1),false(0,1),zeros(0,1), ...
    'VariableNames',{'comparison_id','n_matches','eligible','match_fraction'});
r.status = "no_accepted_detections";
if ~isempty(r.accepted)
    r.status = "tracking_and_export_complete";
    track_root = fullfile(root,'tracks');
    r.membership = readResultsTable(fullfile(track_root,'track_membership.csv'));
    r.tracks = readResultsTable(fullfile(track_root,'track_summary.csv'));
    membership_keys = r.membership.file + "::MU" + string(r.membership.unit_index);
    [~,where] = ismember(r.accepted_keys,membership_keys);
    r.membership = r.membership(where,:);
    observations = readResultsTable(fullfile(root,'export','tracked_mu_observations.csv'));
    r.exported_files = unique(observations.file);
    r.exported_spikes = sum(observations.export_spike_count);
    r.pairs = readResultsTable(fullfile(root,'matches','trial_pair_summary.csv'));
    r.pairs.eligible = r.pairs.n_valid_a > 0 & r.pairs.n_valid_b > 0;
    denominator = min(r.pairs.n_valid_a,r.pairs.n_valid_b);
    r.pairs.match_fraction = NaN(height(r.pairs),1);
    r.pairs.match_fraction(r.pairs.eligible) = ...
        r.pairs.n_matches(r.pairs.eligible)./denominator(r.pairs.eligible);
end
[~,trial_index] = ismember(r.qc.file,r.trials.file);
accepted_count = accumarray(trial_index,double(r.qc.valid_after_qc),[height(r.trials) 1]);
r.coverage = r.trials(:,{'participant','digit','force','profile','rep','file'});
r.coverage.variant = repmat(variant,height(r.coverage),1);
r.coverage.sil_threshold = repmat(threshold,height(r.coverage),1);
r.coverage.accepted_detections = accepted_count;
r.coverage.exported = ismember(r.coverage.file,r.exported_files);
end
