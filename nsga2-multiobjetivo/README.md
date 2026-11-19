# NSGA-II: multi-objective optimization

Implementation of **NSGA-II** (*Non-dominated Sorting Genetic Algorithm II*)
applied to two problems of different nature, each with two conflicting
objectives. Instead of a single optimal solution, the goal is the **Pareto
front**: the solutions in which one objective cannot be improved without
worsening the other.

- **ZDT1 (continuous).** 50 variables in [0, 1] and two objectives to minimize.
  It is a standard test problem and its exact Pareto front is known:
  f₂ = 1 − √f₁.
- **Multi-objective knapsack (discrete and constrained).** 500 items: choose
  which ones to pack to maximize both economic profit and strategic value at the
  same time, without exceeding the maximum weight.

## How it works

The core of the algorithm ([`nsga2.m`](nsga2.m)) is shared by both problems:

1. **Non-dominated sorting.** A solution dominates another if it is no worse in
   any objective and better in at least one. Front 1 is made of the solutions
   that nobody dominates; front 2, of those dominated only by front 1; and so on.
   It is vectorized: the dominance matrix of the whole population is computed at
   once.
2. **Crowding distance.** Within each front it measures how isolated each
   solution is. Solutions in sparse regions are preferred to keep the front well
   spread, and the extremes are always kept.
3. **Binary tournament selection** (the one in the lower front wins and, in case
   of a tie, the one with the larger crowding distance), crossover and mutation.
4. **Elitist selection.** Parents and children are merged and the best whole
   fronts survive. The last front that does not fit completely is truncated by
   crowding distance.

Operators for each problem ([`ejecutar_nsga2.m`](ejecutar_nsga2.m)):

| | ZDT1 (continuous) | Knapsack (binary) |
|---|---|---|
| Crossover | SBX (*Simulated Binary Crossover*) | Uniform |
| Mutation | Polynomial | Bit flip |
| Constraint | — | **Repair**: if a solution exceeds the weight, random items are removed until it fits |

Repair was chosen over penalization so that every solution in the population is
valid and the final front contains no impossible knapsacks.

## Experiments

Three configurations per problem, designed to trigger different behaviours,
with **30 independent runs** each:

| Configuration | Population | Generations | Crossover p. | Mutation p. | Idea |
|---|---|---|---|---|---|
| Balanced | 120 | 500 | 0.9 | 0.1 (ZDT1) / 1/500 (knapsack) | Enough time to converge |
| Exploratory | 200 | 100 | 0.7 | 0.1 / 0.05 | High diversity and mutation, little time |
| Premature | 30 | 30–40 | 0.95 | 0.001 | Small population and almost no mutation |

For ZDT1 the distribution indices of SBX and polynomial mutation are also tuned
(η = 15/20, 5/5 and 50/50): with a high η the children stay very close to their
parents.

Metrics:
- **Hypervolume (HV).** Area of the objective space dominated by the front, up
  to a reference point. It captures convergence and diversity at the same time.
  Higher is better.
- **IGD+.** For each point of the reference front, the distance to the closest
  obtained solution, counting only where the latter is worse. It penalizes gaps
  and uncovered regions. Lower is better. For ZDT1 the reference is the exact
  front. For the knapsack, whose front is unknown, the non-dominated solutions
  of all runs combined are used.

## Results

| Problem | Configuration | HV (mean ± std.) | IGD+ (mean ± std.) |
|---|---|---|---|
| ZDT1 | **Balanced** | **3.648 ± 0.002** | **0.0086 ± 0.0007** |
| ZDT1 | Exploratory | 3.264 ± 0.052 | 0.156 ± 0.019 |
| ZDT1 | Premature | 0 ± 0 | 2.45 ± 0.18 |
| Knapsack | **Balanced** | **2.021·10¹⁰ ± 1.6·10⁸** | **848 ± 230** |
| Knapsack | Exploratory | 1.344·10¹⁰ ± 1.7·10⁸ | 35,660 ± 1,086 |
| Knapsack | Premature | 1.118·10¹⁰ ± 3.6·10⁸ | 45,269 ± 2,724 |

![Hypervolume and IGD+ over 30 runs](figuras/metricas.png)

![Obtained fronts (median run of each configuration)](figuras/frentes.png)

- **The balanced configuration is the best on both problems**, by a wide
  margin. On ZDT1 its front overlaps the exact one (IGD+ < 0.01). On the
  knapsack it covers almost the whole reference front.
- **The exploratory one** keeps a well-spread front, but with only 100
  generations it does not converge: it stays above the true front on ZDT1 and
  far behind on the knapsack.
- **The premature one** stalls far from the front. On ZDT1 all its points fall
  outside the hypervolume reference point (2, 2), so its **HV is 0 in all 30
  runs**. There HV can no longer tell a bad run from a worse one, and it is IGD+
  that keeps measuring how far off it is. That is what having two metrics is
  for.
- **Continuous vs. discrete.** On ZDT1 it is enough to move the variables little
  by little towards the front. On the knapsack, with 500 items and the weight
  constraint, the space is huge and almost any change breaks the constraint,
  which then has to be repaired. That is why the difference between
  configurations is much larger: without enough generations and a low, steady
  mutation rate, the front stays far away.
- Visually comparing the fronts confirms the metrics, but the metrics allow
  comparing all 30 runs at once and also show stability: the balanced
  configuration is also the one with the smallest spread.

## How to run

Run `ejecutar_nsga2.m` in MATLAB (it takes about 2 minutes). The knapsack data
is in `datos/instancia_mokp.mat`: profits, strategic values, weights and maximum
capacity.
