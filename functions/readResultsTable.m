function rows = readResultsTable(filename)
% Read saved tables with explicit text types, preserving IDs such as 01.
fid = fopen(filename,'r','n','UTF-8');
cleanup = onCleanup(@() fclose(fid));
header = fgetl(fid);
clear cleanup
header = erase(string(header),string(char(65279))); % Optional UTF-8 BOM.
variable_names = strip(erase(split(header,','),'"'))';

text_names = ["participant","variant","name","status","file","file_a","file_b", ...
    "profile","digit","force_label","track_id","comparison_id", ...
    "condition_a","condition_b","condition","label","qc_reason","issue_summary", ...
    "output_folder","observation_id","trial_id", ...
    "digit_a","digit_b","force_a","force_b","profile_a","profile_b", ...
    "muap_top_channels_a","muap_top_channels_b","muap_channels_used", ...
    "muap_channels_selected", ...
    "track_id_a","track_id_b","tracking_status","tracking_folder"];
variable_types = repmat("double",size(variable_names));
variable_types(ismember(variable_names,text_names)) = "string";
opts = delimitedTextImportOptions('NumVariables',numel(variable_names));
opts.Delimiter = ',';
opts.DataLines = [2 Inf];
opts.VariableNamesLine = 1;
opts.VariableNamingRule = 'preserve';
opts.VariableNames = cellstr(variable_names);
opts.VariableTypes = cellstr(variable_types);
opts.Encoding = 'UTF-8';
opts.ImportErrorRule = 'error';
rows = readtable(filename,opts);
end
