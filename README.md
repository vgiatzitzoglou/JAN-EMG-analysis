# JAN EMG analysis

MATLAB scripts for quality control, motor-unit matching across trials, track construction, SIL sensitivity and demographic analyses. This is a collaborator review version of the JAN reanalysis. It starts from prepared trial files; it does not perform EMG decomposition or manual spike editing.

## Requirements and inputs

MATLAB with Statistics and Machine Learning Toolbox. The current code has been checked in MATLAB R2026a.

Prepared files follow this layout:

```text
DATA/01/Thumb/force10/trapezium/trial01.mat
```

Each trial file must contain `Maps`, `MUAPs`, `grid_id`, `SIL`, `CoV`, `SpikeCount`, `Spikes` and `metadata` in the format supplied for this project. The defaults cover participants 01–52, Thumb/Index/Middle, force10/force20, trapezium/sine05/sine15 and five repetitions. The force levels are 10% and 20% of the finger-specific maximum voluntary force.

The optional demographic step requires a CSV with these columns:

```text
participant_number, age_years, gender, fat_percent,
forearm_circumference_belly_cm, mgf_n
```

In this dataset, `gender` records sex and `mgf_n` is maximum grip force in Newtons. Keep participant identifiers consistent between the CSV and prepared data.

## Running the analysis

Set `root_path` in `step01_setup.m` to the prepared data folder. Set `demographics_file` if running step 07. Check the participant and condition settings, then run the scripts individually, in order, in the same MATLAB workspace.

| Script | Purpose |
| --- | --- |
| `step01_setup.m` | Set input paths, conditions, participants and SIL cutoffs. |
| `step02_quality_control.m` | Check trial contents and apply MU quality and activity criteria. |
| `step03_match_motor_units.m` | Score candidate MU pairs and find mutual best matches across trials. |
| `step04_build_tracks.m` | Combine direct matches into tracks. |
| `step05_export_data.m` | Export accepted units, spikes and tracking summaries. |
| `step06_compare_sil.m` | Compare yield and tracking across the five SIL cutoffs. |
| `step07_demographics.m` | Relate detections per usable trial to body fat, forearm circumference and grip force. |

Functions are in `functions/`; step 01 adds this folder to the MATLAB path. Results are written to `results/` alongside the scripts. Use a different `output_base` for a new dataset or analysis so that previous outputs are kept separately. No script runs the remaining steps automatically.

## Analysis rules

- All five SIL cutoffs are evaluated from the same prepared inputs: **SIL >0.70, >0.75, >0.80, >0.85 and >0.90**. Equality does not pass the SIL criterion.
- MUs require at least 30 spikes and must pass the configured activity and recruitment rules. Trapezium MUs also require finite stored CoV <0.30; sine trials have no CoV exclusion.
- Matching candidates must share the original decomposition grid. Spatial maps use Pearson correlation without spatial shifting. MUAPs use normalised cross-correlation over the union of the ten strongest physical channels from each MU. The waveform score is the highest mean correlation at one common lag across contributing channels.
- Both map and waveform scores must be finite and **≥0.90**. Each match must be uniquely best in both directions; ties are rejected. The 0.95 score threshold is an additional pairwise sensitivity check.
- Global tracks use the 0.90 matches. Every pair of detections within a track must have a direct accepted match, and a track cannot contain two detections from the same trial. Accepted single detections are retained as singletons.
- Demographics use participant-level Spearman correlations, plus partial Spearman correlations adjusting for age and sex. Before-QC yield is tested once per predictor and method; after-QC yield is tested at each SIL cutoff. Outputs include uncorrected two-sided p-values and pointwise percentile confidence intervals from 2,000 paired participant bootstrap resamples. These analyses are exploratory.

A detection is one MU in one trial. It is not a unique MU across the experiment. Before-QC yield refers to the supplied prepared detections, which may already reflect upstream processing. Detections per usable trial retain usable trials with no accepted MUs; files rejected by the trial checks are excluded.

## Method origin and current limits

The prepared-data layout, electrode map and activity rules come from Renato's project code. JAN matching, track construction, summaries and demographic wrappers were developed or adapted for this reanalysis. MATLAB functions such as `corr`, `xcorr` and `partialcorr` provide the numerical operations.

The strongest-channel approach was informed by Oßwald et al., *Task-specific motor units in the extrinsic hand muscles control single- and multidigit tasks of the human hand* ([paper](https://doi.org/10.1152/japplphysiol.00911.2024)). The combination of channel selection, map gating, common-lag waveform scoring and track rules here is a project-specific method, not a direct reproduction or independently validated implementation of that paper.

The primary pipeline uses stored whole-train CoV rather than a force-defined plateau window. JAN does not recompute SIL or remove within-trial duplicates using discharge-time coincidence. There is no minimum contributing-channel count beyond a finite waveform score; selected and contributing counts are recorded. Trial checks can reject an entire file for malformed MU fields, including a non-finite SIL value. These choices should be reviewed when adapting the code to another prepared dataset.

No participant data, demographic records or results are included in this repository.
