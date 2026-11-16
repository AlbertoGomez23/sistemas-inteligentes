%% NSGA-II sobre un problema continuo (ZDT1) y uno discreto (mochila multiobjetivo)
% Para cada problema se prueban 3 configuraciones pensadas para provocar
% comportamientos distintos (equilibrada, exploratoria y con convergencia
% prematura), con 30 ejecuciones independientes cada una. Se evalúan con
% dos métricas:
%   - Hipervolumen (HV): área del espacio de objetivos dominada por el
%     frente, hasta un punto de referencia. Mide convergencia y
%     diversidad a la vez. Mayor es mejor.
%   - IGD+: distancia media desde cada punto del frente de referencia a la
%     solución obtenida más cercana, contando solo lo que esta es peor.
%     Penaliza los huecos del frente. Menor es mejor.

clear; close all; clc;
carpeta = fileparts(mfilename('fullpath'));
rng(1);   % semilla fija para que los resultados sean reproducibles
numRuns = 30;

%% Configuraciones
%                       nombre          pop  gen   pc     pm      etaC etaM
configsZDT1 = { struct('name', 'Equilibrada',  'pop', 120, 'gen', 500, 'pc', 0.9,  'pm', 0.1,   'etaC', 15, 'etaM', 20), ...
                struct('name', 'Exploratoria', 'pop', 200, 'gen', 100, 'pc', 0.7,  'pm', 0.1,   'etaC', 5,  'etaM', 5), ...
                struct('name', 'Prematura',    'pop', 30,  'gen', 30,  'pc', 0.95, 'pm', 0.001, 'etaC', 50, 'etaM', 50) };

configsMOKP = { struct('name', 'Equilibrada',  'pop', 120, 'gen', 500, 'pc', 0.9,  'pm', 1/500), ...
                struct('name', 'Exploratoria', 'pop', 200, 'gen', 100, 'pc', 0.7,  'pm', 0.05), ...
                struct('name', 'Prematura',    'pop', 30,  'gen', 40,  'pc', 0.95, 'pm', 0.001) };
nombres = cellfun(@(c) c.name, configsZDT1, 'UniformOutput', false);

%% Problema 1: ZDT1 (50 variables en [0, 1], dos objetivos a minimizar)
nVar = 50;
zdt1.inicializar = @(n) rand(n, nVar);
zdt1.evaluar = @evaluar_zdt1;
zdt1.variar = @(P, cfg) variar_real(P, cfg, 0, 1);

f1 = linspace(0, 1, 500)';
frente_real_ZDT1 = [f1, 1 - sqrt(f1)];       % frente de Pareto exacto
ref_ZDT1 = [2, 2];                           % punto de referencia del HV

frentes_ZDT1 = cell(3, numRuns);
hv_ZDT1 = zeros(3, numRuns);
igd_ZDT1 = zeros(3, numRuns);
for c = 1:3
    for r = 1:numRuns
        [~, F] = nsga2(zdt1, configsZDT1{c});
        frentes_ZDT1{c, r} = F;
        hv_ZDT1(c, r) = hipervolumen_min(F, ref_ZDT1);
        igd_ZDT1(c, r) = igd_plus(F, frente_real_ZDT1);
    end
end

%% Problema 2: mochila multiobjetivo (maximizar beneficio y valor estratégico)
% Se minimiza el negativo de cada objetivo. Las soluciones que superan la
% capacidad se reparan quitando objetos al azar hasta que caben.
datos = load(fullfile(carpeta, 'datos', 'instancia_mokp.mat'));
p1 = datos.beneficios(:)';  p2 = datos.valores_estrategicos(:)';
w = datos.pesos(:)';        W = datos.capacidad_maxima;
nObj = numel(p1);

mokp.inicializar = @(n) rand(n, nObj) < 0.5;
mokp.evaluar = @(X) evaluar_mokp(X, p1, p2, w, W);
mokp.variar = @variar_binario;

frentes_MOKP = cell(3, numRuns);
hv_MOKP = zeros(3, numRuns);
for c = 1:3
    for r = 1:numRuns
        [~, F] = nsga2(mokp, configsMOKP{c});
        frentes_MOKP{c, r} = -F;                 % de vuelta a valores positivos
        hv_MOKP(c, r) = hipervolumen_max(-F);
    end
end

% No se conoce el frente exacto de esta instancia: como referencia para
% IGD+ se usan las soluciones no dominadas de todas las ejecuciones juntas
frente_ref_MOKP = no_dominados_max(vertcat(frentes_MOKP{:}));
igd_MOKP = zeros(3, numRuns);
for c = 1:3
    for r = 1:numRuns
        igd_MOKP(c, r) = igd_plus(-frentes_MOKP{c, r}, -frente_ref_MOKP);
    end
end

%% Resultados
fprintf('ZDT1 (%d ejecuciones)\n', numRuns);
for c = 1:3
    fprintf('  %-13s HV: %.4f ± %.4f   IGD+: %.4f ± %.4f\n', nombres{c}, ...
        mean(hv_ZDT1(c, :)), std(hv_ZDT1(c, :)), mean(igd_ZDT1(c, :)), std(igd_ZDT1(c, :)));
end
fprintf('Mochila multiobjetivo (%d objetos, %d ejecuciones)\n', nObj, numRuns);
for c = 1:3
    fprintf('  %-13s HV: %.4g ± %.3g   IGD+: %.1f ± %.1f\n', nombres{c}, ...
        mean(hv_MOKP(c, :)), std(hv_MOKP(c, :)), mean(igd_MOKP(c, :)), std(igd_MOKP(c, :)));
end

%% Figuras
grupo = categorical(repelem(nombres', numRuns), nombres);
fig1 = figure('Color', 'w', 'Position', [100 100 1000 650]);
subplot(2, 2, 1); boxchart(grupo, reshape(hv_ZDT1', [], 1));  grid on; title('ZDT1: hipervolumen (mayor es mejor)');
subplot(2, 2, 2); boxchart(grupo, reshape(igd_ZDT1', [], 1)); grid on; title('ZDT1: IGD+ (menor es mejor)');
subplot(2, 2, 3); boxchart(grupo, reshape(hv_MOKP', [], 1) / 1e9); grid on; ylabel('\times 10^9');
title('Mochila: hipervolumen (mayor es mejor)');
subplot(2, 2, 4); boxchart(grupo, reshape(igd_MOKP', [], 1)); grid on; title('Mochila: IGD+ (menor es mejor)');

% Frentes de la ejecución mediana (según HV) de cada configuración
fig2 = figure('Color', 'w', 'Position', [100 100 1000 420]);
marcas = {'o', 's', '^'};
subplot(1, 2, 1);
plot(frente_real_ZDT1(:, 1), frente_real_ZDT1(:, 2), 'k-', 'LineWidth', 1.5); hold on;
for c = 1:3
    F = frentes_ZDT1{c, ejecucion_mediana(hv_ZDT1(c, :))};
    plot(F(:, 1), F(:, 2), marcas{c}, 'MarkerSize', 4);
end
hold off; grid on; xlabel('f_1'); ylabel('f_2');
title('ZDT1: frentes obtenidos'); legend(['Frente real', nombres], 'Location', 'northeast');

subplot(1, 2, 2);
plot(frente_ref_MOKP(:, 1), frente_ref_MOKP(:, 2), 'k.', 'MarkerSize', 8); hold on;
for c = 1:3
    F = frentes_MOKP{c, ejecucion_mediana(hv_MOKP(c, :))};
    plot(F(:, 1), F(:, 2), marcas{c}, 'MarkerSize', 4);
end
hold off; grid on; xlabel('Beneficio'); ylabel('Valor estratégico');
title('Mochila: frentes obtenidos'); legend(['Referencia', nombres], 'Location', 'southwest');

% Tema claro para las imágenes exportadas (la función theme existe desde R2025a)
if exist('theme', 'file'), theme(fig1, 'light'); theme(fig2, 'light'); end
exportgraphics(fig1, fullfile(carpeta, 'figuras', 'metricas.png'), 'Resolution', 150);
exportgraphics(fig2, fullfile(carpeta, 'figuras', 'frentes.png'), 'Resolution', 150);

%% ========================================================================
% Problemas
% ========================================================================
function [X, F] = evaluar_zdt1(X)
    n = size(X, 2);
    f1 = X(:, 1);
    g = 1 + 9 * sum(X(:, 2:n), 2) / (n - 1);
    F = [f1, g .* (1 - sqrt(f1 ./ g))];
end

function [X, F] = evaluar_mokp(X, p1, p2, w, W)
    for i = 1:size(X, 1)
        peso = w * X(i, :)';
        while peso > W                       % reparación: quitar objetos al azar
            dentro = find(X(i, :));
            q = dentro(randi(numel(dentro)));
            X(i, q) = false;
            peso = peso - w(q);
        end
    end
    F = -[X * p1', X * p2'];
end

%% ========================================================================
% Operadores de variación (los padres vienen emparejados: filas 1-2, 3-4...)
% ========================================================================
% Variables reales: cruce SBX y mutación polinómica
function H = variar_real(P, cfg, lb, ub)
    P1 = P(1:2:end, :);  P2 = P(2:2:end, :);
    [np, nv] = size(P1);

    % SBX: los hijos se reparten alrededor de los padres; con etaC alto
    % quedan muy cerca de ellos (explotación), con etaC bajo más lejos
    u = rand(np, nv);
    beta = (2 * u) .^ (1 / (cfg.etaC + 1));
    alto = u > 0.5;
    beta(alto) = (1 ./ (2 * (1 - u(alto)))) .^ (1 / (cfg.etaC + 1));
    sin_cruce = rand(np, 1) >= cfg.pc;
    beta(sin_cruce, :) = 1;                       % beta = 1: hijos = padres
    H1 = 0.5 * ((1 + beta) .* P1 + (1 - beta) .* P2);
    H2 = 0.5 * ((1 - beta) .* P1 + (1 + beta) .* P2);
    H = [H1; H2];

    % Mutación polinómica: cada gen muta con probabilidad pm
    muta = rand(size(H)) < cfg.pm;
    u = rand(size(H));
    delta = (2 * u) .^ (1 / (cfg.etaM + 1)) - 1;
    alto = u >= 0.5;
    delta(alto) = 1 - (2 * (1 - u(alto))) .^ (1 / (cfg.etaM + 1));
    H(muta) = H(muta) + delta(muta) * (ub - lb);
    H = min(max(H, lb), ub);
end

% Variables binarias: cruce uniforme y mutación por inversión de bits
function H = variar_binario(P, cfg)
    P1 = P(1:2:end, :);  P2 = P(2:2:end, :);
    mascara = rand(size(P1)) < 0.5;
    mascara(rand(size(P1, 1), 1) >= cfg.pc, :) = false;   % parejas sin cruce
    H1 = P1;  H1(mascara) = P2(mascara);
    H2 = P2;  H2(mascara) = P1(mascara);
    H = [H1; H2];
    H = xor(H, rand(size(H)) < cfg.pm);
end

%% ========================================================================
% Métricas
% ========================================================================
% Hipervolumen en minimización con punto de referencia ref: área de la
% unión de los rectángulos entre cada punto del frente y ref
function hv = hipervolumen_min(F, ref)
    F = F(all(F <= ref, 2), :);
    if isempty(F), hv = 0; return; end
    F = sortrows(F, 1);
    hv = 0;
    y_prev = ref(2);
    for i = 1:size(F, 1)
        if F(i, 2) < y_prev
            hv = hv + (ref(1) - F(i, 1)) * (y_prev - F(i, 2));
            y_prev = F(i, 2);
        end
    end
end

% Hipervolumen en maximización con referencia en el origen
function hv = hipervolumen_max(F)
    F = no_dominados_max(F);
    F = sortrows(F, 1);                 % f1 creciente, f2 decreciente
    anchos = diff([0; F(:, 1)]);
    hv = sum(anchos .* F(:, 2));
end

% IGD+ en minimización: A es el frente obtenido y Z el de referencia
function v = igd_plus(A, Z)
    d = zeros(size(Z, 1), 1);
    for i = 1:size(Z, 1)
        dif = max(0, A - Z(i, :));      % solo cuenta en lo que A es peor que Z
        d(i) = min(sqrt(sum(dif.^2, 2)));
    end
    v = mean(d);
end

% Soluciones no dominadas en maximización
function F = no_dominados_max(F)
    F = unique(F, 'rows');
    A = permute(F, [1 3 2]);  B = permute(F, [3 1 2]);
    dominado = any(all(B >= A, 3) & any(B > A, 3), 2);
    F = F(~dominado, :);
end

% Índice de la ejecución con el valor mediano de una métrica
function k = ejecucion_mediana(v)
    [~, orden] = sort(v);
    k = orden(ceil(numel(v) / 2));
end
