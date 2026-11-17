%% Build MU tracks from direct pairwise matches
% every pair must match directly.
% A-B and B-C can share a track only if A-C also matches, avoiding indirect links.
% Each track contains at most one MU per trial; unmatched detections are singletons.
for s = 1:length(subjects)
    subj = subjects(s);
    for v = 1:length(sil_thresholds)
        variant_path = fullfile(output_base,"participant_"+subj, ...
            sprintf('sil%03d',round(100*sil_thresholds(v))));
        units = readResultsTable(fullfile(variant_path,'mu_qc.csv'));
        valid_units = units(units.valid_after_qc==1,:);
        if isempty(valid_units)
            continue
        end
        matches = readResultsTable(fullfile(variant_path,'matches','mutual_best_matches_thr090.csv'));
        [membership,track_summary,edge_decisions] = buildMUTracks(valid_units,matches,subj);
        output_path = fullfile(variant_path,'tracks');
        mkdir(output_path);
        writetable(membership,fullfile(output_path,'track_membership.csv'));
        writetable(track_summary,fullfile(output_path,'track_summary.csv'));
        writetable(edge_decisions,fullfile(output_path,'edge_decisions.csv'));
    end
end
