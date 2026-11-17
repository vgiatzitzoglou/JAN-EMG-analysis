%% Demographic associations with MU detections per usable trial
% Predictors: body fat (%), forearm belly circumference (cm), grip force (N).
% Spearman correlations and partial Spearman correlations adjusting for age
% and sex. 
% Before-QC yield is tested once; after-QC yield is tested at each SIL cutoff.
% These are exploratory analyses with uncorrected, two-sided p-values and
% pointwise 95% paired-participant bootstrap confidence intervals.
% Muscle percentage is excluded because it was derived from body fat.
% demographicCorrelation is a local wrapper around MATLAB corr/partialcorr,
% with paired-participant bootstrap resampling for the confidence intervals.

assert(isfile(demographics_file),'Set demographics_file to the demographic CSV.');
demographics = readDemographics(demographics_file);
assert(all(ismember(string(subjects),demographics.participant)), ...
    'The demographic file must contain every selected participant.');
yield = collectParticipantYield(output_base,subjects,sil_thresholds);
data = join(yield,demographics,'Keys','participant');
data = sortrows(data,{'participant','sil_threshold'});
output_path = fullfile(output_base,'demographics');
mkdir(output_path);
writetable(data,fullfile(output_path,'participant_yield_and_demographics.csv'));

predictors = ["fat_percent","forearm_circumference_belly_cm","mgf_n"];
methods = ["Spearman","Partial Spearman adjusted for age and sex"];
rng(20261028,'twister');
n_bootstrap = 2000;
rows = cell(3*2*(1+numel(sil_thresholds)),1);
n = 0;
for cutoff = [NaN,sil_thresholds]
    if isnan(cutoff)
        current = data(data.sil_threshold==min(sil_thresholds),:);
        stage = "before_qc";
        y = current.prepared_per_usable_trial;
    else
        current = data(data.sil_threshold==cutoff,:);
        stage = "after_qc";
        y = current.accepted_per_usable_trial;
    end
    for predictor = predictors
        x = current.(predictor);
        for method = 1:2
            covariates = zeros(height(current),0);
            if method==2
                covariates = [current.age_years,current.sex_male];
            end
            result = demographicCorrelation(x,y,covariates,n_bootstrap);
            n = n+1;
            rows{n} = addvars(result,stage,cutoff,predictor,methods(method), ...
                'Before',1,'NewVariableNames', ...
                {'stage','sil_cutoff','predictor','method'});
        end
    end
end
associations = vertcat(rows{:});
writetable(associations,fullfile(output_path,'demographic_associations.csv'));
disp(associations(:,{'stage','sil_cutoff','predictor','method','n','rho','p_value'}));
