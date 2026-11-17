function trial = inspectTrial(filename,subj,digit, ...
    force_label,force,trialType,rep,required_variables)
% Check one prepared trial file and return one inventory row.

file_exists = true;
load_ok = false;
nMUs = NaN; n_samples = NaN; fs = NaN;
n_channels = NaN; n_muap_samples = NaN;
problem = "";
try
    data = load(filename);
    load_ok = true;
    missing = setdiff(required_variables,string(fieldnames(data)));
    if isempty(missing)
        [nMUs,n_samples,fs,n_channels,n_muap_samples,problem] = ...
            checkTrialContents(data,subj,digit,force,trialType,rep,problem);
    else
        problem = "missing variables: " + strjoin(missing,',');
    end
catch exception
    file_exists = ~isempty(dir(filename));
    problem = "load failed: " + string(exception.message);
end

has_issue = strlength(problem) > 0;
if ~has_issue
    problem = "ok";
end

trial = table(subj,digit,force_label,force,trialType,rep, ...
    string(filename),file_exists,load_ok,nMUs,n_samples,fs,n_channels, ...
    n_muap_samples,has_issue,problem, ...
    'VariableNames',{'participant','digit','force_label','force', ...
    'profile','rep','file','file_exists','load_ok','n_mu','n_samples', ...
    'fs','n_channels','n_muap_samples','has_issue','issue_summary'});
end
