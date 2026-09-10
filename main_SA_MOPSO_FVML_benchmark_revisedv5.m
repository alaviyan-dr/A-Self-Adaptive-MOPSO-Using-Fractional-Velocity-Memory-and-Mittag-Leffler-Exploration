% Comprehensive Comparison Framework for SA-MOPSO-FVML
% Includes: Performance Metrics, Statistical Tests, Visualization
%
% Author: Dr. Esmat Sadat Alaviyan Shahri
% Date: 2025
% Multi-Objective CEC benchmark functions (requires CEC_MOFunctions.m)
% Available functions: 1-10
% 1: ZDT1 (2 obj)    | 6: DTLZ3 (3 obj)
% 2: ZDT2 (2 obj)    | 7: DTLZ4 (3 obj)
% 3: ZDT3 (2 obj)    | 8: Convex-Concave (2 obj)
% 4: DTLZ1 (3 obj)   | 9: Rosenbrock MO (2 obj)
% 5: DTLZ2 (3 obj)   | 10: Rastrigin MO (2 obj)

clearvars; close all; clc;
rng(42, 'twister');

% Global objective-function evaluation counter.
% Used only for diagnostic/fairness analysis.
global FE_COUNT
FE_COUNT = 0;

outDir = fullfile(pwd, 'results');
figDir = fullfile(pwd, 'figures');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if ~exist(figDir, 'dir')
    mkdir(figDir);
end
%% Dependency check
hasRanksum = exist('ranksum', 'file') == 2;

if ~hasRanksum
    warning(['The function ranksum was not found. ', ...
             'Wilcoxon rank-sum tests require the Statistics and Machine Learning Toolbox. ', ...
             'The optimization and metric calculations will run, but statistical tests will be skipped.']);
end

if exist('CEC_MOFunctions', 'file') ~= 2
    error(['CEC_MOFunctions.m was not found. ', ...
           'Please add CEC_MOFunctions.m to the MATLAB path or the project folder.']);
end


%% ========================================================================
%  FINAL EXPERIMENTAL CONFIGURATION
%  ========================================================================
% Main benchmark configuration used for the final manuscript comparison.
%
% Benchmark functions:
%   F1  = ZDT1              (2 objectives)
%   F2  = ZDT2              (2 objectives)
%   F3  = ZDT3              (2 objectives)
%   F4  = DTLZ1             (3 objectives)
%   F5  = DTLZ2             (3 objectives)
%   F6  = DTLZ3             (3 objectives)
%   F7  = DTLZ4             (3 objectives)
%   F8  = Convex-Concave    (2 objectives)
%   F9  = Rosenbrock-MO     (2 objectives)
%   F10 = Rastrigin-MO      (2 objectives)
%
% All focused reviewer-requested ablation/sensitivity experiments were
% conducted separately and are disabled during the final benchmark.
% ========================================================================

% ------------------------------------------------------------------------
% Benchmark suite
% ------------------------------------------------------------------------

test_functions = 1:10;


% ------------------------------------------------------------------------
% Algorithms included in the final comparison
% ------------------------------------------------------------------------

algorithms = { ...
    'SA-MOPSO-FVML', ...
    'Classical-MOPSO', ...
    'MOPSO-CD', ...
    'MOPSO-FM', ...
    'MOPSO-ML', ...
    'MOPSO-Grid', ...
    'Levy-MOPSO', ...
    'NSGA-II', ...
    'MOEA-D', ...
    'MOFA', ...
    'MOABC'};

n_algorithms = numel(algorithms);

algoFields = cellfun( ...
    @matlab.lang.makeValidName, ...
    algorithms, ...
    'UniformOutput', false);


% ------------------------------------------------------------------------
% Main experimental settings
% ------------------------------------------------------------------------

% Number of independent runs
n_runs = 30;

% Population size
popSize = 100;

% Maximum number of iterations
maxIter = 250;

% Maximum external archive size
archiveSize = 100;


%% ========================================================================
%  MEMORY-DEPTH SENSITIVITY ANALYSIS
%  Reviewer 2 - Major Comment 1
%  ========================================================================
% Previously completed using L = 2, 3, and 4.
% Disabled during the final multi-algorithm benchmark.

runMemoryDepthSensitivity = false;

memoryDepths = [2, 3, 4];

% Representative benchmark problems:
% F2 = ZDT2
% F5 = DTLZ2
memorySensitivityFunctions = [2, 5];

memorySensitivityRuns = 10;


%% ========================================================================
%  HYBRID LEADER-SELECTION ABLATION
%  Reviewer 1 - Comment 2
%  ========================================================================
% Compares adaptive hybrid leader selection against pure crowding-based
% and pure grid-based leader selection.
% Disabled during the final multi-algorithm benchmark.

runHybridLeaderAblation = false;

hybridLeaderModes = { ...
    'hybrid', ...
    'crowding', ...
    'grid'};

hybridLeaderFunctions = [2, 5, 8, 9];

hybridLeaderRuns = 10;


%% ========================================================================
%  STAGNATION-TRIGGERED MUTATION ABLATION
%  Reviewer 1 - Comment 8
%  ========================================================================
% Controlled Mutation-ON versus Mutation-OFF comparison.
% Disabled during the final multi-algorithm benchmark.

runMutationAblation = false;

mutationAblationFunctions = [2, 5, 6, 9];

mutationAblationRuns = 10;


%% ========================================================================
%  MITTAG-LEFFLER NORMALIZATION SENSITIVITY
%  Reviewer 1 - Comment 5
%  ========================================================================
% Compares Q95 normalization with maximum-based normalization,
% logarithmic compression, and sigmoid compression.
% Disabled during the final multi-algorithm benchmark.

runMLNormalizationAblation = false;

mlNormalizationFunctions = [2, 3, 5, 6];

mlNormalizationModes = { ...
    'q95', ...
    'max', ...
    'log', ...
    'sigmoid'};

mlNormalizationRuns = 10;


% Results storage

all_results = struct();
%% Revision profiling storage

revision_log_all = struct();
%% ========================================================================
% Detailed Revision Analysis Logging
% Used for reviewer response:
% R1-4 : Runtime decomposition
% R2-7 : Computational overhead analysis
% R2-4 : DTLZ3 mechanism analysis
% ========================================================================

revision_log = struct();

fprintf('\n');
fprintf('====================================================\n');
fprintf('Revision analysis mode activated\n');
fprintf('Tracking:\n');
fprintf(' - Fractional memory dynamics\n');
fprintf(' - Mittag-Leffler sampling\n');
fprintf(' - Diversity calculation\n');
fprintf(' - Leader selection\n');
fprintf(' - Stagnation mutation\n');
fprintf('====================================================\n\n');


%% ========================================================================
%  RUN ALGORITHMS ON ALL TEST FUNCTIONS
%  ========================================================================

fprintf('========================================\n');
fprintf('COMPREHENSIVE ALGORITHM COMPARISON\n');
fprintf('========================================\n\n');

for func_idx = 1:length(test_functions)

    func_no = test_functions(func_idx);

    % Store the benchmark function number immediately.
    % This is used later for selecting archives and reporting results.
    all_results(func_idx).func_no = func_no;

    fprintf('Testing Function #%d...\n', func_no);
    % Determine problem characteristics
    if func_no <= 3 || func_no >= 8
        nObj = 2;
        nVar = 30;  % ZDT standard in your current framework
    else
        nObj = 3;
        if func_no == 4
            nVar = 7;   % DTLZ1
        else
            nVar = 12;  % DTLZ2-DTLZ4
        end
    end

    % Get bounds
    [varMin, varMax] = getBoundsForFunction(func_no, nVar);

    % Get true Pareto front for IGD calculation
    true_PF = getTrueParetoFront(func_no, 1000);

    % Temporary storage for all algorithms on this function
    function_results = struct();

    % This stores all objective vectors obtained for this benchmark.
    % It will be used to define one common HV reference point.
    all_objective_values = [];

    % --------------------------------------------------------------------
    % First stage: run all algorithms and store archives only
    % --------------------------------------------------------------------
    for algo_idx = 1:n_algorithms

        algo_name  = algorithms{algo_idx};
        algo_field = algoFields{algo_idx};

        fprintf('  Running %s... ', algo_name);

        Time_runs = zeros(n_runs, 1);
        Archives  = cell(n_runs, 1);
       FE_runs = zeros(n_runs, 1);
        for run = 1:n_runs
 % Reset objective-function evaluation counter for this run.
    FE_COUNT = 0;
      tRun = tic;
switch algo_name

    case 'SA-MOPSO-FVML'
        archive = run_SAMOPSO_FVML(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax);

    case 'Classical-MOPSO'
        archive = run_Classical_MOPSO(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax);

    case 'MOPSO-CD'
        archive = run_MOPSO_CD(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax);

    case 'MOPSO-FM'
        archive = run_MOPSO_FM(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax);

    case 'MOPSO-ML'
        archive = run_MOPSO_ML(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax);

    case 'MOPSO-Grid'
    archive = run_MOPSO_Grid( ...
        func_no, nVar, nObj, ...
        popSize, maxIter, archiveSize, ...
        varMin, varMax);

case 'Levy-MOPSO'
    archive = run_Levy_MOPSO( ...
        func_no, nVar, nObj, ...
        popSize, maxIter, archiveSize, ...
        varMin, varMax);

case 'NSGA-II'
    archive = run_NSGAII( ...
        func_no, nVar, nObj, ...
        popSize, maxIter, archiveSize, ...
        varMin, varMax);

case 'MOEA-D'
    archive = run_MOEAD( ...
        func_no, nVar, nObj, ...
        popSize, maxIter, archiveSize, ...
        varMin, varMax);

case 'MOFA'
        archive = run_MOFA(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax);

    case 'MOABC'
        archive = run_MOABC(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax);

    otherwise
        error('Unknown algorithm name: %s', algo_name);
end
Time_runs(run) = toc(tRun);
FE_runs(run)   = FE_COUNT;
Archives{run}  = archive;
% Store detailed profiling only for SA-MOPSO-FVML
if strcmp(algo_name, 'SA-MOPSO-FVML') && ...
        isfield(archive, 'revision_log')

    revision_log_all(func_idx).func_no = func_no;
    revision_log_all(func_idx).run(run).log = archive.revision_log;
end
            
% -------------------------------------------------------------
% Print SA-MOPSO-FVML profiling AFTER runtime measurement
% so console-output time does not contaminate algorithm runtime.
% -------------------------------------------------------------
if strcmp(algo_name, 'SA-MOPSO-FVML') && ...
        isfield(archive, 'revision_log')

    L = archive.revision_log;

    fprintf('\nSA-MOPSO-FVML Revision Analysis Summary - F%d Run %d/%d\n', ...
        func_no, run, n_runs);
    fprintf('---------------------------------------\n');

    fprintf('Memory computation time : %.6f s\n', ...
        sum(L.memory_time));

    fprintf('ML generation time      : %.6f s\n', ...
        sum(L.ML_time));

    fprintf('Diversity calculation   : %.6f s\n', ...
        sum(L.diversity_time));

    fprintf('Leader selection        : %.6f s\n', ...
        sum(L.leader_time));

    fprintf('Average pML             : %.4f\n', ...
        mean(L.pML(:)));

    fprintf('Average pMem            : %.4f\n', ...
        mean(L.pMem(:)));

    fprintf('Average pGrid           : %.4f\n', ...
        mean(L.pGrid(:)));

    fprintf('Memory activation ratio : %.2f %%\n', ...
        100 * L.memory_activation / ...
        max(1, L.total_velocity_updates));

    fprintf('Grid leader usage ratio : %.2f %%\n', ...
        100 * L.grid_activation / ...
        max(1, L.total_velocity_updates));

    fprintf('Mutation events         : %d\n', ...
        L.mutation_events);

    fprintf('Mutation overhead time  : %.6f s\n', ...
        sum(L.mutation_time));

    fprintf('---------------------------------------\n');
end


% Collect all objective vectors for common reference point
            if isfield(archive, 'F') && ~isempty(archive.F)
                all_objective_values = [all_objective_values; archive.F];
            end
        end

fprintf('Done (Avg time: %.2fs | Avg FE: %.0f)\n', ...
    mean(Time_runs), mean(FE_runs));
        function_results.(algo_field).Time     = Time_runs;
        function_results.(algo_field).Archives = Archives;
        function_results.(algo_field).FE = FE_runs;
    end

    % --------------------------------------------------------------------
    % Second stage: define ONE common HV reference point for this function
    % --------------------------------------------------------------------
    [ref_point, ideal_point] = buildCommonHVReferenceBox(all_objective_values);

    fprintf('  Common HV reference point for Function #%d: ', func_no);
    fprintf('%.4g ', ref_point);
    fprintf('\n');

    % --------------------------------------------------------------------
    % Third stage: compute metrics using the same reference point
    % --------------------------------------------------------------------
    for algo_idx = 1:n_algorithms

        algo_field = algoFields{algo_idx};

        HV_runs   = zeros(n_runs, 1);
        IGD_runs  = zeros(n_runs, 1);
        SP_runs   = zeros(n_runs, 1);

        Archives  = function_results.(algo_field).Archives;
        Time_runs = function_results.(algo_field).Time;

        for run = 1:n_runs

            archive = Archives{run};

            % HV is calculated with the same ref_point for all algorithms/runs
            HV_runs(run) = calculateHypervolumeMin(archive.F, ref_point, ideal_point);

            % IGD and SP remain as in your current framework
            IGD_runs(run) = calculateIGD(archive.F, true_PF);
            SP_runs(run)  = calculateSpacing(archive.F);
        end

        all_results(func_idx).(algo_field).HV   = HV_runs;
        all_results(func_idx).(algo_field).IGD  = IGD_runs;
        all_results(func_idx).(algo_field).SP   = SP_runs;
        all_results(func_idx).(algo_field).Time = Time_runs;
        all_results(func_idx).(algo_field).FE =  function_results.(algo_field).FE;
       % ---------------------------------------------------------------
% Store representative archives
% ---------------------------------------------------------------

% Best-HV archive is retained only for diagnostic purposes.
[~, best_idx] = max(HV_runs);

all_results(func_idx).(algo_field).BestArchive = ...
    Archives{best_idx};

% Manuscript figures use the run whose HV is closest to the
% median HV across independent runs. This avoids visually
% selecting an unusually favorable stochastic realization.
medianHV = median(HV_runs, 'omitnan');

[~, median_idx] = ...
    min(abs(HV_runs - medianHV));

all_results(func_idx).(algo_field).MedianArchive = ...
    Archives{median_idx};

all_results(func_idx).(algo_field).MedianArchiveRun = ...
    median_idx;
        all_results(func_idx).func_no = func_no;
        all_results(func_idx).HV_ref_point = ref_point;
        all_results(func_idx).HV_ideal_point = ideal_point;
    end

    fprintf('\n');
end


%% ========================================================================
%  SELECT ARCHIVES FOR ARTICLE FIGURES (ROBUST VERSION)
%  ========================================================================

saField = matlab.lang.makeValidName('SA-MOPSO-FVML');

% Show what is currently available
disp('Current test_functions = ');
disp(test_functions);

if isfield(all_results, 'func_no')
    disp('Available function numbers in all_results = ');
    disp([all_results.func_no]);
else
    disp('Warning: all_results does not contain func_no field.');
end

% Initialize archives as empty
A_ZDT3_SA  = [];
A_DTLZ1_SA = [];
A_DTLZ3_SA = [];
A_RAST_SA  = [];

% Extract only if the requested function exists
if ismember(3, test_functions)
    A_ZDT3_SA = getArchiveByTestFunctionIndex(all_results, test_functions, 3, saField);
else
    warning('ZDT3 plot skipped because Function #3 is not included in test_functions.');
end

if ismember(4, test_functions)
    A_DTLZ1_SA = getArchiveByTestFunctionIndex(all_results, test_functions, 4, saField);
else
    warning('DTLZ1 plot skipped because Function #4 is not included in test_functions.');
end

if ismember(6, test_functions)
    A_DTLZ3_SA = getArchiveByTestFunctionIndex(all_results, test_functions, 6, saField);
else
    warning('DTLZ3 plot skipped because Function #6 is not included in test_functions.');
end

if ismember(10, test_functions)
    A_RAST_SA = getArchiveByTestFunctionIndex(all_results, test_functions, 10, saField);
else
    warning('Rastrigin-MO plot skipped because Function #10 is not included in test_functions.');
end


%% ========================================================================
%  STATISTICAL ANALYSIS
%  ========================================================================

fprintf('========================================\n');
fprintf('STATISTICAL SIGNIFICANCE TESTING\n');
fprintf('========================================\n\n');

% ========================================================================
% Statistical analysis
% ========================================================================

if hasRanksum

    statistical_results = performStatisticalTests( ...
        all_results, ...
        test_functions, ...
        algoFields);

else

    statistical_results = struct();

    fprintf(['Statistical tests were skipped because ', ...
             'the MATLAB ranksum function is not available.\n']);

end

%% ========================================================================
%  GENERATE COMPREHENSIVE RESULTS
%  ========================================================================

% 1. Summary Tables
generateSummaryTables(all_results, test_functions, algoFields);

% 2. Pareto Front Visualizations
visualizeParetoFronts(all_results, test_functions, algoFields);

% 3. Statistical Comparison Plots
%plotStatisticalComparison(all_results, test_functions, algoFields, statistical_results);
% 3b. Ablation HV figure for the manuscript

%makeAblationHVFigure(all_results, test_functions);
% 4. Convergence Analysis
%plotConvergenceAnalysis(all_results, test_functions, algoFields);

% 5. Reviewer-requested memory-depth sensitivity analysis
if runMemoryDepthSensitivity

    memory_depth_results = performMemoryDepthSensitivity( ...
        memorySensitivityFunctions, ...
        memoryDepths, ...
        memorySensitivityRuns, ...
        popSize, ...
        maxIter, ...
        archiveSize, ...
        outDir);

else

    memory_depth_results = struct();

end
% 5b. Reviewer-requested hybrid leader-selection ablation
if runHybridLeaderAblation

    hybrid_leader_results = performHybridLeaderAblation( ...
        hybridLeaderFunctions, ...
        hybridLeaderModes, ...
        hybridLeaderRuns, ...
        popSize, ...
        maxIter, ...
        archiveSize, ...
        outDir);

else

    hybrid_leader_results = struct();

end
% ==============================================================
% Reviewer 1 - Comment 8
% Controlled stagnation-triggered mutation ablation
% ==============================================================

if runMutationAblation

    mutation_ablation_results = performMutationAblation( ...
        mutationAblationFunctions, ...
        mutationAblationRuns, ...
        popSize, ...
        maxIter, ...
        archiveSize, ...
        outDir);

else

    mutation_ablation_results = struct();

end

% ==============================================================
% Reviewer 1 - Comment 5
% Mittag-Leffler normalization/compression ablation
% ==============================================================

if runMLNormalizationAblation

    ml_normalization_results = performMLNormalizationAblation( ...
        mlNormalizationFunctions, ...
        mlNormalizationModes, ...
        mlNormalizationRuns, ...
        popSize, ...
        maxIter, ...
        archiveSize, ...
        outDir);

else

    ml_normalization_results = struct();

end
% 6. Computational Complexity
analyzeComputationalComplexity(all_results, test_functions, algoFields);
% 7. Detailed revision profiling summary
revision_summary = printRevisionProfilingSummary( ...
    revision_log_all, all_results, test_functions);

fprintf('\n========================================\n');
fprintf('ALL ANALYSES COMPLETED!\n');
fprintf('========================================\n');
%% Save complete results
save(fullfile(outDir, 'SA_MOPSO_FVML_benchmark_results.mat'), ...
    'all_results', ...
    'revision_log_all', ...
    'revision_summary', ...
  'memory_depth_results', ...
'hybrid_leader_results', ...
'mutation_ablation_results', ...
'statistical_results', ...
    'test_functions', ...
    'algorithms', ...
    'algoFields', ...
    'n_runs', ...
    'popSize', ...
    'maxIter', ...
    'archiveSize');

fprintf('\nResults saved to:\n%s\n', ...
    fullfile(outDir, 'SA_MOPSO_FVML_benchmark_results.mat'));
if ~isempty(A_ZDT3_SA)
    figure('Position',[100 100 500 420]);
    scatter(A_ZDT3_SA.F(:,1), A_ZDT3_SA.F(:,2), 35, 'filled');
    xlabel('$f_1$','Interpreter','latex');
    ylabel('$f_2$','Interpreter','latex');
    title('(a) ZDT3 -- Disconnected Pareto Front','FontWeight','bold');
    grid on;
end
if ~isempty(A_DTLZ1_SA)
    figure('Position',[100 100 500 420]);
    scatter3(A_DTLZ1_SA.F(:,1), A_DTLZ1_SA.F(:,2), A_DTLZ1_SA.F(:,3), 35, 'filled');
    xlabel('$f_1$','Interpreter','latex');
    ylabel('$f_2$','Interpreter','latex');
    zlabel('$f_3$','Interpreter','latex');
    title('(b) DTLZ1 -- Pareto Front Approximation','FontWeight','bold');
    view(135,30);
    grid on;
end

if ~isempty(A_DTLZ3_SA)
    figure('Position',[100 100 500 420]);
    scatter3(A_DTLZ3_SA.F(:,1), A_DTLZ3_SA.F(:,2), A_DTLZ3_SA.F(:,3), 28, 'filled');
    xlabel('$f_1$','Interpreter','latex');
    ylabel('$f_2$','Interpreter','latex');
    zlabel('$f_3$','Interpreter','latex');
    title('(c) DTLZ3 -- Pareto Front Approximation','FontWeight','bold');
    view(45,35);
    grid on;
end

if ~isempty(A_RAST_SA)
    figure('Position',[100 100 500 420]);
    scatter(A_RAST_SA.F(:,1), A_RAST_SA.F(:,2), 35, 'filled');
    xlabel('$f_1$','Interpreter','latex');
    ylabel('$f_2$','Interpreter','latex');
    title('(d) Rastrigin-MO -- Pareto Front Approximation','FontWeight','bold');
    grid on;
end

%% ========================================================================
%  ALGORITHM IMPLEMENTATIONS
%  ========================================================================

function archive = run_SAMOPSO_FVML(func_no, nVar, nObj, ...
    popSize, maxIter, archiveSize, varMin, varMax, ...
    memoryDepth, leaderMode, mutationEnabled, mlNormMode)%RUN_SAMOPSO_FVML
% Adaptive SA-MOPSO-FVML:
%   1) Fractional velocity memory is activated adaptively, not permanently.
%   2) Mittag-Leffler-uniform mixture remains the main exploration mechanism.
%   3) Leader selection switches probabilistically between crowding-based
%      and grid-based archive leaders.
%   4) No ASF/convergence leader is used in the final version.
%   5) Stagnation-triggered Mittag-Leffler mutation is preserved as an
%      escape operator.
 %% ---------------------------------------------------------------
    %  Optional memory-depth parameter
    %  ---------------------------------------------------------------

    % Standard SA-MOPSO-FVML uses the four-term memory structure.
    % The optional argument is used only for reviewer-requested
    % truncation-depth sensitivity analysis.
    if nargin < 9 || isempty(memoryDepth)
        memoryDepth = 4;
    end

    if ~ismember(memoryDepth, [2, 3, 4])
        error('memoryDepth must be 2, 3, or 4.');
    end
    % ---------------------------------------------------------------
% Optional leader-selection mode
% ---------------------------------------------------------------
% 'hybrid'   : adaptive pGrid(t)-controlled crowding/grid selection
% 'crowding' : crowding-distance leader only
% 'grid'     : grid-based leader only
%
% The default preserves the standard SA-MOPSO-FVML implementation.

if nargin < 10 || isempty(leaderMode)
    leaderMode = 'hybrid';
end

validLeaderModes = {'hybrid', 'crowding', 'grid'};

if ~ismember(lower(leaderMode), validLeaderModes)
    error('leaderMode must be ''hybrid'', ''crowding'', or ''grid''.');
end

leaderMode = lower(leaderMode);
% ---------------------------------------------------------------
% Optional stagnation-triggered mutation switch
% ---------------------------------------------------------------
% true  : standard SA-MOPSO-FVML with stagnation-triggered ML mutation
% false : identical full framework, but mutation is disabled
%
% Default = true preserves the standard algorithm.

if nargin < 11 || isempty(mutationEnabled)
    mutationEnabled = true;
end

if ~(islogical(mutationEnabled) || ...
        (isnumeric(mutationEnabled) && isscalar(mutationEnabled)))
    error('mutationEnabled must be true or false.');
end

mutationEnabled = logical(mutationEnabled);
% ---------------------------------------------------------------
% Mittag-Leffler normalization mode
% ---------------------------------------------------------------
% q95     : proposed 95th-percentile normalization
% max     : maximum-based normalization
% log     : logarithmic compression
% sigmoid : smooth sigmoid compression
%
% Default q95 preserves the standard SA-MOPSO-FVML algorithm.

if nargin < 12 || isempty(mlNormMode)
    mlNormMode = 'q95';
end

mlNormMode = lower(string(mlNormMode));

validMLNormModes = ["q95","max","log","sigmoid"];

if ~any(mlNormMode == validMLNormModes)
    error('Unknown ML normalization mode: %s', mlNormMode);
end

mlNormMode = char(mlNormMode);
    %% ---------------------------------------------------------------
    %  Main parameters
    %  ---------------------------------------------------------------

    % Fractional memory parameters
    alpha = 0.7;
    a_param = 0.5;
    b_param = 10;

    % Acceleration coefficients
    c1 = 1.5;
    c2 = 1.5;

    % Classical inertia fallback
    w_max = 0.9;
    w_min = 0.4;

    % Mittag-Leffler exploration parameters
    ml_alpha = 0.8;       % 0 < ml_alpha <= 1
    ml_scale = 1.0;       % Scale after quantile normalization
    ml_rmax_min = 1.2;    % Mild ML bound near convergence
    ml_rmax_max = 2.2;    % Stronger ML bound during exploration/stagnation

    % ML mixture probability
    pML_min = 0.20;
    pML_max = 0.75;

    % Adaptive fractional-memory activation probability
    pMem_min = 0.20;
    pMem_max = 0.85;
    memoryDiversityTarget = 0.30;

    % Hybrid leader selection probability
    % pGrid increases when diversity is low, so sparse-region leader
    % selection helps recover Pareto-front coverage.
    pGrid_min = 0.30;
    pGrid_max = 0.75;
    gridDiversityTarget = 0.35;

    % Grid leader parameters
    nGrid = 10;
    leaderBeta = 1.5;

    % Velocity control
    chi_v = 0.88;
    vmaxRatio = 0.40;

    % Stagnation-triggered ML mutation
    stallLimit = 10;
    mutationRate = 0.08;
    sigmaMax = 0.06;
    sigmaMin = 0.01;

    %% ---------------------------------------------------------------
    %  Initialization
    %  ---------------------------------------------------------------

    particle = initializeParticles(popSize, nVar, nObj, varMin, varMax, func_no);

    X = vertcat(particle.x);
    F = evaluateCECMO(X, func_no);

    archive = updateArchive([], X, F, archiveSize);

    stagnationCounter = 0;
    previousArchiveF = archive.F;

%% =====================================================
% Revision monitoring variables
% =====================================================

log.memory_time = zeros(maxIter,1);
log.ML_time = zeros(maxIter,1);
log.diversity_time = zeros(maxIter,1);
log.leader_time = zeros(maxIter,1);
log.mutation_time = zeros(maxIter,1);

log.E = zeros(maxIter,1);
log.pML = zeros(maxIter,1);
log.pMem = zeros(maxIter,1);
log.pGrid = zeros(maxIter,1);

log.stagnation = zeros(maxIter,1);
%% Actual mechanism activation counters
log.memory_activation = 0;

log.grid_activation = 0;
log.mutation_events = 0;
log.total_velocity_updates = 0;
log.memory_depth = memoryDepth;
log.leader_mode = leaderMode;
log.mutation_enabled = mutationEnabled;
log.ml_normalization_mode = mlNormMode;
    %% ---------------------------------------------------------------
    %  Main loop
    %  ---------------------------------------------------------------

    for it = 1:maxIter

        X = vertcat(particle.x);
    

        % Objective-space diversity
tDiv = tic;

E_t = computeObjectiveDiversity(F);

log.diversity_time(it) = ...
    log.diversity_time(it) + toc(tDiv);

log.E(it)=E_t;
        % Iteration factor: high at the beginning, low near the end
        iterFactor = 1 - it / maxIter;

        % Low-diversity factor: high when objective-space diversity is low
        lowDiversityForMemory = max(0, (memoryDiversityTarget - E_t) / (memoryDiversityTarget + eps));
        lowDiversityForGrid   = max(0, (gridDiversityTarget   - E_t) / (gridDiversityTarget   + eps));

        % Stagnation factor
        stagnationFactor = min(1, stagnationCounter / max(1, stallLimit));

        % Adaptive memory activation:
        % Memory is more active in early iterations, under low diversity,
        % or when the archive stagnates.
        pMem = pMem_min + (pMem_max - pMem_min) * ...
               max([0.5 * iterFactor, lowDiversityForMemory, stagnationFactor]);
        pMem = min(max(pMem, pMem_min), pMem_max);
        log.pMem(it)=pMem;
        % Adaptive ML contribution:
        % ML remains active, but becomes stronger during exploration,
        % diversity loss, or stagnation.
        pML = pML_min + (pML_max - pML_min) * ...
              max([iterFactor, 1 - E_t, stagnationFactor]);
        pML = min(max(pML, pML_min), pML_max);
        log.pML(it)=pML;
        % Adaptive ML upper bound
        ml_rmax_t = ml_rmax_min + (ml_rmax_max - ml_rmax_min) * ...
                    max([iterFactor, 1 - E_t, stagnationFactor]);
        ml_rmax_t = min(max(ml_rmax_t, ml_rmax_min), ml_rmax_max);

        % Adaptive grid-leader probability:
        % Grid leader is used more when diversity is low or archive stagnates.
        pGrid = pGrid_min + (pGrid_max - pGrid_min) * ...
                max(lowDiversityForGrid, stagnationFactor);
        pGrid = min(max(pGrid, pGrid_min), pGrid_max);
    log.pGrid(it)=pGrid;
        % Raw fractional memory coefficients
        tMem = tic;

[w1, w2, w3, w4] =  computeRawMemoryWeights(alpha, a_param, b_param, E_t);

log.memory_time(it) = log.memory_time(it) + toc(tMem);
memoryWeights = [w1, w2, w3, w4];
        % Classical inertia fallback
        w_classic = w_max - (w_max - w_min) * (it / maxIter);

        for i = 1:popSize

            %% -------------------------------------------------------
            %  Hybrid leader selection
            %  -------------------------------------------------------
            % No ideal-point or ASF convergence leader is used.
            % The leader is selected either by grid-based diversity pressure
            % or by the original crowding-distance-based selection.

tLeader = tic;

switch leaderMode

    case 'hybrid'

        if rand < pGrid
            log.grid_activation = log.grid_activation + 1;
            g = selectLeaderGrid(archive, nGrid, leaderBeta);
        else
            g = selectLeader(archive);
        end

    case 'crowding'

        % Full SA-MOPSO-FVML with crowding-distance leader only.
        % All other adaptive mechanisms remain unchanged.
        g = selectLeader(archive);

    case 'grid'

        % Full SA-MOPSO-FVML with grid-based leader only.
        % All other adaptive mechanisms remain unchanged.
        log.grid_activation = log.grid_activation + 1;
        g = selectLeaderGrid(archive, nGrid, leaderBeta);

end

log.leader_time(it) = ...
    log.leader_time(it) + toc(tLeader);

            %% -------------------------------------------------------
            %  ML-uniform stochastic coefficients
            %  -------------------------------------------------------

            u1 = rand(1, nVar);
            u2 = rand(1, nVar);
              tML = tic;

ml1 = mittagLefflerRand(ml_alpha, ml_scale, [1, nVar], ...
    'QuantileLevel', 0.95, ...
    'RMax', ml_rmax_t, ...
    'UnitInterval', false, ...
    'NormalizationMode', mlNormMode);

ml2 = mittagLefflerRand(ml_alpha, ml_scale, [1, nVar], ...
    'QuantileLevel', 0.95, ...
    'RMax', ml_rmax_t, ...
    'UnitInterval', false, ...
    'NormalizationMode', mlNormMode);
log.ML_time(it) = ...
    log.ML_time(it) + toc(tML);
            r1 = (1 - pML) .* u1 + pML .* ml1;
            r2 = (1 - pML) .* u2 + pML .* ml2;

            %% -------------------------------------------------------
            %  Adaptive velocity-memory term
            %  -------------------------------------------------------
            % Fractional memory is not always active. When inactive,
            % the algorithm falls back to classical first-order velocity.

            if rand < pMem

    log.memory_activation = log.memory_activation + 1;

    % Fractional-inspired finite-memory term.
    % Only the first memoryDepth historical velocity terms are used.
    memoryTerm = zeros(1, nVar);

    for lag = 1:memoryDepth
        memoryTerm = memoryTerm + ...
            memoryWeights(lag) * particle(i).v_hist(lag,:);
    end

else

    memoryTerm = w_classic * particle(i).v_hist(1,:);

end

            %% -------------------------------------------------------
            %  Velocity update
            %  -------------------------------------------------------

            v_new = ...
                memoryTerm + ...
                c1 .* r1 .* (particle(i).pbest - particle(i).x) + ...
                c2 .* r2 .* (g - particle(i).x);

            % Constriction is applied to the complete velocity vector,
            % not to the memory weights. This preserves the relative effect
            % of the fractional-memory terms.
            v_new = chi_v * v_new;

            % Velocity bound
            vmax = vmaxRatio * (varMax - varMin);
            v_new = max(min(v_new, vmax), -vmax);

            % Update velocity history
            particle(i).v_hist(4,:) = particle(i).v_hist(3,:);
            particle(i).v_hist(3,:) = particle(i).v_hist(2,:);
            particle(i).v_hist(2,:) = particle(i).v_hist(1,:);
            particle(i).v_hist(1,:) = v_new;

            % Position update
            particle(i).x = particle(i).x + v_new;

            % Boundary handling
            particle(i).x = max(min(particle(i).x, varMax), varMin);
        end
      log.total_velocity_updates = ...
    log.total_velocity_updates + popSize;
        %% -----------------------------------------------------------
        %  Evaluation and pbest update
        %  -----------------------------------------------------------

        X = vertcat(particle.x);
        F = evaluateCECMO(X, func_no);

        for i = 1:popSize
            [particle(i).pbest, particle(i).pbestF] = updatePersonalBestMOO( ...
                particle(i).x, F(i,:), ...
                particle(i).pbest, particle(i).pbestF, ...
                archive.F);
        end

        %% -----------------------------------------------------------
        %  Archive update and stagnation detection
        %  -----------------------------------------------------------

        archive = updateArchive(archive, X, F, archiveSize);

        if hasArchiveChanged(previousArchiveF, archive.F)
            stagnationCounter = 0;
            previousArchiveF = archive.F;
        else
            stagnationCounter = stagnationCounter + 1;
        end

        %% -----------------------------------------------------------
        %  Stagnation-triggered ML mutation
        %  -----------------------------------------------------------

if mutationEnabled && stagnationCounter >= stallLimit

    tMutation = tic;

    log.mutation_events = log.mutation_events + 1;

    [particle, F] = applyMittagLefflerMutation( ...
        particle, F, archive, func_no, ...
        varMin, varMax, ...
        ml_alpha, ml_scale, ml_rmax_t, ...
        mutationRate, sigmaMax, sigmaMin, ...
        it, maxIter, mlNormMode);

    % Mutation candidates are evaluated inside
    % applyMittagLefflerMutation. Therefore, F already corresponds
    % to the current particle positions and no full-population
    % re-evaluation is required here.
    X = vertcat(particle.x);

    archive = updateArchive(archive, X, F, archiveSize);

    previousArchiveF = archive.F;
    stagnationCounter = 0;

    log.mutation_time(it) = ...
        log.mutation_time(it) + toc(tMutation);
end
    end
    %% Store revision analysis data

archive.revision_log = log;

end
function archive = run_MOPSO_FM(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax)
%RUN_MOPSO_FM
% Ablation variant: MOPSO with fractional-inspired velocity memory only.
% No Mittag-Leffler coefficients and no grid-based leader selection.

    alpha = 0.7;
    a_param = 0.5;
    b_param = 10;

    c1 = 1.5;
    c2 = 1.5;

    chi_v = 0.90;
    vmaxRatio = 0.40;

    particle = initializeParticles( ...
    popSize, nVar, nObj, varMin, varMax, func_no);

X = vertcat(particle.x);
F = evaluateCECMO(X, func_no);

archive = updateArchive([], X, F, archiveSize);

    for it = 1:maxIter

    % F already represents the current population.
        E_t = computeObjectiveDiversity(F);

        [w1, w2, w3, w4] = computeRawMemoryWeights(alpha, a_param, b_param, E_t);

        for i = 1:popSize

            g = selectLeader(archive);

            r1 = rand(1, nVar);
            r2 = rand(1, nVar);

            v_new = ...
                w1 * particle(i).v_hist(1,:) + ...
                w2 * particle(i).v_hist(2,:) + ...
                w3 * particle(i).v_hist(3,:) + ...
                w4 * particle(i).v_hist(4,:) + ...
                c1 .* r1 .* (particle(i).pbest - particle(i).x) + ...
                c2 .* r2 .* (g - particle(i).x);

            v_new = chi_v * v_new;

            vmax = vmaxRatio * (varMax - varMin);
            v_new = max(min(v_new, vmax), -vmax);

            particle(i).v_hist(4,:) = particle(i).v_hist(3,:);
            particle(i).v_hist(3,:) = particle(i).v_hist(2,:);
            particle(i).v_hist(2,:) = particle(i).v_hist(1,:);
            particle(i).v_hist(1,:) = v_new;

            particle(i).x = particle(i).x + v_new;
            particle(i).x = max(min(particle(i).x, varMax), varMin);
        end

        F = evaluateCECMO(vertcat(particle.x), func_no);

        for i = 1:popSize
            [particle(i).pbest, particle(i).pbestF] = updatePersonalBestMOO( ...
                particle(i).x, F(i,:), ...
                particle(i).pbest, particle(i).pbestF, ...
                archive.F);
        end

        archive = updateArchive(archive, vertcat(particle.x), F, archiveSize);
    end
end
function archive = run_MOPSO_ML(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax)
%RUN_MOPSO_ML
% Ablation variant: MOPSO with bounded Mittag-Leffler-uniform mixture only.
% No fractional velocity memory and no grid-based leader selection.

    w_max = 0.9;
    w_min = 0.4;

    c1 = 1.5;
    c2 = 1.5;

    ml_alpha = 0.8;
    ml_scale = 1.0;
    ml_rmax  = 2.0;

    pML_max = 0.70;
    pML_min = 0.20;

    vmaxRatio = 0.40;

   particle = initializeParticles( ...
    popSize, nVar, nObj, varMin, varMax, func_no);

X = vertcat(particle.x);
F = evaluateCECMO(X, func_no);

archive = updateArchive([], X, F, archiveSize);

    for it = 1:maxIter

    % F already represents the current population.
        E_t = computeObjectiveDiversity(F);

        w = w_max - (w_max - w_min) * (it / maxIter);

        iterFactor = 1 - it / maxIter;
        diversityFactor = 1 - E_t;

        pML = pML_min + (pML_max - pML_min) * max(iterFactor, diversityFactor);
        pML = min(max(pML, pML_min), pML_max);

        for i = 1:popSize

            g = selectLeader(archive);

            u1 = rand(1, nVar);
            u2 = rand(1, nVar);

            ml1 = mittagLefflerRand(ml_alpha, ml_scale, [1, nVar], ...
                'QuantileLevel', 0.95, ...
                'RMax', ml_rmax, ...
                'UnitInterval', false);

            ml2 = mittagLefflerRand(ml_alpha, ml_scale, [1, nVar], ...
                'QuantileLevel', 0.95, ...
                'RMax', ml_rmax, ...
                'UnitInterval', false);

            r1 = (1 - pML) .* u1 + pML .* ml1;
            r2 = (1 - pML) .* u2 + pML .* ml2;

            v_new = ...
                w * particle(i).v_hist(1,:) + ...
                c1 .* r1 .* (particle(i).pbest - particle(i).x) + ...
                c2 .* r2 .* (g - particle(i).x);

            vmax = vmaxRatio * (varMax - varMin);
            v_new = max(min(v_new, vmax), -vmax);

            particle(i).v_hist(1,:) = v_new;

            particle(i).x = particle(i).x + v_new;
            particle(i).x = max(min(particle(i).x, varMax), varMin);
        end

        F = evaluateCECMO(vertcat(particle.x), func_no);

        for i = 1:popSize
            [particle(i).pbest, particle(i).pbestF] = updatePersonalBestMOO( ...
                particle(i).x, F(i,:), ...
                particle(i).pbest, particle(i).pbestF, ...
                archive.F);
        end

        archive = updateArchive(archive, vertcat(particle.x), F, archiveSize);
    end

end
function archive = run_MOPSO_Grid(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax)
%RUN_MOPSO_GRID
% Ablation variant: MOPSO with grid-based leader selection only.
% No fractional velocity memory and no Mittag-Leffler coefficients.

    w_max = 0.9;
    w_min = 0.4;

    c1 = 1.5;
    c2 = 1.5;

    nGrid = 10;
    leaderBeta = 1.5;

    vmaxRatio = 0.40;

    particle = initializeParticles(popSize, nVar, nObj, varMin, varMax, func_no);
    archive = updateArchive([], vertcat(particle.x), evaluateCECMO(vertcat(particle.x), func_no), archiveSize);

    for it = 1:maxIter

        w = w_max - (w_max - w_min) * (it / maxIter);

        for i = 1:popSize

            g = selectLeaderGrid(archive, nGrid, leaderBeta);

            r1 = rand(1, nVar);
            r2 = rand(1, nVar);

            v_new = ...
                w * particle(i).v_hist(1,:) + ...
                c1 .* r1 .* (particle(i).pbest - particle(i).x) + ...
                c2 .* r2 .* (g - particle(i).x);

            vmax = vmaxRatio * (varMax - varMin);
            v_new = max(min(v_new, vmax), -vmax);

            particle(i).v_hist(1,:) = v_new;

            particle(i).x = particle(i).x + v_new;
            particle(i).x = max(min(particle(i).x, varMax), varMin);
        end

        F = evaluateCECMO(vertcat(particle.x), func_no);

        for i = 1:popSize
            [particle(i).pbest, particle(i).pbestF] = updatePersonalBestMOO( ...
                particle(i).x, F(i,:), ...
                particle(i).pbest, particle(i).pbestF, ...
                archive.F);
        end

        archive = updateArchive(archive, vertcat(particle.x), F, archiveSize);
    end
end

function archive = run_Levy_MOPSO( ...
    func_no, nVar, nObj, ...
    popSize, maxIter, archiveSize, ...
    varMin, varMax)
%RUN_LEVY_MOPSO
% Controlled Levy-flight MOPSO comparator.
%
% Purpose:
%   Provides a heavy-tailed MOPSO baseline for comparison with
%   SA-MOPSO-FVML.
%
% Design principle:
%   The algorithm preserves the same basic archive-based MOPSO
%   structure as Classical-MOPSO and introduces only an additional
%   Levy-flight perturbation in the position update.
%
% This implementation is intentionally NOT called MOPSO-LFDA,
% because the published MOPSO-LFDA algorithm additionally uses
% a double-archive mechanism and a specialized leader-selection
% strategy.
%
% Levy-flight samples are generated using Mantegna's algorithm
% with beta = 1.5.

    %% ---------------------------------------------------------------
    % Classical MOPSO parameters
    % ---------------------------------------------------------------

    w_max = 0.9;
    w_min = 0.4;

    c1 = 2.0;
    c2 = 2.0;

    vmaxRatio = 0.40;

    %% ---------------------------------------------------------------
    % Levy-flight parameters
    % ---------------------------------------------------------------

    % Stable-distribution exponent.
    % beta = 1.5 is commonly used for Levy-flight search.
    levyBeta = 1.5;

    % Fixed dimensionless perturbation amplitude.
    % Kept identical for all benchmark functions.
    levyScale = 0.01;

    %% ---------------------------------------------------------------
    % Initialization
    % ---------------------------------------------------------------

    particle = initializeParticles( ...
        popSize, nVar, nObj, ...
        varMin, varMax, func_no);

    X = vertcat(particle.x);

    F = evaluateCECMO(X, func_no);

    archive = updateArchive( ...
        [], X, F, archiveSize);

    %% ---------------------------------------------------------------
    % Main optimization loop
    % ---------------------------------------------------------------

    for it = 1:maxIter

        % Classical linearly decreasing inertia weight
        w = ...
            w_max - ...
            (w_max - w_min) * ...
            (it / maxIter);

        for i = 1:popSize

            %% -------------------------------------------------------
            % Archive leader
            % -------------------------------------------------------

            g = selectLeader(archive);

            %% -------------------------------------------------------
            % Conventional PSO stochastic coefficients
            % -------------------------------------------------------

            r1 = rand(1, nVar);
            r2 = rand(1, nVar);

            %% -------------------------------------------------------
            % Classical MOPSO velocity
            % -------------------------------------------------------

            v_new = ...
                w .* particle(i).v_hist(1,:) + ...
                c1 .* r1 .* ...
                (particle(i).pbest - particle(i).x) + ...
                c2 .* r2 .* ...
                (g - particle(i).x);

            %% -------------------------------------------------------
            % Velocity bound
            % -------------------------------------------------------

            vmax = ...
                vmaxRatio .* (varMax - varMin);

            v_new = ...
                max(min(v_new, vmax), -vmax);

            %% -------------------------------------------------------
            % Levy-flight perturbation
            % -------------------------------------------------------
            % Mantegna Levy step is added in the direction defined
            % by the difference between the archive leader and the
            % current particle.
            %
            % This preserves the standard PSO velocity while adding
            % an explicitly heavy-tailed exploratory component.

            levyStep = ...
                levyFlightMantegna( ...
                    [1, nVar], levyBeta);

            levyPerturbation = ...
                levyScale .* ...
                levyStep .* ...
                (g - particle(i).x);

            %% -------------------------------------------------------
            % Position update
            % -------------------------------------------------------

            particle(i).v_hist(1,:) = v_new;

            particle(i).x = ...
                particle(i).x + ...
                v_new + ...
                levyPerturbation;

            %% -------------------------------------------------------
            % Boundary handling
            % -------------------------------------------------------

            particle(i).x = ...
                max(min(particle(i).x, varMax), varMin);

        end

        %% -----------------------------------------------------------
        % ONE population evaluation per iteration
        % ---------------------------------------------------------------

        X = vertcat(particle.x);

        F = evaluateCECMO(X, func_no);

        %% -----------------------------------------------------------
        % Personal-best update
        % -----------------------------------------------------------
        % The same dominance-only rule used by Classical-MOPSO is
        % retained so that the Levy term is the principal difference
        % between the two algorithms.

        for i = 1:popSize

            if dominates(F(i,:), particle(i).pbestF)

                particle(i).pbest = ...
                    particle(i).x;

                particle(i).pbestF = ...
                    F(i,:);

            end

        end

        %% -----------------------------------------------------------
        % Archive update
        % ---------------------------------------------------------------

        archive = updateArchive( ...
            archive, ...
            X, ...
            F, ...
            archiveSize);

    end

end

function archive = run_Classical_MOPSO(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax)
    % Classical MOPSO with linearly decreasing inertia
    
    w_max = 0.9;
    w_min = 0.4;
    c1 = 2.0;
    c2 = 2.0;
    
particle = initializeParticles(popSize, nVar, nObj, varMin, varMax, func_no);
archive = updateArchive([], vertcat(particle.x), evaluateCECMO(vertcat(particle.x), func_no), archiveSize);
    
    for it = 1:maxIter
        w = w_max - (w_max - w_min) * (it / maxIter);
        
        for i = 1:popSize
            g = selectLeader(archive);
            r1 = rand(1, nVar);
            r2 = rand(1, nVar);
            
            v_new = w*particle(i).v_hist(1,:) + ...
                    c1.*r1.*(particle(i).pbest - particle(i).x) + ...
                    c2.*r2.*(g - particle(i).x);
            
            vmax = 0.4*(varMax - varMin);
            v_new = max(min(v_new, vmax), -vmax);
            
            particle(i).v_hist(1,:) = v_new;
            particle(i).x = particle(i).x + v_new;
            particle(i).x = max(min(particle(i).x, varMax), varMin);
        end
        
        F = evaluateCECMO(vertcat(particle.x), func_no);
        for i = 1:popSize
            if dominates(F(i,:), particle(i).pbestF)
                particle(i).pbest = particle(i).x;
                particle(i).pbestF = F(i,:);
            end
        end
        
        archive = updateArchive(archive, vertcat(particle.x), F, archiveSize);
    end
end


function archive = run_MOPSO_CD(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax)
    % MOPSO with Crowding Distance but without fractional memory and ML
    
    w_max = 0.9;
    w_min = 0.4;
    c1 = 1.5;
    c2 = 1.5;
    
particle = initializeParticles(popSize, nVar, nObj, varMin, varMax, func_no);
archive = updateArchive([], vertcat(particle.x), evaluateCECMO(vertcat(particle.x), func_no), archiveSize);
    
    for it = 1:maxIter
        w = w_max - (w_max - w_min) * (it / maxIter);
        
        for i = 1:popSize
            g = selectLeader(archive);  % Using crowding distance
            r1 = rand(1, nVar);
            r2 = rand(1, nVar);
            
            v_new = w*particle(i).v_hist(1,:) + ...
                    c1.*r1.*(particle(i).pbest - particle(i).x) + ...
                    c2.*r2.*(g - particle(i).x);
            
            vmax = 0.4*(varMax - varMin);
            v_new = max(min(v_new, vmax), -vmax);
            
            particle(i).v_hist(1,:) = v_new;
            particle(i).x = particle(i).x + v_new;
            particle(i).x = max(min(particle(i).x, varMax), varMin);
        end
        
        F = evaluateCECMO(vertcat(particle.x), func_no);
        for i = 1:popSize
            if dominates(F(i,:), particle(i).pbestF)
                particle(i).pbest = particle(i).x;
                particle(i).pbestF = F(i,:);
            end
        end
        
        archive = updateArchive(archive, vertcat(particle.x), F, archiveSize);
    end
end

function archive = run_NSGAII( ...
    func_no, nVar, nObj, ...
    popSize, maxIter, archiveSize, ...
    varMin, varMax)
%RUN_NSGAII
% Standard elitist NSGA-II baseline.
%
% Main components:
%   - Fast non-dominated sorting
%   - Crowding-distance preservation
%   - Binary tournament mating selection
%   - Simulated binary crossover (SBX)
%   - Polynomial mutation
%   - Elitist parent-offspring environmental selection
%
% The external archive used elsewhere in the benchmark is NOT used to
% guide NSGA-II. The returned archive is constructed only from the final
% NSGA-II population for consistent metric evaluation.

    %% ---------------------------------------------------------------
    % Bounds
    % ---------------------------------------------------------------

    [lb, ub] = makeBoundsVectorMO( ...
        varMin, varMax, nVar);

    range = ub - lb;

    %% ---------------------------------------------------------------
    % Standard NSGA-II parameters
    % ---------------------------------------------------------------

    crossoverProbability = 0.90;

    % SBX distribution index
    etaC = 20;

    % Polynomial-mutation distribution index
    etaM = 20;

    % Expected approximately one mutated decision variable per offspring
    mutationProbability = 1 / nVar;

    %% ---------------------------------------------------------------
    % Initialization
    % ---------------------------------------------------------------

    X = lb + ...
        rand(popSize, nVar) .* range;

    F = evaluateCECMO(X, func_no);

    %% ---------------------------------------------------------------
    % Main evolutionary loop
    % ---------------------------------------------------------------

    for it = 1:maxIter

        % -----------------------------------------------------------
        % Rank and crowding distance of current parent population
        % -----------------------------------------------------------

        [rank, fronts] = ...
            nsga2FastNonDominatedSort(F);

        crowd = ...
            nsga2CrowdingDistance(F, fronts);

        % -----------------------------------------------------------
        % Generate offspring population
        % -----------------------------------------------------------

        offspringX = ...
            zeros(popSize, nVar);

        offspringCounter = 1;

        while offspringCounter <= popSize

            % Binary tournament using rank first and crowding second
            idx1 = ...
                nsga2TournamentSelection( ...
                    rank, crowd);

            idx2 = ...
                nsga2TournamentSelection( ...
                    rank, crowd);

            parent1 = X(idx1,:);
            parent2 = X(idx2,:);

            % -------------------------------------------------------
            % Simulated binary crossover
            % -------------------------------------------------------

            if rand < crossoverProbability

                [child1, child2] = ...
                    nsga2SBX( ...
                        parent1, parent2, ...
                        lb, ub, etaC);

            else

                child1 = parent1;
                child2 = parent2;

            end

            % -------------------------------------------------------
            % Polynomial mutation
            % -------------------------------------------------------

            child1 = ...
                nsga2PolynomialMutation( ...
                    child1, ...
                    lb, ub, ...
                    mutationProbability, ...
                    etaM);

            child2 = ...
                nsga2PolynomialMutation( ...
                    child2, ...
                    lb, ub, ...
                    mutationProbability, ...
                    etaM);

            offspringX(offspringCounter,:) = ...
                child1;

            offspringCounter = ...
                offspringCounter + 1;

            if offspringCounter <= popSize

                offspringX(offspringCounter,:) = ...
                    child2;

                offspringCounter = ...
                    offspringCounter + 1;

            end

        end

        %% -----------------------------------------------------------
        % ONE objective evaluation per offspring
        % ---------------------------------------------------------------

        offspringF = ...
            evaluateCECMO(offspringX, func_no);

        %% -----------------------------------------------------------
        % Elitist environmental selection
        % ---------------------------------------------------------------

        combinedX = ...
            [X; offspringX];

        combinedF = ...
            [F; offspringF];

        [X, F] = ...
            nsga2EnvironmentalSelection( ...
                combinedX, ...
                combinedF, ...
                popSize);

    end

    %% ---------------------------------------------------------------
    % Final nondominated set for benchmark reporting
    % ---------------------------------------------------------------

    archive = ...
        updateArchive( ...
            [], X, F, archiveSize);

end


function archive = run_MOEAD( ...
    func_no, nVar, nObj, ...
    popSize, maxIter, archiveSize, ...
    varMin, varMax)
%RUN_MOEAD
% Multi-Objective Evolutionary Algorithm based on Decomposition (MOEA/D).
%
% Main components:
%   - Uniformly distributed weight vectors
%   - Tchebycheff scalarizing function
%   - Weight-vector neighborhoods
%   - Neighborhood-biased mating
%   - SBX crossover
%   - Polynomial mutation
%   - Restricted neighborhood replacement
%
% The algorithm is not guided by the external MOPSO archive.
% The archive is constructed only from the final population for
% consistent benchmark reporting.
%
% One offspring is evaluated for each decomposition subproblem per
% generation, resulting in approximately the same FE budget as NSGA-II
% and the MOPSO baselines.

    %% ---------------------------------------------------------------
    % Bounds
    % ---------------------------------------------------------------

    [lb, ub] = makeBoundsVectorMO( ...
        varMin, varMax, nVar);

    range = ub - lb; %#ok<NASGU>

    %% ---------------------------------------------------------------
    % MOEA/D parameters
    % ---------------------------------------------------------------

    % Number of neighboring weight vectors
    T = min(20, popSize);

    % Probability of selecting parents from the neighborhood
    delta = 0.90;

    % Maximum number of neighboring solutions replaced by one child
    nr = 2;

    % SBX parameters
    crossoverProbability = 0.90;
    etaC = 20;

    % Polynomial mutation
    mutationProbability = 1 / nVar;
    etaM = 20;

    %% ---------------------------------------------------------------
    % Weight vectors
    % ---------------------------------------------------------------

    W = moeadGenerateWeightVectors( ...
        popSize, nObj);

    % Safety check
    if size(W,1) ~= popSize || size(W,2) ~= nObj
        error('MOEA/D weight-vector dimension mismatch.');
    end

    %% ---------------------------------------------------------------
    % Weight-vector neighborhoods
    % ---------------------------------------------------------------

    weightDistances = zeros(popSize, popSize);

    for i = 1:popSize
        diffW = W - W(i,:);
        weightDistances(i,:) = ...
            sqrt(sum(diffW.^2, 2))';
    end

    neighborhood = zeros(popSize, T);

    for i = 1:popSize

        [~, order] = ...
            sort(weightDistances(i,:), 'ascend');

        neighborhood(i,:) = ...
            order(1:T);

    end

    %% ---------------------------------------------------------------
    % Initialize population
    % ---------------------------------------------------------------

    X = ...
        lb + rand(popSize, nVar) .* (ub - lb);

    F = ...
        evaluateCECMO(X, func_no);

    % Ideal objective vector
    z = min(F, [], 1);

    %% ---------------------------------------------------------------
    % Main MOEA/D loop
    % ---------------------------------------------------------------

    for it = 1:maxIter

        % Random order avoids systematic subproblem bias.
        subproblemOrder = randperm(popSize);

        for kk = 1:popSize

            i = subproblemOrder(kk);

            %% -------------------------------------------------------
            % Mating pool
            % -------------------------------------------------------

            if rand < delta

                matingPool = ...
                    neighborhood(i,:);

            else

                matingPool = ...
                    1:popSize;

            end

            if numel(matingPool) < 2
                matingPool = 1:popSize;
            end

            parentIndices = ...
                matingPool(randperm(numel(matingPool), 2));

            parent1 = ...
                X(parentIndices(1),:);

            parent2 = ...
                X(parentIndices(2),:);

            %% -------------------------------------------------------
            % Recombination
            % -------------------------------------------------------

            if rand < crossoverProbability

                [child1, child2] = ...
                    nsga2SBX( ...
                        parent1, parent2, ...
                        lb, ub, etaC);

                % Randomly retain one of the two SBX offspring.
                if rand < 0.5
                    child = child1;
                else
                    child = child2;
                end

            else

                if rand < 0.5
                    child = parent1;
                else
                    child = parent2;
                end

            end

            %% -------------------------------------------------------
            % Polynomial mutation
            % -------------------------------------------------------

            child = ...
                nsga2PolynomialMutation( ...
                    child, ...
                    lb, ub, ...
                    mutationProbability, ...
                    etaM);

            %% -------------------------------------------------------
            % ONE objective evaluation
            % -------------------------------------------------------

            fChild = ...
                CEC_MOFunctions(child, func_no);

            %% -------------------------------------------------------
            % Update ideal point
            % -------------------------------------------------------

            z = min(z, fChild);

            %% -------------------------------------------------------
            % Candidate replacement set
            % -------------------------------------------------------

            if rand < delta

                replacementSet = ...
                    neighborhood(i,:);

            else

                replacementSet = ...
                    1:popSize;

            end

            % Random replacement order
            replacementSet = ...
                replacementSet( ...
                    randperm(numel(replacementSet)));

            nReplaced = 0;

            %% -------------------------------------------------------
            % Tchebycheff-based neighborhood replacement
            % -------------------------------------------------------

            for jj = 1:numel(replacementSet)

                j = replacementSet(jj);

                oldValue = ...
                    moeadTchebycheff( ...
                        F(j,:), ...
                        W(j,:), ...
                        z);

                newValue = ...
                    moeadTchebycheff( ...
                        fChild, ...
                        W(j,:), ...
                        z);

                if newValue <= oldValue

                    X(j,:) = child;
                    F(j,:) = fChild;

                    nReplaced = nReplaced + 1;

                end

                if nReplaced >= nr
                    break;
                end

            end

        end

    end

    %% ---------------------------------------------------------------
    % Final nondominated archive
    % ---------------------------------------------------------------

    archive = ...
        updateArchive( ...
            [], X, F, archiveSize);

end
function archive = run_MOFA( ...
    func_no, nVar, nObj, ...
    popSize, maxIter, archiveSize, ...
    varMin, varMax)
%RUN_MOFA
% Multi-Objective Firefly Algorithm (MOFA).
%
% The implementation follows the main structure of Yang's
% multi-objective firefly formulation:
%
%   1) Objective values are evaluated once for the population at
%      each generation.
%
%   2) A firefly dominated by another firefly moves toward the
%      dominating firefly using distance-dependent attractiveness.
%
%   3) A currently non-dominated firefly performs a random walk
%      around a weighted best solution gStar.
%
%   4) Random weights are regenerated at every generation.
%
%   5) An external nondominated archive is maintained only for
%      consistent reporting within the present benchmark framework.
%
% Importantly, objective functions are NOT re-evaluated after every
% pairwise movement. The complete updated population is evaluated
% once per generation, avoiding the excessive function-evaluation
% count of the previous customized implementation.

    %% ---------------------------------------------------------------
    % Bounds
    % ---------------------------------------------------------------

    [lb, ub] = makeBoundsVectorMO( ...
        varMin, varMax, nVar);

    range = ub - lb;

    %% ---------------------------------------------------------------
    % MOFA parameters
    % ---------------------------------------------------------------

    % Initial attractiveness
    beta0 = 1.0;

    % Light absorption coefficient
    gamma = 1.0;

    % Initial randomization amplitude
    alpha0 = 0.25;

    % Yang's exponential randomization reduction
    alphaDecay = 0.90;

    %% ---------------------------------------------------------------
    % Initialization
    % ---------------------------------------------------------------

    X = lb + rand(popSize, nVar) .* range;

    F = evaluateCECMO(X, func_no);

    archive = updateArchive( ...
        [], X, F, archiveSize);

    %% ---------------------------------------------------------------
    % Main optimization loop
    % ---------------------------------------------------------------

    for it = 1:maxIter

        % -----------------------------------------------------------
        % Generation-dependent randomization
        % -----------------------------------------------------------

        alpha = alpha0 * alphaDecay^(it - 1);

        % -----------------------------------------------------------
        % Random weighted aggregate used to identify gStar
        % -----------------------------------------------------------
        % Positive random weights are regenerated at every
        % generation and normalized to sum to one.

        weights = rand(1, nObj);
        weights = weights ./ sum(weights);

        weightedScore = F * weights';

        [~, gIndex] = min(weightedScore);

        gStar = X(gIndex, :);

        % -----------------------------------------------------------
        % Use the evaluated generation as the comparison reference
        % -----------------------------------------------------------

        Xbase = X;
        Fbase = F;

        Xnew = Xbase;

        % -----------------------------------------------------------
        % Pairwise firefly movement
        % -----------------------------------------------------------

        for i = 1:popSize

            xi = Xbase(i, :);

            hasDominator = false;

            for j = 1:popSize

                if i == j
                    continue;
                end

                % In a minimization problem, firefly j is brighter
                % when it Pareto-dominates firefly i.
                if dominates(Fbase(j,:), Fbase(i,:))

                    hasDominator = true;

                    xj = Xbase(j, :);

                    % Normalized squared distance prevents the
                    % numerical scale of the decision space from
                    % dominating the attractiveness calculation.
                    rij2 = sum( ...
                        ((xi - xj) ./ (range + eps)).^2);

                    beta = beta0 * exp(-gamma * rij2);

                    % Standard attraction plus randomization.
                    randomStep = ...
                        alpha .* range .* ...
                        (rand(1, nVar) - 0.5);

                    xi = ...
                        xi + ...
                        beta .* (xj - xi) + ...
                        randomStep;

                    % Feasible-domain projection
                    xi = max(min(xi, ub), lb);

                end
            end

            % -------------------------------------------------------
            % Non-dominated firefly
            % -------------------------------------------------------
            % If no population member dominates firefly i, perform
            % a random walk around the current weighted best gStar.

            if ~hasDominator

                randomStep = ...
                    alpha .* range .* ...
                    (rand(1, nVar) - 0.5);

                xi = gStar + randomStep;

                xi = max(min(xi, ub), lb);

            end

            Xnew(i, :) = xi;

        end

        %% -----------------------------------------------------------
        % ONE population evaluation per generation
        % ---------------------------------------------------------------

        X = Xnew;

        F = evaluateCECMO(X, func_no);

        %% -----------------------------------------------------------
        % External nondominated archive
        % ---------------------------------------------------------------

        archive = updateArchive( ...
            archive, X, F, archiveSize);

    end

    %% ---------------------------------------------------------------
    % Final archive cleanup
    % ---------------------------------------------------------------

    archive = updateArchive( ...
        [], archive.X, archive.F, archiveSize);

end
function archive = run_MOABC(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax)
%RUN_MOABC
% Multi-Objective Artificial Bee Colony with external nondominated archive.
%
% To keep the evaluation effort comparable to one-population swarm methods,
% the number of food sources is set to ceil(popSize/2), because each cycle
% includes employed and onlooker phases.

    [lb, ub] = makeBoundsVectorMO(varMin, varMax, nVar);
    range = ub - lb;

    nFood = ceil(popSize / 2);

    % ABC parameters
    limit = max(10, round(0.25 * maxIter));
    phiMax = 1.0;
    pArchiveScout = 0.30;

    % Initialize food sources
    X = lb + rand(nFood, nVar) .* range;
    F = evaluateCECMO(X, func_no);

    trial = zeros(nFood, 1);

    archive = updateArchive([], X, F, archiveSize);

    for it = 1:maxIter

        % ---------------------------------------------------------------
        % Employed bee phase
        % ---------------------------------------------------------------
        for i = 1:nFood

            [xCand, fCand] = generateABCNeighbor(i, X, func_no, lb, ub, phiMax);

            if acceptCandidateMOO(fCand, F(i, :), archive.F)
                X(i, :) = xCand;
                F(i, :) = fCand;
                trial(i) = 0;
            else
                trial(i) = trial(i) + 1;
            end
        end

        archive = updateArchive(archive, X, F, archiveSize);

        % ---------------------------------------------------------------
        % Onlooker bee phase
        % ---------------------------------------------------------------
        probs = computeMOABCSelectionProbabilities(F, archive.F);

        for t = 1:nFood

            i = rouletteSelectMO(probs);

            [xCand, fCand] = generateABCNeighbor(i, X, func_no, lb, ub, phiMax);

            if acceptCandidateMOO(fCand, F(i, :), archive.F)
                X(i, :) = xCand;
                F(i, :) = fCand;
                trial(i) = 0;
            else
                trial(i) = trial(i) + 1;
            end
        end

        archive = updateArchive(archive, X, F, archiveSize);

        % ---------------------------------------------------------------
        % Scout bee phase
        % ---------------------------------------------------------------
        for i = 1:nFood

            if trial(i) >= limit

                if rand < pArchiveScout && ~isempty(archive) && ~isempty(archive.F)
                    % Archive-guided scout: restart around a nondominated leader
                    g = selectArchiveLeaderMO(archive);
                    sigma = 0.10 * (1 - it / maxIter) + 0.02;

                    xNew = g + sigma .* range .* randn(1, nVar);
                    xNew = max(min(xNew, ub), lb);
                else
                    % Pure random scout
                    xNew = lb + rand(1, nVar) .* range;
                end

                fNew = CEC_MOFunctions(xNew, func_no);

                X(i, :) = xNew;
                F(i, :) = fNew;
                trial(i) = 0;
            end
        end

        archive = updateArchive(archive, X, F, archiveSize);
    end

    % Final nondominated archive
    archive = updateArchive([], archive.X, archive.F, archiveSize);
end

%% ========================================================================
%  PERFORMANCE METRICS
%  ========================================================================
%% ========================================================================
%  CORRECT HYPERVOLUME FOR MINIMIZATION WITH COMMON REFERENCE POINT
%  ========================================================================

function [ref_point, ideal_point] = buildCommonHVReferenceBox(F_all)
%BUILDCOMMONHVREFERENCEBOX
% Builds one common HV reference point for a benchmark function.
% The same reference point must be used for all algorithms and all runs.

    if isempty(F_all)
        error('No objective values were collected for HV reference point construction.');
    end

    % Remove invalid rows
    F_all = F_all(all(isfinite(F_all), 2), :);

    if isempty(F_all)
        error('All objective values are invalid. Cannot construct HV reference point.');
    end

    f_min = min(F_all, [], 1);
    f_max = max(F_all, [], 1);

    span = f_max - f_min;

    % Avoid zero span in any objective
    for j = 1:length(span)
        if span(j) <= eps
            span(j) = max(1, abs(f_max(j)));
        end
    end

    % For minimization, the reference point must be worse than all solutions.
    ref_point = f_max + 0.10 * span;

    % Ideal point is used only as the lower bound of the Monte Carlo box.
    ideal_point = f_min;

    % Small safety margin
    ref_point = ref_point + eps;
end


function HV = calculateHypervolumeMin(PF, ref_point, ideal_point)
%CALCULATEHYPERVOLUMEMIN
% Calculates dominated hypervolume for minimization problems.
%
% PF        : objective vectors of obtained solutions
% ref_point : common reference point, worse than all solutions
% ideal_point: lower corner used for Monte Carlo box in M >= 3
%
% This function assumes minimization.

    if nargin < 3 || isempty(ideal_point)
        ideal_point = min(PF, [], 1);
    end

    if isempty(PF)
        HV = 0;
        return;
    end

    % Remove invalid rows
    PF = PF(all(isfinite(PF), 2), :);

    if isempty(PF)
        HV = 0;
        return;
    end

    % Keep only points inside the reference box
    inside = all(PF <= ref_point, 2);
    PF = PF(inside, :);

    if isempty(PF)
        HV = 0;
        return;
    end

    % Remove duplicated and dominated points
    PF = unique(PF, 'rows');
    PF = removeDominatedRowsForHV(PF);

    [N, M] = size(PF);

    if M == 2
        % ---------------------------------------------------------------
        % Exact 2D HV for minimization
        % ---------------------------------------------------------------
        PF = sortrows(PF, 1);
        N = size(PF, 1);

        HV = 0;

        for i = 1:N

            if i < N
                width = PF(i+1, 1) - PF(i, 1);
            else
                width = ref_point(1) - PF(i, 1);
            end

            height = ref_point(2) - PF(i, 2);

            if width > 0 && height > 0
                HV = HV + width * height;
            end
        end

    else
        % ---------------------------------------------------------------
        % Monte Carlo HV for M >= 3, minimization
        % ---------------------------------------------------------------
        n_samples = 200000;

        box_span = ref_point - ideal_point;

        if any(box_span <= 0)
            HV = 0;
            return;
        end

        % Use a local random stream to avoid changing the global RNG state.
        stream = RandStream('mt19937ar', 'Seed', 12345);
        U = rand(stream, n_samples, M);

        samples = ideal_point + U .* box_span;

        dominated = false(n_samples, 1);

        for i = 1:size(PF, 1)
            % Correct minimization dominance:
            % PF(i,:) dominates sample if PF(i,:) <= sample in all objectives.
            dominated = dominated | all(PF(i, :) <= samples, 2);
        end

        HV = mean(dominated) * prod(box_span);
    end
end


function PF_nd = removeDominatedRowsForHV(PF)
%REMOVEDOMINATEDROWSFORHV
% Removes dominated rows from PF for minimization.

    N = size(PF, 1);
    dominated = false(N, 1);

    for i = 1:N
        for j = 1:N
            if i ~= j
                if all(PF(j, :) <= PF(i, :)) && any(PF(j, :) < PF(i, :))
                    dominated(i) = true;
                    break;
                end
            end
        end
    end

    PF_nd = PF(~dominated, :);
end
function IGD = calculateIGD(PF, true_PF)
%CALCULATEIGD  Inverted Generational Distance.
% Returns NaN when no analytical/reference Pareto front is available.

    if nargin < 2 || isempty(true_PF)
        IGD = NaN;
        return;
    end

    if isempty(PF)
        IGD = NaN;
        return;
    end

    PF = PF(all(isfinite(PF), 2), :);
    true_PF = true_PF(all(isfinite(true_PF), 2), :);

    if isempty(PF) || isempty(true_PF)
        IGD = NaN;
        return;
    end

    N_true = size(true_PF, 1);
    distances = zeros(N_true, 1);

    for i = 1:N_true
        diff = PF - true_PF(i, :);
        distances(i) = min(sqrt(sum(diff.^2, 2)));
    end

    IGD = mean(distances);
end

function SP = calculateSpacing(PF)
    % Spacing metric
    N = size(PF, 1);
    if N < 2
        SP = 0;
        return;
    end
    
    distances = zeros(N, 1);
    for i = 1:N
        min_dist = inf;
        for j = 1:N
            if i ~= j
                dist = norm(PF(i,:) - PF(j,:));
                if dist < min_dist
                    min_dist = dist;
                end
            end
        end
        distances(i) = min_dist;
    end
    
    d_mean = mean(distances);
    SP = sqrt(sum((distances - d_mean).^2) / (N-1));
end

%% ========================================================================
%  STATISTICAL TESTING
%  ========================================================================

function stats = performStatisticalTests(all_results, test_functions, algorithms)
    n_funcs = length(test_functions);
    n_algos = length(algorithms);
    
    stats = struct();
    
    fprintf('Wilcoxon Rank-Sum Tests:\n');
    fprintf('------------------------\n');
    
    for func_idx = 1:n_funcs
        func_no = test_functions(func_idx);
        fprintf('\nFunction #%d:\n', func_no);
        
        % Get SA-MOPSO-FVML results as baseline
           baseline_HV = all_results(func_idx).SA_MOPSO_FVML.HV;
        
        for algo_idx = 2:n_algos  % Skip SA-MOPSO-FVML itself
           algo_name = algorithms{algo_idx};
                  
            compare_HV = all_results(func_idx).(algo_name).HV;
            
            [p, h] = ranksum(baseline_HV, compare_HV);
            
            if h == 1
                if median(baseline_HV) > median(compare_HV)
                    symbol = '+';
                else
                    symbol = '-';
                end
            else
                symbol = '≈';
            end
            
            fprintf('  vs %s: p=%.4f %s\n', algo_name, p, symbol);
            
            stats(func_idx).(algo_name).p_value = p;
            stats(func_idx).(algo_name).significant = h;
            stats(func_idx).(algo_name).symbol = symbol;
        end
    end
end

%% ========================================================================
%  VISUALIZATION FUNCTIONS
%  ========================================================================

function generateSummaryTables(all_results, test_functions, algorithms)
    fprintf('\n========================================\n');
    fprintf('PERFORMANCE SUMMARY TABLES\n');
    fprintf('========================================\n\n');
    
    for func_idx = 1:length(test_functions)
        func_no = test_functions(func_idx);
        fprintf('Function #%d Results:\n', func_no);
        fprintf('%-20s | %12s | %12s | %12s | %10s\n', ...
                'Algorithm', 'HV (median)', 'IGD (median)', 'SP (median)', 'Time (s)');
        fprintf('%s\n', repmat('-', 80, 1));
        
        for algo_idx = 1:length(algorithms)
            algo_name = algorithms{algo_idx};
            results = all_results(func_idx).(algo_name);
            
            fprintf('%-20s | %12.6f | %12.6f | %12.6f | %10.2f\n', ...
                    algo_name, ...
                    median(results.HV), ...
                    median(results.IGD), ...
                    median(results.SP), ...
                    mean(results.Time));
        end
        fprintf('\n');
    end
end

 
function plotConvergenceAnalysis(all_results, test_functions, algorithms)
    fprintf('\nGenerating convergence analysis plots...\n');
    % Placeholder: Would need to store iteration-wise metrics during runs
end
function visualizeParetoFronts(all_results, test_functions, algorithms)

    nAlgorithms = length(algorithms);

    for func_idx = 1:length(test_functions)

        func_no = test_functions(func_idx);
        nObj = size( ...
    all_results(func_idx).('SA_MOPSO_FVML').MedianArchive.F, 2);

        nCols = min(4, nAlgorithms);
        nRows = ceil(nAlgorithms / nCols);

        if nObj == 2
            figure('Position', [100, 100, 350*nCols, 320*nRows]);
        else
            figure('Position', [100, 100, 380*nCols, 360*nRows]);
        end

        for algo_idx = 1:nAlgorithms

            subplot(nRows, nCols, algo_idx);

            algo_name = algorithms{algo_idx};
            algo_field = matlab.lang.makeValidName(algo_name);

            archive = ...
    all_results(func_idx).(algo_field).MedianArchive;

            if isempty(archive) || ~isfield(archive, 'F') || isempty(archive.F)
                title(sprintf('%s (empty)', strrep(algo_name, '_', '-')));
                continue;
            end

            if nObj == 2
                scatter(archive.F(:,1), archive.F(:,2), 35, 'filled', 'MarkerFaceAlpha', 0.60);
                xlabel('f_1');
                ylabel('f_2');
            else
                scatter3(archive.F(:,1), archive.F(:,2), archive.F(:,3), 35, 'filled', 'MarkerFaceAlpha', 0.60);
                xlabel('f_1');
                ylabel('f_2');
                zlabel('f_3');
                view(45, 30);
            end

            title(sprintf('%s (F%d)', strrep(algo_name, '_', '-'), func_no), 'Interpreter', 'none');
            grid on;
        end

        sgtitle(sprintf('Pareto Front Comparison - Function #%d', func_no), 'FontWeight', 'bold');
    end
end 
function memory_depth_results = performMemoryDepthSensitivity( ...
    selectedFuncs, memoryDepths, nRuns, ...
    popSize, maxIter, archiveSize, outDir)
%PERFORMMEMORYDEPTHSENSITIVITY
% Reviewer-requested sensitivity analysis of the finite-memory truncation
% depth used by SA-MOPSO-FVML.
%
% Only the memory depth L is changed.
% All other algorithmic parameters and mechanisms remain unchanged.
%
% Tested depths:
%       L = 2, 3, 4
%
% Common random seeds are used for corresponding runs across different
% depths to improve fairness of the comparison.

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('MEMORY-DEPTH SENSITIVITY ANALYSIS\n');
    fprintf('Reviewer 2 - Major Comment 1\n');
    fprintf('============================================================\n');

    fprintf('Memory depths: ');
    fprintf('%d ', memoryDepths);
    fprintf('\n');

    fprintf('Selected functions: ');
    fprintf('F%d ', selectedFuncs);
    fprintf('\n');

    fprintf('Independent runs per depth: %d\n', nRuns);
    fprintf('Population size: %d\n', popSize);
    fprintf('Maximum iterations: %d\n', maxIter);
    fprintf('Archive size: %d\n', archiveSize);

    fprintf('============================================================\n\n');

    memory_depth_results = struct();

    % Preserve the RNG state of the main experiment.
    oldRngState = rng;
    cleanupObj = onCleanup(@() rng(oldRngState)); %#ok<NASGU>

    for fidx = 1:numel(selectedFuncs)

        func_no = selectedFuncs(fidx);

        fprintf('\n============================================================\n');
        fprintf('Memory-depth sensitivity for Function #%d\n', func_no);
        fprintf('============================================================\n');

        % -------------------------------------------------------------
        % Problem dimensions -- identical to the main benchmark framework
        % -------------------------------------------------------------
        if func_no <= 3 || func_no >= 8

            nObj = 2;
            nVar = 30;

        else

            nObj = 3;

            if func_no == 4
                nVar = 7;
            else
                nVar = 12;
            end
        end

        [varMin, varMax] = getBoundsForFunction(func_no, nVar);

        true_PF = getTrueParetoFront(func_no, 1000);

        % All depths/runs contribute to one common HV reference box.
        allObjectiveValues = [];

        depthData = struct();

        % =============================================================
        % Stage 1: run each memory depth and store archives
        % =============================================================
        for didx = 1:numel(memoryDepths)

            L = memoryDepths(didx);

            fprintf('\nRunning memory depth L = %d\n', L);
            fprintf('----------------------------------------\n');

            Archives = cell(nRuns,1);
            Times = zeros(nRuns,1);
            Logs = cell(nRuns,1);

            for run = 1:nRuns

                % Paired seed:
                % the same function/run receives the same initial RNG state
                % for L=2, L=3, and L=4.
                pairedSeed = 700000 + 1000*func_no + run;
                rng(pairedSeed, 'twister');

                tRun = tic;

                archive = run_SAMOPSO_FVML( ...
                    func_no, ...
                    nVar, ...
                    nObj, ...
                    popSize, ...
                    maxIter, ...
                    archiveSize, ...
                    varMin, ...
                    varMax, ...
                    L);

                Times(run) = toc(tRun);

                Archives{run} = archive;

                if isfield(archive, 'revision_log')
                    Logs{run} = archive.revision_log;
                else
                    Logs{run} = [];
                end

                if isfield(archive, 'F') && ~isempty(archive.F)
                    allObjectiveValues = ...
                        [allObjectiveValues; archive.F]; %#ok<AGROW>
                end

                fprintf('  L=%d | Run %02d/%02d completed | Time = %.4f s\n', ...
                    L, run, nRuns, Times(run));
            end

            depthData(didx).L = L;
            depthData(didx).Archives = Archives;
            depthData(didx).Time = Times;
            depthData(didx).Logs = Logs;
        end

        % =============================================================
        % Stage 2: common HV reference point
        % =============================================================
        [refPoint, idealPoint] = ...
            buildCommonHVReferenceBox(allObjectiveValues);

        fprintf('\nCommon HV reference point for F%d: ', func_no);
        fprintf('%.6g ', refPoint);
        fprintf('\n');

        % =============================================================
        % Stage 3: calculate all metrics
        % =============================================================
        for didx = 1:numel(memoryDepths)

            L = depthData(didx).L;

            HV = zeros(nRuns,1);
            IGD = nan(nRuns,1);
            SP = zeros(nRuns,1);

            for run = 1:nRuns

                archive = depthData(didx).Archives{run};

                HV(run) = calculateHypervolumeMin( ...
                    archive.F, refPoint, idealPoint);

                IGD(run) = calculateIGD( ...
                    archive.F, true_PF);

                SP(run) = calculateSpacing(archive.F);

                fprintf(['F%02d | L=%d | Run %02d/%02d | ', ...
                         'HV=%12.6g | IGD=%12.6g | ', ...
                         'SP=%12.6g | Time=%8.4f s\n'], ...
                    func_no, ...
                    L, ...
                    run, ...
                    nRuns, ...
                    HV(run), ...
                    IGD(run), ...
                    SP(run), ...
                    depthData(didx).Time(run));
            end

            % Raw data
            memory_depth_results(fidx).func_no = func_no;
            memory_depth_results(fidx).HV_ref_point = refPoint;
            memory_depth_results(fidx).HV_ideal_point = idealPoint;

            memory_depth_results(fidx).depth(didx).L = L;
            memory_depth_results(fidx).depth(didx).HV = HV;
            memory_depth_results(fidx).depth(didx).IGD = IGD;
            memory_depth_results(fidx).depth(didx).SP = SP;
            memory_depth_results(fidx).depth(didx).Time = ...
                depthData(didx).Time;

            memory_depth_results(fidx).depth(didx).Logs = ...
                depthData(didx).Logs;

            % Summary statistics
            memory_depth_results(fidx).depth(didx).summary.HV_median = ...
                median(HV, 'omitnan');

            memory_depth_results(fidx).depth(didx).summary.HV_mean = ...
                mean(HV, 'omitnan');

            memory_depth_results(fidx).depth(didx).summary.HV_std = ...
                std(HV, 'omitnan');

            memory_depth_results(fidx).depth(didx).summary.IGD_median = ...
                median(IGD, 'omitnan');

            memory_depth_results(fidx).depth(didx).summary.IGD_mean = ...
                mean(IGD, 'omitnan');

            memory_depth_results(fidx).depth(didx).summary.IGD_std = ...
                std(IGD, 'omitnan');

            memory_depth_results(fidx).depth(didx).summary.SP_median = ...
                median(SP, 'omitnan');

            memory_depth_results(fidx).depth(didx).summary.SP_mean = ...
                mean(SP, 'omitnan');

            memory_depth_results(fidx).depth(didx).summary.SP_std = ...
                std(SP, 'omitnan');

            memory_depth_results(fidx).depth(didx).summary.Time_mean = ...
                mean(depthData(didx).Time);

            memory_depth_results(fidx).depth(didx).summary.Time_std = ...
                std(depthData(didx).Time);
        end

        % =============================================================
        % Stage 4: compact manuscript-oriented summary
        % =============================================================
        fprintf('\n');
        fprintf('------------------------------------------------------------\n');
        fprintf('MEMORY-DEPTH SUMMARY - FUNCTION #%d\n', func_no);
        fprintf('------------------------------------------------------------\n');

        fprintf('%5s | %14s | %14s | %14s | %11s\n', ...
            'L', ...
            'Median HV', ...
            'Median IGD', ...
            'Median SP', ...
            'Mean Time');

        fprintf('%s\n', repmat('-', 72, 1));

        for didx = 1:numel(memoryDepths)

            S = memory_depth_results(fidx).depth(didx).summary;

            fprintf('%5d | %14.6g | %14.6g | %14.6g | %10.4f s\n', ...
                memoryDepths(didx), ...
                S.HV_median, ...
                S.IGD_median, ...
                S.SP_median, ...
                S.Time_mean);
        end

        fprintf('------------------------------------------------------------\n');
    end

    % =================================================================
    % Save full raw and summary sensitivity data
    % =================================================================
    sensitivityFile = fullfile( ...
        outDir, ...
        'MemoryDepthSensitivity_L2_L3_L4.mat');

    save(sensitivityFile, ...
        'memory_depth_results', ...
        'selectedFuncs', ...
        'memoryDepths', ...
        'nRuns', ...
        'popSize', ...
        'maxIter', ...
        'archiveSize');

    fprintf('\n============================================================\n');
    fprintf('MEMORY-DEPTH SENSITIVITY COMPLETED\n');
    fprintf('============================================================\n');
    fprintf('Results saved to:\n%s\n', sensitivityFile);
    fprintf('============================================================\n\n');
end
function hybrid_leader_results = performHybridLeaderAblation( ...
    selectedFuncs, leaderModes, nRuns, ...
    popSize, maxIter, archiveSize, outDir)
%PERFORMHYBRIDLEADERABLATION
% Reviewer 1 - Comment 2
%
% Isolates the contribution of the adaptive crowding/grid leader-selection
% mechanism while keeping every other SA-MOPSO-FVML component unchanged.
%
% Compared configurations:
%   hybrid   : adaptive pGrid(t)-controlled crowding/grid selection
%   crowding : crowding-distance leader only
%   grid     : grid-based leader only

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('HYBRID LEADER-SELECTION ABLATION\n');
    fprintf('Reviewer 1 - Comment 2\n');
    fprintf('============================================================\n');

    fprintf('Leader modes: ');
    for k = 1:numel(leaderModes)
        fprintf('%s ', leaderModes{k});
    end
    fprintf('\n');

    fprintf('Selected functions: ');
    fprintf('F%d ', selectedFuncs);
    fprintf('\n');

    fprintf('Independent paired runs per mode: %d\n', nRuns);
    fprintf('============================================================\n\n');

    hybrid_leader_results = struct();

    oldRngState = rng;
    cleanupObj = onCleanup(@() rng(oldRngState)); %#ok<NASGU>

    for fidx = 1:numel(selectedFuncs)

        func_no = selectedFuncs(fidx);

        fprintf('\n============================================================\n');
        fprintf('Hybrid-leader ablation for Function #%d\n', func_no);
        fprintf('============================================================\n');

        % -------------------------------------------------------------
        % Problem dimensions
        % -------------------------------------------------------------
        if func_no <= 3 || func_no >= 8
            nObj = 2;
            nVar = 30;
        else
            nObj = 3;

            if func_no == 4
                nVar = 7;
            else
                nVar = 12;
            end
        end

        [varMin, varMax] = getBoundsForFunction(func_no, nVar);
        true_PF = getTrueParetoFront(func_no, 1000);

        allObjectiveValues = [];
        modeData = struct();

        % =============================================================
        % Stage 1: run three leader-selection configurations
        % =============================================================
        for midx = 1:numel(leaderModes)

            modeName = leaderModes{midx};

            fprintf('\nRunning leader mode: %s\n', modeName);
            fprintf('----------------------------------------\n');

            Archives = cell(nRuns,1);
            Times = zeros(nRuns,1);
            Logs = cell(nRuns,1);

            for run = 1:nRuns

                % Same seed for corresponding runs across the three modes
                pairedSeed = 810000 + 1000*func_no + run;
                rng(pairedSeed, 'twister');

                tRun = tic;

                archive = run_SAMOPSO_FVML( ...
                    func_no, ...
                    nVar, ...
                    nObj, ...
                    popSize, ...
                    maxIter, ...
                    archiveSize, ...
                    varMin, ...
                    varMax, ...
                    4, ...
                    modeName);

                Times(run) = toc(tRun);

                Archives{run} = archive;

                if isfield(archive, 'revision_log')
                    Logs{run} = archive.revision_log;
                else
                    Logs{run} = [];
                end

                if isfield(archive, 'F') && ~isempty(archive.F)
                    allObjectiveValues = ...
                        [allObjectiveValues; archive.F]; %#ok<AGROW>
                end

                fprintf('  %s | Run %02d/%02d completed | Time = %.4f s\n', ...
                    modeName, run, nRuns, Times(run));
            end

            modeData(midx).mode = modeName;
            modeData(midx).Archives = Archives;
            modeData(midx).Time = Times;
            modeData(midx).Logs = Logs;
        end

        % =============================================================
        % Stage 2: common HV reference point
        % =============================================================
        [refPoint, idealPoint] = ...
            buildCommonHVReferenceBox(allObjectiveValues);

        fprintf('\nCommon HV reference point for F%d: ', func_no);
        fprintf('%.6g ', refPoint);
        fprintf('\n');

        % =============================================================
        % Stage 3: metrics
        % =============================================================
        for midx = 1:numel(leaderModes)

            modeName = modeData(midx).mode;

            HV = zeros(nRuns,1);
            IGD = nan(nRuns,1);
            SP = zeros(nRuns,1);

            for run = 1:nRuns

                archive = modeData(midx).Archives{run};

                HV(run) = calculateHypervolumeMin( ...
                    archive.F, refPoint, idealPoint);

                IGD(run) = calculateIGD( ...
                    archive.F, true_PF);

                SP(run) = calculateSpacing(archive.F);
            end

            hybrid_leader_results(fidx).func_no = func_no;
            hybrid_leader_results(fidx).HV_ref_point = refPoint;
            hybrid_leader_results(fidx).HV_ideal_point = idealPoint;

            hybrid_leader_results(fidx).mode(midx).name = modeName;
            hybrid_leader_results(fidx).mode(midx).HV = HV;
            hybrid_leader_results(fidx).mode(midx).IGD = IGD;
            hybrid_leader_results(fidx).mode(midx).SP = SP;
            hybrid_leader_results(fidx).mode(midx).Time = ...
                modeData(midx).Time;
            hybrid_leader_results(fidx).mode(midx).Logs = ...
                modeData(midx).Logs;

            S.HV_median  = median(HV, 'omitnan');
            S.HV_mean    = mean(HV, 'omitnan');
            S.HV_std     = std(HV, 'omitnan');

            S.IGD_median = median(IGD, 'omitnan');
            S.IGD_mean   = mean(IGD, 'omitnan');
            S.IGD_std    = std(IGD, 'omitnan');

            S.SP_median  = median(SP, 'omitnan');
            S.SP_mean    = mean(SP, 'omitnan');
            S.SP_std     = std(SP, 'omitnan');

            S.Time_mean  = mean(modeData(midx).Time);
            S.Time_std   = std(modeData(midx).Time);

            hybrid_leader_results(fidx).mode(midx).summary = S;
        end

        % =============================================================
        % Stage 4: compact summary
        % =============================================================
        fprintf('\n');
        fprintf('------------------------------------------------------------\n');
        fprintf('HYBRID-LEADER SUMMARY - FUNCTION #%d\n', func_no);
        fprintf('------------------------------------------------------------\n');

        fprintf('%12s | %14s | %14s | %14s | %11s\n', ...
            'Mode', ...
            'Median HV', ...
            'Median IGD', ...
            'Median SP', ...
            'Mean Time');

        fprintf('%s\n', repmat('-', 78, 1));

        for midx = 1:numel(leaderModes)

            S = hybrid_leader_results(fidx).mode(midx).summary;

            fprintf('%12s | %14.6g | %14.6g | %14.6g | %10.4f s\n', ...
                leaderModes{midx}, ...
                S.HV_median, ...
                S.IGD_median, ...
                S.SP_median, ...
                S.Time_mean);
        end

        fprintf('------------------------------------------------------------\n');

        % -------------------------------------------------------------
        % Checkpoint after each benchmark
        % -------------------------------------------------------------
        checkpointFile = fullfile( ...
            outDir, ...
            sprintf('HybridLeaderAblation_checkpoint_F%d.mat', func_no));

        save(checkpointFile, ...
            'hybrid_leader_results', ...
            'selectedFuncs', ...
            'leaderModes', ...
            'nRuns', ...
            'popSize', ...
            'maxIter', ...
            'archiveSize');

        fprintf('Checkpoint saved for F%d:\n%s\n', ...
            func_no, checkpointFile);
    end

    % =================================================================
    % Final save
    % =================================================================
    resultFile = fullfile( ...
        outDir, ...
        'HybridLeaderAblation_Hybrid_Crowding_Grid.mat');

    save(resultFile, ...
        'hybrid_leader_results', ...
        'selectedFuncs', ...
        'leaderModes', ...
        'nRuns', ...
        'popSize', ...
        'maxIter', ...
        'archiveSize');

    fprintf('\n============================================================\n');
    fprintf('HYBRID LEADER-SELECTION ABLATION COMPLETED\n');
    fprintf('============================================================\n');
    fprintf('Results saved to:\n%s\n', resultFile);
    fprintf('============================================================\n\n');
end
function mutation_ablation_results = performMutationAblation( ...
    selectedFuncs, nRuns, popSize, maxIter, archiveSize, outDir)
%PERFORMMUTATIONABLATION
% Reviewer 1 - Comment 8
%
% Controlled ablation of the stagnation-triggered Mittag-Leffler mutation.
%
% Two configurations are compared:
%
%   Mutation ON:
%       Complete standard SA-MOPSO-FVML
%
%   Mutation OFF:
%       Identical SA-MOPSO-FVML framework, except that the
%       stagnation-triggered ML mutation is disabled.
%
% All remaining mechanisms remain unchanged:
%   - memory depth L = 4
%   - adaptive fractional memory
%   - bounded ML exploration
%   - adaptive hybrid crowding/grid leader selection
%   - archive management
%   - velocity constriction
%
% Corresponding ON/OFF runs use identical random seeds.

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('STAGNATION-TRIGGERED ML MUTATION ABLATION\n');
    fprintf('Reviewer 1 - Comment 8\n');
    fprintf('============================================================\n');

    fprintf('Selected functions: ');
    fprintf('F%d ', selectedFuncs);
    fprintf('\n');

    fprintf('Paired independent runs per configuration: %d\n', nRuns);
    fprintf('Memory depth fixed at L = 4\n');
    fprintf('Leader mode fixed at adaptive hybrid\n');

    fprintf('============================================================\n\n');

    mutation_ablation_results = struct();

    % Preserve RNG state of the main experiment.
    oldRngState = rng;
    cleanupObj = onCleanup(@() rng(oldRngState)); %#ok<NASGU>

    mutationModes = [true, false];
    mutationNames = {'Mutation-ON', 'Mutation-OFF'};

    for fidx = 1:numel(selectedFuncs)

        func_no = selectedFuncs(fidx);

        fprintf('\n============================================================\n');
        fprintf('Mutation ablation for Function #%d\n', func_no);
        fprintf('============================================================\n');

        % -------------------------------------------------------------
        % Problem dimensions -- identical to main benchmark
        % -------------------------------------------------------------
        if func_no <= 3 || func_no >= 8

            nObj = 2;
            nVar = 30;

        else

            nObj = 3;

            if func_no == 4
                nVar = 7;
            else
                nVar = 12;
            end

        end

        [varMin, varMax] = getBoundsForFunction(func_no, nVar);

        true_PF = getTrueParetoFront(func_no, 1000);

        allObjectiveValues = [];

        modeData = struct();

        % =============================================================
        % Stage 1: execute Mutation ON/OFF
        % =============================================================
        for midx = 1:2

            mutationEnabled = mutationModes(midx);
            modeName = mutationNames{midx};

            fprintf('\nRunning configuration: %s\n', modeName);
            fprintf('----------------------------------------\n');

            Archives = cell(nRuns,1);
            Times = zeros(nRuns,1);
            Logs = cell(nRuns,1);

            for run = 1:nRuns

                % Same seed for Mutation-ON and Mutation-OFF
                pairedSeed = 820000 + 1000*func_no + run;
                rng(pairedSeed, 'twister');

                tRun = tic;

                archive = run_SAMOPSO_FVML( ...
                    func_no, ...
                    nVar, ...
                    nObj, ...
                    popSize, ...
                    maxIter, ...
                    archiveSize, ...
                    varMin, ...
                    varMax, ...
                    4, ...             % memoryDepth
                    'hybrid', ...      % leaderMode
                    mutationEnabled);  % mutation switch

                Times(run) = toc(tRun);

                Archives{run} = archive;

                if isfield(archive, 'revision_log')
                    Logs{run} = archive.revision_log;
                else
                    Logs{run} = [];
                end

                if isfield(archive, 'F') && ~isempty(archive.F)
                    allObjectiveValues = ...
                        [allObjectiveValues; archive.F]; %#ok<AGROW>
                end

                fprintf('  %s | Run %02d/%02d completed | Time = %.4f s\n', ...
                    modeName, run, nRuns, Times(run));

            end

            modeData(midx).name = modeName;
            modeData(midx).mutationEnabled = mutationEnabled;
            modeData(midx).Archives = Archives;
            modeData(midx).Time = Times;
            modeData(midx).Logs = Logs;

        end

        % =============================================================
        % Stage 2: common HV reference box
        % =============================================================
        [refPoint, idealPoint] = ...
            buildCommonHVReferenceBox(allObjectiveValues);

        fprintf('\nCommon HV reference point for F%d: ', func_no);
        fprintf('%.6g ', refPoint);
        fprintf('\n');

        % =============================================================
        % Stage 3: calculate metrics
        % =============================================================
        for midx = 1:2

            HV = zeros(nRuns,1);
            IGD = nan(nRuns,1);
            SP = zeros(nRuns,1);

            for run = 1:nRuns

                archive = modeData(midx).Archives{run};

                HV(run) = calculateHypervolumeMin( ...
                    archive.F, ...
                    refPoint, ...
                    idealPoint);

                IGD(run) = calculateIGD( ...
                    archive.F, ...
                    true_PF);

                SP(run) = calculateSpacing(archive.F);

            end

            mutation_ablation_results(fidx).func_no = func_no;
            mutation_ablation_results(fidx).HV_ref_point = refPoint;
            mutation_ablation_results(fidx).HV_ideal_point = idealPoint;

            mutation_ablation_results(fidx).mode(midx).name = ...
                modeData(midx).name;

            mutation_ablation_results(fidx).mode(midx).mutationEnabled = ...
                modeData(midx).mutationEnabled;

            mutation_ablation_results(fidx).mode(midx).HV = HV;
            mutation_ablation_results(fidx).mode(midx).IGD = IGD;
            mutation_ablation_results(fidx).mode(midx).SP = SP;

            mutation_ablation_results(fidx).mode(midx).Time = ...
                modeData(midx).Time;

            mutation_ablation_results(fidx).mode(midx).Logs = ...
                modeData(midx).Logs;

            S.HV_median = median(HV, 'omitnan');
            S.HV_mean   = mean(HV, 'omitnan');
            S.HV_std    = std(HV, 'omitnan');

            S.IGD_median = median(IGD, 'omitnan');
            S.IGD_mean   = mean(IGD, 'omitnan');
            S.IGD_std    = std(IGD, 'omitnan');

            S.SP_median = median(SP, 'omitnan');
            S.SP_mean   = mean(SP, 'omitnan');
            S.SP_std    = std(SP, 'omitnan');

            S.Time_mean = mean(modeData(midx).Time);
            S.Time_std  = std(modeData(midx).Time);

            mutation_ablation_results(fidx).mode(midx).summary = S;

        end

        % =============================================================
        % Stage 4: paired statistical comparison
        % =============================================================

        HV_on  = mutation_ablation_results(fidx).mode(1).HV;
        HV_off = mutation_ablation_results(fidx).mode(2).HV;

        IGD_on  = mutation_ablation_results(fidx).mode(1).IGD;
        IGD_off = mutation_ablation_results(fidx).mode(2).IGD;

        SP_on  = mutation_ablation_results(fidx).mode(1).SP;
        SP_off = mutation_ablation_results(fidx).mode(2).SP;

        stats = struct();

        try
            stats.HV_signrank_p = signrank(HV_on, HV_off);
        catch
            stats.HV_signrank_p = NaN;
        end

        validIGD = isfinite(IGD_on) & isfinite(IGD_off);

        if any(validIGD)
            try
                stats.IGD_signrank_p = ...
                    signrank(IGD_on(validIGD), IGD_off(validIGD));
            catch
                stats.IGD_signrank_p = NaN;
            end
        else
            stats.IGD_signrank_p = NaN;
        end

        try
            stats.SP_signrank_p = signrank(SP_on, SP_off);
        catch
            stats.SP_signrank_p = NaN;
        end

        mutation_ablation_results(fidx).statistics = stats;

        % =============================================================
        % Stage 5: compact output
        % =============================================================

        fprintf('\n');
        fprintf('------------------------------------------------------------\n');
        fprintf('MUTATION ABLATION SUMMARY - FUNCTION #%d\n', func_no);
        fprintf('------------------------------------------------------------\n');

        fprintf('%14s | %14s | %14s | %14s\n', ...
            'Configuration', ...
            'Median HV', ...
            'Median IGD', ...
            'Median SP');

        fprintf('%s\n', repmat('-', 67,1));

        for midx = 1:2

            S = mutation_ablation_results(fidx).mode(midx).summary;

            fprintf('%14s | %14.6g | %14.6g | %14.6g\n', ...
                mutationNames{midx}, ...
                S.HV_median, ...
                S.IGD_median, ...
                S.SP_median);

        end

        fprintf('%s\n', repmat('-', 67,1));

        fprintf('Paired Wilcoxon signed-rank p-values:\n');
        fprintf('  HV  : %.6g\n', stats.HV_signrank_p);
        fprintf('  IGD : %.6g\n', stats.IGD_signrank_p);
        fprintf('  SP  : %.6g\n', stats.SP_signrank_p);

        % =============================================================
        % Checkpoint after each benchmark
        % =============================================================

        checkpointFile = fullfile( ...
            outDir, ...
            sprintf('MutationAblation_checkpoint_F%d.mat', func_no));

        save(checkpointFile, ...
            'mutation_ablation_results', ...
            'selectedFuncs', ...
            'nRuns', ...
            'popSize', ...
            'maxIter', ...
            'archiveSize');

        fprintf('\nCheckpoint saved for F%d:\n%s\n', ...
            func_no, checkpointFile);

    end

    % =============================================================
    % Final save
    % =============================================================

    resultFile = fullfile( ...
        outDir, ...
        'MutationAblation_ON_vs_OFF.mat');

    save(resultFile, ...
        'mutation_ablation_results', ...
        'selectedFuncs', ...
        'nRuns', ...
        'popSize', ...
        'maxIter', ...
        'archiveSize');

    fprintf('\n============================================================\n');
    fprintf('STAGNATION-MUTATION ABLATION COMPLETED\n');
    fprintf('============================================================\n');
    fprintf('Results saved to:\n%s\n', resultFile);
    fprintf('============================================================\n\n');

end
function results = performMLNormalizationAblation( ...
    selectedFuncs, normalizationModes, nRuns, ...
    popSize, maxIter, archiveSize, outDir)
%PERFORMMLNORMALIZATIONABLATION
%
% Reviewer 1 - Comment 5
%
% Controlled comparison of four bounded Mittag-Leffler
% normalization/compression strategies:
%
%   q95
%   max
%   log
%   sigmoid
%
% All other SA-MOPSO-FVML components are kept unchanged.

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('MITTAG-LEFFLER NORMALIZATION ABLATION\n');
    fprintf('Reviewer 1 - Comment 5\n');
    fprintf('============================================================\n');

    fprintf('Functions: ');
    fprintf('F%d ', selectedFuncs);
    fprintf('\n');

    fprintf('Modes: ');
    fprintf('%s ', normalizationModes{:});
    fprintf('\n');

    fprintf('Paired runs per mode: %d\n', nRuns);
    fprintf('Memory depth: L = 4\n');
    fprintf('Leader mode: adaptive hybrid\n');
    fprintf('Mutation: enabled\n');

    fprintf('============================================================\n\n');

    results = struct();

    oldRngState = rng;
    cleanupObj = onCleanup(@() rng(oldRngState)); %#ok<NASGU>

    for fidx = 1:numel(selectedFuncs)

        func_no = selectedFuncs(fidx);

        fprintf('\n============================================================\n');
        fprintf('ML NORMALIZATION ABLATION - FUNCTION #%d\n', func_no);
        fprintf('============================================================\n');

        % -------------------------------------------------------------
        % Problem dimensions
        % -------------------------------------------------------------

        if func_no <= 3

            nObj = 2;
            nVar = 30;

        else

            nObj = 3;

            if func_no == 4
                nVar = 7;
            else
                nVar = 12;
            end

        end

        [varMin,varMax] = ...
            getBoundsForFunction(func_no,nVar);

        truePF = ...
            getTrueParetoFront(func_no,1000);

        modeData = struct();

        pooledObjectives = [];

        % =============================================================
        % Run all four normalization modes
        % =============================================================

        for midx = 1:numel(normalizationModes)

            modeName = normalizationModes{midx};

            fprintf('\nMode: %s\n', upper(modeName));
            fprintf('----------------------------------------\n');

            Archives = cell(nRuns,1);
            Times    = zeros(nRuns,1);

            for run = 1:nRuns

                % Same initial seed for corresponding runs across modes.
                pairedSeed = ...
                    950000 + 1000*func_no + run;

                rng(pairedSeed,'twister');

                tRun = tic;

                archive = run_SAMOPSO_FVML( ...
                    func_no, ...
                    nVar, ...
                    nObj, ...
                    popSize, ...
                    maxIter, ...
                    archiveSize, ...
                    varMin, ...
                    varMax, ...
                    4, ...             % memoryDepth
                    'hybrid', ...      % leaderMode
                    true, ...          % mutationEnabled
                    modeName);         % ML normalization mode

                Times(run) = toc(tRun);

                Archives{run} = archive;

                if isfield(archive,'F') && ~isempty(archive.F)

                    pooledObjectives = ...
                        [pooledObjectives; archive.F]; %#ok<AGROW>

                end

                fprintf( ...
                    '  %-8s | Run %02d/%02d | %.4f s\n', ...
                    upper(modeName), ...
                    run, ...
                    nRuns, ...
                    Times(run));

            end

            modeData(midx).name = modeName;
            modeData(midx).Archives = Archives;
            modeData(midx).Times = Times;

        end

        % =============================================================
        % Common HV reference box
        % =============================================================

        [refPoint,idealPoint] = ...
            buildCommonHVReferenceBox(pooledObjectives);

        fprintf('\nCommon HV reference point for F%d: ',func_no);
        fprintf('%.6g ',refPoint);
        fprintf('\n');

        % =============================================================
        % Metrics
        % =============================================================

        for midx = 1:numel(normalizationModes)

            HV  = zeros(nRuns,1);
            IGD = nan(nRuns,1);
            SP  = zeros(nRuns,1);

            for run = 1:nRuns

                archive = ...
                    modeData(midx).Archives{run};

                HV(run) = ...
                    calculateHypervolumeMin( ...
                    archive.F, ...
                    refPoint, ...
                    idealPoint);

                IGD(run) = ...
                    calculateIGD( ...
                    archive.F, ...
                    truePF);

                SP(run) = ...
                    calculateSpacing(archive.F);

            end

            results(fidx).func_no = func_no;

            results(fidx).HV_ref_point = refPoint;
            results(fidx).HV_ideal_point = idealPoint;

            results(fidx).mode(midx).name = ...
                normalizationModes{midx};

            results(fidx).mode(midx).HV = HV;
            results(fidx).mode(midx).IGD = IGD;
            results(fidx).mode(midx).SP = SP;

            results(fidx).mode(midx).Time = ...
                modeData(midx).Times;

            S.HV_median  = median(HV,'omitnan');
            S.IGD_median = median(IGD,'omitnan');
            S.SP_median  = median(SP,'omitnan');

            S.HV_mean  = mean(HV,'omitnan');
            S.IGD_mean = mean(IGD,'omitnan');
            S.SP_mean  = mean(SP,'omitnan');

            S.HV_std  = std(HV,'omitnan');
            S.IGD_std = std(IGD,'omitnan');
            S.SP_std  = std(SP,'omitnan');

            S.Time_mean = ...
                mean(modeData(midx).Times);

            results(fidx).mode(midx).summary = S;

        end

        % =============================================================
        % Compact summary
        % =============================================================

        fprintf('\n');
        fprintf('------------------------------------------------------------\n');
        fprintf('ML NORMALIZATION SUMMARY - FUNCTION #%d\n',func_no);
        fprintf('------------------------------------------------------------\n');

        fprintf( ...
            '%10s | %14s | %14s | %14s\n', ...
            'Mode', ...
            'Median HV', ...
            'Median IGD', ...
            'Median SP');

        fprintf('%s\n',repmat('-',1,62));

        for midx = 1:numel(normalizationModes)

            S = results(fidx).mode(midx).summary;

            fprintf( ...
                '%10s | %14.6g | %14.6g | %14.6g\n', ...
                upper(normalizationModes{midx}), ...
                S.HV_median, ...
                S.IGD_median, ...
                S.SP_median);

        end

        % =============================================================
        % Save benchmark checkpoint
        % =============================================================

        checkpointFile = fullfile( ...
            outDir, ...
            sprintf( ...
            'MLNormalization_checkpoint_F%d.mat', ...
            func_no));

        save( ...
            checkpointFile, ...
            'results', ...
            'selectedFuncs', ...
            'normalizationModes', ...
            'nRuns', ...
            'popSize', ...
            'maxIter', ...
            'archiveSize');

        fprintf('\nCheckpoint saved:\n%s\n',checkpointFile);

    end

    % =============================================================
    % Final save
    % =============================================================

    resultFile = fullfile( ...
        outDir, ...
        'ML_Normalization_Ablation.mat');

    save( ...
        resultFile, ...
        'results', ...
        'selectedFuncs', ...
        'normalizationModes', ...
        'nRuns', ...
        'popSize', ...
        'maxIter', ...
        'archiveSize');

    fprintf('\n============================================================\n');
    fprintf('ML NORMALIZATION ABLATION COMPLETED\n');
    fprintf('============================================================\n');
    fprintf('Saved to:\n%s\n',resultFile);

end

function analyzeComputationalComplexity(all_results, test_functions, algorithms)
    fprintf('\n========================================\n');
    fprintf('COMPUTATIONAL COMPLEXITY ANALYSIS\n');
    fprintf('========================================\n\n');
    
    fprintf('%-20s | %15s | %15s\n', 'Algorithm', 'Avg Time (s)', 'Theoretical');
    fprintf('%s\n', repmat('-', 55, 1));
    
    for algo_idx = 1:length(algorithms)
        algo_name = algorithms{algo_idx};
        total_time = 0;
        
        for func_idx = 1:length(test_functions)
            total_time = total_time + mean(all_results(func_idx).(algo_name).Time);
        end
        
        avg_time = total_time / length(test_functions);
        fprintf('%-20s | %15.4f | %15s\n', algo_name, avg_time, 'O(N^2·M)');
    end
end
function revision_summary = printRevisionProfilingSummary( ...
    revision_log_all, all_results, test_functions)
%PRINTREVISIONPROFILINGSUMMARY
% Aggregates SA-MOPSO-FVML revision profiling information across
% independent runs and prints a reviewer-oriented summary.
%
% Reported quantities:
%   - total SA-MOPSO-FVML runtime
%   - fractional-memory weight calculation time
%   - Mittag-Leffler sampling time
%   - diversity computation time
%   - hybrid leader-selection time
%   - stagnation-mutation overhead
%   - adaptive pML, pMem, and pGrid
%   - actual memory/grid activation ratios
%   - mutation-event frequency
%   - mean objective-space diversity
%
% This function performs reporting only and does not alter algorithm results.

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('SA-MOPSO-FVML REVISION PROFILING SUMMARY\n');
    fprintf('============================================================\n');

    revision_summary = struct();

    saField = matlab.lang.makeValidName('SA-MOPSO-FVML');

    for func_idx = 1:length(test_functions)

        func_no = test_functions(func_idx);

        if numel(revision_log_all) < func_idx || ...
           ~isfield(revision_log_all(func_idx), 'run') || ...
           isempty(revision_log_all(func_idx).run)

            fprintf('\nFunction #%d: no revision log available.\n', func_no);
            continue;
        end

        nLogged = numel(revision_log_all(func_idx).run);

        memoryTime   = nan(nLogged,1);
        mlTime       = nan(nLogged,1);
        diversityTime = nan(nLogged,1);
        leaderTime   = nan(nLogged,1);
        mutationTime = nan(nLogged,1);

        meanPML      = nan(nLogged,1);
        meanPMem     = nan(nLogged,1);
        meanPGrid    = nan(nLogged,1);
        meanE        = nan(nLogged,1);

        memoryRatio  = nan(nLogged,1);
        gridRatio    = nan(nLogged,1);
        mutationEvents = nan(nLogged,1);

        for r = 1:nLogged

            L = revision_log_all(func_idx).run(r).log;

            memoryTime(r)    = sum(L.memory_time);
            mlTime(r)        = sum(L.ML_time);
            diversityTime(r) = sum(L.diversity_time);
            leaderTime(r)    = sum(L.leader_time);
            mutationTime(r)  = sum(L.mutation_time);

            meanPML(r)   = mean(L.pML(:));
            meanPMem(r)  = mean(L.pMem(:));
            meanPGrid(r) = mean(L.pGrid(:));
            meanE(r)     = mean(L.E(:));

            if isfield(L, 'total_velocity_updates') && ...
               L.total_velocity_updates > 0

                memoryRatio(r) = ...
                    L.memory_activation / L.total_velocity_updates;

                gridRatio(r) = ...
                    L.grid_activation / L.total_velocity_updates;
            end

            if isfield(L, 'mutation_events')
                mutationEvents(r) = L.mutation_events;
            end
        end

        % Total SA-MOPSO-FVML runtime from the main experimental framework
        totalTime = all_results(func_idx).(saField).Time(:);

        avgTotal = mean(totalTime);
        stdTotal = std(totalTime);

        avgMem  = mean(memoryTime);
        avgML   = mean(mlTime);
        avgDiv  = mean(diversityTime);
        avgLead = mean(leaderTime);
        avgMut  = mean(mutationTime);

        profiledSubtotal = avgMem + avgML + avgDiv + avgLead + avgMut;

        otherTime = max(0, avgTotal - profiledSubtotal);

        % Percentages relative to complete SA-MOPSO-FVML runtime
        pctMem   = 100 * avgMem  / max(avgTotal, eps);
        pctML    = 100 * avgML   / max(avgTotal, eps);
        pctDiv   = 100 * avgDiv  / max(avgTotal, eps);
        pctLead  = 100 * avgLead / max(avgTotal, eps);
        pctMut   = 100 * avgMut  / max(avgTotal, eps);
        pctOther = 100 * otherTime / max(avgTotal, eps);

        fprintf('\n------------------------------------------------------------\n');
        fprintf('Function #%d | Independent runs logged: %d\n', ...
            func_no, nLogged);
        fprintf('------------------------------------------------------------\n');

        fprintf('Total runtime           : %.4f +/- %.4f s\n', ...
            avgTotal, stdTotal);

        fprintf('\nRuntime decomposition:\n');

        fprintf('  ML sampling           : %.4f s  (%6.2f %%)\n', ...
            avgML, pctML);

        fprintf('  Hybrid leader         : %.4f s  (%6.2f %%)\n', ...
            avgLead, pctLead);

        fprintf('  Diversity calculation : %.4f s  (%6.2f %%)\n', ...
            avgDiv, pctDiv);

        fprintf('  Memory weights        : %.4f s  (%6.2f %%)\n', ...
            avgMem, pctMem);

        fprintf('  ML mutation overhead  : %.4f s  (%6.2f %%)\n', ...
            avgMut, pctMut);

        fprintf('  Other algorithm cost  : %.4f s  (%6.2f %%)\n', ...
            otherTime, pctOther);

        fprintf('\nAdaptive mechanism statistics:\n');

        fprintf('  Mean E(t)             : %.4f +/- %.4f\n', ...
            mean(meanE), std(meanE));

        fprintf('  Mean pML(t)           : %.4f +/- %.4f\n', ...
            mean(meanPML), std(meanPML));

        fprintf('  Mean pMem(t)          : %.4f +/- %.4f\n', ...
            mean(meanPMem), std(meanPMem));

        fprintf('  Mean pGrid(t)         : %.4f +/- %.4f\n', ...
            mean(meanPGrid), std(meanPGrid));

        fprintf('  Memory activation     : %.2f +/- %.2f %%\n', ...
            100*mean(memoryRatio), 100*std(memoryRatio));

        fprintf('  Grid leader usage     : %.2f +/- %.2f %%\n', ...
            100*mean(gridRatio), 100*std(gridRatio));

        fprintf('  Mutation events/run   : %.2f +/- %.2f\n', ...
            mean(mutationEvents), std(mutationEvents));

        % -------------------------------------------------------------
        % Save numerical values for later manuscript/reviewer analysis
        % -------------------------------------------------------------
        revision_summary(func_idx).func_no = func_no;
        revision_summary(func_idx).n_runs = nLogged;

        revision_summary(func_idx).runtime.total_mean = avgTotal;
        revision_summary(func_idx).runtime.total_std  = stdTotal;

        revision_summary(func_idx).runtime.memory_mean = avgMem;
        revision_summary(func_idx).runtime.ML_mean = avgML;
        revision_summary(func_idx).runtime.diversity_mean = avgDiv;
        revision_summary(func_idx).runtime.leader_mean = avgLead;
        revision_summary(func_idx).runtime.mutation_mean = avgMut;
        revision_summary(func_idx).runtime.other_mean = otherTime;

        revision_summary(func_idx).runtime.memory_percent = pctMem;
        revision_summary(func_idx).runtime.ML_percent = pctML;
        revision_summary(func_idx).runtime.diversity_percent = pctDiv;
        revision_summary(func_idx).runtime.leader_percent = pctLead;
        revision_summary(func_idx).runtime.mutation_percent = pctMut;
        revision_summary(func_idx).runtime.other_percent = pctOther;

        revision_summary(func_idx).adaptive.E_mean = mean(meanE);
        revision_summary(func_idx).adaptive.E_std = std(meanE);

        revision_summary(func_idx).adaptive.pML_mean = mean(meanPML);
        revision_summary(func_idx).adaptive.pML_std = std(meanPML);

        revision_summary(func_idx).adaptive.pMem_mean = mean(meanPMem);
        revision_summary(func_idx).adaptive.pMem_std = std(meanPMem);

        revision_summary(func_idx).adaptive.pGrid_mean = mean(meanPGrid);
        revision_summary(func_idx).adaptive.pGrid_std = std(meanPGrid);

        revision_summary(func_idx).adaptive.memory_activation_mean = ...
            mean(memoryRatio);

        revision_summary(func_idx).adaptive.memory_activation_std = ...
            std(memoryRatio);

        revision_summary(func_idx).adaptive.grid_usage_mean = ...
            mean(gridRatio);

        revision_summary(func_idx).adaptive.grid_usage_std = ...
            std(gridRatio);

        revision_summary(func_idx).adaptive.mutation_events_mean = ...
            mean(mutationEvents);

        revision_summary(func_idx).adaptive.mutation_events_std = ...
            std(mutationEvents);
    end

    fprintf('\n============================================================\n');
    fprintf('END OF REVISION PROFILING SUMMARY\n');
    fprintf('============================================================\n\n');
end
%% ========================================================================
%  HELPER FUNCTIONS (Reused from main code)
%  ========================================================================

function particle = initializeParticles(popSize, nVar, nObj, varMin, varMax, func_no)
    particle(popSize) = struct();

    for i = 1:popSize
        particle(i).x = varMin + rand(1, nVar).*(varMax - varMin);
        particle(i).v_hist = zeros(4, nVar);

        particle(i).pbest = particle(i).x;

        % Correct pbest initialization using the objective value
        % of the initial particle position.
        particle(i).pbestF = CEC_MOFunctions(particle(i).x, func_no);

        % Safety check: ensure objective dimension is consistent.
        if numel(particle(i).pbestF) ~= nObj
            error('Objective dimension mismatch in initializeParticles for Function #%d.', func_no);
        end
    end
end
function [lb, ub] = getBoundsForFunction(func_no, D)
    switch func_no
        case {1, 2, 3}, lb = 0; ub = 1;
        case {4, 5, 6, 7}, lb = 0; ub = 1;
        case 8, lb = -5; ub = 5;
        case 9, lb = -5; ub = 10;
        case 10, lb = -5.12; ub = 5.12;
        otherwise, lb = -5; ub = 5;
    end
end


function true_PF = getTrueParetoFront(func_no, n_points)
%GETTRUEPARETOFRONT
% Generates analytical/reference Pareto fronts for IGD calculation.
%
% Function numbers:
%   1: ZDT1
%   2: ZDT2
%   3: ZDT3
%   4: DTLZ1
%   5: DTLZ2
%   6: DTLZ3
%   7: DTLZ4
%
% For custom functions 8-10, this function returns [] because no analytical
% Pareto front is defined here.

    switch func_no

        case 1  % ZDT1
            f1 = linspace(0, 1, n_points)';
            f2 = 1 - sqrt(f1);
            true_PF = [f1, f2];

        case 2  % ZDT2
            f1 = linspace(0, 1, n_points)';
            f2 = 1 - f1.^2;
            true_PF = [f1, f2];

        case 3  % ZDT3
            true_PF = generateZDT3ParetoFront(n_points);

        case 4  % DTLZ1
            true_PF = generateDTLZ1ParetoFront3D(n_points);

        case {5, 6, 7}  % DTLZ2, DTLZ3, DTLZ4
            true_PF = generateSphericalParetoFront3D(n_points);

        otherwise
            % For custom functions, no analytical reference front is provided.
            % If IGD is required for these functions, construct a reference
            % front from the nondominated union of all algorithms and runs.
            true_PF = [];
    end
end


function PF = generateZDT3ParetoFront(n_points)
%GENERATEZDT3PARETOFRONT
% Generates the true disconnected Pareto front of ZDT3.
%
% The ZDT3 Pareto front is not the entire set obtained by f2 >= 0.
% It consists of five disconnected intervals in f1.

    intervals = [
        0.0000000000, 0.0830015349
        0.1822287280, 0.2577623634
        0.4093136748, 0.4538821041
        0.6183967944, 0.6525117038
        0.8233317983, 0.8518328654
    ];

    nSegments = size(intervals, 1);
    pointsPerSegment = ceil(n_points / nSegments);

    f1 = [];

    for k = 1:nSegments
        f1_segment = linspace(intervals(k, 1), intervals(k, 2), pointsPerSegment)';
        f1 = [f1; f1_segment];
    end

    % Keep approximately n_points samples
    if numel(f1) > n_points
        f1 = f1(1:n_points);
    end

    f2 = 1 - sqrt(f1) - f1 .* sin(10*pi*f1);

    PF = [f1, f2];
end


function PF = generateDTLZ1ParetoFront3D(n_points)
%GENERATEDTLZ1PARETOFRONT3D
% Generates the true Pareto front of DTLZ1 for three objectives.
%
% For DTLZ1, the Pareto front is linear and satisfies:
%       f1 + f2 + f3 = 0.5,   fi >= 0
%
% Therefore, it must not be generated as a spherical front.

    H = 1;

    % Increase H until enough points are generated on the simplex
    while nchoosek(H + 2, 2) < n_points
        H = H + 1;
    end

    PF = [];

    for i = 0:H
        for j = 0:(H - i)

            f1 = 0.5 * i / H;
            f2 = 0.5 * j / H;
            f3 = 0.5 - f1 - f2;

            if f3 >= -1e-12
                PF = [PF; f1, f2, max(f3, 0)];
            end
        end
    end

    % If more points are generated, select approximately uniformly
    if size(PF, 1) > n_points
        idx = round(linspace(1, size(PF, 1), n_points));
        PF = PF(idx, :);
    end
end


function PF = generateSphericalParetoFront3D(n_points)
%GENERATESPHERICALPARETOFRONT3D
% Generates a reference spherical Pareto front for DTLZ2, DTLZ3, and DTLZ4
% in the three-objective case.
%
% The front lies on the positive orthant of the unit sphere:
%       f1^2 + f2^2 + f3^2 = 1,   fi >= 0

    H = ceil(sqrt(n_points));

    theta = linspace(0, pi/2, H);
    phi   = linspace(0, pi/2, H);

    [THETA, PHI] = meshgrid(theta, phi);

    f1 = cos(THETA(:)) .* cos(PHI(:));
    f2 = cos(THETA(:)) .* sin(PHI(:));
    f3 = sin(THETA(:));

    PF = [f1, f2, f3];

    if size(PF, 1) > n_points
        idx = round(linspace(1, size(PF, 1), n_points));
        PF = PF(idx, :);
    end
end



% Include all helper functions from original code
% (mittagLefflerRand, dominates, updateArchive, etc.)

% ... [Previous helper functions] ...

function F = evaluateCECMO(X, func_no)
    N = size(X, 1);
    if func_no <= 3 || func_no >= 8
        M = 2;
    else
        M = 3;
        end
    
    F = zeros(N, M);
    for i = 1:N
        F(i, :) = CEC_MOFunctions(X(i, :), func_no);
    end
end
function rStar = mittagLefflerRand(alpha, scale, sz, varargin)
%MITTAGLEFFLERRAND
% Generates bounded positive Mittag-Leffler stochastic coefficients.
%
% Supported normalization/compression modes:
%
%   q95
%       Current SA-MOPSO-FVML formulation.
%       Raw samples are divided by their empirical q-quantile and
%       subsequently clipped by RMax.
%
%   max
%       Maximum-based normalization. The largest sample in the
%       generated batch is mapped to RMax.
%
%   log
%       Logarithmic compression followed by maximum normalization.
%
%   sigmoid
%       Smooth saturating compression using the sample median as a
%       robust scale parameter.
%
% All four alternatives remain bounded by RMax.

    p = inputParser;

    addParameter(p, 'QuantileLevel', 0.95, ...
        @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 1);

    addParameter(p, 'RMax', 2.0, ...
        @(x) isnumeric(x) && isscalar(x) && x > 0);

    addParameter(p, 'UnitInterval', false, ...
        @(x) islogical(x) || isnumeric(x));

    addParameter(p, 'NormalizationMode', 'q95', ...
        @(x) ischar(x) || isstring(x));

    parse(p, varargin{:});

    qLevel = p.Results.QuantileLevel;
    rMax   = p.Results.RMax;

    unitInterval = logical(p.Results.UnitInterval);

    normalizationMode = ...
        lower(char(p.Results.NormalizationMode));

    if nargin < 3 || isempty(sz)
        sz = [1 1];
    end

    if alpha <= 0 || alpha > 1
        error(['For the positive Mittag-Leffler sampler used here, ', ...
               'alpha must satisfy 0 < alpha <= 1.']);
    end

    if scale <= 0
        error('The scale parameter must be positive.');
    end

    n = prod(sz);

    % -------------------------------------------------------------
    % Generate raw positive Mittag-Leffler samples
    % -------------------------------------------------------------

    U = rand(n,1);
    V = rand(n,1);

    % Avoid exact endpoints for numerical stability.
    U = min(max(U, eps), 1-eps);
    V = min(max(V, eps), 1-eps);

    if abs(alpha - 1) < 1e-12

        X = -log(U);

    else

        bracketTerm = ...
            sin(pi*alpha) ./ tan(pi*alpha.*V) ...
            - cos(pi*alpha);

        bracketTerm = max(bracketTerm, eps);

        X = -log(U) .* ...
            bracketTerm.^(1/alpha);

    end

    X = scale .* X;

    X(~isfinite(X)) = realmax('double');
    X = max(X, 0);

    % -------------------------------------------------------------
    % Apply selected bounded transformation
    % -------------------------------------------------------------

    switch normalizationMode

        case 'q95'

            % Empirical quantile without requiring Statistics Toolbox.
            Xsorted = sort(X(:));

            qPosition = 1 + ...
                (numel(Xsorted)-1) * qLevel;

            qLow  = floor(qPosition);
            qHigh = ceil(qPosition);

            if qLow == qHigh
                qValue = Xsorted(qLow);
            else
                fraction = qPosition - qLow;

                qValue = ...
                    Xsorted(qLow) + ...
                    fraction .* ...
                    (Xsorted(qHigh)-Xsorted(qLow));
            end

            qValue = max(qValue, eps);

            rStar = X ./ qValue;

            rStar = min(rStar, rMax);


        case 'max'

            % Maximum-based normalization.
            % A single extreme value therefore determines the batch scale.
            maxValue = max(X);

            maxValue = max(maxValue, eps);

            rStar = ...
                rMax .* X ./ maxValue;


        case 'log'

            % Logarithmic compression reduces the influence of
            % very large raw heavy-tailed samples.
            Z = log1p(X);

            maxValue = max(Z);

            maxValue = max(maxValue, eps);

            rStar = ...
                rMax .* Z ./ maxValue;


        case 'sigmoid'

            % Smooth bounded compression. Median provides a robust
            % scale without allowing a single extreme sample to
            % determine the transformation.
            scaleValue = median(X);

            scaleValue = max(scaleValue, eps);

            Z = X ./ scaleValue;

            rStar = ...
                rMax .* ...
                (2 ./ (1 + exp(-Z)) - 1);


        otherwise

            error( ...
                'Unknown Mittag-Leffler normalization mode: %s', ...
                normalizationMode);

    end

    % Final numerical safety bound.
    rStar = max(rStar, 0);
    rStar = min(rStar, rMax);

    if unitInterval
        rStar = rStar ./ max(rMax, eps);
        rStar = min(max(rStar,0),1);
    end

    rStar = reshape(rStar, sz);

end
 function q = localQuantile(x, p)
%LOCALQUANTILE  Simple quantile function without requiring toolboxes.

    x = sort(x(:));
    n = numel(x);

    if n == 1
        q = x;
        return;
    end

    pos = 1 + (n - 1) * p;
    lo = floor(pos);
    hi = ceil(pos);

    if lo == hi
        q = x(lo);
    else
        q = x(lo) + (pos - lo) * (x(hi) - x(lo));
    end
 end

 function step = levyFlightMantegna(sz, beta)
%LEVYFLIGHTMANTEGNA
% Generates symmetric Levy-flight steps using Mantegna's algorithm.
%
% INPUTS:
%   sz   : output size, e.g. [1 nVar]
%   beta : Levy stability exponent, 1 < beta < 2
%
% OUTPUT:
%   step : symmetric heavy-tailed random steps
%
% For beta = 1.5, occasional large jumps coexist with many
% small perturbations, which is the characteristic behavior
% required for Levy-flight exploration.

    if beta <= 1 || beta >= 2
        error('Levy beta must satisfy 1 < beta < 2.');
    end

    sigmaU = ...
        ( ...
        gamma(1 + beta) .* ...
        sin(pi * beta / 2) ./ ...
        ( ...
        gamma((1 + beta) / 2) .* ...
        beta .* ...
        2.^((beta - 1) / 2) ...
        ) ...
        ).^(1 / beta);

    u = sigmaU .* randn(sz);

    v = randn(sz);

    denominator = abs(v).^(1 / beta);

    denominator = max(denominator, eps);

    step = u ./ denominator;

    % Numerical safety only.
    step(~isfinite(step)) = 0;

 end
 
function [rank, fronts] = nsga2FastNonDominatedSort(F)
%NSGA2FASTNONDOMINATEDSORT
% Deb-style non-dominated sorting for minimization problems.

    N = size(F,1);

    dominationCount = ...
        zeros(N,1);

    dominatesSet = ...
        cell(N,1);

    rank = ...
        inf(N,1);

    firstFront = [];

    for p = 1:N

        Sp = [];

        np = 0;

        for q = 1:N

            if p == q
                continue;
            end

            if dominates(F(p,:), F(q,:))

                Sp(end+1) = q; %#ok<AGROW>

            elseif dominates(F(q,:), F(p,:))

                np = np + 1;

            end

        end

        dominatesSet{p} = Sp;
        dominationCount(p) = np;

        if np == 0

            rank(p) = 1;

            firstFront(end+1) = p; %#ok<AGROW>

        end

    end

    fronts = {};

    fronts{1} = firstFront;

    frontNo = 1;

    while frontNo <= numel(fronts) && ...
            ~isempty(fronts{frontNo})

        nextFront = [];

        currentFront = ...
            fronts{frontNo};

        for ii = 1:numel(currentFront)

            p = currentFront(ii);

            Sp = dominatesSet{p};

            for jj = 1:numel(Sp)

                q = Sp(jj);

                dominationCount(q) = ...
                    dominationCount(q) - 1;

                if dominationCount(q) == 0

                    rank(q) = frontNo + 1;

                    nextFront(end+1) = q; %#ok<AGROW>

                end

            end

        end

        if ~isempty(nextFront)

            fronts{frontNo + 1} = ...
                unique(nextFront, 'stable');

        end

        frontNo = frontNo + 1;

    end

end
function crowd = nsga2CrowdingDistance(F, fronts)
%NSGA2CROWDINGDISTANCE
% Crowding distance calculated independently within each Pareto front.

    N = size(F,1);
    M = size(F,2);

    crowd = zeros(N,1);

    for fidx = 1:numel(fronts)

        front = fronts{fidx};

        nFront = numel(front);

        if nFront == 0
            continue;
        end

        if nFront <= 2

            crowd(front) = inf;
            continue;

        end

        frontF = F(front,:);

        localCrowd = ...
            zeros(nFront,1);

        for m = 1:M

            [sortedValues, order] = ...
                sort(frontF(:,m));

            localCrowd(order(1)) = inf;
            localCrowd(order(end)) = inf;

            fMin = sortedValues(1);
            fMax = sortedValues(end);

            if abs(fMax - fMin) <= eps
                continue;
            end

            for k = 2:(nFront-1)

                if ~isinf(localCrowd(order(k)))

                    localCrowd(order(k)) = ...
                        localCrowd(order(k)) + ...
                        ( ...
                        sortedValues(k+1) - ...
                        sortedValues(k-1) ...
                        ) / ...
                        (fMax - fMin);

                end

            end

        end

        crowd(front) = localCrowd;

    end

end
function idx = nsga2TournamentSelection(rank, crowd)
%NSGA2TOURNAMENTSELECTION
% Binary tournament:
%   1) lower Pareto rank is preferred;
%   2) for equal rank, larger crowding distance is preferred;
%   3) exact ties are resolved randomly.

    N = numel(rank);

    a = randi(N);
    b = randi(N);

    if rank(a) < rank(b)

        idx = a;

    elseif rank(b) < rank(a)

        idx = b;

    elseif crowd(a) > crowd(b)

        idx = a;

    elseif crowd(b) > crowd(a)

        idx = b;

    else

        if rand < 0.5
            idx = a;
        else
            idx = b;
        end

    end

end

function [child1, child2] = nsga2SBX( ...
    parent1, parent2, lb, ub, etaC)
%NSGA2SBX
% Bounded simulated binary crossover (SBX).

    nVar = numel(parent1);

    child1 = parent1;
    child2 = parent2;

    for j = 1:nVar

        if rand > 0.5
            continue;
        end

        p1 = parent1(j);
        p2 = parent2(j);

        if abs(p1 - p2) <= 1e-14
            continue;
        end

        x1 = min(p1, p2);
        x2 = max(p1, p2);

        lower = lb(j);
        upper = ub(j);

        randValue = rand;

        % -----------------------------------------------------------
        % First child
        % -----------------------------------------------------------

        beta = ...
            1 + ...
            2 * (x1 - lower) / (x2 - x1);

        alpha = ...
            2 - beta^(-(etaC + 1));

        if randValue <= 1 / alpha

            betaQ = ...
                (randValue * alpha)^( ...
                1 / (etaC + 1));

        else

            betaQ = ...
                ( ...
                1 / ...
                (2 - randValue * alpha) ...
                )^(1 / (etaC + 1));

        end

        c1 = ...
            0.5 * ...
            ( ...
            (x1 + x2) - ...
            betaQ * (x2 - x1) ...
            );

        % -----------------------------------------------------------
        % Second child
        % -----------------------------------------------------------

        beta = ...
            1 + ...
            2 * (upper - x2) / ...
            (x2 - x1);

        alpha = ...
            2 - beta^(-(etaC + 1));

        if randValue <= 1 / alpha

            betaQ = ...
                (randValue * alpha)^( ...
                1 / (etaC + 1));

        else

            betaQ = ...
                ( ...
                1 / ...
                (2 - randValue * alpha) ...
                )^(1 / (etaC + 1));

        end

        c2 = ...
            0.5 * ...
            ( ...
            (x1 + x2) + ...
            betaQ * (x2 - x1) ...
            );

        c1 = min(max(c1, lower), upper);
        c2 = min(max(c2, lower), upper);

        % Random exchange avoids positional bias
        if rand < 0.5

            child1(j) = c2;
            child2(j) = c1;

        else

            child1(j) = c1;
            child2(j) = c2;

        end

    end

end

function child = nsga2PolynomialMutation( ...
    child, lb, ub, mutationProbability, etaM)
%NSGA2POLYNOMIALMUTATION
% Bounded polynomial mutation used by NSGA-II.

    nVar = numel(child);

    for j = 1:nVar

        if rand > mutationProbability
            continue;
        end

        lower = lb(j);
        upper = ub(j);

        if upper <= lower
            continue;
        end

        y = child(j);

        delta1 = ...
            (y - lower) / (upper - lower);

        delta2 = ...
            (upper - y) / (upper - lower);

        rnd = rand;

        mutationPower = ...
            1 / (etaM + 1);

        if rnd <= 0.5

            xy = 1 - delta1;

            val = ...
                2 * rnd + ...
                (1 - 2 * rnd) * ...
                xy^(etaM + 1);

            deltaQ = ...
                val^mutationPower - 1;

        else

            xy = 1 - delta2;

            val = ...
                2 * (1 - rnd) + ...
                2 * (rnd - 0.5) * ...
                xy^(etaM + 1);

            deltaQ = ...
                1 - val^mutationPower;

        end

        y = ...
            y + ...
            deltaQ * (upper - lower);

        child(j) = ...
            min(max(y, lower), upper);

    end

end

function [Xnext, Fnext] = nsga2EnvironmentalSelection( ...
    combinedX, combinedF, popSize)
%NSGA2ENVIRONMENTALSELECTION
% Standard elitist NSGA-II parent-offspring environmental selection.

    [~, fronts] = ...
        nsga2FastNonDominatedSort(combinedF);

    crowd = ...
        nsga2CrowdingDistance( ...
            combinedF, fronts);

    selected = [];

    for fidx = 1:numel(fronts)

        front = fronts{fidx};

        if isempty(front)
            continue;
        end

        remaining = ...
            popSize - numel(selected);

        if remaining <= 0
            break;
        end

        if numel(front) <= remaining

            selected = ...
                [selected, front]; %#ok<AGROW>

        else

            [~, order] = ...
                sort( ...
                    crowd(front), ...
                    'descend');

            chosen = ...
                front(order(1:remaining));

            selected = ...
                [selected, chosen]; %#ok<AGROW>

            break;

        end

    end

    selected = selected(:);

    Xnext = combinedX(selected,:);
    Fnext = combinedF(selected,:);

end

 function d = dominates(a, b)
    d = all(a <= b) && any(a < b);
 end

 function W = moeadGenerateWeightVectors(N, M)
%MOEADGENERATEWEIGHTVECTORS
% Generates approximately uniformly distributed decomposition
% weight vectors on the unit simplex.
%
% Exactly N vectors are returned.

    if M == 2

        % Exact uniform distribution for bi-objective problems.
        w1 = linspace(0, 1, N)';

        W = ...
            [w1, 1 - w1];

        return;

    end

    if M == 3

        % -----------------------------------------------------------
        % Simplex-lattice design
        % -----------------------------------------------------------

        H = 1;

        while nchoosek(H + M - 1, M - 1) < N
            H = H + 1;
        end

        candidates = [];

        for i = 0:H

            for j = 0:(H-i)

                k = H - i - j;

                candidates = ...
                    [candidates; ...
                     i/H, j/H, k/H]; %#ok<AGROW>

            end

        end

        % If the lattice contains exactly N points, return directly.
        if size(candidates,1) == N

            W = candidates;
            return;

        end

        % -----------------------------------------------------------
        % Farthest-point subset selection
        % -----------------------------------------------------------
        % When the closest simplex lattice contains slightly more than
        % N vectors, select N well-spread vectors rather than simply
        % discarding the final rows.

        W = ...
            moeadFarthestWeightSubset( ...
                candidates, N);

        return;

    end

    % ---------------------------------------------------------------
    % Generic fallback for M > 3
    % ---------------------------------------------------------------
    % Not used by the current benchmark suite, but included for safety.

    raw = -log(max(rand(N, M), eps));

    W = ...
        raw ./ sum(raw, 2);

 end

 function W = moeadFarthestWeightSubset(candidates, N)
%MOEADFARTHESTWEIGHTSUBSET
% Selects a well-spread subset of simplex weight vectors using
% deterministic farthest-point sampling.

    nCandidates = size(candidates,1);

    if N >= nCandidates
        W = candidates;
        return;
    end

    selected = false(nCandidates,1);

    % Begin from one simplex extreme.
    [~, currentIdx] = ...
        max(candidates(:,1));

    selected(currentIdx) = true;

    minDistance = inf(nCandidates,1);

    for count = 2:N

        diffW = ...
            candidates - ...
            candidates(currentIdx,:);

        d = ...
            sqrt(sum(diffW.^2, 2));

        minDistance = ...
            min(minDistance, d);

        minDistance(selected) = -inf;

        [~, currentIdx] = ...
            max(minDistance);

        selected(currentIdx) = true;

    end

    W = candidates(selected,:);

    % Numerical simplex normalization.
    rowSum = sum(W,2);
    rowSum(rowSum <= eps) = 1;

    W = W ./ rowSum;

 end

 function value = moeadTchebycheff(f, weight, idealPoint)
%MOEADTCHEBYCHEFF
% Weighted Tchebycheff scalarizing function for minimization.

    w = weight;

    % Avoid a completely inactive objective when an extreme
    % decomposition vector contains a zero component.
    w(w <= 1e-6) = 1e-6;

    value = ...
        max( ...
            w .* ...
            abs(f - idealPoint) ...
        );

end
%% ========================================================================
%  MOFA / MOABC HELPER FUNCTIONS
%  ========================================================================

function [lb, ub] = makeBoundsVectorMO(varMin, varMax, nVar)
%MAKEBOUNDSVECTORMO
% Converts scalar or vector bounds to row vectors.

    if isscalar(varMin)
        lb = varMin * ones(1, nVar);
    else
        lb = varMin;
    end

    if isscalar(varMax)
        ub = varMax * ones(1, nVar);
    else
        ub = varMax;
    end

    if numel(lb) ~= nVar || numel(ub) ~= nVar
        error('Bounds dimension mismatch in makeBoundsVectorMO.');
    end
end


function accept = acceptCandidateMOO(fCand, fOld, archiveF)
%ACCEPTCANDIDATEMOO
% Accepts a candidate solution based on Pareto dominance and a secondary
% normalized scalar score when the two objective vectors are nondominated.

    if dominates(fCand, fOld)
        accept = true;
        return;
    end

    if dominates(fOld, fCand)
        accept = false;
        return;
    end

    % If neither dominates, use normalized scalarized score.
    if nargin < 3 || isempty(archiveF)
        refF = [fCand; fOld];
    else
        refF = [archiveF; fCand; fOld];
    end

    scoreCand = scalarScoreSingle(fCand, refF);
    scoreOld  = scalarScoreSingle(fOld,  refF);

    % Mild stochastic acceptance prevents over-greedy behavior.
    accept = (scoreCand < scoreOld) || (rand < 0.05);
end


function score = scalarScoreSingle(f, refF)
%SCALARSCORESINGLE
% Computes a simple normalized weighted-sum score for minimization.

    fMin = min(refF, [], 1);
    fMax = max(refF, [], 1);

    fN = (f - fMin) ./ (fMax - fMin + eps);

    score = sum(fN);
end


function scores = scalarScoresForPopulation(F)
%SCALARSCORESFORPOPULATION
% Computes normalized scalar scores for all objective vectors.

    fMin = min(F, [], 1);
    fMax = max(F, [], 1);

    FN = (F - fMin) ./ (fMax - fMin + eps);

    scores = sum(FN, 2);
end


function g = selectArchiveLeaderMO(archive)
%SELECTARCHIVELEADERMO
% Selects a nondominated archive member using crowding-distance probability.
% This keeps the baseline algorithms compatible with your archive strategy.

    if isempty(archive) || isempty(archive.F)
        error('Archive is empty in selectArchiveLeaderMO.');
    end

    N = size(archive.X, 1);

    if N == 1
        g = archive.X(1, :);
        return;
    end

    cd = crowdingDistance(archive.F);

    if all(isinf(cd))
        idx = randi(N);
        g = archive.X(idx, :);
        return;
    end

    finiteCD = cd(isfinite(cd));

    if isempty(finiteCD)
        idx = randi(N);
        g = archive.X(idx, :);
        return;
    end

    cd(isinf(cd)) = 10 * max(finiteCD);

    if sum(cd) <= 0 || any(~isfinite(cd))
        idx = randi(N);
    else
        p = cd ./ sum(cd);
        idx = rouletteSelectMO(p);
    end

    g = archive.X(idx, :);
end


function idx = rouletteSelectMO(p)
%ROULETTESELECTMO
% Roulette-wheel selection from a probability vector.

    p = p(:);

    if isempty(p) || sum(p) <= 0 || any(~isfinite(p))
        idx = randi(numel(p));
        return;
    end

    p = p ./ sum(p);

    r = rand;
    cp = cumsum(p);

    idx = find(cp >= r, 1, 'first');

    if isempty(idx)
        idx = numel(p);
    end
end


function [xCand, fCand] = generateABCNeighbor(i, X, func_no, lb, ub, phiMax)
%GENERATEABCNEIGHBOR
% Generates a candidate neighbor for MOABC.

    [nFood, nVar] = size(X);

    k = randi(nFood);
    while k == i
        k = randi(nFood);
    end

    phi = -phiMax + 2 * phiMax * rand(1, nVar);

    % Standard ABC perturbation
    xCand = X(i, :) + phi .* (X(i, :) - X(k, :));

    % Mutate a random subset of dimensions to avoid excessive disruption.
    mask = rand(1, nVar) < max(0.10, 1 / nVar);

    if ~any(mask)
        mask(randi(nVar)) = true;
    end

    xTemp = X(i, :);
    xTemp(mask) = xCand(mask);
    xCand = xTemp;

    xCand = max(min(xCand, ub), lb);

    fCand = CEC_MOFunctions(xCand, func_no);
end


function probs = computeMOABCSelectionProbabilities(F, archiveF)
%COMPUTEMOABCSELECTIONPROBABILITIES
% Computes source-selection probabilities for MOABC using normalized
% scalarized objective scores. Lower objective score means higher probability.

    N = size(F, 1);

    if nargin < 2 || isempty(archiveF)
        refF = F;
    else
        refF = [archiveF; F];
    end

    fMin = min(refF, [], 1);
    fMax = max(refF, [], 1);

    FN = (F - fMin) ./ (fMax - fMin + eps);

    score = sum(FN, 2);

    fitness = 1 ./ (1 + score);

    if sum(fitness) <= 0 || any(~isfinite(fitness))
        probs = ones(N, 1) ./ N;
    else
        probs = fitness ./ sum(fitness);
    end
end
function archive = updateArchive(archive, Xnew, Fnew, archiveSize)
    if isempty(archive)
        A_X = [];
        A_F = [];
    else
        A_X = archive.X;
        A_F = archive.F;
    end

    CombX = [A_X; Xnew];
    CombF = [A_F; Fnew];

    nd_idx = nondominatedSort(CombF);
    CombX = CombX(nd_idx,:);
    CombF = CombF(nd_idx,:);

    N = size(CombF,1);
    if N > archiveSize
        cd = crowdingDistance(CombF);
        [~, idxSort] = sort(cd, 'descend');
        keep = idxSort(1:archiveSize);
        CombX = CombX(keep,:);
        CombF = CombF(keep,:);
    end

    archive.X = CombX;
    archive.F = CombF;
end

function nd_idx = nondominatedSort(F)
    N = size(F,1);
    dominatedFlag = false(N,1);
    for i=1:N
        if dominatedFlag(i), continue; end
        for j=1:N
            if i==j, continue; end
            if all(F(j,:) <= F(i,:)) && any(F(j,:) < F(i,:))
                dominatedFlag(i) = true;
                break;
            end
        end
    end
    nd_idx = find(~dominatedFlag);
end

function cd = crowdingDistance(F)
    [N, M] = size(F);
    cd = zeros(N,1);
    if N <= 2
        cd(:) = inf;
        return;
    end
    
    for m=1:M
        [~, idx] = sort(F(:,m));
        fm = F(idx,m);
        fmin = fm(1);
        fmax = fm(end);
        
        cd(idx(1)) = inf;
        cd(idx(end)) = inf;
        
        if fmax - fmin == 0
            continue;
        end
        
        for k=2:N-1
            cd(idx(k)) = cd(idx(k)) + (fm(k+1) - fm(k-1)) / (fmax - fmin);
        end
    end
end

function g = selectLeader(archive)
    if isempty(archive) || isempty(archive.F)
        error('Archive is empty when selecting leader.');
    end
    
    N = size(archive.X, 1);
    
    if N == 1
        g = archive.X(1,:);
        return;
    end
    
    cd = crowdingDistance(archive.F);
    
    if all(isinf(cd))
        idx = randi(N);
        g = archive.X(idx,:);
        return;
    end
    
    max_finite = max(cd(~isinf(cd)));
    if isempty(max_finite) || max_finite == 0
        max_finite = 1;
    end
    cd(isinf(cd)) = max_finite * 10;
    
    probs = cd / sum(cd);
    if sum(probs) == 0
        idx = randi(N);
    else
        r = rand();
        cum = cumsum(probs);
        idx = find(cum >= r, 1, 'first');
        if isempty(idx)
            idx = N;
        end
    end
    
    g = archive.X(idx,:);
end


%% ========================================================================
%  SA-MOPSO-FVML-v2 HELPER FUNCTIONS
%  ========================================================================

function E_t = computeObjectiveDiversity(F)
%COMPUTEOBJECTIVEDIVERSITY
% Computes a normalized diversity indicator in objective space.
% This is more suitable for multi-objective optimization than using
% global max/min values over all objectives.

    epsVal = 1e-12;

    if isempty(F) || size(F,1) < 2
        E_t = 0;
        return;
    end

    fMin = min(F, [], 1);
    fMax = max(F, [], 1);

    Fnorm = (F - fMin) ./ (fMax - fMin + epsVal);

    center = mean(Fnorm, 1);
    distances = sqrt(sum((Fnorm - center).^2, 2));

    E_t = mean(distances);

    % Bound the value for numerical stability
    E_t = max(0, min(1, E_t));
end

function [w1, w2, w3, w4] = computeRawMemoryWeights(alpha, a_param, b_param, E_t)
%COMPUTERAWMEMORYWEIGHTS
% Computes the raw fractional-inspired velocity-memory coefficients.
%
% In this version, the memory coefficients are not normalized. This preserves
% the relative magnitude of the fractional-memory terms. Stability is handled
% later by applying a constriction factor to the complete velocity vector.

    sigmoid_term = a_param / (1 + exp(b_param * E_t));

    w1 = alpha - sigmoid_term;
    w2 = 0.5 * alpha;
    w3 = alpha * (1 - alpha) / 6;
    w4 = alpha * (1 - alpha) * (2 - alpha) / 24;
end
function [pbest, pbestF] = updatePersonalBestMOO(xNew, fNew, pbestOld, pbestFOld, archiveF)
%UPDATEPERSONALBESTMOO
% Updates the personal best in a multi-objective setting.
%
% Rule:
%   1) If the new solution dominates the previous pbest, update.
%   2) If the previous pbest dominates the new solution, keep old pbest.
%   3) If neither dominates, use a normalized scalarized secondary criterion.
%      A small random update probability is also used to avoid stagnation.

    if dominates(fNew, pbestFOld)
        pbest = xNew;
        pbestF = fNew;
        return;
    end

    if dominates(pbestFOld, fNew)
        pbest = pbestOld;
        pbestF = pbestFOld;
        return;
    end

    % Non-dominated with respect to each other:
    % use normalized scalarized score as secondary criterion.
    if nargin < 5 || isempty(archiveF)
        refF = [fNew; pbestFOld];
    else
        refF = [archiveF; fNew; pbestFOld];
    end

    fMin = min(refF, [], 1);
    fMax = max(refF, [], 1);

    fNewN = (fNew - fMin) ./ (fMax - fMin + eps);
    fOldN = (pbestFOld - fMin) ./ (fMax - fMin + eps);

    scoreNew = sum(fNewN);
    scoreOld = sum(fOldN);

    if scoreNew < scoreOld || rand < 0.10
        pbest = xNew;
        pbestF = fNew;
    else
        pbest = pbestOld;
        pbestF = pbestFOld;
    end
end


function g = selectLeaderGrid(archive, nGrid, beta)
%SELECTLEADERGRID
% Grid-based leader selection for multi-objective PSO.
%
% Less crowded grid cells are selected with higher probability.
% This reduces excessive leader selection from very dense archive regions.

    if isempty(archive) || isempty(archive.F)
        error('Archive is empty when selecting grid-based leader.');
    end

    X = archive.X;
    F = archive.F;

    N = size(F, 1);

    if N == 1
        g = X(1,:);
        return;
    end

    M = size(F, 2);

    fMin = min(F, [], 1);
    fMax = max(F, [], 1);

    Fnorm = (F - fMin) ./ (fMax - fMin + eps);

    gridIndex = floor(Fnorm * nGrid) + 1;
    gridIndex = max(min(gridIndex, nGrid), 1);

    multipliers = nGrid .^ (0:M-1);
    cellID = 1 + sum((gridIndex - 1) .* multipliers, 2);

    uniqueCells = unique(cellID);
    nCells = numel(uniqueCells);

    cellCounts = zeros(nCells, 1);

    for c = 1:nCells
        cellCounts(c) = sum(cellID == uniqueCells(c));
    end

    % Less crowded cells should have larger selection probability
    probCells = 1 ./ (cellCounts .^ beta);
    probCells = probCells / sum(probCells);

    r = rand;
    cumProb = cumsum(probCells);

    selectedCellIdx = find(cumProb >= r, 1, 'first');

    if isempty(selectedCellIdx)
        selectedCellIdx = nCells;
    end

    selectedCell = uniqueCells(selectedCellIdx);

    members = find(cellID == selectedCell);

    selectedMember = members(randi(numel(members)));

    g = X(selectedMember, :);
end

function changed = hasArchiveChanged(Fold, Fnew)
%HASARCHIVECHANGED
% Checks whether the archive objective set has changed.

    if isempty(Fold) && isempty(Fnew)
        changed = false;
        return;
    end

    if isempty(Fold) || isempty(Fnew)
        changed = true;
        return;
    end

    if size(Fold,1) ~= size(Fnew,1) || size(Fold,2) ~= size(Fnew,2)
        changed = true;
        return;
    end

    Fold = sortrows(Fold);
    Fnew = sortrows(Fnew);

    diffVal = max(abs(Fold(:) - Fnew(:)));

    changed = diffVal > 1e-10;
end


function [particle, F] = applyMittagLefflerMutation( ...
    particle, F, archive, func_no, varMin, varMax, ...
    ml_alpha, ml_scale, ml_rmax, ...
    mutationRate, sigmaMax, sigmaMin, ...
    it, maxIter, mlNormMode)
%APPLYMITTAGLEFFLERMUTATION
% Applies bounded Mittag-Leffler position mutation when the archive stagnates.
%
% This operator is not applied at every iteration. It is only triggered
% after stagnation, so it acts as an escape mechanism rather than a permanent
% disturbance in the velocity dynamics.

    popSize = numel(particle);
    nVar = numel(particle(1).x);

    nMut = max(1, ceil(mutationRate * popSize));

    selected = randperm(popSize, nMut);

    sigma = sigmaMin + (sigmaMax - sigmaMin) * (1 - it / maxIter);

    range = varMax - varMin;

    if isscalar(range)
        range = range * ones(1, nVar);
    end

    for k = 1:nMut

        idx = selected(k);

        % Direction is symmetric around zero
        direction = 2 * rand(1, nVar) - 1;

mlStep = mittagLefflerRand(ml_alpha, ml_scale, [1, nVar], ...
    'QuantileLevel', 0.95, ...
    'RMax', ml_rmax, ...
    'UnitInterval', false, ...
    'NormalizationMode', mlNormMode);

        xCandidate = particle(idx).x + sigma .* range .* mlStep .* direction;

        xCandidate = max(min(xCandidate, varMax), varMin);

        fCandidate = CEC_MOFunctions(xCandidate, func_no);

       % Accept if it improves pbest. If neither solution dominates the other,
        % accept with a moderate probability to help escape stagnation.
      if dominates(fCandidate, particle(idx).pbestF) || ...
   (~dominates(particle(idx).pbestF, fCandidate) && rand < 0.20)

    particle(idx).x = xCandidate;

    % The candidate has already been objectively evaluated above.
    % Store that value directly so that the complete population
    % does not need to be re-evaluated after mutation.
    F(idx,:) = fCandidate;

    % Reset velocity history after mutation to avoid carrying
    % inconsistent momentum from the pre-mutation trajectory.
    particle(idx).v_hist(:,:) = 0;

    [particle(idx).pbest, particle(idx).pbestF] = updatePersonalBestMOO( ...
        particle(idx).x, fCandidate, ...
        particle(idx).pbest, particle(idx).pbestF, ...
        archive.F);
end
    end
end
   
 

function archive = getArchiveByTestFunctionIndex(all_results, test_functions, func_no, algoField) 
%GETARCHIVEBYTESTFUNCTIONINDEX 
% Robustly extracts the selected archive using test_functions indexing. 
% This avoids relying on all_results.func_no, which may be missing if not
%  % stored consistently in the main loop. 
idx = find(test_functions == func_no, 1, 'first');
if isempty(idx) 
    error('Function #%d is not included in test_functions.', func_no); 
end
if numel(all_results) < idx
    error(['all_results has only %d entries, but function #%d is expected at index %d. ', ...
        'This usually means the main loop stopped before completing all test functions.'], ...
        numel(all_results), func_no, idx);
end
if ~isfield(all_results(idx), algoField)
    disp('Available fields in all_results(idx):'); 
    disp(fieldnames(all_results(idx))); 
    error('Algorithm field "%s" was not found for Function #%d.', algoField, func_no); 
end 
if ~isfield(all_results(idx).(algoField), 'MedianArchive')

    error(['MedianArchive was not found for algorithm "%s" ', ...
           'on Function #%d.'], ...
           algoField, func_no);

end

archive = ...
    all_results(idx).(algoField).MedianArchive;

if isempty(archive) || ...
        ~isfield(archive, 'F') || ...
        isempty(archive.F)

    error(['MedianArchive for algorithm "%s" on Function #%d ', ...
           'is empty or invalid.'], ...
           algoField, func_no);

end
end