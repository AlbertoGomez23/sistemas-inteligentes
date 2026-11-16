%% Colonia de hormigas para el CVRP: comparación de 3 configuraciones
% Instancia: 500 clientes y un almacén, vehículos de capacidad Q.
% Se ejecutan 30 veces independientes cada configuración de (alpha, beta,
% rho) y se comparan la distancia final, la convergencia y el tiempo.

clear; close all; clc;
carpeta = fileparts(mfilename('fullpath'));
rng(1);   % semilla fija para que los resultados sean reproducibles

inst = load(fullfile(carpeta, 'datos', 'instance_cvrp.mat'));
assert(all(inst.demandas <= inst.Q), 'Hay clientes con más demanda que la capacidad Q');
fprintf('%d clientes, capacidad Q = %d, demanda total = %d (mínimo %d vehículos)\n', ...
    inst.num_clientes, inst.Q, sum(inst.demandas), ceil(sum(inst.demandas) / inst.Q));

runs = 30;
max_iter = 100;
n_hormigas = 30;
%            alpha  beta  rho
configs = [  1,     2,    0.1;     % configuración de partida 1
             1,     5,    0.5;     % configuración de partida 2
             2,     6,    0.3 ];   % configuración 3 (propia)
n_conf = size(configs, 1);

distancias = zeros(runs, n_conf);
tiempos = zeros(runs, n_conf);
curvas = zeros(n_conf, max_iter);
mejor_global = inf;

for c = 1:n_conf
    logs = zeros(runs, max_iter);
    for r = 1:runs
        t = tic;
        [distancias(r, c), ruta, logs(r, :)] = aco_cvrp(inst, configs(c, 1), configs(c, 2), ...
            configs(c, 3), n_hormigas, max_iter);
        tiempos(r, c) = toc(t);
        if distancias(r, c) < mejor_global
            mejor_global = distancias(r, c);
            mejor_ruta = ruta;
            mejor_conf = c;
        end
    end
    curvas(c, :) = mean(logs, 1);
    fprintf('Conf %d (alpha=%g, beta=%g, rho=%g): %.0f ± %.0f   mejor %.0f   tiempo %.1f s/ejecución\n', ...
        c, configs(c, :), mean(distancias(:, c)), std(distancias(:, c)), ...
        min(distancias(:, c)), mean(tiempos(:, c)));
end

comprobar_solucion(mejor_ruta, inst);

%% Figuras
etiquetas = arrayfun(@(c) sprintf('Conf %d', c), 1:n_conf, 'UniformOutput', false);

fig1 = figure('Color', 'w');
boxchart(categorical(repelem(etiquetas', runs), etiquetas), distancias(:));
ylabel('Distancia total'); grid on;
title(sprintf('Distancia final en %d ejecuciones', runs));

fig2 = figure('Color', 'w');
plot(1:max_iter, curvas', 'LineWidth', 1.5); grid on;
xlabel('Iteración'); ylabel('Mejor distancia (media)');
title('Convergencia media'); legend(etiquetas);

% Mejor solución encontrada: cada vehículo en un color
fig3 = figure('Color', 'w', 'Position', [100 100 700 650]);
xy = inst.coordenadas;
vueltas = find(mejor_ruta == 1);
colores = lines(numel(vueltas) - 1);
hold on;
for v = 1:numel(vueltas) - 1
    tramo = mejor_ruta(vueltas(v):vueltas(v + 1));
    plot(xy(tramo, 1), xy(tramo, 2), '-', 'Color', colores(v, :), 'LineWidth', 1);
end
plot(xy(2:end, 1), xy(2:end, 2), 'k.', 'MarkerSize', 6);
plot(xy(1, 1), xy(1, 2), 'ks', 'MarkerSize', 10, 'MarkerFaceColor', 'y');
hold off; axis equal; box on;
title(sprintf('Mejor solución (conf %d): %.0f, %d vehículos', mejor_conf, mejor_global, numel(vueltas) - 1));

% Tema claro para las imágenes exportadas (la función theme existe desde R2025a)
if exist('theme', 'file'), theme(fig1, 'light'); theme(fig2, 'light'); theme(fig3, 'light'); end
exportgraphics(fig1, fullfile(carpeta, 'figuras', 'boxplot.png'), 'Resolution', 150);
exportgraphics(fig2, fullfile(carpeta, 'figuras', 'convergencia.png'), 'Resolution', 150);
exportgraphics(fig3, fullfile(carpeta, 'figuras', 'mejor_solucion.png'), 'Resolution', 150);

%% Comprobación de que una solución cumple las restricciones del CVRP
function comprobar_solucion(ruta, inst)
    assert(ruta(1) == 1 && ruta(end) == 1, 'La solución debe empezar y acabar en el almacén');
    clientes = ruta(ruta ~= 1);
    assert(numel(clientes) == inst.num_clientes && numel(unique(clientes)) == inst.num_clientes, ...
        'Cada cliente debe visitarse exactamente una vez');
    vueltas = find(ruta == 1);
    for v = 1:numel(vueltas) - 1
        carga = sum(inst.demandas(ruta(vueltas(v) + 1 : vueltas(v + 1) - 1)));
        assert(carga <= inst.Q, 'Un vehículo supera la capacidad Q');
    end
    fprintf('Mejor solución comprobada: %d clientes, %d vehículos, ninguno supera Q\n', ...
        numel(clientes), numel(vueltas) - 1);
end
