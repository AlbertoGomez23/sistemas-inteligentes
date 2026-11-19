# Intelligent systems: metaheuristic optimization

Combinatorial and continuous optimization problems solved with metaheuristics
implemented from scratch in MATLAB, without optimization toolboxes: local search,
evolutionary algorithms, swarm intelligence and multi-objective optimization.
Each project includes its own experimental analysis, with several
configurations, repeated runs and metrics.

| Project | Techniques | Problem |
|---|---|---|
| [Simulated annealing and tabu search](tsp-recocido-tabu/) | Simulated annealing, tabu search, 2-opt neighbourhood | Clustered travelling salesman problem (TSP), up to 1000 cities |
| [Genetic algorithm for Job Shop](jssp-algoritmo-genetico/) | Integer-coded GA, JOX crossover, inversion mutation | Job shop scheduling (JSSP) |
| [PSO vs. genetic algorithm](pso-vs-ag-real/) | Particle swarm optimization, real-coded GA | Multimodal Ackley and Rastrigin functions |
| [Ant colony optimization](aco-cvrp/) | ACO with capacity constraint | Vehicle routing (CVRP) with 500 customers |
| [Multi-objective NSGA-II](nsga2-multiobjetivo/) | NSGA-II, SBX, polynomial mutation, hypervolume, IGD+ | ZDT1 and multi-objective knapsack |

## Structure

Each folder is an independent project, with its code, its data, an
`ejecutar_*.m` (or `comparar_*.m`) script that reproduces the results, and a
README with the explanation, results and figures. The code (identifiers and
comments) is written in Spanish.

## How to run

1. Open MATLAB (tested on R2025a; no toolbox required).
2. Go to the project folder and run its main script.

The results in the READMEs were obtained with a fixed seed (`rng(1)`). In the
time-limited problems (TSP and JSSP) they may vary slightly depending on the
speed of the computer, since more or fewer iterations fit in the same time.
