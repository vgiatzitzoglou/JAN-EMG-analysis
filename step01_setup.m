% Data layout: 01/Thumb/force10/trapezium/trial01.mat, etc.
% Input files: Maps, MUAPs, grid_id, SIL, CoV, SpikeCount, Spikes, metadata.
% Demographic CSV: participant_number, age_years, gender, fat_percent,
% forearm_circumference_belly_cm, mgf_n.

root_path = "";          % folder containing prepared participant folders
demographics_file = ""; % demographic CSV

script_path = fileparts(mfilename('fullpath'));
output_base = fullfile(script_path,'results'); % new folder for a new analysis
subjects = compose("%02d",1:52);
forces = ["10","20"];
digit_labels = ["Thumb","Index","Middle"];
trialTypes = ["trapezium","sine05","sine15"];
reps = 5;
sil_thresholds = [0.70 0.75 0.80 0.85 0.90];

addpath(fullfile(script_path,'functions'));
assert(isfolder(root_path),'Set root_path to the prepared data folder.');
mkdir(output_base);

