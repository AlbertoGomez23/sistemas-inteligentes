function [mejorDist, mejorRuta, log] = aco_cvrp(inst, alpha, beta, rho, n_hormigas, max_iter)
% Optimización por colonia de hormigas (ACO) para el problema de rutas de
% vehículos con capacidad (CVRP).
%
% Entradas:
%   inst       - struct con los datos de la instancia: distancias (matriz
%                de distancias entre nodos), demandas (demanda de cada nodo)
%                y Q (capacidad de cada vehículo). El nodo 1 es el almacén.
%   alpha      - peso de la feromona
%   beta       - peso de la heurística (inversa de la distancia)
%   rho        - tasa de evaporación de la feromona
%   n_hormigas - hormigas por iteración
%   max_iter   - número de iteraciones
% Salidas:
%   mejorDist - distancia total de la mejor solución
%   mejorRuta - secuencia de nodos de esa solución; cada vuelta al nodo 1
%               separa la ruta de un vehículo de la del siguiente
%   log       - mejor distancia tras cada iteración
%
% Cada hormiga construye una solución completa: desde el nodo actual elige
% el siguiente cliente por ruleta, con probabilidad proporcional a
% tau^alpha * eta^beta, entre los no visitados cuya demanda cabe en la
% carga que le queda. Si no cabe ninguno, vuelve al almacén a recargar.

    D = inst.distancias;
    demandas = inst.demandas(:)';
    Q = inst.Q;
    n_nodos = size(D, 1);

    tau0 = 0.1;                       % feromona inicial (no puede ser 0)
    tau = tau0 * ones(n_nodos);
    eta = 1 ./ D;                     % heurística: los nodos cercanos son más atractivos
    eta(~isfinite(eta)) = 0;          % diagonal (distancia 0)

    limite_estancamiento = 20;        % iteraciones sin mejora antes de reiniciar la feromona
    sin_mejora = 0;
    mejorDist = inf;
    mejorRuta = [];
    log = zeros(1, max_iter);

    for it = 1:max_iter
        % Atractivo de cada arista: se calcula una vez por iteración, porque
        % la feromona no cambia mientras las hormigas construyen
        atractivo = (tau .^ alpha) .* (eta .^ beta);

        rutas = cell(n_hormigas, 1);
        dists = zeros(n_hormigas, 1);
        for h = 1:n_hormigas
            rutas{h} = construir_solucion(atractivo, demandas, Q, n_nodos);
            dists(h) = coste_ruta(rutas{h}, D);
        end

        [d_it, h_it] = min(dists);
        if d_it < mejorDist
            mejorDist = d_it;
            mejorRuta = rutas{h_it};
            sin_mejora = 0;
        else
            sin_mejora = sin_mejora + 1;
        end

        % Evaporación y depósito: cada hormiga deja en sus aristas una
        % cantidad de feromona inversamente proporcional a su distancia
        tau = (1 - rho) * tau;
        for h = 1:n_hormigas
            r = rutas{h};
            aporte = Q / dists(h);
            idx = sub2ind([n_nodos n_nodos], r(1:end-1), r(2:end));
            idx_t = sub2ind([n_nodos n_nodos], r(2:end), r(1:end-1));
            tau(idx) = tau(idx) + aporte;
            tau(idx_t) = tau(idx_t) + aporte;
        end

        % Si la colonia se estanca, se reinicia la feromona para explorar
        if sin_mejora >= limite_estancamiento
            tau = tau0 * ones(n_nodos);
            sin_mejora = 0;
        end

        log(it) = mejorDist;
    end
end

%% Construcción de la solución de una hormiga
function ruta = construir_solucion(atractivo, demandas, Q, n_nodos)
    visitado = false(1, n_nodos);
    visitado(1) = true;                         % el almacén no es un cliente
    ruta = zeros(1, 2 * n_nodos);
    ruta(1) = 1;
    pos = 1;
    actual = 1;
    carga = Q;
    pendientes = n_nodos - 1;

    while pendientes > 0
        validos = find(~visitado & demandas <= carga);
        if isempty(validos)
            siguiente = 1;                      % vuelve al almacén a recargar
            carga = Q;
        else
            p = atractivo(actual, validos);
            if sum(p) > 0
                siguiente = validos(ruleta(p));
            else
                siguiente = validos(randi(numel(validos)));
            end
            visitado(siguiente) = true;
            carga = carga - demandas(siguiente);
            pendientes = pendientes - 1;
        end
        pos = pos + 1;
        ruta(pos) = siguiente;
        actual = siguiente;
    end
    ruta = [ruta(1:pos), 1];                    % al final vuelve al almacén
end

%% Selección por ruleta: índice elegido con probabilidad proporcional a p
function i = ruleta(p)
    acumulada = cumsum(p);
    i = find(rand() * acumulada(end) <= acumulada, 1, 'first');
end

%% Distancia total recorrida por una solución
function c = coste_ruta(ruta, D)
    c = sum(D(sub2ind(size(D), ruta(1:end-1), ruta(2:end))));
end
