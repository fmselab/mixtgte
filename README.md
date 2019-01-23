# MixTgTe
Efficient and Guaranteed Detection of t-way Failure-inducing Combinations

This repository contains the benchmarks used, the final data obtained by running the process, and a script to aggregate such data.

- Benchmarks here encode directly the delta difference between the models M_f and M_o described in the paper. They are available as CTWedge models, with the true-mfics expressed as negated constraints (the constraints represents the passing tests).
Benchmarks are available under the `benchmarks` folder in this repository.

- The final data is available under the `log` folder in this repository.

- The R script to aggregate statistics and generate data for Table V is available at the root of this repository: `stats.R`

The authors,

P. Arcaini, [A. Gargantini](mailto://angelo.gargantini@unibg.it), [M. Radavelli](https://cs.unibg.it/radavelli/)
