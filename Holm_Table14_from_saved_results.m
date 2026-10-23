%% Holm-Bonferroni correction of Table 14 (no optimization rerun)
% SA-MOPSO-FVML / Applied Soft Computing, revision diagnostic.
% Input : SA_MOPSO_FVML_benchmark_results.mat (30-run main benchmark)
% Output: Table14_Holm_Details.csv, Table14_Holm_Symbols.csv,
%         Table14_Holm_Workspace.mat, Table14_Holm_Table.tex
% The correction is applied jointly to 100 comparisons:
%   10 functions x 10 SA-versus-competitor comparisons.

clearvars; clc;

% Locate the existing benchmark MAT file, without running the optimizers.
matFile = fullfile(pwd, 'results', 'SA_MOPSO_FVML_benchmark_results.mat');
if ~isfile(matFile)
    [fn, fp] = uigetfile('*.mat', ...
        'Select the existing SA_MOPSO_FVML_benchmark_results.mat');
    if isequal(fn, 0)
        error('No MAT file was selected.');
    end
    matFile = fullfile(fp, fn);
end

S = load(matFile);
if ~isfield(S, 'all_results') || ~isfield(S, 'algoFields')
    error(['The selected MAT file must contain all_results and algoFields ', ...
           'from the 30-run main benchmark.']);
end

R = S.all_results;
fields = S.algoFields;
if isstring(fields) || ischar(fields)
    fields = cellstr(fields);
elseif ~iscell(fields)
    error('algoFields must be a cell array of names or a string array.');
end
if isfield(S, 'test_functions')
    funs = S.test_functions(:)';
else
    funs = [R.func_no];
end

if numel(R) ~= 10 || numel(fields) ~= 11 || numel(funs) ~= 10
    error('Expected 10 functions and 11 algorithms; verify the input MAT file.');
end
if ~strcmp(fields{1}, 'SA_MOPSO_FVML')
    error('First algorithm must be SA_MOPSO_FVML.');
end
if exist('ranksum', 'file') ~= 2
    error('MATLAB ranksum requires the Statistics and Machine Learning Toolbox.');
end

alpha = 0.05;
nFunctions = numel(funs);
nCompetitors = numel(fields) - 1;
m = nFunctions * nCompetitors;     % 100 total tests

rawP = nan(m, 1);
problemId = nan(m, 1);
competitorName = strings(m, 1);
medianSA = nan(m, 1);
medianCompetitor = nan(m, 1);

idx = 0;
for f = 1:nFunctions
    x = R(f).(fields{1}).HV(:);
    x = x(isfinite(x));
    if numel(x) ~= 30
        error('F%d: baseline has %d finite runs, not 30.', funs(f), numel(x));
    end
    for c = 1:nCompetitors
        idx = idx + 1;
        name = fields{c+1};
        y = R(f).(name).HV(:);
        y = y(isfinite(y));
        if numel(y) ~= 30
            error('F%d, %s: %d finite runs, not 30.', funs(f), name, numel(y));
        end
        rawP(idx) = ranksum(x, y, 'tail', 'both');
        problemId(idx) = funs(f);
        competitorName(idx) = string(name);
        medianSA(idx) = median(x);
        medianCompetitor(idx) = median(y);
    end
end

% Correct Holm step-down adjusted p-values across the full family.
[sortedP, sortedIndex] = sort(rawP, 'ascend');
adjustedSorted = (m - (1:m)' + 1) .* sortedP;
adjustedSorted = min(1, cummax(adjustedSorted));
adjustedP = nan(m, 1);
adjustedP(sortedIndex) = adjustedSorted;

rawSignificant = rawP <= alpha;
holmSignificant = adjustedP <= alpha;
rawSymbols = strings(m, 1);
holmSymbols = strings(m, 1);
for i = 1:m
    if medianSA(i) > medianCompetitor(i)
        direction = '+';
    elseif medianSA(i) < medianCompetitor(i)
        direction = '-';
    else
        direction = '=';  % no claim of direction if medians are equal
    end
    rawSymbols(i) = "~";
    holmSymbols(i) = "~";
    if rawSignificant(i)
        rawSymbols(i) = string(direction);
    end
    if holmSignificant(i)
        holmSymbols(i) = string(direction);
    end
end

changed = rawSymbols ~= holmSymbols;

T = table(problemId, competitorName, medianSA, medianCompetitor, ...
    rawP, adjustedP, rawSymbols, holmSymbols, changed, ...
    'VariableNames', {'Function','Competitor','MedianSA','MedianCompetitor', ...
    'RawP','HolmAdjustedP','NominalSymbol','HolmSymbol','Changed'});

outDir = fileparts(matFile);
writetable(T, fullfile(outDir, 'Table14_Holm_Details.csv'));

symbols = strings(nFunctions, nCompetitors);
for f = 1:nFunctions
    rows = (f-1)*nCompetitors + (1:nCompetitors);
    symbols(f,:) = holmSymbols(rows)';
end
symbolTable = array2table(symbols, 'VariableNames', fields(2:end));
symbolTable = addvars(symbolTable, funs(:), 'Before', 1, 'NewVariableNames', 'Function');
writetable(symbolTable, fullfile(outDir, 'Table14_Holm_Symbols.csv'));

save(fullfile(outDir, 'Table14_Holm_Workspace.mat'), ...
    'T','symbolTable','rawP','adjustedP','alpha','m','changed');

fprintf('\n============================================================\n');
fprintf('HOLM CORRECTION - MAIN 30-RUN BENCHMARK\n');
fprintf('Family: %d tests, alpha=%.3f\n', m, alpha);
fprintf('Significant without correction: %d\n', sum(rawSignificant));
fprintf('Significant after Holm:        %d\n', sum(holmSignificant));
fprintf('Changed table cells:          %d\n', sum(changed));
fprintf('============================================================\n');

fprintf('\nChanged comparisons (if any):\n');
for i = find(changed)'
    fprintf('F%-2d %-20s raw p=%.7g | Holm p=%.7g | %s -> %s\n', ...
        problemId(i), char(competitorName(i)), rawP(i), adjustedP(i), ...
        char(rawSymbols(i)), char(holmSymbols(i)));
end

fprintf('\nTable 14 corrected symbols (~ means no significant difference):\n');
for f = 1:nFunctions
    fprintf('F%-2d : ', funs(f));
    for c = 1:nCompetitors
        fprintf('%-3s ', char(symbols(f,c)));
    end
    fprintf('\n');
end

% Generate a ready-to-paste LaTeX Table 14.
texPath = fullfile(outDir, 'Table14_Holm_Table.tex');
fid = fopen(texPath, 'w');
assert(fid > 0, 'Unable to open LaTeX table output.');
fprintf(fid, '%% Holm-corrected Table 14; automatically generated from saved 30-run HV data.\n');
fprintf(fid, '\\begin{table}[t]\n');
fprintf(fid, '\\centering\n\\scriptsize\n');
fprintf(fid, '\\caption{Two-sided Wilcoxon rank-sum comparisons of the 30-run HV distributions between SA-MOPSO-FVML and ten competing algorithms. Holm--Bonferroni correction was applied across all 100 pairwise comparisons at family-wise $\\alpha=0.05$. Symbols $+$ and $-$ denote significantly higher and lower HV for SA-MOPSO-FVML, respectively; $\\approx$ denotes no statistically significant difference after correction.}\n');
fprintf(fid, '\\label{tab:holm_hv_comparison}\n');
fprintf(fid, '\\resizebox{\\textwidth}{!}{%%\n');
fprintf(fid, '\\begin{tabular}{l*{10}{c}}\n\\toprule\n');
fprintf(fid, 'Problem & Classical & MOPSO-CD & MOPSO-FM & MOPSO-ML & MOPSO-Grid & Levy-MOPSO & NSGA-II & MOEA/D & MOFA & MOABC \\\\\n');
fprintf(fid, '\\midrule\n');
for f = 1:nFunctions
    fprintf(fid, 'F%d', funs(f));
    for c = 1:nCompetitors
        token = char(symbols(f,c));
        if strcmp(token, '~')
            token = '$\\approx$';
        elseif strcmp(token, '-')
            token = '$-$';
        else
            token = '$+$';
        end
        fprintf(fid, ' & %s', token);
    end
    fprintf(fid, ' \\\\\n');
end
fprintf(fid, '\\bottomrule\n\\end{tabular}%%\n}\\end{table}\n');
fclose(fid);

fprintf('\nOutputs written to: %s\n', outDir);
fprintf('LaTeX table: %s\n', texPath);
