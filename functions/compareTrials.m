function candidates = compareTrials(A,B,channel_map)
% Compare every same-grid MU pair from two trials.

n_pairs = 0;
for unit_a = 1:A.n_valid
    n_pairs = n_pairs + sum(B.grid_id == A.grid_id(unit_a));
end

unit_a = nan(n_pairs,1);
unit_b = nan(n_pairs,1);
gridID = nan(n_pairs,1);
similarity = nan(n_pairs,1);
map_similarity = nan(n_pairs,1);
muap_similarity = nan(n_pairs,1);
n_channels = nan(n_pairs,1);
n_selected_channels = nan(n_pairs,1);
top_channels_a = strings(n_pairs,1);
top_channels_b = strings(n_pairs,1);
channels_used = strings(n_pairs,1);
channels_selected = strings(n_pairs,1);
lag_samples = nan(n_pairs,1);
sil_a = nan(n_pairs,1);
sil_b = nan(n_pairs,1);

row = 0;
for a = 1:A.n_valid
    for b = 1:B.n_valid
        if A.grid_id(a) ~= B.grid_id(b)
            continue
        end

        row = row + 1;
        map_a = squeeze(A.Maps(a,:,:));
        map_b = squeeze(B.Maps(b,:,:));

        map_similarity(row) = compareMaps(map_a,map_b);
        [muap_similarity(row),lag_samples(row),selected,top_a,top_b,used] = ...
            compareMUAPs(A.MUAPs{a},B.MUAPs{b}, ...
            map_a,map_b,channel_map);

        unit_a(row) = A.units(a);
        unit_b(row) = B.units(b);
        gridID(row) = A.grid_id(a);
        if isfinite(map_similarity(row)) && isfinite(muap_similarity(row))
            similarity(row) = min(map_similarity(row),muap_similarity(row));
        end
        n_channels(row) = numel(used);
        n_selected_channels(row) = numel(selected);
        top_channels_a(row) = strjoin(string(top_a(:)'),';');
        top_channels_b(row) = strjoin(string(top_b(:)'),';');
        channels_used(row) = strjoin(string(used(:)'),';');
        channels_selected(row) = strjoin(string(selected(:)'),';');
        sil_a(row) = A.sil(a);
        sil_b(row) = B.sil(b);
    end
end

candidates = table(unit_a,unit_b,gridID,similarity,map_similarity, ...
    muap_similarity,n_channels,n_selected_channels,top_channels_a,top_channels_b, ...
    channels_used,channels_selected,lag_samples,sil_a,sil_b, ...
    'VariableNames',{'unit_a','unit_b','grid_id','similarity', ...
    'map_similarity','muap_similarity', ...
    'muap_n_channels_used','muap_n_channels_selected', ...
    'muap_top_channels_a','muap_top_channels_b', ...
    'muap_channels_used','muap_channels_selected', ...
    'alignment_lag_samples','sil_a','sil_b'});

candidates = sortrows(candidates,'similarity','descend');
end
