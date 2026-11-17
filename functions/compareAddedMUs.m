function row = compareAddedMUs(reference,lower,trialType)
is_new = ~ismember(lower.accepted_keys,reference.accepted_keys);
profile_mask = true(height(lower.accepted),1);
if trialType ~= "all"
    profile_mask = lower.accepted.profile == trialType;
end
new = is_new & profile_mask;
shared = ~is_new & profile_mask;
[~,position] = ismember(lower.accepted_keys(shared),reference.accepted_keys);
old_multi = reference.membership.track_n_trials(position) > 1;
now_multi = lower.membership.track_n_trials(shared) > 1;
s.participant = lower.participant; s.profile = trialType;
s.reference_sil = reference.sil_threshold; s.lower_sil = lower.sil_threshold;
s.newly_admitted_detections = nnz(new);
s.new_detections_in_multitrial_tracks = nnz(new & lower.membership.track_n_trials > 1);
s.new_detections_in_singleton_tracks = nnz(new & lower.membership.track_n_trials == 1);
s.pct_new_detections_in_multitrial_tracks = ...
    100*safeRatio(s.new_detections_in_multitrial_tracks,nnz(new));
s.shared_detections = nnz(shared);
s.shared_multitrial_in_reference = nnz(old_multi);
s.shared_multitrial_in_lower_sil = nnz(now_multi);
s.shared_changed_singleton_to_multitrial = nnz(~old_multi & now_multi);
s.shared_changed_multitrial_to_singleton = nnz(old_multi & ~now_multi);
row = struct2table(s);
end
