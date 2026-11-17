function matches = findMutualBestMatches(candidates,threshold)
% Keep pairs in which A and B are uniquely each other's best match.
% Reject unavailable scores before choosing the best candidate for either MU.
valid_scores = isfinite(candidates.map_similarity) & ...
    isfinite(candidates.muap_similarity) & isfinite(candidates.similarity);
candidates = candidates(valid_scores,:);
keep = false(height(candidates),1);

for row = 1:height(candidates)
    if candidates.map_similarity(row) < threshold ...
            || candidates.muap_similarity(row) < threshold
        continue
    end

    same_a = candidates.unit_a == candidates.unit_a(row);
    same_b = candidates.unit_b == candidates.unit_b(row);
    best_for_a = max(candidates.similarity(same_a),[],'omitnan');
    best_for_b = max(candidates.similarity(same_b),[],'omitnan');
    a_rows = find(same_a & candidates.similarity == best_for_a);
    b_rows = find(same_b & candidates.similarity == best_for_b);

    if isscalar(a_rows) && isscalar(b_rows) ...
            && a_rows == row && b_rows == row
        keep(row) = true;
    end
end

matches = candidates(keep,:);
end
