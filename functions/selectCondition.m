function rows = selectCondition(trials,condition)
% Select every structurally valid trial available in one condition.
rows = trials(trials.digit == condition.digit ...
    & trials.force_label == condition.force_label ...
    & trials.profile == condition.profile,:);
rows = sortrows(rows,'rep');
end
