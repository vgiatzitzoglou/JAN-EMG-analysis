function score = compareMaps(map_a,map_b)
% Pearson correlation between the two spatial amplitude maps.
x = double(map_a(:));
y = double(map_b(:));
valid = isfinite(x) & isfinite(y);
score = NaN;
if nnz(valid)<3 || std(x(valid))==0 || std(y(valid))==0
    return
end
score = corr(x(valid),y(valid),'Type','Pearson');
end
