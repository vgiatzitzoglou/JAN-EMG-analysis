function conditions = makeConditions(digits,forces,trialTypes)
% Define the condition labels in digit, force and profile order.
conditions = table();
for digit = digits
    for level = forces
        force_label = "force"+level;
        force = str2double(level);
        for trialType = trialTypes
            label = digit+"_"+force_label+"_"+trialType;
            row = table(digit,force_label,force,trialType,label, ...
                'VariableNames',{'digit','force_label','force','profile','label'});
            conditions = [conditions;row];
        end
    end
end
end
