%% Match MUs between trials at each SIL cutoff
% Both map and waveform scores must be finite and >=0.90.
% Additional pairwise matches at 0.95; global tracks use 0.90.

threshold = 0.90;
sensitivity_threshold = 0.95;
conditions = makeConditions(digit_labels,forces,trialTypes);
channel_map = getChannelMap();

% Load trial information
for s = 1:length(subjects)
    subj = subjects(s);
    participant_path = fullfile(output_base,"participant_"+subj);
    trial_table = readResultsTable(fullfile(participant_path,'trial_inventory.csv'));
    valid_trials = trial_table(trial_table.file_exists & trial_table.load_ok & ~trial_table.has_issue,:);
    condition_availability = conditions;
    condition_availability.n_valid_trials = zeros(height(conditions),1);
    for condition = 1:height(conditions)
        condition_availability.n_valid_trials(condition) = ...
            height(selectCondition(valid_trials,conditions(condition,:)));
    end
    writetable(condition_availability,fullfile(participant_path,'condition_trial_availability.csv'));

    for v = 1:length(sil_thresholds)
        variant_path = fullfile(participant_path,sprintf('sil%03d',round(100*sil_thresholds(v))));
        units = readResultsTable(fullfile(variant_path,'mu_qc.csv'));
        valid_units = units(units.valid_after_qc==1,:);
        if isempty(valid_units)
            continue
        end
        if height(valid_trials)<2
            error('JAN:InsufficientTrials', ...
                'Participant %s needs at least two usable trials for matching.',subj);
        end
        output_path = fullfile(variant_path,'matches');
        mkdir(output_path);
        candidate_file = fullfile(output_path,'candidate_scores.csv');
        match_file = fullfile(output_path,'mutual_best_matches_thr090.csv');
        sensitivity_match_file = fullfile(output_path, ...
            'mutual_best_matches_thr095.csv');
        summary_file = fullfile(output_path,'trial_pair_summary.csv');
        sensitivity_summary_file = fullfile(output_path, ...
            'trial_pair_summary_thr095.csv');

        % Compare accepted MUs
        % MATLAB nchoosek counts/lists each unique trial pair once.
        n_pairs = nchoosek(height(valid_trials),2);
        comparison_summary = cell(n_pairs,1);
        sensitivity_comparison_summary = cell(n_pairs,1);
        comparison_number = 0;

        for condition_a = 1:height(conditions)
            rows_a = selectCondition(valid_trials,conditions(condition_a,:));
            trials_a = loadConditionTrials(rows_a,valid_units,channel_map);

            for condition_b = condition_a:height(conditions)
                if condition_a == condition_b
                    trials_b = trials_a;
                    if numel(trials_a) < 2
                        trial_pairs = zeros(0,2);
                    else
                        trial_pairs = nchoosek(1:numel(trials_a),2);
                    end
                else
                    rows_b = selectCondition( ...
                        valid_trials,conditions(condition_b,:));
                    trials_b = loadConditionTrials( ...
                        rows_b,valid_units,channel_map);
                    [a,b] = ndgrid(1:numel(trials_a),1:numel(trials_b));
                    trial_pairs = [a(:),b(:)];
                end

                for pair = 1:size(trial_pairs,1)
                    comparison_number = comparison_number + 1;
                    A = trials_a{trial_pairs(pair,1)};
                    B = trials_b{trial_pairs(pair,2)};

                    % Map: Pearson corr at the same electrode positions, without shifting.
                    % MUAP: normalised xcorr allows time alignment; the final score
                    % uses the highest mean correlation at one shared lag across channels.
                    candidates = compareTrials(A,B,channel_map);
                    [candidates,comparison_id] = addComparisonInfo(candidates, ...
                        subj,conditions(condition_a,:), ...
                        conditions(condition_b,:),A,B);

                    writeRows(candidates,candidate_file,comparison_number==1);

                    % Local JAN helper: both scores must be finite and >=threshold,
                    % with each MU uniquely the other's best candidate; ties are rejected.
                    matches = findMutualBestMatches(candidates,threshold);
                    matches.threshold = repmat(threshold,height(matches),1);

                    writeRows(matches,match_file,comparison_number==1);

                    sensitivity_matches = findMutualBestMatches( ...
                        candidates,sensitivity_threshold);
                    sensitivity_matches.threshold = repmat( ...
                        sensitivity_threshold,height(sensitivity_matches),1);

                    writeRows(sensitivity_matches,sensitivity_match_file,comparison_number==1);

                    mean_similarity = mean(matches.similarity,'omitnan');
                    tracking_rate = height(matches) / ...
                        min(A.n_valid,B.n_valid);

                    new_summary = table(comparison_id,subj, ...
                        conditions.label(condition_a), ...
                        conditions.label(condition_b),A.rep,B.rep,A.file,B.file, ...
                        A.n_valid,B.n_valid,height(candidates),threshold, ...
                        height(matches),mean_similarity,tracking_rate, ...
                        'VariableNames',{'comparison_id','participant', ...
                        'condition_a','condition_b','rep_a','rep_b', ...
                        'file_a','file_b','n_valid_a','n_valid_b', ...
                        'n_candidate_pairs','threshold','n_matches', ...
                        'mean_match_similarity','tracking_rate'});

                    comparison_summary{comparison_number} = new_summary;

                    new_sensitivity_summary = new_summary;
                    new_sensitivity_summary.threshold = sensitivity_threshold;
                    new_sensitivity_summary.n_matches = height(sensitivity_matches);
                    new_sensitivity_summary.mean_match_similarity = ...
                        mean(sensitivity_matches.similarity,'omitnan');
                    new_sensitivity_summary.tracking_rate = height(sensitivity_matches) / ...
                        min(A.n_valid,B.n_valid);

                    sensitivity_comparison_summary{comparison_number} = new_sensitivity_summary;
                end
            end

            fprintf('Participant %s, SIL >%.2f: condition %d / %d\n', ...
                subj,sil_thresholds(v),condition_a,height(conditions));
        end

        % Save summaries and matrices
        comparison_summary = vertcat(comparison_summary{:});
        sensitivity_comparison_summary = vertcat(sensitivity_comparison_summary{:});
        writetable(comparison_summary,summary_file);
        writetable(sensitivity_comparison_summary,sensitivity_summary_file);

        makeConditionMatrices(comparison_summary,conditions,reps, ...
            output_path);
    end
end
