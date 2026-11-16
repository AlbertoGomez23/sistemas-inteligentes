%% Algoritmo genético para el Job Shop Scheduling Problem
% Se resuelven las 4 instancias (de 6 a 1000 trabajos) con un límite de
% tiempo para cada una y se compara el makespan obtenido con una cota
% inferior sencilla: ninguna planificación puede acabar antes que la
% máquina más cargada ni que el trabajo más largo.
% Tarda unos 80 segundos.

clear; close all; clc;
carpeta = fileparts(mfilename('fullpath'));
rng(1);   % semilla fija para que los resultados sean reproducibles

instancias = {'jssp_easy', 'jssp_medium', 'jssp_hard', 'jssp_vhard'};
tiempos    = [10, 15, 20, 30];   % segundos por instancia
logs = cell(1, numel(instancias));

fprintf('%-12s %8s %9s %10s %11s %8s\n', 'Instancia', 'Trabajos', 'Máquinas', 'Makespan', 'Cota inf.', 'Gen.');
for k = 1:numel(instancias)
    [R, T] = leer_instancia(fullfile(carpeta, 'instancias', [instancias{k} '.txt']));
    [best_sol, best_cost, logs{k}, num_gens] = solve_int_ga(R, T, tiempos(k));

    % Cota inferior: carga de la máquina más ocupada y trabajo más largo
    carga = accumarray(R(R > 0), T(R > 0));
    cota = max(max(carga), max(sum(T, 2)));
    fprintf('%-12s %8d %9d %10d %11d %8d\n', instancias{k}, size(R, 1), size(R, 2), ...
        best_cost, cota, num_gens);

    if strcmp(instancias{k}, 'jssp_easy')
        sol_easy = best_sol;  R_easy = R;  T_easy = T;
    end
end

%% Convergencia
fig1 = figure('Color', 'w', 'Position', [100 100 1000 600]);
for k = 1:numel(instancias)
    subplot(2, 2, k);
    plot(logs{k}, 'LineWidth', 1.5); grid on;
    xlabel('Generación'); ylabel('Mejor makespan');
    title(strrep(instancias{k}, '_', '\_'));
end

%% Diagrama de Gantt de la mejor planificación de la instancia pequeña
[inicio, fin, maquina, trabajo] = planificacion(sol_easy, R_easy, T_easy);
fig2 = figure('Color', 'w', 'Position', [100 100 900 350]);
colores = lines(max(trabajo));
hold on;
for o = 1:numel(inicio)
    rectangle('Position', [inicio(o), maquina(o) - 0.4, fin(o) - inicio(o), 0.8], ...
        'FaceColor', colores(trabajo(o), :), 'EdgeColor', 'w');
    if fin(o) - inicio(o) >= 10        % solo se rotulan las barras que tienen sitio
        text((inicio(o) + fin(o)) / 2, maquina(o), sprintf('T%d', trabajo(o)), ...
            'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold');
    end
end
hold off; box on;
set(gca, 'YTick', 1:max(maquina), 'YDir', 'reverse');
ylabel('Máquina'); xlabel('Tiempo');
title(sprintf('Planificación de jssp\\_easy (makespan = %d)', max(fin)));

% Tema claro para las imágenes exportadas (la función theme existe desde R2025a)
if exist('theme', 'file'), theme(fig1, 'light'); theme(fig2, 'light'); end
exportgraphics(fig1, fullfile(carpeta, 'figuras', 'convergencia.png'), 'Resolution', 150);
exportgraphics(fig2, fullfile(carpeta, 'figuras', 'gantt_easy.png'), 'Resolution', 150);

%% Funciones auxiliares
% Formato: primera línea "J M", después J filas de máquinas y J de tiempos
function [R, T] = leer_instancia(fichero)
    v = sscanf(fileread(fichero), '%f');
    J = v(1);  M = v(2);
    R = reshape(v(3 : 2+J*M), M, J)';
    T = reshape(v(3+J*M : 2+2*J*M), M, J)';
end

% Decodifica un cromosoma y devuelve inicio, fin, máquina y trabajo de
% cada operación (la misma regla que EvalPob, guardando los instantes)
function [inicio, fin, maquina, trabajo] = planificacion(sol, R, T)
    [J, M] = size(R);
    fin_trabajo = zeros(1, J);  fin_maquina = zeros(1, M);  op_count = zeros(1, J);
    n = numel(sol);
    inicio = zeros(1, n); fin = zeros(1, n); maquina = zeros(1, n); trabajo = sol;
    for w = 1:n
        j = sol(w);
        op_count(j) = op_count(j) + 1;
        m = R(j, op_count(j));
        inicio(w) = max(fin_trabajo(j), fin_maquina(m));
        fin(w) = inicio(w) + T(j, op_count(j));
        fin_trabajo(j) = fin(w);  fin_maquina(m) = fin(w);
        maquina(w) = m;
    end
end
