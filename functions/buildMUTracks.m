function [membership,track_summary,edge_decisions] = ...
    buildMUTracks(units,matches,subj)
% Build tracks with direct pairwise support and at most one MU per trial.

% Each accepted detection starts as a separate node.

units = sortrows(units, ...
    {'digit','force','profile','rep','file','unit_index'});
n_nodes = height(units);
node_key = units.file + "::MU" + string(units.unit_index);

key_to_node = containers.Map(cellstr(node_key),num2cell(1:n_nodes));

n_edges = height(matches);
node_a = nan(n_edges,1);
node_b = nan(n_edges,1);

for edge = 1:n_edges
    key_a = char(matches.file_a(edge) + "::MU" + string(matches.unit_a(edge)));
    key_b = char(matches.file_b(edge) + "::MU" + string(matches.unit_b(edge)));

    node_a(edge) = key_to_node(key_a);
    node_b(edge) = key_to_node(key_b);
end

matches.node_a = node_a;
matches.node_b = node_b;
matches.original_edge_order = (1:n_edges)';
sort_keys = [-matches.similarity,-matches.map_similarity, ...
    -matches.muap_similarity,min(node_a,node_b),max(node_a,node_b)];
[~,edge_order] = sortrows(sort_keys);
matches = matches(edge_order,:);

direct_match = sparse([node_a;node_b],[node_b;node_a], ...
    ones(2*n_edges,1),n_nodes,n_nodes);

parent = (1:n_nodes)';
component_size = ones(n_nodes,1);
component_files = cell(n_nodes,1);
component_nodes = cell(n_nodes,1);
status = strings(n_edges,1);

for node = 1:n_nodes
    component_files{node} = units.file(node);
    component_nodes{node} = node;
end

for edge = 1:n_edges
    [root_a,parent] = findRoot(parent,matches.node_a(edge));
    [root_b,parent] = findRoot(parent,matches.node_b(edge));

    if root_a == root_b
        status(edge) = "supporting_cycle";
        continue
    end

    shared_trial = any(ismember(component_files{root_a}, ...
        component_files{root_b}));
    if shared_trial
        status(edge) = "rejected_same_trial_conflict";
        continue
    end

    nodes_a = component_nodes{root_a};
    nodes_b = component_nodes{root_b};
    if nnz(direct_match(nodes_a,nodes_b)) < numel(nodes_a)*numel(nodes_b)
        status(edge) = "rejected_incomplete_pair_support";
        continue
    end

    if component_size(root_a) < component_size(root_b)
        temporary_root = root_a;
        root_a = root_b;
        root_b = temporary_root;
    end

    parent(root_b) = root_a;
    component_size(root_a) = component_size(root_a) + ...
        component_size(root_b);
    component_files{root_a} = unique( ...
        [component_files{root_a};component_files{root_b}],'stable');
    component_nodes{root_a} = [component_nodes{root_a};component_nodes{root_b}];
    status(edge) = "accepted_merge";
end

matches.status = status;

roots = nan(n_nodes,1);
for node = 1:n_nodes
    [roots(node),parent] = findRoot(parent,node);
end

unique_roots = unique(roots,'stable');
n_tracks = numel(unique_roots);
track_id = strings(n_nodes,1);

for track = 1:n_tracks
    track_id(roots == unique_roots(track)) = ...
        "P" + subj + "_MU_TRACK_" + compose('%04d',track);
end

membership = addvars(units,(1:n_nodes)',track_id, ...
    'Before','participant','NewVariableNames',{'node_id','track_id'});
membership.condition = membership.digit + "_" + ...
    membership.force_label + "_" + membership.profile;
membership.track_n_nodes = zeros(n_nodes,1);
membership.track_n_trials = zeros(n_nodes,1);
membership.track_n_conditions = zeros(n_nodes,1);

for track = 1:n_tracks
    members = membership.track_id == ...
        "P" + subj + "_MU_TRACK_" + compose('%04d',track);
    membership.track_n_nodes(members) = sum(members);
    membership.track_n_trials(members) = numel(unique(membership.file(members)));
    membership.track_n_conditions(members) = ...
        numel(unique(membership.condition(members)));
end

track_a = membership.track_id(matches.node_a);
track_b = membership.track_id(matches.node_b);
edge_decisions = addvars(matches,track_a,track_b, ...
    'After','node_b','NewVariableNames',{'track_id_a','track_id_b'});
edge_decisions = sortrows(edge_decisions,'original_edge_order');

track_summary = table();

for track = 1:n_tracks
    id = "P" + subj + "_MU_TRACK_" + compose('%04d',track);
    members = membership(membership.track_id == id,:);
    accepted_edge = ismember(edge_decisions.status, ...
        ["accepted_merge","supporting_cycle"]) ...
        & edge_decisions.track_id_a == id & edge_decisions.track_id_b == id;
    evidence = edge_decisions(accepted_edge,:);

    if isempty(evidence)
        min_similarity = NaN;
        mean_similarity = NaN;
        max_similarity = NaN;
    else
        min_similarity = min(evidence.similarity,[],'omitnan');
        mean_similarity = mean(evidence.similarity,'omitnan');
        max_similarity = max(evidence.similarity,[],'omitnan');
    end

    new_row = table(string(subj),id,height(members), ...
        numel(unique(members.file)),numel(unique(members.condition)), ...
        numel(unique(members.digit)),numel(unique(members.force_label)), ...
        numel(unique(members.profile)),height(evidence), ...
        min_similarity,mean_similarity,max_similarity,height(members) == 1, ...
        'VariableNames',{'participant','track_id','n_nodes','n_trials', ...
        'n_conditions','n_digits','n_force_levels','n_profiles', ...
        'n_supporting_edges','min_similarity','mean_similarity', ...
        'max_similarity','is_singleton'});

    track_summary = [track_summary;new_row];
end
end
