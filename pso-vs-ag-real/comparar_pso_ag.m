%% Comparación experimental de PSO y algoritmo genético con codificación real
% Funciones de Ackley y Rastrigin en 10 y 30 dimensiones. Mismas
% condiciones para los dos algoritmos: población de 250, mismo dominio y
% mismo criterio de parada (máximo de iteraciones o estancamiento).
% Se repite cada caso N_RUNS veces y se cuenta como éxito f(x) < 1e-3.

clear; close all; clc;
carpeta = fileparts(mfilename('fullpath'));
rng(1);   % semilla fija para que los resultados sean reproducibles

N_RUNS = 5;           % ejecuciones por caso (con 100 tarda unos 30 min)
n = 250;              % tamaño del enjambre / población
max_iter = 30000;     % máximo de iteraciones / generaciones
paciencia = 3000;     % parada si el mejor no mejora en tantas iteraciones
exito = 1e-3;

%           función     límite    sigma de la mutación del AG
casos = { @ackley,    32.768,   0.01;
          @rastrigin,  5.12,    0.05 };
dims = [10, 30];

resultados = struct();
fila = 0;
for c = 1:size(casos, 1)
    for d = dims
        fila = fila + 1;
        f = casos{c, 1};  lim = casos{c, 2};  sigma = casos{c, 3};
        val = zeros(N_RUNS, 2);  iters = zeros(N_RUNS, 2);  tiempo = zeros(N_RUNS, 2);
        curva = cell(1, 2);
        for r = 1:N_RUNS
            t = tic;
            [~, val(r, 1), log_pso] = run_PSO(f, n, d, -lim, lim, max_iter, paciencia);
            tiempo(r, 1) = toc(t);
            t = tic;
            [~, val(r, 2), log_ga] = run_GA_real(f, n, d, -lim, lim, max_iter, paciencia, sigma);
            tiempo(r, 2) = toc(t);
            iters(r, :) = [numel(log_pso), numel(log_ga)];
            if r == 1, curva = {log_pso, log_ga}; end
        end
        resultados(fila).nombre = sprintf('%s d=%d', func2str(f), d);
        resultados(fila).val = val;
        resultados(fila).curva = curva;
        fprintf(['%-14s | PSO: %.2e ± %.2e, éxito %3d/%d, %5.0f iter, %.2f s | ' ...
                 'AG: %.2e ± %.2e, éxito %3d/%d, %5.0f gen, %.2f s\n'], resultados(fila).nombre, ...
            mean(val(:, 1)), std(val(:, 1)), sum(val(:, 1) < exito), N_RUNS, mean(iters(:, 1)), mean(tiempo(:, 1)), ...
            mean(val(:, 2)), std(val(:, 2)), sum(val(:, 2) < exito), N_RUNS, mean(iters(:, 2)), mean(tiempo(:, 2)));
    end
end

%% Comprobación con el óptimo desplazado
% Las dos funciones tienen el óptimo en el centro del dominio, y tanto el
% cruce aritmético como el movimiento de las partículas hacia sus mejores
% posiciones podrían favorecer el centro. Se repite el experimento
% moviendo el óptimo a x = 0.3 * límite para comprobar que no es así.
N_DESPL = 3;
fprintf('\nÓptimo desplazado a x = 0.3 * límite (%d ejecuciones, mediana y éxitos)\n', N_DESPL);
for c = 1:size(casos, 1)
    for d = dims
        f = casos{c, 1};  lim = casos{c, 2};  sigma = casos{c, 3};
        f_despl = @(x) f(x - 0.3 * lim);
        val = zeros(N_DESPL, 2);
        for r = 1:N_DESPL
            [~, val(r, 1)] = run_PSO(f_despl, n, d, -lim, lim, max_iter, paciencia);
            [~, val(r, 2)] = run_GA_real(f_despl, n, d, -lim, lim, max_iter, paciencia, sigma);
        end
        fprintf('%-14s | PSO: %.2e, éxito %2d/%d | AG: %.2e, éxito %2d/%d\n', ...
            sprintf('%s d=%d', func2str(f), d), median(val(:, 1)), sum(val(:, 1) < exito), N_DESPL, ...
            median(val(:, 2)), sum(val(:, 2) < exito), N_DESPL);
    end
end

%% Figuras
fig1 = figure('Color', 'w', 'Position', [100 100 1000 650]);
for k = 1:numel(resultados)
    subplot(2, 2, k);
    semilogy(max(resultados(k).curva{1}, 1e-16), 'LineWidth', 1.5); hold on;
    semilogy(max(resultados(k).curva{2}, 1e-16), 'LineWidth', 1.5); hold off;
    grid on; xlabel('Iteración / generación'); ylabel('Mejor f(x)');
    title(resultados(k).nombre); legend('PSO', 'AG', 'Location', 'northeast');
end

fig2 = figure('Color', 'w', 'Position', [100 100 1000 650]);
for k = 1:numel(resultados)
    subplot(2, 2, k);
    v = log10(max(resultados(k).val, 1e-16));
    grupo = categorical(repelem({'PSO'; 'AG'}, N_RUNS), {'PSO', 'AG'});
    boxchart(grupo, v(:));
    grid on; ylabel('log_{10} f(x) final');
    title(resultados(k).nombre);
end

% Tema claro para las imágenes exportadas (la función theme existe desde R2025a)
if exist('theme', 'file'), theme(fig1, 'light'); theme(fig2, 'light'); end
exportgraphics(fig1, fullfile(carpeta, 'figuras', 'convergencia.png'), 'Resolution', 150);
exportgraphics(fig2, fullfile(carpeta, 'figuras', 'boxplots.png'), 'Resolution', 150);
