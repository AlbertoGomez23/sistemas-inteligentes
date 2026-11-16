# Sistemas inteligentes: metaheurísticas de optimización

Problemas de optimización combinatoria y continua resueltos con metaheurísticas
implementadas desde cero en MATLAB, sin toolboxes de optimización: búsqueda
local, algoritmos evolutivos, inteligencia de enjambre y optimización
multiobjetivo. Cada proyecto incluye su análisis experimental, con varias
configuraciones, ejecuciones repetidas y métricas.

| Proyecto | Técnicas | Problema |
|---|---|---|
| [Recocido simulado y búsqueda tabú](tsp-recocido-tabu/) | Recocido simulado, búsqueda tabú, vecindario 2-opt | Viajante (TSP) con ciudades agrupadas, hasta 1000 ciudades |
| [Algoritmo genético para Job Shop](jssp-algoritmo-genetico/) | AG con representación entera, cruce JOX, mutación por inversión | Planificación de trabajos en máquinas (JSSP) |
| [PSO contra algoritmo genético](pso-vs-ag-real/) | Enjambre de partículas, AG con codificación real | Funciones multimodales de Ackley y Rastrigin |
| [Colonia de hormigas](aco-cvrp/) | ACO con restricción de capacidad | Rutas de reparto (CVRP) con 500 clientes |
| [NSGA-II multiobjetivo](nsga2-multiobjetivo/) | NSGA-II, SBX, mutación polinómica, hipervolumen, IGD+ | ZDT1 y mochila multiobjetivo |

## Estructura

Cada carpeta es un proyecto independiente, con su código, sus datos, un
script `ejecutar_*.m` (o `comparar_*.m`) que reproduce los resultados y un
README con la explicación, los resultados y las figuras.

## Cómo ejecutar

1. Abrir MATLAB (probado en R2025a; no hace falta ninguna toolbox).
2. Entrar en la carpeta del proyecto y ejecutar su script principal.

Los resultados de los README se han obtenido con semilla fija (`rng(1)`). En
los problemas con límite de tiempo (TSP y JSSP) pueden variar algo según la
velocidad del ordenador, porque en el mismo tiempo se hacen más o menos
iteraciones.
