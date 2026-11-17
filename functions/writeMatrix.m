function writeMatrix(matrix,labels,filename)
% Save a labelled numeric matrix as CSV.
names = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(labels));
output = array2table(matrix,'VariableNames',cellstr(names));
output.condition = labels;
output = movevars(output,'condition','Before',1);
writetable(output,filename)
end
