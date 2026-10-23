# SA-MOPSO-FVML

**A Self-Adaptive MOPSO Framework with Fractional-Order Velocity Memory and Heavy-Tailed Mittag-Leffler Distribution**

MATLAB research code and supporting materials for **SA-MOPSO-FVML**, a self-adaptive multi-objective particle swarm optimization framework combining finite *fractional-inspired* velocity memory, diversity-dependent adaptation, bounded Mittag-Leffler stochastic exploration, adaptive crowding–grid archive-leader selection, and conditional stagnation-triggered mutation.

**Authors:** Esmat Sadat Alaviyan-Shahri and YangQuan Chen  
**Associated manuscript:** *A Self-Adaptive MOPSO Framework with Fractional-Order Velocity Memory and Heavy-Tailed Mittag-Leffler Distribution* (submitted to *Applied Soft Computing*).

The study includes an 11-algorithm comparison on ten benchmark functions, focused sensitivity and ablation studies, and a simulation-based marine dynamic-positioning (DP) case study involving offline PIDA-controller tuning.

> **Scope:** The finite velocity-memory update is *fractional-inspired*; it is not presented as an exact numerical solution of a fractional differential equation. The boundedness analysis does not establish global Pareto convergence. Reported optimization advantages are problem-dependent.

## 1. Repository layout

The recommended layout for the updated research release is:

```text
.
├── README.md
├── Benchmark/
│   ├── main_SA_MOPSO_FVML_benchmark_revisedv5.m
│   ├── CEC_MOFunctions.m
│   ├── Focused_Experiments/          # Final scripts and data for focused tests
│   └── results/                      # Main benchmark outputs (created on execution)
├── Statistical_Analysis/
│   └── Holm_Table14_from_saved_results.m
├── Marine_DP/
│   ├── CostFunctionDPShip.m          # Plus all simulation dependencies
│   ├── deadzoon.m                    # Error dead-zone function
│   ├── Validate_DP_Settling_Robust_800s.m
│   └── results/
│       └── SAMOPSO_FVML_Results.mat  # Original saved Pareto archive, if distributed
├── Results/                       # Curated final tables, figures, and saved data
└── Figures/                       # Selected figures from the manuscript
```

**Important:** This tree describes the *intended updated release layout*, not a claim that every file is already in the repository. Extract the final MATLAB source files from the supplied benchmark and engineering ZIP archives and place them in the corresponding directories. Keep the original function names. Upload the final scripts and saved results for the focused studies before describing those studies as fully reproducible.

## 2. Requirements

- **MATLAB**. The exact MATLAB release used for all experiments should be recorded when publishing the final code release; it has not been verified from the files available for this README.
- **Statistics and Machine Learning Toolbox** for the `ranksum` statistical tests and the Holm–Bonferroni analysis. Without `ranksum`, the main benchmark script can run but skips those statistical tests.
- The accompanying `.m` files, particularly `CEC_MOFunctions.m` for the benchmark and `CostFunctionDPShip.m` **plus its dependent functions** for the marine DP simulations.
- Sufficient time and memory for the complete 11-algorithm, ten-function, 30-run benchmark. Runtime depends on hardware and MATLAB implementation.

No additional third-party dependencies should be assumed without checking the relevant MATLAB source files.

## 3. Running the main benchmark

1. Download or clone this repository and organize the files as shown above.
2. Start MATLAB and change the working directory to `Benchmark/`.
3. Ensure `CEC_MOFunctions.m` is located in that directory or on the MATLAB path.
4. Run:

```matlab
main_SA_MOPSO_FVML_benchmark_revisedv5
```

The final main-benchmark script is configured for:

| Setting | Value |
|---|---|
| Test functions | F1–F10 (ZDT1–3, DTLZ1–4, F8–F10) |
| Compared optimizers | 11, including SA-MOPSO-FVML |
| Stochastic runs | 30 per algorithm–function combination |
| Population size | 100 |
| Maximum iterations | 250 |
| Maximum archive size | 100 |
| Initial random stream | `rng(42, 'twister')` |

The main script initializes one random stream at the beginning of the complete benchmark. **It does not reset an independent matched seed for every algorithm–problem–run combination.** Separate focused experiments may instead use paired/matched seeds.

The script creates `results/` and `figures/` relative to the **MATLAB current working directory** and saves the principal workspace to:

```text
Benchmark/results/SA_MOPSO_FVML_benchmark_results.mat
```

The MAT file includes `all_results`, `algoFields`, experiment settings, and available profiling data. The main comparison uses a common hypervolume reference point *within each benchmark problem*. Reference boxes created for separate focused experiments can differ; do not compare their raw HV values directly across experiments.

## 4. Reproducing the statistical comparison (Table 14)

The Holm script operates on the **saved 30-run main-benchmark results**; it does not rerun the optimizers.

From the `Benchmark/` working directory:

```matlab
addpath(fullfile('..', 'Statistical_Analysis'));
Holm_Table14_from_saved_results
```

It looks for `results/SA_MOPSO_FVML_benchmark_results.mat` and can prompt you to select the MAT file if it is elsewhere. The input must contain the `all_results` and `algoFields` variables for ten functions and eleven algorithms (30 finite HV values per comparison group).

Expected output files, written alongside the selected MAT file:

```text
Table14_Holm_Details.csv
Table14_Holm_Symbols.csv
Table14_Holm_Workspace.mat
Table14_Holm_Table.tex
```

The analysis applies two-sided Wilcoxon rank-sum tests with a **single Holm–Bonferroni correction across 100 comparisons**, at family-wise `alpha = 0.05`. The manuscript reports 83 nominally significant comparisons and 79 after Holm correction; these figures should be regenerated and checked against the published result files.

## 5. Focused experiments and manuscript tables

| Manuscript item | Supporting analysis or material |
|---|---|
| Tables 7–8 | Main 30-run, 11-algorithm benchmark (`main_SA_MOPSO_FVML_benchmark_revisedv5.m` and its saved MAT file) |
| Table 9 | Separate 30-run comparison with DAMOPSO and Levy-MOPSO; provide its **final dedicated source and saved results** |
| Table 10 | **Final 30-run matched-seed** hybrid/crowding/grid leader-selection experiment; provide its dedicated final source and saved results |
| Table 11 | Controlled stagnation-mutation ON/OFF experiment |
| Table 12 | Finite-memory-depth sensitivity (`L = 2, 3, 4`) |
| Table 13 | Mittag-Leffler sample transformation sensitivity (Q95, maximum, logarithmic, sigmoid) |
| Table 14 | Holm-adjusted HV comparison (`Holm_Table14_from_saved_results.m`) |
| Table 15 | Runtime decomposition collected during the 30-run main benchmark |
| Tables 16–17 | Marine DP controller gains and 400-s tracking/actuation diagnostics |
| Table 18 | Extended 800-s marine DP horizontal tracking-error validation |

**Reproduction warning for Table 10:** In the provided `main_SA_MOPSO_FVML_benchmark_revisedv5.m`, the optional `runHybridLeaderAblation` flag is disabled and `hybridLeaderRuns` is set to **10**. **Table 10 in the revised manuscript reports 30 matched-seed runs.** Do not use that disabled 10-run configuration to claim reproduction of Table 10. Publish and use the actual final 30-run experiment and its corresponding result files.

Other optional experiment switches in the main script are disabled for the primary benchmark. Run focused analyses separately and report their settings and random-seed protocols rather than combining their HV values with the main benchmark.

## 6. Marine dynamic-positioning (DP) experiment

The engineering study uses SA-MOPSO-FVML for **offline** optimization of a fixed-structure PIDA controller in a simulated marine DP system. To reproduce it, place `CostFunctionDPShip.m`, all functions called by it, the controller code, and the relevant model/disturbance files in `Marine_DP/` (or add their actual directories to the MATLAB path).

### Error dead zone

The implemented `deadzoon.m` function zeroes **tracking-error components** whose magnitudes are strictly below the specified channel thresholds:

| Channel | Error dead-zone threshold |
|---|---|
| Surge | `abs(error) < 0.5 m` |
| Sway | `abs(error) < 0.3 m` |
| Yaw | `abs(error) < 0.5 deg` |

This is an **error-signal dead zone**, not a statement that thruster commands or physical actuator outputs are necessarily zero within the band. It is intended to limit unnecessary corrective activity in response to small deviations.

### Extended-horizon verification (Table 18)

From the `Marine_DP/` working directory, with all dependencies on the MATLAB path:

```matlab
Validate_DP_Settling_Robust_800s
```

The script runs **ten independent 800-s simulations per scenario**, holds the PIDA gains fixed, and uses a **60-s post-entry observation requirement** for settling-band verification. It evaluates observer-based tracking information. The principal outputs are written under:

```text
Marine_DP/results/DP_Settling_Robust_800s/
```

including:

```text
DP_per_seed_400prefix_800_bands.csv
DP_summary_400prefix_800_bands.csv
DP_repeatability_800s.csv
DP_full_validation_800s.mat
```

**Controller-gain provenance is essential:** The validation script looks for `SAMOPSO_FVML_Results.mat` containing the original optimized Pareto archive (`Pareto_SAMOPSO`). If it cannot find the archive or a previously supplied exact controller vector, it falls back to *rounded manuscript gains* and issues a warning. **Runs using rounded fallback gains must not be presented as exact reproductions of the paper's reported controller validation.**

The manuscript's extended evaluation reports residual **observer-based** horizontal tracking errors under simulated conditions. These results should not be interpreted as compliance with a universal or mission-specific DP operational standard.

## 7. Reproducibility checklist before a public release

- [ ] Include the exact final benchmark `.m` files and `CEC_MOFunctions.m`.
- [ ] Include the source scripts and archived outputs actually used for the 30-run leader ablation, the DAMOPSO comparison, and the remaining focused tests.
- [ ] Include the exact PIDA gain archive and every `CostFunctionDPShip.m` dependency used for Table 18.
- [ ] Ensure `deadzoon.m` is the same version used in the reported simulation.
- [ ] Include the saved MAT files and machine-readable tables needed to verify numerical results without rerunning all optimization experiments.
- [ ] Confirm the MATLAB version and toolboxes and test the documented commands in a clean MATLAB working directory.
- [ ] Remove local absolute paths, confidential data, duplicate temporary outputs, and third-party files not licensed for redistribution.
- [ ] Specify a software license **only if** the authors intend to grant those reuse permissions.

## 8. Citation

If you use the code or results, please cite:

> E. S. Alaviyan-Shahri and Y. Chen, “A Self-Adaptive MOPSO Framework with Fractional-Order Velocity Memory and Heavy-Tailed Mittag-Leffler Distribution,” manuscript submitted to *Applied Soft Computing*.

Please update this citation with the final publication details and DOI when available.

## 9. Contact

**Esmat Sadat Alaviyan-Shahri**  
Department of Electrical and Computer Engineering, University of Gonabad, Iran.

For scientific questions or reproducibility concerns, please open a GitHub issue in this repository.
