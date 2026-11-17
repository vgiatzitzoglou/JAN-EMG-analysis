function [firingThreshHz,restThresh,minActiveDuration, ...
    latestRecruitment] = getActivityRules(trialType,force)
if trialType == "trapezium"
    firingThreshHz = 2;
    restThresh = 0.5;
    minActiveDuration = 1;

    if force == 10
        highForceTime = 7;
    elseif force == 20
        highForceTime = 9;
    else
        error('Unexpected force level: %g',force)
    end
elseif ismember(trialType,["sine05","sine15"])
    firingThreshHz = 0;
    restThresh = 0.1;
    minActiveDuration = 0.01;
    highForceTime = 5;
else
    error('Unexpected trial profile: %s',trialType)
end

latestRecruitment = highForceTime + 2;
end
