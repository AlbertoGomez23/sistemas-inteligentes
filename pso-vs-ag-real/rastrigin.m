function f = rastrigin(x)
% Función de Rastrigin. x: matriz n x d (un punto por fila). f: vector n x 1.
% Mínimo global f = 0 en x = 0. Dominio habitual: [-5.12, 5.12]^d.
    d = size(x, 2);
    f = 10 * d + sum(x.^2 - 10 * cos(2*pi*x), 2);
end
