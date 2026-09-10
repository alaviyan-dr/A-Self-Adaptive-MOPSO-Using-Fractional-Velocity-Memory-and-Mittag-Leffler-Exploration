function f = CEC_MOFunctions(x, func_no)
% CEC_MOFunctions
%   Multi-objective benchmark functions (MO-CEC style)
%
%   Usage:
%       func_no = 1;
%       f = CEC_MOFunctions(x, func_no);
%
%   Output:
%       f = [f1, f2, ... fM]
%
% Count objective-function evaluations for benchmark diagnostics.
global FE_COUNT

if isempty(FE_COUNT)
    FE_COUNT = 0;
end

FE_COUNT = FE_COUNT + 1;
    x = x(:)';         % Ensure row vector
    D = length(x);     % Dimension

    switch func_no
        
        %% ------------------------------------------------------------
        % 1) ZDT1  (2 objectives)
        %% ------------------------------------------------------------
        case 1
            f = ZDT1(x);

        %% ------------------------------------------------------------
        % 2) ZDT2 (2 objectives)
        %% ------------------------------------------------------------
        case 2
            f = ZDT2(x);

        %% ------------------------------------------------------------
        % 3) ZDT3 (2 objectives)
        %% ------------------------------------------------------------
        case 3
            f = ZDT3(x);

        %% ------------------------------------------------------------
        % 4) DTLZ1  (3 objectives)
        %% ------------------------------------------------------------
        case 4
            f = DTLZ1(x,3);

        %% ------------------------------------------------------------
        % 5) DTLZ2 (3 objectives)
        %% ------------------------------------------------------------
        case 5
            f = DTLZ2(x,3);

        %% ------------------------------------------------------------
        % 6) DTLZ3 (3 objectives)
        %% ------------------------------------------------------------
        case 6
            f = DTLZ3(x,3);

        %% ------------------------------------------------------------
        % 7) DTLZ4 (3 objectives)
        %% ------------------------------------------------------------
        case 7
            f = DTLZ4(x,3);

        %% ------------------------------------------------------------
        % 8) Convex–Concave MOP (CEC-style custom)
        %% ------------------------------------------------------------
        case 8
            f = CEC_ConvexConcave(x);

        %% ------------------------------------------------------------
        % 9) Rosenbrock-based bi-objective
        %% ------------------------------------------------------------
        case 9
            f = CEC_Rosenbrock_MO(x);

        %% ------------------------------------------------------------
        % 10) Rastrigin-based multiobjective
        %% ------------------------------------------------------------
        case 10
            f = CEC_Rastrigin_MO(x);

        otherwise
            error('Function number not defined (use 1–10).');
    end

end

%% =====================================================================
%%                  IMPLEMENTATION OF BENCHMARK FUNCTIONS
%% =====================================================================

%% ---------------- ZDT1 ----------------
function f = ZDT1(x)
    g = 1 + 9*mean(x(2:end));
    f1 = x(1);
    f2 = g*(1 - sqrt(x(1)/g));
    f = [f1, f2];
end

%% ---------------- ZDT2 ----------------
function f = ZDT2(x)
    g = 1 + 9*mean(x(2:end));
    f1 = x(1);
    f2 = g*(1 - (x(1)/g)^2);
    f = [f1, f2];
end

%% ---------------- ZDT3 ----------------
function f = ZDT3(x)
    g = 1 + 9*mean(x(2:end));
    f1 = x(1);
    f2 = g*(1 - sqrt(x(1)/g) - (x(1)/g)*sin(10*pi*x(1)));
    f = [f1, f2];
end

%% ---------------- DTLZ1 ----------------
function f = DTLZ1(x, M)
    k = length(x) - M + 1;
    g = 100*(k + sum((x(end-k+1:end)-0.5).^2 - cos(20*pi*(x(end-k+1:end)-0.5))));
    f = zeros(1,M);
    for m = 1:M
        f(m) = 0.5*(1 + g)*prod(x(1:M-m));
        if m > 1
            f(m) = f(m)*(1 - x(M-m+1));
        end
    end
end

%% ---------------- DTLZ2 ----------------
function f = DTLZ2(x, M)
    k = length(x) - M + 1;
    g = sum((x(end-k+1:end)-0.5).^2);
    f = zeros(1,M);
    for m = 1:M
        f(m) = (1 + g);
        for i = 1:M-m
            f(m) = f(m)*cos(x(i)*pi/2);
        end
        if m > 1
            f(m) = f(m)*sin(x(M-m+1)*pi/2);
        end
    end
end

%% ---------------- DTLZ3 ----------------
function f = DTLZ3(x, M)
    k = length(x) - M + 1;
    g = 100*(k + sum((x(end-k+1:end)-0.5).^2 - cos(20*pi*(x(end-k+1:end)-0.5))));
    f = zeros(1,M);
    for m = 1:M
        f(m) = (1 + g);
        for i = 1:M-m
            f(m) = f(m)*cos(x(i)*pi/2);
        end
        if m > 1
            f(m) = f(m)*sin(x(M-m+1)*pi/2);
        end
    end
end

%% ---------------- DTLZ4 ----------------
%% ---------------- DTLZ4 ----------------
function f = DTLZ4(x, M)
%DTLZ4 Standard DTLZ4 benchmark problem.
%
% The bias exponent alpha is applied only to the angular decision
% variables x(1:M-1). The distance-related variables used in g
% remain untransformed, according to the standard DTLZ4 definition.

    alpha = 100;

    % Number of distance-related variables
    k = length(x) - M + 1;

    % Standard DTLZ4 distance function:
    % use the ORIGINAL decision variables x(M:end)
    g = sum((x(end-k+1:end) - 0.5).^2);

    f = zeros(1, M);

    for m = 1:M

        f(m) = 1 + g;

        % Cosine terms involving the biased angular variables
        for i = 1:(M-m)

            f(m) = f(m) * ...
                cos((x(i)^alpha) * pi/2);

        end

        % Sine term
        if m > 1

            idx = M - m + 1;

            f(m) = f(m) * ...
                sin((x(idx)^alpha) * pi/2);

        end

    end

end

%% ---------------- Custom convex–concave MOP ----------------
function f = CEC_ConvexConcave(x)
    f1 = sum(x.^2);
    f2 = sum((x-1).^2);
    f = [f1, f2];
end

%% ---------------- Custom Rosenbrock-based MOP ----------------
function f = CEC_Rosenbrock_MO(x)
    f1 = sum(100*(x(2:end)-x(1:end-1).^2).^2 + (1-x(1:end-1)).^2);
    f2 = sum((x+2).^2);
    f = [f1, f2];
end

%% ---------------- Custom Rastrigin-based MOP ----------------
function f = CEC_Rastrigin_MO(x)
    f1 = 10*numel(x) + sum(x.^2 - 10*cos(2*pi*x));
    f2 = 10*numel(x) + sum((x-1).^2 - 10*cos(2*pi*(x-1)));
    f = [f1, f2];
end
