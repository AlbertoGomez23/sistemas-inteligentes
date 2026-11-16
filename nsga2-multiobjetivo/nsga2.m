function [X, F] = nsga2(problema, cfg)
% NSGA-II (Non-dominated Sorting Genetic Algorithm II) para dos objetivos.
% Todos los objetivos se minimizan (para maximizar, se cambia el signo).
%
% Entradas:
%   problema - struct con tres funciones:
%       X = problema.inicializar(n)    población inicial (un individuo por fila)
%       [X, F] = problema.evaluar(X)   objetivos (n x 2); puede reparar X
%       H = problema.variar(P, cfg)    hijos a partir de los padres P, que
%                                      vienen emparejados: filas 1-2, 3-4...
%   cfg      - struct con pop (tamaño de población, par), gen (generaciones)
%              y los parámetros que use problema.variar
% Salidas:
%   X, F - individuos del primer frente (no dominados) de la población
%          final y sus objetivos, sin repetidos
%
% En cada generación se crean tantos hijos como padres, se juntan con la
% población actual y sobreviven los mejores según el rango de dominancia
% y, para desempatar dentro de un frente, la distancia de crowding (se
% prefieren las soluciones de zonas poco pobladas del frente).

    X = problema.inicializar(cfg.pop);
    [X, F] = problema.evaluar(X);
    [rango, crowding] = rango_y_crowding(F);

    for g = 1:cfg.gen
        padres = torneo(rango, crowding, cfg.pop);
        H = problema.variar(X(padres, :), cfg);
        [H, FH] = problema.evaluar(H);

        XU = [X; H];
        FU = [F; FH];
        [rU, cU] = rango_y_crowding(FU);
        sel = seleccion_ambiental(rU, cU, cfg.pop);
        X = XU(sel, :);  F = FU(sel, :);
        rango = rU(sel);  crowding = cU(sel);
    end

    rango = rango_y_crowding(F);
    [F, idx] = unique(F(rango == 1, :), 'rows');
    X1 = X(rango == 1, :);
    X = X1(idx, :);
end

%% Ordenación por dominancia y distancia de crowding
% i domina a j si no es peor en ningún objetivo y es mejor en al menos uno.
% Frente 1: los que nadie domina; frente 2: los que solo dominan los del
% frente 1; y así sucesivamente.
function [rango, crowding] = rango_y_crowding(F)
    N = size(F, 1);
    A = permute(F, [1 3 2]);              % N x 1 x 2
    B = permute(F, [3 1 2]);              % 1 x N x 2
    domina = all(A <= B, 3) & any(A < B, 3);   % domina(i, j): i domina a j

    n_dominado = sum(domina, 1)';         % cuántos dominan a cada individuo
    rango = zeros(N, 1);
    pendiente = true(N, 1);
    r = 0;
    while any(pendiente)
        r = r + 1;
        frente = pendiente & n_dominado == 0;
        rango(frente) = r;
        pendiente(frente) = false;
        n_dominado = n_dominado - sum(domina(frente, :), 1)';
    end

    % Crowding: para cada objetivo, distancia normalizada entre los dos
    % vecinos de cada solución dentro de su frente. Los extremos reciben
    % infinito para que se conserven siempre.
    crowding = zeros(N, 1);
    for r = 1:max(rango)
        idx = find(rango == r);
        n = numel(idx);
        for m = 1:size(F, 2)
            [valores, orden] = sort(F(idx, m));
            crowding(idx(orden([1 end]))) = inf;
            rango_m = valores(end) - valores(1);
            if n > 2 && rango_m > 0
                crowding(idx(orden(2:end-1))) = crowding(idx(orden(2:end-1))) + ...
                    (valores(3:end) - valores(1:end-2)) / rango_m;
            end
        end
    end
end

%% Torneo binario: gana el de menor rango; con el mismo rango, el de mayor crowding
function ganadores = torneo(rango, crowding, n)
    N = numel(rango);
    a = randi(N, n, 1);
    b = randi(N, n, 1);
    gana_a = rango(a) < rango(b) | (rango(a) == rango(b) & crowding(a) > crowding(b));
    ganadores = b;
    ganadores(gana_a) = a(gana_a);
end

%% Selección ambiental: se llenan los huecos frente a frente; el último
% frente que no cabe entero se recorta quedándose con los de mayor crowding
function sel = seleccion_ambiental(rango, crowding, n)
    sel = [];
    for r = 1:max(rango)
        idx = find(rango == r);
        if numel(sel) + numel(idx) <= n
            sel = [sel; idx]; %#ok<AGROW>
        else
            [~, orden] = sort(crowding(idx), 'descend');
            sel = [sel; idx(orden(1:n - numel(sel)))]; %#ok<AGROW>
            break;
        end
    end
end
