function [best_sol, best_cost, log, num_gens] = solve_int_ga(M_maquinas, M_tiempos, time_limit)
% Algoritmo genético con representación entera para el Job Shop
% Scheduling Problem (JSSP).
%
% Entradas:
%   M_maquinas - matriz J x M: máquina de la k-ésima operación de cada
%                trabajo (0 si el trabajo tiene menos de k operaciones)
%   M_tiempos  - matriz J x M: duración de cada operación
%   time_limit - tiempo máximo de ejecución en segundos
% Salidas:
%   best_sol  - mejor cromosoma (vector de índices de trabajo)
%   best_cost - makespan de best_sol (instante en que acaba el último trabajo)
%   log       - mejor makespan en cada generación
%   num_gens  - número de generaciones completadas
%
% Codificación por operaciones: el trabajo j aparece en el cromosoma tantas
% veces como operaciones tiene, y la q-ésima aparición de j es su q-ésima
% operación. Así cualquier permutación de genes es una planificación
% válida y nunca hace falta reparar soluciones.

    [J, ~] = size(M_maquinas);
    n_ops = sum(M_maquinas > 0, 2)';      % operaciones de cada trabajo
    N_op = sum(n_ops);

    % Cromosoma base: [1 1 1 2 2 3 3 3 ...] y la población inicial son
    % permutaciones aleatorias de él
    base = repelem(1:J, n_ops);

    % Hiperparámetros
    pop_size = 86;          % debe ser par (los padres se emparejan)
    k_torneo = 2;
    Pcross = 0.9;
    Pmut = 0.3;

    pop = zeros(pop_size, N_op);
    for i = 1:pop_size
        pop(i, :) = base(randperm(N_op));
    end
    fitness = EvalPob(pop, M_maquinas, M_tiempos);

    [best_cost, idx] = min(fitness);
    best_sol = pop(idx, :);
    log = [];
    num_gens = 0;

    t_inicio = tic;
    while toc(t_inicio) < time_limit - 0.5
        num_gens = num_gens + 1;

        parejas = Torneo(fitness, k_torneo);
        pobCross = Cruce(pop, parejas, Pcross, J);
        pobMut = Mutacion(pobCross, Pmut);
        fitMut = EvalPob(pobMut, M_maquinas, M_tiempos);
        [pop, fitness] = Reemplazo_Elitista(pobMut, pop, fitMut, fitness);

        if fitness(1) < best_cost       % la población queda ordenada
            best_cost = fitness(1);
            best_sol = pop(1, :);
        end
        log(end + 1) = best_cost; %#ok<AGROW>
    end
end

%% Evaluación: decodificación voraz de izquierda a derecha
% Cada operación empieza en cuanto han terminado la operación anterior de
% su trabajo y lo que esté ejecutando su máquina.
function f = EvalPob(pop, M_maquinas, M_tiempos)
    [n_ind, N_op] = size(pop);
    [J, M] = size(M_maquinas);
    f = zeros(n_ind, 1);

    for i = 1:n_ind
        fin_trabajo = zeros(1, J);    % cuándo acabó la última op. de cada trabajo
        fin_maquina = zeros(1, M);    % cuándo queda libre cada máquina
        op_count = zeros(1, J);

        for w = 1:N_op
            j = pop(i, w);
            op_count(j) = op_count(j) + 1;
            k = op_count(j);
            m = M_maquinas(j, k);
            inicio = max(fin_trabajo(j), fin_maquina(m));
            fin_trabajo(j) = inicio + M_tiempos(j, k);
            fin_maquina(m) = fin_trabajo(j);
        end
        f(i) = max(fin_trabajo);
    end
end

%% Selección por torneo de tamaño k (se minimiza el makespan)
function parejas = Torneo(fitness, k)
    n = numel(fitness);
    elegidos = zeros(n, 1);
    for i = 1:n
        candidatos = randperm(n, k);
        [~, pos] = min(fitness(candidatos));
        elegidos(i) = candidatos(pos);
    end
    parejas = reshape(elegidos, n/2, 2);
end

%% Cruce
% Los cruces clásicos de permutaciones (PMX, OX) o el de un punto no sirven
% aquí: suponen que cada gen aparece una sola vez o rompen el número de
% apariciones de cada trabajo. Se usa JOX (Job-based Order Crossover).
function pobCross = Cruce(pop, parejas, Pcross, J)
    [n_ind, n_genes] = size(pop);
    pobCross = zeros(n_ind, n_genes);
    hijo = 1;
    for i = 1:size(parejas, 1)
        padres = pop(parejas(i, :), :);
        if rand() <= Pcross
            padres = JOX(padres, J);
        end
        pobCross(hijo:hijo+1, :) = padres;
        hijo = hijo + 2;
    end
end

% JOX: se elige un trabajo al azar; cada hijo conserva las posiciones de
% ese trabajo en su padre y rellena los huecos con los genes del otro padre
% en el orden en que aparecen. El número de apariciones de cada trabajo se
% mantiene, así que el hijo siempre es válido.
function hijos = JOX(p, J)
    N = size(p, 2);
    hijos = zeros(2, N);
    trabajo = randi(J);

    for h = 1:2
        otro = 3 - h;
        fijo = p(h, :) == trabajo;
        hijos(h, fijo) = trabajo;
        relleno = p(otro, p(otro, :) ~= trabajo);
        hijos(h, ~fijo) = relleno;
    end
end

%% Mutación por inversión de un tramo
% Invertir un tramo solo reordena genes, así que el cromosoma sigue
% conteniendo cada trabajo el número correcto de veces.
function pobMut = Mutacion(pobCross, Pmut)
    [n_ind, N] = size(pobCross);
    pobMut = pobCross;
    for i = 1:n_ind
        if rand() <= Pmut
            k1 = randi(N - 1);
            k2 = randi([k1 + 1, N]);
            pobMut(i, k1:k2) = pobMut(i, k2:-1:k1);
        end
    end
end

%% Reemplazo elitista (mu + lambda): sobreviven los mejores entre padres e hijos
function [pop, fitness] = Reemplazo_Elitista(pobMut, pop, fitMut, fitness)
    n_ind = size(pop, 1);
    pobTotal = [pop; pobMut];
    fitTotal = [fitness; fitMut];
    [fitTotal, orden] = sort(fitTotal);
    pop = pobTotal(orden(1:n_ind), :);
    fitness = fitTotal(1:n_ind);
end
