function summary = summarizeTrialFiles(trials)
% Count complete files, issues and decomposed MUs for each participant.
subjects = unique(trials.participant,'stable');
summary = table();

for subj = subjects'
    rows = trials(trials.participant == subj,:);
    new_row = table(subj,height(rows),sum(rows.file_exists), ...
        sum(rows.load_ok),sum(rows.has_issue),sum(~rows.file_exists), ...
        sum(rows.n_mu,'omitnan'),~any(rows.has_issue), ...
        'VariableNames',{'participant','expected_trials','files_found', ...
        'files_loaded','trials_with_issues','missing_files','total_mu', ...
        'no_issues'});

    summary = [summary;new_row];
end
end
