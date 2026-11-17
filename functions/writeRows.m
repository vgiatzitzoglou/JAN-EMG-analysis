function writeRows(rows,filename,first_write)
% Write the header on the first pair, including when its table is empty.
if first_write
    writetable(rows,filename);
elseif ~isempty(rows)
    writetable(rows,filename,'WriteMode','append','WriteVariableNames',false);
end
end
