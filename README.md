SA-MOPSO-FVML: Self-Adaptive Multi-Objective Particle Swarm Optimization with Fractional Velocity Memory and Mittag-Leffler Exploration

This repository contains the MATLAB source code for the SA-MOPSO-FVML algorithm and its benchmark comparison framework for multi-objective optimization problems.

SA-MOPSO-FVML is a self-adaptive multi-objective particle swarm optimization method that combines:

- adaptive fractional velocity memory,
- bounded Mittag-Leffler-uniform tempered stochastic exploration,
- hybrid archive leader selection using crowding distance and grid-based sparse-region pressure,
- stagnation-triggered Mittag-Leffler mutation,
- external nondominated archive management.

The code is designed to reproduce the benchmark comparison reported in the associated study.

---

## Repository Contents

The recommended repository structure is:

```text
A-Self-Adaptive-MOPSO-Using-Fractional-Velocity-Memory-and-Mittag-Leffler-Exploration/
│
├── README.md
├── LICENSE
├── .gitignore
├── main_SA_MOPSO_FVML_benchmark.m
├── CEC_MOFunctions.m
│
├── results/
│   └── .gitkeep
│
└── figures/
    └── .gitkeep

The previous ZIP archive, if present in the repository, is retained only as an older uploaded archive. For reproducing the results, please use the MATLAB source files directly, especially:

main_SA_MOPSO_FVML_benchmark.m
CEC_MOFunctions.m
Main File

The main script is:

main_SA_MOPSO_FVML_benchmark.m

This script performs the full benchmark comparison, computes performance metrics, performs statistical testing when the required MATLAB toolbox is available, generates Pareto-front visualizations, and saves the complete results.

Required Files

The code requires the benchmark function file:

CEC_MOFunctions.m

This file must be placed in the same folder as the main script or added to the MATLAB path.

MATLAB Requirements

Required:

MATLAB

Required source file:

CEC_MOFunctions.m

Optional:

Statistics and Machine Learning Toolbox

The Statistics and Machine Learning Toolbox is needed only for the Wilcoxon rank-sum test through MATLAB's ranksum function. If this toolbox is not available, the optimization and metric calculations can still be executed, but the statistical significance test should be skipped or disabled.

Benchmark Problems

The framework evaluates ten multi-objective benchmark functions.

Function	Problem	Number of Objectives
F1	ZDT1	2
F2	ZDT2	2
F3	ZDT3	2
F4	DTLZ1	3
F5	DTLZ2	3
F6	DTLZ3	3
F7	DTLZ4	3
F8	Convex-Concave	2
F9	Rosenbrock-MO	2
F10	Rastrigin-MO	2

For F1-F7, analytical or reference Pareto fronts are used for IGD calculation. For F8-F10, IGD is not reported because no analytical Pareto front is provided in the current implementation.

Compared Algorithms

The benchmark framework compares the proposed method with several MOPSO-family and swarm-based variants:

Algorithm	Description
SA-MOPSO-FVML	Proposed adaptive MOPSO with fractional velocity memory and Mittag-Leffler exploration
Classical-MOPSO	Classical multi-objective PSO with linearly decreasing inertia
MOPSO-CD	MOPSO with crowding-distance-based archive leader selection
MOPSO-FM	Ablation variant using fractional velocity memory only
MOPSO-ML	Ablation variant using Mittag-Leffler-uniform stochastic coefficients only
MOPSO-Grid	Ablation variant using grid-based leader selection only
MOFA	Multi-objective Firefly Algorithm
MOABC	Multi-objective Artificial Bee Colony
Default Experimental Configuration

The default experimental setting is:

test_functions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

n_runs = 30;
popSize = 100;
maxIter = 250;
archiveSize = 100;

A fixed random seed is used for reproducibility:

rng(42, 'twister');
How to Run
Download or clone this repository.
Open MATLAB.
Set the repository folder as the current MATLAB working directory.
Make sure CEC_MOFunctions.m is in the same folder or on the MATLAB path.
Run:
main_SA_MOPSO_FVML_benchmark

Depending on the system hardware, the full benchmark with 10 functions, 8 algorithms, and 30 independent runs may require a noticeable amount of computation time.

Output Files

The script automatically creates the following folders if they do not already exist:

results/
figures/

The complete benchmark results are saved as:

results/SA_MOPSO_FVML_benchmark_results.mat

The saved .mat file contains:

all_results
statistical_results
test_functions
algorithms
algoFields
n_runs
popSize
maxIter
archiveSize
Performance Metrics

The following performance indicators are computed:

Metric	Meaning
HV	Hypervolume; larger values indicate better convergence and diversity
IGD	Inverted Generational Distance; smaller values indicate better closeness to the reference Pareto front
SP	Spacing metric; smaller values generally indicate more uniform solution distribution
Time	Mean computational time per run
Hypervolume Calculation

Hypervolume is computed for minimization problems using a common reference point for each benchmark function.

For each function, the common hypervolume reference point is constructed from the union of all objective vectors obtained by all algorithms and all independent runs. The same reference point is then used for all algorithms on that benchmark function.

This avoids the unfair situation where each algorithm is evaluated using its own reference point. However, the resulting HV values should be interpreted relative to the empirical common reference box used in this implementation.

IGD Calculation

For F1-F7, IGD is computed using analytical or generated reference Pareto fronts.

For F8-F10, the current implementation returns NaN for IGD because no analytical Pareto front is available in the benchmark implementation.

Statistical Testing

The code uses the Wilcoxon rank-sum test to compare the proposed SA-MOPSO-FVML algorithm against the other algorithms based on HV values.

This test requires MATLAB's ranksum function from the Statistics and Machine Learning Toolbox.

If this toolbox is not available, users can still run the optimization and metric calculations, but the statistical testing section should be skipped.

Reproducibility

The code uses a fixed random seed:

rng(42, 'twister');

This improves reproducibility across repeated executions in the same MATLAB environment. Minor numerical differences may still occur across MATLAB versions or operating systems.

Notes for Users
Keep CEC_MOFunctions.m in the same folder as the main script.
Do not remove the results/ folder if you want saved .mat output files.
Do not upload large generated .mat files unless needed.
For fast testing, reduce n_runs, maxIter, or use a smaller subset of test_functions.
For final paper-level results, use the default setting with 30 independent runs.

Example quick test configuration:

test_functions = [1, 2, 3];
n_runs = 3;
popSize = 50;
maxIter = 50;
archiveSize = 50;
GitHub Notes

If an older ZIP file exists in the repository, it is kept only for archival purposes. The recommended files for running the current version are the MATLAB source files directly.

Recommended .gitignore content:

*.asv
*.fig
*.mat
*.mex*
*.slxc

results/*.mat
figures/*.fig

If you want GitHub to keep empty folders such as results/ and figures/, place an empty .gitkeep file inside each folder.

Citation

If you use this code in your research, please cite the associated paper or project:

E. S. Alaviyan Shahri, SA-MOPSO-FVML: A Self-Adaptive Multi-Objective Particle Swarm Optimization Using Fractional Velocity Memory and Mittag-Leffler Exploration, 2025.

Repository:

https://github.com/alaviyan-dr/A-Self-Adaptive-MOPSO-Using-Fractional-Velocity-Memory-and-Mittag-Leffler-Exploration
Data Availability

Data and source code supporting the findings of this study are available at the following GitHub repository:

https://github.com/alaviyan-dr/A-Self-Adaptive-MOPSO-Using-Fractional-Velocity-Memory-and-Mittag-Leffler-Exploration
License

Please specify the license before public release.

Recommended option:

MIT License

The MIT License allows others to use, modify, and distribute the code, provided that the copyright notice and license text are retained.
