function [best_tour, best_dist, log] = solve_tsp_tabu(coords, max_time)
% Búsqueda tabú para el problema del viajante.
%
% Entradas:
%   coords   - matriz n x 2 con las coordenadas (x, y) de cada ciudad
%   max_time - tiempo máximo de ejecución en segundos
% Salidas:
%   best_tour - permutación 1 x n de las ciudades (mejor ruta encontrada)
%   best_dist - longitud total de esa ruta (cerrada, vuelve al origen)
%   log       - mejor distancia encontrada en cada iteración
%
% En cada iteración se evalúan TODOS los movimientos 2-opt (n(n-1)/2) y se
% aplica el mejor que no sea tabú, aunque empeore la solución: así se puede
% salir de los óptimos locales. Tras invertir el tramo entre las ciudades b
% y c, el par {b, c} queda prohibido durante 'tenencia' iteraciones para no
% deshacer el movimiento. Criterio de aspiración: un movimiento tabú se
% permite si mejora la mejor solución encontrada hasta el momento.

    n = size(coords, 1);
    D = matriz_distancias(coords);
    tenencia = 40;

    % Todos los pares de posiciones i < j (sin el par (1, n), que invierte
    % la ruta entera y no cambia nada)
    [I, J] = find(triu(true(n), 1));
    quitar = (I == 1 & J == n);
    I(quitar) = [];  J(quitar) = [];
    anterior = [n, 1:n-1];      % posición anterior a cada posición
    siguiente = [2:n, 1];       % posición siguiente a cada posición

    % tabu_hasta(b, c): iteración hasta la que está prohibido el par {b, c}
    tabu_hasta = zeros(n, n);

    current = randperm(n);
    coste = coste_ruta(current, D);
    best_tour = current;
    best_dist = coste;

    log = zeros(1, 1e5);
    iter = 0;

    t_inicio = tic;
    while toc(t_inicio) < max_time && iter < numel(log)
        iter = iter + 1;

        % Variación de coste de todos los movimientos 2-opt a la vez
        a = current(anterior(I));
        b = current(I);
        c = current(J);
        d = current(siguiente(J));
        delta = D(sub2ind([n n], a, c)) + D(sub2ind([n n], b, d)) ...
              - D(sub2ind([n n], a, b)) - D(sub2ind([n n], c, d));

        % Movimientos permitidos: no tabú, o tabú pero mejoran el récord
        es_tabu = tabu_hasta(sub2ind([n n], b, c)) >= iter;
        aspiracion = coste + delta < best_dist - 1e-9;
        delta(es_tabu & ~aspiracion) = inf;

        [delta_min, k] = min(delta);
        if isinf(delta_min)
            break;    % todos los movimientos son tabú
        end

        % Se aplica el mejor movimiento permitido
        i = I(k);  j = J(k);
        current(i:j) = current(j:-1:i);
        coste = coste + delta_min;
        tabu_hasta(b(k), c(k)) = iter + tenencia;
        tabu_hasta(c(k), b(k)) = iter + tenencia;

        if coste < best_dist
            best_dist = coste;
            best_tour = current;
        end
        log(iter) = best_dist;
    end
    log = log(1:iter);

    % Se recalcula la distancia desde cero para no arrastrar error numérico
    best_dist = coste_ruta(best_tour, D);
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
