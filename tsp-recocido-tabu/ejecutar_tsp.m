%% Recocido simulado y búsqueda tabú sobre instancias del TSP agrupado
% Las ciudades están agrupadas en clusters pequeños muy separados entre sí,
% lo que crea muchos óptimos locales: un mal orden de visita de los
% clusters es difícil de corregir con movimientos pequeños.
%
% Se ejecutan los dos algoritmos sobre las 5 instancias, con un límite de
% tiempo que crece con el tamaño, y se guardan la ruta y la convergencia de la
% instancia de 200 ciudades. Tarda unos 4 minutos en total.

clear; close all; clc;
carpeta = fileparts(mfilename('fullpath'));
rng(1);   % semilla fija para que los resultados sean reproducibles

instancias = {'tsp_0050', 'tsp_0100', 'tsp_0200', 'tsp_0500', 'tsp_1000'};
tiempos    = [5, 10, 20, 30, 60];   % segundos por instancia
res_sa = zeros(1, numel(instancias));
res_tabu = zeros(1, numel(instancias));

for k = 1:numel(instancias)
    coords = leer_instancia(fullfile(carpeta, 'instancias', [instancias{k} '.txt']));
    [ruta_sa, res_sa(k), log_sa] = solve_tsp_sa(coords, tiempos(k));
    [ruta_tabu, res_tabu(k), log_tabu] = solve_tsp_tabu(coords, tiempos(k));
    fprintf('%-9s (%4d ciudades, %2d s)  recocido: %8.2f   tabú: %8.2f\n', ...
        instancias{k}, size(coords, 1), tiempos(k), res_sa(k), res_tabu(k));

    if strcmp(instancias{k}, 'tsp_0200')
        coords_200 = coords;
        rutas_200 = {ruta_sa, ruta_tabu};
        dist_200 = [res_sa(k), res_tabu(k)];
        logs_200 = {log_sa, log_tabu};
    end
end

%% Figuras de la instancia de 200 ciudades
nombres = {'Recocido simulado', 'Búsqueda tabú'};
fig1 = figure('Color', 'w', 'Position', [100 100 1000 450]);
for a = 1:2
    subplot(1, 2, a);
    r = [rutas_200{a}, rutas_200{a}(1)];       % se cierra el ciclo
    plot(coords_200(r, 1), coords_200(r, 2), '-', 'LineWidth', 1.2); hold on;
    plot(coords_200(:, 1), coords_200(:, 2), '.', 'MarkerSize', 10); hold off;
    axis equal; grid on;
    title(sprintf('%s: %.1f', nombres{a}, dist_200(a)));
end

fig2 = figure('Color', 'w', 'Position', [100 100 1000 380]);
subplot(1, 2, 1);
plot((1:numel(logs_200{1})) * 1000, logs_200{1}, 'LineWidth', 1.5);
set(gca, 'XScale', 'log'); grid on;
xlabel('Iteración'); ylabel('Mejor distancia'); title('Recocido simulado');
subplot(1, 2, 2);
plot(logs_200{2}, 'LineWidth', 1.5);
set(gca, 'XScale', 'log'); grid on;
xlabel('Iteración'); ylabel('Mejor distancia'); title('Búsqueda tabú');

% Tema claro para las imágenes exportadas (la función theme existe desde R2025a)
if exist('theme', 'file'), theme(fig1, 'light'); theme(fig2, 'light'); end
exportgraphics(fig1, fullfile(carpeta, 'figuras', 'rutas_200.png'), 'Resolution', 150);
exportgraphics(fig2, fullfile(carpeta, 'figuras', 'convergencia_200.png'), 'Resolution', 150);

%% Lectura de instancias: primera línea n, después n líneas "x y"
function coords = leer_instancia(fichero)
    v = sscanf(fileread(fichero), '%f');
    coords = reshape(v(2 : 1+2*v(1)), 2, [])';
end
