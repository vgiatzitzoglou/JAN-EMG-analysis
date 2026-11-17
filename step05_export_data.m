%% Export spike times, force traces and track membership
for s = 1:length(subjects)
    subj = subjects(s);
    for v = 1:length(sil_thresholds)
        variant_path = fullfile(output_base,"participant_"+subj, ...
            sprintf('sil%03d',round(100*sil_thresholds(v))));
        units = readResultsTable(fullfile(variant_path,'mu_qc.csv'));
        if ~any(units.valid_after_qc)
            continue
        end
        membership = readResultsTable(fullfile(variant_path,'tracks','track_membership.csv'));
        track_summary = readResultsTable(fullfile(variant_path,'tracks','track_summary.csv'));
        dataset = exportSubjectData(membership,track_summary,subj);
        output_path = fullfile(variant_path,'export');
        mkdir(output_path);
        writetable(dataset.observations,fullfile(output_path,'tracked_mu_observations.csv'));
        save(fullfile(output_path,'tracked_mu_dataset.mat'),'dataset','-v7.3');
    end
end
