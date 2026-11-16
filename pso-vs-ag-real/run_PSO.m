function [xgbest, gbest, log] = run_PSO(fitness_func, n, d, lb, ub, max_iter, paciencia)
% Optimización por enjambre de partículas (PSO) con representación real.
%
% Entradas:
%   fitness_func - función a minimizar; recibe una matriz n x d (una
%                  partícula por fila) y devuelve un vector n x 1
%   n            - número de partículas
%   d            - número de dimensiones
%   lb, ub       - límites inferior y superior de cada variable
%   max_iter     - número máximo de iteraciones
%   paciencia    - se para si el mejor valor no mejora en tantas iteraciones
% Salidas:
%   xgbest - mejor posición encontrada
%   gbest  - valor de la función en xgbest
%   log    - mejor valor en cada iteración (curva de convergencia)

    % Parámetros
    w  = 0.8;     % inercia
    cp = 1.8;     % aceleración cognitiva (atracción hacia el mejor propio)
    cg = 2.4;     % aceleración social (atracción hacia el mejor global)

    % Inicialización: posiciones aleatorias en el dominio y velocidad nula
    x = lb + (ub - lb) * rand(n, d);
    V = zeros(n, d);
    f_pbest = fitness_func(x);
    xpbest = x;
    [gbest, idx] = min(f_pbest);
    xgbest = x(idx, :);

    log = zeros(1, max_iter);
    sin_mejora = 0;
    iter = 0;

    while iter < max_iter && sin_mejora < paciencia
        iter = iter + 1;

        % Actualización de velocidad y posición de todas las partículas a la vez.
        % r1 y r2 son un número aleatorio por partícula (el mismo en todas
        % sus dimensiones): cada partícula se mueve en línea hacia su mejor
        % posición y hacia la mejor global. Con un aleatorio distinto por
        % dimensión, estos parámetros se estancan en Rastrigin (ver README).
        r1 = rand(n, 1);
        r2 = rand(n, 1);
        V = w * V + cp * r1 .* (xpbest - x) + cg * r2 .* (xgbest - x);
        x = max(min(x + V, ub), lb);       % las que salen del dominio se quedan en el borde

        % Actualización de los mejores personales y del global
        f = fitness_func(x);
        mejora = f < f_pbest;
        f_pbest(mejora) = f(mejora);
        xpbest(mejora, :) = x(mejora, :);

        [f_min, idx] = min(f_pbest);
        if f_min < gbest - 1e-12 * max(1, abs(gbest))
            sin_mejora = 0;
        else
            sin_mejora = sin_mejora + 1;
        end
        if f_min < gbest
            gbest = f_min;
            xgbest = xpbest(idx, :);
        end
        log(iter) = gbest;
    end
    log = log(1:iter);
end
