function result = demographicCorrelation(x,y,z,n_bootstrap)
% Complete-case rank correlation with paired participant bootstrap resampling.
% An empty z selects Spearman; otherwise adjust for every column of z.
complete = all(isfinite([x,y,z]),2);
n_excluded = nnz(~complete);
x = x(complete); y = y(complete); z = z(complete,:);
n = numel(x);
rho = NaN; p_value = NaN;
ci_low = NaN; ci_high = NaN;
samples = NaN(n_bootstrap,1);
estimable = n>size(z,2)+2 && numel(unique(x))>1 && numel(unique(y))>1;
if ~isempty(z)
    estimable = estimable && rank([ones(n,1),tiedrank(z)])==size(z,2)+1;
end
if estimable
    if isempty(z)
        [rho,p_value] = corr(x,y,'Type','Spearman');
    else
        [rho,p_value] = partialcorr(x,y,z,'Type','Spearman');
    end
    for b = 1:n_bootstrap
        selected = randi(n,n,1);
        xb = x(selected); yb = y(selected); zb = z(selected,:);
        if numel(unique(xb))<2 || numel(unique(yb))<2
            continue
        end
        if isempty(z)
            samples(b) = corr(xb,yb,'Type','Spearman');
        elseif rank([ones(n,1),tiedrank(zb)])==size(z,2)+1
            samples(b) = partialcorr(xb,yb,zb,'Type','Spearman');
        end
    end
end
n_bootstrap_valid = nnz(isfinite(samples));
if n_bootstrap_valid>0
    interval = prctile(samples(isfinite(samples)),[2.5 97.5]);
    ci_low = interval(1); ci_high = interval(2);
end
result = table(n,n_excluded,rho,ci_low,ci_high,p_value,n_bootstrap_valid);
end
