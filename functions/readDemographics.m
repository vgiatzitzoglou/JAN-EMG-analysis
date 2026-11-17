function demographics = readDemographics(filename)
% Read only the source demographic columns; ignore any historical outcomes.
columns = ["participant_number","age_years","gender","fat_percent", ...
    "forearm_circumference_belly_cm","mgf_n"];
opts = detectImportOptions(filename,'VariableNamingRule','preserve');
assert(all(ismember(columns,string(opts.VariableNames))), ...
    'The demographic CSV is missing a required column.');
opts.SelectedVariableNames = cellstr(columns);
opts = setvartype(opts,cellstr(columns(columns~="gender")),'double');
opts = setvartype(opts,'gender','string');
demographics = readtable(filename,opts);
ids = demographics.participant_number;
assert(all(isfinite(ids) & ids>=1 & ids<=52 & ids==fix(ids)) && ...
    numel(unique(ids))==numel(ids),'Participant numbers must be unique IDs from 1 to 52.');
demographics.participant = string(compose('%02d',ids));
sex = lower(strtrim(demographics.gender));
assert(all(ismissing(sex) | ismember(sex,["male","female"])), ...
    'The source gender column must contain Male/Female, or a missing value.');
demographics.sex_male = double(sex=="male");
demographics.sex_male(ismissing(sex)) = NaN;
end
