%% Read trial files and apply the revised MU selection rules
% Require at least 30 spikes and SIL above the chosen cutoff.
% Apply CoV <0.30 only to trapezium; sine firing rate varies with the force cycle.

required_variables = ["Maps","MUAPs","grid_id","SIL","CoV", ...
    "SpikeCount","Spikes","metadata"];

for s = 1:length(subjects)
    subj = subjects(s);
    disp(strcat("Checking MUs for subject ",subj));
    output_path = fullfile(output_base,"participant_" + subj);
    mkdir(output_path);

    % Check the available trial files
    trial_rows = cell(length(forces)*length(trialTypes)*length(digit_labels)*reps,1);
    n = 0;
    for f = 1:length(forces)
        for type = 1:length(trialTypes)
            for d = 1:length(digit_labels)
                for t = 1:reps
                    force_label = strcat("force",forces(f));
                    file_path = fullfile(root_path,subj,digit_labels(d), ...
                        force_label,trialTypes(type),sprintf('trial%02d.mat',t));
                    n = n + 1;
                    trial_rows{n} = inspectTrial(file_path,subj,digit_labels(d), ...
                        force_label,str2double(forces(f)),trialTypes(type),t,required_variables);
                end
            end
        end
    end
    trial_info = vertcat(trial_rows{:});
    trial_info = sortrows(trial_info,{'participant','digit','force','profile','rep'});
    writetable(trial_info,fullfile(output_path,'trial_inventory.csv'));
    writetable(trial_info(trial_info.has_issue,:),fullfile(output_path,'issues.csv'));
    writetable(summarizeTrialFiles(trial_info), ...
        fullfile(output_path,'trial_inventory_summary.csv'));
    valid_trials = trial_info(trial_info.file_exists & trial_info.load_ok & ~trial_info.has_issue,:);
    if isempty(valid_trials)
        error('JAN:NoUsableTrials','Participant %s has no usable trials; check the data folder and trial inventory.',subj);
    end

    % Measure each MU once for all SIL cutoffs
    mu_rows = cell(height(valid_trials),1);
    for t = 1:height(valid_trials)
        mu_rows{t} = measureMUQuality(valid_trials(t,:),min(sil_thresholds));
    end
    mu_data = vertcat(mu_rows{:});
    mu_data = sortrows(mu_data,{'participant','digit','force','profile','rep','unit_index'});

    % Apply QC at each SIL cutoff
    for v = 1:length(sil_thresholds)
        units = checkValidMUs(mu_data,sil_thresholds(v));
        variant_path = fullfile(output_path,sprintf('sil%03d',round(100*sil_thresholds(v))));
        mkdir(variant_path);
        writetable(units,fullfile(variant_path,'mu_qc.csv'));
        writetable(summarizeTrialQC(units),fullfile(variant_path,'trial_qc_summary.csv'));
        writetable(summarizeSubjectQC(units),fullfile(variant_path,'participant_qc_summary.csv'));
    end
end
