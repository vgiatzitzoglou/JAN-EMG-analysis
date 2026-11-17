function units = checkValidMUs(measurements, minSIL)
% Apply the revised spike count, SIL, CoV and recruitment criteria.
units = measurements;
trialTypes = string(units.profile);
isSine = ismember(trialTypes,["sine05","sine15"]);
units.minimum_sil_applied = repmat(minSIL,height(units),1);
units.minimum_total_spikes_applied = repmat(30,height(units),1);
units.cov_filter_applied = ~isSine;
units.maximum_cov_when_applied = NaN(height(units),1);
units.maximum_cov_when_applied(units.cov_filter_applied) = 0.30;
units.passes_spike_count = units.spike_count >= 30;
units.passes_sil = isfinite(units.sil) & units.sil > minSIL;
units.passes_cov_diagnostic = isfinite(units.cov) & units.cov < 0.30;
units.passes_cov = ~units.cov_filter_applied | units.passes_cov_diagnostic;
quality = units.passes_spike_count & units.passes_sil & units.passes_cov;
units.passes_recruitment = units.has_active_period & ...
    units.recruitment_time_sec <= units.latest_allowed_recruitment_sec;
units.valid_after_qc = quality & units.passes_recruitment;

reason = repmat("accepted",height(units),1);
reason(~units.passes_spike_count) = "fewer than 30 spikes";
reason(units.passes_spike_count & ~units.passes_sil) = ...
    "SIL not above " + compose('%.2f',minSIL);
reason(units.passes_spike_count & units.passes_sil & ~units.passes_cov) = ...
    "CoV not below 30 percent";
reason(quality & ~units.has_active_period) = "no active period";
reason(quality & units.has_active_period & ~units.passes_recruitment) = ...
    "recruited too late";
units.qc_reason = reason;
end
