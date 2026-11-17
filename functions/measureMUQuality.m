function units = measureMUQuality(trial, minSIL)
% Read quality values, active periods and recruitment times for each MU.
% Reuse the measurements across all five SIL thresholds.
data = load(trial.file,'Spikes','grid_id','SIL','CoV','metadata');
spikes = data.Spikes(:,1:end-1) > 0;
nMUs = size(spikes,2);
fs = double(data.metadata.fs);

unit_index = (1:nMUs)';
gridID = double(data.grid_id(:));
sil = double(data.SIL(:));
cov = double(data.CoV(:));
spikeCount = full(sum(spikes,1))';

minSpikes = 30;

passesSpikeCount = spikeCount >= minSpikes;
passesSIL = isfinite(sil) & sil > minSIL;
[firingThreshHz,restThresh,minActiveDuration, ...
    latestRecruitment] = getActivityRules(trial.profile,trial.force);

hasActivePeriod = false(nMUs,1);
recruitTimes = NaN(nMUs,1);
temporalQC = passesSpikeCount & passesSIL;
validMUs = find(temporalQC);

if ~isempty(validMUs)
    activePeriods = findMUActivePeriods(spikes(:,validMUs), ...
        firingThreshHz,fs,restThresh,minActiveDuration);

    for unit = 1:numel(validMUs)
        mu = validMUs(unit);
        if ~isempty(activePeriods{unit})
            hasActivePeriod(mu) = true;
            recruitTimes(mu) = min(activePeriods{unit},[],'all');
        end
    end
end

units = table( ...
    repmat(trial.participant,nMUs,1),repmat(trial.digit,nMUs,1), ...
    repmat(trial.force_label,nMUs,1),repmat(trial.force,nMUs,1), ...
    repmat(trial.profile,nMUs,1),repmat(trial.rep,nMUs,1), ...
    repmat(trial.file,nMUs,1),unit_index,gridID,sil,cov,spikeCount, ...
    hasActivePeriod, ...
    recruitTimes,repmat(latestRecruitment,nMUs,1), ...
    'VariableNames',{'participant','digit','force_label','force', ...
    'profile','rep','file','unit_index','grid_id','sil','cov', ...
    'spike_count','has_active_period','recruitment_time_sec', ...
    'latest_allowed_recruitment_sec'});
units.temporal_qc_evaluated = temporalQC;
end
