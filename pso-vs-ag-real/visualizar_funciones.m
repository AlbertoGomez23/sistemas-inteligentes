%% Visualización de las funciones de Ackley y Rastrigin en 2 dimensiones
% Superficie 3D y curvas de nivel de cada función.

clear; close all; clc;
carpeta = fileparts(mfilename('fullpath'));

funciones = {@ackley, @rastrigin};
nombres = {'Ackley', 'Rastrigin'};
limites = [32.768, 5.12];

fig = figure('Color', 'w', 'Position', [100 100 1000 750]);
for k = 1:2
    % Malla de 200 x 200 puntos: cada punto (x1, x2) es una fila de 'puntos'
    eje = linspace(-limites(k), limites(k), 200);
    [X1, X2] = meshgrid(eje, eje);
    puntos = [X1(:), X2(:)];
    Z = reshape(funciones{k}(puntos), size(X1));

    subplot(2, 2, 2*k - 1);
    surf(X1, X2, Z); shading interp; colormap(parula);
    xlabel('x_1'); ylabel('x_2'); zlabel('f(x)');
    title([nombres{k} ': superficie']);

    subplot(2, 2, 2*k);
    contour(X1, X2, Z, 30); axis equal tight;
    xlabel('x_1'); ylabel('x_2');
    title([nombres{k} ': curvas de nivel']);
end

% Tema claro para las imágenes exportadas (la función theme existe desde R2025a)
if exist('theme', 'file'), theme(fig, 'light'); end
exportgraphics(fig, fullfile(carpeta, 'figuras', 'funciones.png'), 'Resolution', 150);
