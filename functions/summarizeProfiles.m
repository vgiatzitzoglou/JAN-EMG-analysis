function rows = summarizeProfiles(r)
parts = cell(3,1); k = 0;
for trialType = ["trapezium","sine05","sine15"]
    k = k+1;
    a = r.membership.profile == trialType;
    t = r.coverage.profile == trialType;
    s.participant = r.participant; s.variant = r.variant;
    s.sil_threshold = r.sil_threshold; s.profile = trialType;
    s.exported_input_detections = nnz(r.qc.profile == trialType);
    s.accepted_detections = nnz(a);
    s.usable_trials = nnz(t);
    s.trials_with_accepted_detections = nnz(t & r.coverage.accepted_detections > 0);
    s.exported_trials = nnz(t & r.coverage.exported);
    s.mean_accepted_per_usable_trial = safeRatio(nnz(a),nnz(t));
    s.detections_in_multitrial_tracks = nnz(a & r.membership.track_n_trials > 1);
    s.detections_in_singleton_tracks = nnz(a & r.membership.track_n_trials == 1);
    s.pct_detections_in_multitrial_tracks = 100*safeRatio(s.detections_in_multitrial_tracks,nnz(a));
    s.tracks_present = numel(unique(r.membership.track_id(a)));
    parts{k} = struct2table(s);
end
rows = vertcat(parts{:});
end
