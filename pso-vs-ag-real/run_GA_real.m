function [best_sol, best_cost, log] = run_GA_real(fitness_func, n, d, lb, ub, max_iter, paciencia, sigma_rel)
% Algoritmo genético con codificación real (sin binarizar).
%
% Entradas:
%   fitness_func - función a minimizar; recibe una matriz n x d (un
%                  individuo por fila) y devuelve un vector n x 1
%   n            - tamaño de la población (par)
%   d            - número de dimensiones
%   lb, ub       - límites inferior y superior de cada variable
%   max_iter     - número máximo de generaciones
%   paciencia    - se para si el mejor valor no mejora en tantas generaciones
%   sigma_rel    - desviación de la mutación gaussiana, como fracción del
%                  tamaño del dominio (por ejemplo 0.01 = 1 %)
% Salidas:
%   best_sol  - mejor individuo encontrado
%   best_cost - valor de la función en best_sol
%   log       - mejor valor en cada generación (curva de convergencia)

    % Parámetros
    k = 3;          % tamaño del torneo
    Pcross = 0.9;
    Pmut = 0.2;     % probabilidad de mutar cada gen
    sigma = sigma_rel * (ub - lb);

    pop = lb + (ub - lb) * rand(n, d);
    fitness = fitness_func(pop);
    [best_cost, idx] = min(fitness);
    best_sol = pop(idx, :);

    log = zeros(1, max_iter);
    sin_mejora = 0;
    gen = 0;

    while gen < max_iter && sin_mejora < paciencia
        gen = gen + 1;

        padres = Torneo(fitness, k);
        hijos = Cruce(pop, padres, Pcross);
        hijos = Mutacion(hijos, Pmut, sigma, lb, ub);
        fit_hijos = fitness_func(hijos);
        [pop, fitness] = Reemplazo_Elitista(hijos, pop, fit_hijos, fitness);

        if fitness(1) < best_cost - 1e-12 * max(1, abs(best_cost))
            sin_mejora = 0;
        else
            sin_mejora = sin_mejora + 1;
        end
        if fitness(1) < best_cost
            best_cost = fitness(1);
            best_sol = pop(1, :);
        end
        log(gen) = best_cost;
    end
    log = log(1:gen);
end

%% Selección por torneo: se toman k individuos al azar y gana el mejor
function padres = Torneo(fitness, k)
    n = numel(fitness);
    candidatos = randi(n, n, k);
    [~, pos] = min(fitness(candidatos), [], 2);
    padres = candidatos(sub2ind([n k], (1:n)', pos));
    padres = reshape(padres, n/2, 2);
end

%% Cruce aritmético
% Con un peso aleatorio a en [0, 1] por pareja:
%   hijo1 = a * P1 + (1 - a) * P2
%   hijo2 = (1 - a) * P1 + a * P2
% Los hijos quedan en el segmento entre los dos padres. Si no hay cruce
% (a = 1), los hijos son copias de los padres.
function hijos = Cruce(pop, padres, Pcross)
    P1 = pop(padres(:, 1), :);
    P2 = pop(padres(:, 2), :);
    a = rand(size(P1, 1), 1);
    a(rand(size(a)) > Pcross) = 1;
    hijos = [a .* P1 + (1 - a) .* P2;
             (1 - a) .* P1 + a .* P2];
end

%% Mutación gaussiana: a cada gen se le suma ruido N(0, sigma) con
% probabilidad Pmut y se recorta al dominio
function hijos = Mutacion(hijos, Pmut, sigma, lb, ub)
    mascara = rand(size(hijos)) <= Pmut;
    hijos(mascara) = hijos(mascara) + sigma * randn(nnz(mascara), 1);
    hijos = max(min(hijos, ub), lb);
end

%% Reemplazo elitista (mu + lambda): sobreviven los n mejores entre padres e hijos
function [pop, fitness] = Reemplazo_Elitista(hijos, pop, fit_hijos, fitness)
    n = size(pop, 1);
    total = [pop; hijos];
    fit_total = [fitness; fit_hijos];
    [fit_total, orden] = sort(fit_total);
    pop = total(orden(1:n), :);
    fitness = fit_total(1:n);
end
