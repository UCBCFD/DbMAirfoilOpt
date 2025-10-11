# AirDbM

This public repository accompanies our research article **"Airfoil Optimization using Design-by-Morphing with Minimized Design-Space Dimensionality"**.

It extends our 2023 release in the *Journal of Computational Design and Engineering* ([https://doi.org/10.1093/jcde/qwad059](https://doi.org/10.1093/jcde/qwad059)) by introducing **AirDbM**, a compact 12-baseline implementation of Design-by-Morphing (DbM) that preserves geometric diversity while halving the number of design variables.

## Description

Design-by-Morphing (DbM) offers rich shape variation with few parameters, yet its efficiency depends on the size of the baseline set. **AirDbM** systematically selects 12 representative airfoils from the 1,600-shape UIUC database through a forward-search baseline selection process that maximizes reconstruction capability.

With these baselines, AirDbM:
* Reconstructs over 98% of the UIUC database with a mean absolute error (MAE) < 0.005 — matching the accuracy of the previous 25-baseline DbM;
* Accelerates multi-objective optimization, achieving a Pareto front with larger hypervolume and higher lift-to-drag ratios at moderate stall tolerance;
* Demonstrates high adaptability for reinforcement-learning agents, outperforming classical parameterizations (CST, Hicks–Henne, NURBS, PARSEC) in both learning speed and final accuracy.

## Materials

* Paper: *[link to be added after acceptance]*  
* Data: See `GAOutput_MO.mat` in this repository (MATLAB-compatible format). Also see `airfoilDB/AirDbM_Reconstruct.txt` for the DbM weight sets used to reconstruct the UIUC database, along with their corresponding MAE values.

> The 2023 article *"Airfoil Optimization using Design-by-Morphing"* is available at [https://doi.org/10.1093/jcde/qwad059](https://doi.org/10.1093/jcde/qwad059).

## How to cite

If you use this repository, please cite:

- Lee, S. & Sheikh, H. M. (2025). *Airfoil Optimization using Design-by-Morphing with Minimized Design-Space Dimensionality*. Manuscript in preparation (DOI and journal information will be updated upon publication).  
- Sheikh, H. M., Lee, S., Wang, J., & Marcus, P. S. (2023). Airfoil Optimization using Design-by-Morphing. *Journal of Computational Design and Engineering*, 10(4), 1443–1459. https://doi.org/10.1093/jcde/qwad059

---