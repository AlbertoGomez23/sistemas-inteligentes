function f = ackley(x)
% Función de Ackley. x: matriz n x d (un punto por fila). f: vector n x 1.
% Mínimo global f = 0 en x = 0. Dominio habitual: [-32.768, 32.768]^d.
    d = size(x, 2);
    f = -20 * exp(-0.2 * sqrt(sum(x.^2, 2) / d)) - exp(sum(cos(2*pi*x), 2) / d) + 20 + exp(1);
end
