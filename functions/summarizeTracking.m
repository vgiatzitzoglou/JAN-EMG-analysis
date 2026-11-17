function row = summarizeTracking(r)
s.participant = r.participant; s.variant = r.variant; s.sil_threshold = r.sil_threshold;
s.tracking_status = r.status;
s.exported_input_detections = height(r.qc);
s.accepted_detections = height(r.accepted);
s.usable_trials = height(r.trials);
s.trials_with_accepted_detections = nnz(r.coverage.accepted_detections > 0);
s.usable_trials_without_accepted_detections = nnz(r.coverage.accepted_detections == 0);
s.exported_trials = numel(r.exported_files);
s.mean_accepted_per_usable_trial = safeRatio(height(r.accepted),height(r.trials));
s.total_tracks = height(r.tracks);
s.multitrial_tracks = nnz(r.tracks.n_trials > 1);
s.singleton_tracks = nnz(r.tracks.n_trials == 1);
s.detections_in_multitrial_tracks = nnz(r.membership.track_n_trials > 1);
s.pct_detections_in_multitrial_tracks = 100*safeRatio(s.detections_in_multitrial_tracks,height(r.accepted));
s.pct_tracks_singleton = 100*safeRatio(s.singleton_tracks,height(r.tracks));
s.median_trials_per_multitrial_track = median(r.tracks.n_trials(r.tracks.n_trials > 1),'omitnan');
s.exported_spikes = r.exported_spikes;
s.trial_pairs_summarized = height(r.pairs);
s.eligible_pairs_with_detections_both_sides = nnz(r.pairs.eligible);
s.pairwise_match_events = NaN;
if ~isempty(r.pairs)
    s.pairwise_match_events = sum(r.pairs.n_matches);
end
s.mean_matches_per_usable_trial_pair = mean(r.pairs.n_matches,'omitnan');
s.mean_match_pct_eligible_pairs = mean(r.pairs.match_fraction(r.pairs.eligible),'omitnan')*100;
s.common_eligible_pairs = 0;
s.mean_match_pct_common_eligible_pairs = NaN;
s.mean_matches_common_eligible_pairs = NaN;
row = struct2table(s);
end
