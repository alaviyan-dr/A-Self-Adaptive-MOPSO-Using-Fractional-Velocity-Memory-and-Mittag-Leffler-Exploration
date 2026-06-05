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

outDir = fullfile(pwd, 'results');
figDir = fullfile(pwd, 'figures');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if ~exist(figDir, 'dir')
    mkdir(figDir);
end
%% Dependency check
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

if exist('CEC_MOFunctions', 'file') ~= 2
    error(['CEC_MOFunctions.m was not found. ', ...
           'Please add CEC_MOFunctions.m to the MATLAB path or the project folder.']);
end
%% ========================================================================
%  EXPERIMENTAL CONFIGURATION
%  ========================================================================

% Test functions to evaluate (1-10)
 test_functions = [1, 2, 3,4, 5,6,7, 8,9, 10]; 
 % test_functions = [1,3]; 
%test_functions = [1, 2, 3, 5, 7, 10];
%test_functions = [2, 4, 6];
%test_functions = [1, 2, 3];

% Algorithms to compare
  % algorithms = { ...
  %   'SA-MOPSO-FVML', ...
  %   'Classical-MOPSO', ...
  %   'MOPSO-CD', ...
  %   'MOFA', ...
  %   'MOABC'};
algorithms = { ...
    'SA-MOPSO-FVML', ...
    'Classical-MOPSO', ...
    'MOPSO-CD', ...
    'MOPSO-FM', ...
    'MOPSO-ML', ...
    'MOPSO-Grid', ...
    'MOFA', ...
    'MOABC'};

n_algorithms = length(algorithms);
algoFields = cellfun(@matlab.lang.makeValidName, algorithms, 'UniformOutput', false);

% Number of independent runs for statistical significance
n_runs =30;

% Common parameters
popSize = 100;
maxIter = 250;
archiveSize = 100;

% Results storage

all_results = struct();

%% ========================================================================
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

        for run = 1:n_runs

            tic;

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
        archive = run_MOPSO_Grid(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax);

    case 'MOFA'
        archive = run_MOFA(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax);

    case 'MOABC'
        archive = run_MOABC(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax);

    otherwise
        error('Unknown algorithm name: %s', algo_name);
end
            Time_runs(run) = toc;
            Archives{run} = archive;

            % Collect all objective vectors for common reference point
            if isfield(archive, 'F') && ~isempty(archive.F)
                all_objective_values = [all_objective_values; archive.F];
            end
        end

        fprintf('Done (Avg time: %.2fs)\n', mean(Time_runs));

        function_results.(algo_field).Time     = Time_runs;
        function_results.(algo_field).Archives = Archives;
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

        % Keep best archive based on the corrected HV values
        best_idx = find(HV_runs == max(HV_runs), 1, 'first');
        all_results(func_idx).(algo_field).BestArchive = Archives{best_idx};

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

if hasRanksum
    statistical_results = performStatisticalTests(all_results, test_functions, algoFields);
else
    statistical_results = struct();
    fprintf('Statistical tests skipped because ranksum is not available.\n');
end
statistical_results = performStatisticalTests(all_results, test_functions, algoFields);

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

% 5. Sensitivity Analysis
%performSensitivityAnalysis();

% 6. Computational Complexity
analyzeComputationalComplexity(all_results, test_functions, algoFields);

fprintf('\n========================================\n');
fprintf('ALL ANALYSES COMPLETED!\n');
fprintf('========================================\n');
%% Save complete results
save(fullfile(outDir, 'SA_MOPSO_FVML_benchmark_results.mat'), ...
    'all_results', ...
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

function archive = run_SAMOPSO_FVML(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax)
%RUN_SAMOPSO_FVML
% Adaptive SA-MOPSO-FVML:
%   1) Fractional velocity memory is activated adaptively, not permanently.
%   2) Mittag-Leffler-uniform mixture remains the main exploration mechanism.
%   3) Leader selection switches probabilistically between crowding-based
%      and grid-based archive leaders.
%   4) No ASF/convergence leader is used in the final version.
%   5) Stagnation-triggered Mittag-Leffler mutation is preserved as an
%      escape operator.

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

    %% ---------------------------------------------------------------
    %  Main loop
    %  ---------------------------------------------------------------

    for it = 1:maxIter

        X = vertcat(particle.x);
        F = evaluateCECMO(X, func_no);

        % Objective-space diversity
        E_t = computeObjectiveDiversity(F);

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

        % Adaptive ML contribution:
        % ML remains active, but becomes stronger during exploration,
        % diversity loss, or stagnation.
        pML = pML_min + (pML_max - pML_min) * ...
              max([iterFactor, 1 - E_t, stagnationFactor]);
        pML = min(max(pML, pML_min), pML_max);

        % Adaptive ML upper bound
        ml_rmax_t = ml_rmax_min + (ml_rmax_max - ml_rmax_min) * ...
                    max([iterFactor, 1 - E_t, stagnationFactor]);
        ml_rmax_t = min(max(ml_rmax_t, ml_rmax_min), ml_rmax_max);

        % Adaptive grid-leader probability:
        % Grid leader is used more when diversity is low or archive stagnates.
        pGrid = pGrid_min + (pGrid_max - pGrid_min) * ...
                max(lowDiversityForGrid, stagnationFactor);
        pGrid = min(max(pGrid, pGrid_min), pGrid_max);

        % Raw fractional memory coefficients
        [w1, w2, w3, w4] = computeRawMemoryWeights(alpha, a_param, b_param, E_t);

        % Classical inertia fallback
        w_classic = w_max - (w_max - w_min) * (it / maxIter);

        for i = 1:popSize

            %% -------------------------------------------------------
            %  Hybrid leader selection
            %  -------------------------------------------------------
            % No ideal-point or ASF convergence leader is used.
            % The leader is selected either by grid-based diversity pressure
            % or by the original crowding-distance-based selection.

            if rand < pGrid
                g = selectLeaderGrid(archive, nGrid, leaderBeta);
            else
                g = selectLeader(archive);
            end

            %% -------------------------------------------------------
            %  ML-uniform stochastic coefficients
            %  -------------------------------------------------------

            u1 = rand(1, nVar);
            u2 = rand(1, nVar);

            ml1 = mittagLefflerRand(ml_alpha, ml_scale, [1, nVar], ...
                'QuantileLevel', 0.95, ...
                'RMax', ml_rmax_t, ...
                'UnitInterval', false);

            ml2 = mittagLefflerRand(ml_alpha, ml_scale, [1, nVar], ...
                'QuantileLevel', 0.95, ...
                'RMax', ml_rmax_t, ...
                'UnitInterval', false);

            r1 = (1 - pML) .* u1 + pML .* ml1;
            r2 = (1 - pML) .* u2 + pML .* ml2;

            %% -------------------------------------------------------
            %  Adaptive velocity-memory term
            %  -------------------------------------------------------
            % Fractional memory is not always active. When inactive,
            % the algorithm falls back to classical first-order velocity.

            if rand < pMem
                memoryTerm = ...
                    w1 * particle(i).v_hist(1,:) + ...
                    w2 * particle(i).v_hist(2,:) + ...
                    w3 * particle(i).v_hist(3,:) + ...
                    w4 * particle(i).v_hist(4,:);
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

        if stagnationCounter >= stallLimit

            particle = applyMittagLefflerMutation( ...
                particle, archive, func_no, ...
                varMin, varMax, ...
                ml_alpha, ml_scale, ml_rmax_t, ...
                mutationRate, sigmaMax, sigmaMin, it, maxIter);

            X = vertcat(particle.x);
            F = evaluateCECMO(X, func_no);

            archive = updateArchive(archive, X, F, archiveSize);

            previousArchiveF = archive.F;
            stagnationCounter = 0;
        end
    end
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

    particle = initializeParticles(popSize, nVar, nObj, varMin, varMax, func_no);
    archive = updateArchive([], vertcat(particle.x), evaluateCECMO(vertcat(particle.x), func_no), archiveSize);

    for it = 1:maxIter

        F = evaluateCECMO(vertcat(particle.x), func_no);
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

    particle = initializeParticles(popSize, nVar, nObj, varMin, varMax, func_no);
    archive = updateArchive([], vertcat(particle.x), evaluateCECMO(vertcat(particle.x), func_no), archiveSize);

    for it = 1:maxIter

        F = evaluateCECMO(vertcat(particle.x), func_no);
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

function archive = run_MOFA(func_no, nVar, nObj, popSize, maxIter, archiveSize, varMin, varMax)
%RUN_MOFA
% Multi-Objective Firefly Algorithm with external nondominated archive.
%
% This implementation is tuned to be compatible with the current benchmark
% framework:
%   - same input/output format as MOPSO variants
%   - same archive update function
%   - minimization-based dominance
%   - crowding-distance-based archive leader assistance
%
% Output:
%   archive.X : nondominated decision vectors
%   archive.F : objective vectors

    [lb, ub] = makeBoundsVectorMO(varMin, varMax, nVar);
    range = ub - lb;

    % Firefly parameters
    beta0 = 1.0;        % base attractiveness
    gamma = 1.0;        % light absorption coefficient
    alpha0 = 0.25;      % initial randomization amplitude
    alphaMin = 0.02;    % final randomization amplitude
    alphaDecay = (alphaMin / alpha0)^(1 / maxIter);

    % Small archive-guided component
    pArchiveGuide = 0.30;

    % Initialize population
    X = lb + rand(popSize, nVar) .* range;
    F = evaluateCECMO(X, func_no);

    archive = updateArchive([], X, F, archiveSize);

    alpha = alpha0;

    for it = 1:maxIter

        % Sort by a scalarized normalized score only to make the pairwise
        % loop more stable; dominance is still used for actual acceptance.
        scores = scalarScoresForPopulation(F);
        [~, order] = sort(scores, 'ascend');

        X = X(order, :);
        F = F(order, :);

        for i = 1:popSize

            xi = X(i, :);
            fi = F(i, :);

            xBestLocal = xi;
            fBestLocal = fi;

            % Move firefly i toward brighter/nondominating fireflies.
            for j = 1:popSize

                if i == j
                    continue;
                end

                xj = X(j, :);
                fj = F(j, :);

                % A firefly is considered attractive if it dominates the
                % current firefly or has a better scalarized score.
                attractive = dominates(fj, fi) || ...
                    (~dominates(fi, fj) && scalarScoreSingle(fj, [F; archive.F]) < scalarScoreSingle(fi, [F; archive.F]));

                if attractive

                    rij2 = sum(((xi - xj) ./ (range + eps)).^2);
                    beta = beta0 * exp(-gamma * rij2);

                    stepRandom = alpha .* range .* (rand(1, nVar) - 0.5);

                    xCand = xi + beta .* (xj - xi) + stepRandom;
                    xCand = max(min(xCand, ub), lb);

                    fCand = CEC_MOFunctions(xCand, func_no);

                    if acceptCandidateMOO(fCand, fBestLocal, archive.F)
                        xBestLocal = xCand;
                        fBestLocal = fCand;
                    end
                end
            end

            % Occasional archive-guided movement helps maintain Pareto-front
            % coverage and prevents pure pairwise attraction from stagnating.
            if rand < pArchiveGuide && ~isempty(archive) && ~isempty(archive.F)

                g = selectArchiveLeaderMO(archive);

                rij2 = sum(((xBestLocal - g) ./ (range + eps)).^2);
                beta = beta0 * exp(-gamma * rij2);

                stepRandom = 0.5 * alpha .* range .* (rand(1, nVar) - 0.5);

                xCand = xBestLocal + beta .* (g - xBestLocal) + stepRandom;
                xCand = max(min(xCand, ub), lb);

                fCand = CEC_MOFunctions(xCand, func_no);

                if acceptCandidateMOO(fCand, fBestLocal, archive.F)
                    xBestLocal = xCand;
                    fBestLocal = fCand;
                end
            end

            X(i, :) = xBestLocal;
            F(i, :) = fBestLocal;
        end

        archive = updateArchive(archive, X, F, archiveSize);

        alpha = alpha * alphaDecay;
        alpha = max(alpha, alphaMin);
    end

    % Final nondominated archive
    archive = updateArchive([], archive.X, archive.F, archiveSize);
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
        nObj = size(all_results(func_idx).('SA_MOPSO_FVML').BestArchive.F, 2);

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

            archive = all_results(func_idx).(algo_field).BestArchive;

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
function performSensitivityAnalysis()
    fprintf('\n========================================\n');
    fprintf('SENSITIVITY ANALYSIS\n');
    fprintf('========================================\n');
    
    % Test alpha parameter
    alpha_values = [0.5, 0.6, 0.7, 0.8, 0.9];
    fprintf('\nTesting alpha parameter: ');
    fprintf('%.1f ', alpha_values);
    fprintf('\n(Run full sensitivity test for complete results)\n');
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
%MITTAGLEFFLERRAND  Bounded Mittag-Leffler-based stochastic coefficients.
%
%   rStar = mittagLefflerRand(alpha, scale, sz)
%   generates stochastic coefficients based on a positive one-parameter
%   Mittag-Leffler random variable with tail index alpha.
%
%   The raw random variable X follows the standard positive Mittag-Leffler
%   law with Laplace transform
%
%       E[exp(-sX)] = 1 / (1 + s^alpha),      0 < alpha <= 1.
%
%   The generated raw samples are then scaled, quantile-normalized, and
%   truncated to obtain numerically stable PSO acceleration coefficients.
%
%   Inputs:
%       alpha : Mittag-Leffler tail parameter, 0 < alpha <= 1
%       scale : positive scale factor
%       sz    : output size, e.g., [N, D]
%
%   Optional name-value pairs:
%       'QuantileLevel' : normalization quantile, default 0.95
%       'RMax'          : upper truncation bound, default 2.0
%       'UnitInterval'  : if true, maps output to [0,1], default false
%
%   Output:
%       rStar : bounded Mittag-Leffler-based stochastic coefficients

    p = inputParser;
    addParameter(p, 'QuantileLevel', 0.95, @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 1);
    addParameter(p, 'RMax', 2.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'UnitInterval', false, @(x) islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    qLevel = p.Results.QuantileLevel;
    rMax   = p.Results.RMax;
    unitInterval = logical(p.Results.UnitInterval);

    if nargin < 3 || isempty(sz)
        sz = [1, 1];
    end

    if alpha <= 0 || alpha > 1
        error('For the positive Mittag-Leffler sampler used here, alpha must satisfy 0 < alpha <= 1.');
    end

    if scale <= 0
        error('The scale parameter must be positive.');
    end

    n = prod(sz);

    % Avoid exactly 0 or 1 for numerical stability.
    U = max(rand(n, 1), realmin);
    V = min(max(rand(n, 1), eps), 1 - eps);

    if abs(alpha - 1) < 1e-12
        % For alpha = 1, the standard Mittag-Leffler law reduces to
        % the exponential distribution.
        X = -log(U);
    else
        % Kozubowski--Rachev representation of the positive
        % one-parameter Mittag-Leffler distribution:
        %
        % X = -log(U) * [ sin(pi*alpha)/tan(pi*alpha*V)
        %                 - cos(pi*alpha) ]^(1/alpha)
        %
        theta = pi * alpha;
        A = sin(theta) ./ tan(theta * V) - cos(theta);

        % Round-off protection: theoretically A is positive.
        A = max(A, realmin);

        X = -log(U) .* (A .^ (1 / alpha));
    end

   

    % Robust quantile normalization. This is preferable to max-normalization,
    % because a single extreme sample should not determine the scale of all
    % generated coefficients.
    qVal = localQuantile(X, qLevel);
    if qVal <= 0 || ~isfinite(qVal)
        qVal = max(median(X), realmin);
    end

rStar = scale .* (X ./ qVal);
    % Truncate extreme coefficients to avoid numerical instability in PSO.
    rStar = min(rStar, rMax);

    % Optional mapping to [0,1]. Use this only if the algorithm requires
    % acceleration coefficients in the classical PSO range.
    if unitInterval
        rStar = rStar ./ rMax;
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

function d = dominates(a, b)
    d = all(a <= b) && any(a < b);
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


function particle = applyMittagLefflerMutation(particle, archive, func_no, varMin, varMax, ...
    ml_alpha, ml_scale, ml_rmax, mutationRate, sigmaMax, sigmaMin, it, maxIter)
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
            'UnitInterval', false);

        xCandidate = particle(idx).x + sigma .* range .* mlStep .* direction;

        xCandidate = max(min(xCandidate, varMax), varMin);

        fCandidate = CEC_MOFunctions(xCandidate, func_no);

       % Accept if it improves pbest. If neither solution dominates the other,
        % accept with a moderate probability to help escape stagnation.
        if dominates(fCandidate, particle(idx).pbestF) || ...
           (~dominates(particle(idx).pbestF, fCandidate) && rand < 0.20)

            particle(idx).x = xCandidate;

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
if ~isfield(all_results(idx).(algoField), 'BestArchive') 
    error('BestArchive was not found for algorithm "%s" on Function #%d.', algoField, func_no);
end
archive = all_results(idx).(algoField).BestArchive;
if isempty(archive) || ~isfield(archive, 'F') || isempty(archive.F)
    error('BestArchive for algorithm "%s" on Function #%d is empty or invalid.', algoField, func_no); 
end 
end