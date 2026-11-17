%% Compare the configured SIL thresholds
% Summarise MU yield, tracking, trial coverage and newly included MUs.

sil_values = sort(sil_thresholds(:),'descend');
n_variants = numel(sil_values);
variant_names = compose('sil%03d',round(100*sil_values));

for s = 1:length(subjects)
    subj = subjects(s);
    participant_path = fullfile(output_base,"participant_"+subj);

    % Load each SIL result
    results = cell(n_variants,1);
    summary_rows = cell(n_variants,1);
    profile_rows = cell(n_variants,1);
    trial_rows = cell(n_variants,1);
    for v = 1:n_variants
        variant_path = fullfile(participant_path,variant_names(v));
        results{v} = loadTrackingResults(variant_path,subj,variant_names(v),sil_values(v));
        summary_rows{v} = summarizeTracking(results{v});
        profile_rows{v} = summarizeProfiles(results{v});
        trial_rows{v} = results{v}.coverage;
    end

    % Every cutoff must describe the same prepared trial/MU inputs.
    input_columns = {'file','unit_index','grid_id','sil','cov','spike_count'};
    reference_inputs = sortrows(results{1}.qc(:,input_columns), ...
        {'file','unit_index'});
    reference_trials = sortrows(results{1}.trials,'file');
    for v = 2:n_variants
        current_inputs = sortrows(results{v}.qc(:,input_columns), ...
            {'file','unit_index'});
        assert(isequaln(reference_inputs,current_inputs) && ...
            isequaln(reference_trials,sortrows(results{v}.trials,'file')), ...
            'JAN:DifferentInputs', ...
            'SIL runs have different trial inventories or saved MU input measurements.');
        assert(all(ismember(results{v-1}.accepted_keys,results{v}.accepted_keys)), ...
            'JAN:NonNestedSIL','Accepted MU pools are not nested as SIL is lowered.');
    end

    % Use the same eligible trial pairs at every cutoff
    common_pairs = results{1}.pairs.comparison_id(results{1}.pairs.eligible);
    for v = 2:n_variants
        common_pairs = intersect(common_pairs, ...
            results{v}.pairs.comparison_id(results{v}.pairs.eligible));
    end
    for v = 1:n_variants
        pairs = results{v}.pairs;
        selected = ismember(pairs.comparison_id,common_pairs);
        row = summary_rows{v};
        row.common_eligible_pairs = nnz(selected);
        row.mean_match_pct_common_eligible_pairs = mean(pairs.match_fraction(selected),'omitnan')*100;
        row.mean_matches_common_eligible_pairs = mean(pairs.n_matches(selected),'omitnan');
        summary_rows{v} = row;
    end

    % Identify detections admitted by lowering SIL
    comparisons = nchoosek(1:n_variants,2);
    added_rows = cell(size(comparisons,1)*(numel(trialTypes)+1),1);
    n = 0;
    for c = 1:size(comparisons,1)
        for type = ["all",trialTypes]
            n = n + 1;
            added_rows{n} = compareAddedMUs(results{comparisons(c,1)}, ...
                results{comparisons(c,2)},type);
        end
    end

    summary = vertcat(summary_rows{:});
    profiles = vertcat(profile_rows{:});
    coverage = vertcat(trial_rows{:});
    added = vertcat(added_rows{:});
    output_path = fullfile(participant_path,'sil_comparison');
    mkdir(output_path);
    writetable(summary,fullfile(output_path,'sil_tracking_summary.csv'));
    writetable(profiles,fullfile(output_path,'profile_summary.csv'));
    writetable(coverage,fullfile(output_path,'trial_coverage.csv'));
    writetable(added,fullfile(output_path,'added_detection_summary.csv'));

end

disp(strcat("Analysis saved in: ",output_base));
