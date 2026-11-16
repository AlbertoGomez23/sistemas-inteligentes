function [best_tour, best_dist, log] = solve_tsp_sa(coords, max_time)
% Recocido simulado (simulated annealing) para el problema del viajante.
%
% Entradas:
%   coords   - matriz n x 2 con las coordenadas (x, y) de cada ciudad
%   max_time - tiempo máximo de ejecución en segundos
% Salidas:
%   best_tour - permutación 1 x n de las ciudades (mejor ruta encontrada)
%   best_dist - longitud total de esa ruta (cerrada, vuelve al origen)
%   log       - mejor distancia encontrada, guardada cada 1000 iteraciones
%
% Vecindario 2-opt: se eligen dos posiciones i < j y se invierte el tramo
% entre ellas. Solo cambian dos aristas, así que la variación de coste se
% calcula en O(1) sin recorrer la ruta entera.

    n = size(coords, 1);
    D = matriz_distancias(coords);

    % Enfriamiento geométrico ligado al tiempo: la temperatura baja de T0 a
    % T_min a lo largo de max_time, T = T0 * (T_min / T0)^(t / max_time).
    % Con un factor fijo por iteración (T = alfa * T) el ritmo dependería de
    % la velocidad del ordenador y con poco tiempo no llegaría a enfriarse.
    T0 = 1000;
    T_min = 1e-3;
    T = T0;

    current = randperm(n);
    coste = coste_ruta(current, D);
    best_tour = current;
    best_dist = coste;

    paso_log = 1000;
    log = zeros(1, 1e5);
    n_log = 0;
    iter = 0;

    t_inicio = tic;
    t = 0;
    while t < max_time
        % Movimiento 2-opt aleatorio
        i = randi(n - 1);
        j = randi([i + 1, n]);
        delta = delta_2opt(current, i, j, D, n);

        % Se acepta siempre si mejora; si empeora, con probabilidad
        % exp(-delta / T), que disminuye a medida que baja la temperatura
        if delta < 0 || rand() < exp(-delta / T)
            current(i:j) = current(j:-1:i);
            coste = coste + delta;
            if coste < best_dist
                best_dist = coste;
                best_tour = current;
            end
        end

        t = toc(t_inicio);
        T = T0 * (T_min / T0)^(t / max_time);
        iter = iter + 1;
        if mod(iter, paso_log) == 0
            n_log = n_log + 1;
            log(n_log) = best_dist;
        end
    end
    log = log(1:n_log);

    % Se recalcula la distancia desde cero para no arrastrar error numérico
    best_dist = coste_ruta(best_tour, D);
end

%% Variación de coste al invertir el tramo current(i:j)
% Se rompen las aristas (a, b) y (c, d) y se crean (a, c) y (b, d), siendo
% a la ciudad anterior a i, b = current(i), c = current(j) y d la ciudad
% siguiente a j (la ruta es cerrada).
function delta = delta_2opt(current, i, j, D, n)
    if i == 1 && j == n          % invertir la ruta entera no cambia nada
        delta = 0;
        return;
    end
    if i == 1, a = current(n); else, a = current(i - 1); end
    if j == n, d = current(1); else, d = current(j + 1); end
    b = current(i);
    c = current(j);
    delta = D(a, c) + D(b, d) - D(a, b) - D(c, d);
end

%% Longitud de una ruta cerrada
function r = coste_ruta(ruta, D)
    r = sum(D(sub2ind(size(D), ruta, [ruta(2:end), ruta(1)])));
end

%% Matriz de distancias euclídeas entre todas las ciudades
function D = matriz_distancias(coords)
    dx = coords(:, 1) - coords(:, 1)';
    dy = coords(:, 2) - coords(:, 2)';
    D = sqrt(dx.^2 + dy.^2);
end
