function trials = loadConditionTrials(trial_rows,unit_table,channel_map)
% Load all five trials, including trials with no accepted MUs.
trial_index = unique(trial_rows(:,{'file','rep'}),'rows','stable');
trial_index = sortrows(trial_index,'rep');
trials = cell(height(trial_index),1);

for trial_number = 1:height(trial_index)
    filename = trial_index.file(trial_number);
    qc = unit_table(unit_table.file == filename,:);
    qc = sortrows(qc,'unit_index');
    data = load(filename,'Maps','MUAPs','grid_id');

    unit_index = double(qc.unit_index);
    keep = unit_index >= 1 & unit_index <= numel(data.MUAPs) ...
        & unit_index <= size(data.Maps,1) ...
        & unit_index <= numel(data.grid_id);
    unit_index = unit_index(keep);
    qc = qc(keep,:);

    trial.file = filename;
    trial.rep = trial_index.rep(trial_number);
    trial.units = unit_index;
    trial.grid_id = double(data.grid_id(unit_index(:)));
    trial.grid_id = trial.grid_id(:);
    trial.sil = double(qc.sil);
    trial.Maps = double(data.Maps(unit_index,:,:));
    trial.MUAPs = data.MUAPs(unit_index);

    valid = false(numel(unit_index),1);
    for mu = 1:numel(unit_index)
        map = squeeze(trial.Maps(mu,:,:));
        waveform = double(trial.MUAPs{mu});
        valid(mu) = isequal(size(map),size(channel_map)) ...
            && any(isfinite(map),'all') && any(isfinite(waveform),'all');
    end

    trial.units = trial.units(valid);
    trial.grid_id = trial.grid_id(valid);
    trial.sil = trial.sil(valid);
    trial.Maps = trial.Maps(valid,:,:);
    trial.MUAPs = trial.MUAPs(valid);
    trial.n_valid = numel(trial.units);
    trials{trial_number} = trial;
end
end
