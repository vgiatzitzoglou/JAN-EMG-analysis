function makeConditionMatrices(summary,conditions,reps, ...
    output_path)
% Aggregate trial-pair matches into complete symmetric 18 x 18 matrices.
labels = conditions.label;
n_conditions = height(conditions);
total_matches = nan(n_conditions);
mean_matches = nan(n_conditions);
mean_tracking_rate = nan(n_conditions);
available_trial_pairs = zeros(n_conditions);
expected_trial_pairs = reps^2 * ones(n_conditions);
expected_trial_pairs(1:n_conditions+1:end) = reps*(reps-1)/2;

for a = 1:n_conditions
    for b = a:n_conditions
        selected = summary.condition_a == labels(a) ...
            & summary.condition_b == labels(b);
        values = summary(selected,:);
        available_trial_pairs(a,b) = height(values);
        available_trial_pairs(b,a) = available_trial_pairs(a,b);

        if isempty(values)
            continue
        end

        total_matches(a,b) = sum(values.n_matches);
        mean_matches(a,b) = mean(values.n_matches);
        mean_tracking_rate(a,b) = mean(values.tracking_rate,'omitnan');
        total_matches(b,a) = total_matches(a,b);
        mean_matches(b,a) = mean_matches(a,b);
        mean_tracking_rate(b,a) = mean_tracking_rate(a,b);
    end
end

trial_pair_coverage = available_trial_pairs ./ expected_trial_pairs;

writeMatrix(total_matches,labels,fullfile(output_path, ...
    'condition_total_matches_thr090.csv'));
writeMatrix(mean_matches,labels,fullfile(output_path, ...
    'condition_mean_matches_thr090.csv'));
writeMatrix(mean_tracking_rate,labels,fullfile(output_path, ...
    'condition_mean_tracking_rate_thr090.csv'));
writeMatrix(available_trial_pairs,labels,fullfile(output_path, ...
    'condition_available_trial_pairs.csv'));
writeMatrix(expected_trial_pairs,labels,fullfile(output_path, ...
    'condition_expected_trial_pairs.csv'));
writeMatrix(trial_pair_coverage,labels,fullfile(output_path, ...
    'condition_trial_pair_coverage.csv'));

end
