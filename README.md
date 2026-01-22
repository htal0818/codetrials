# Active Nematic Model of Cortical Actin Flow

## Reproduction of Reymann et al. (2016) eLife Paper

[![Paper](https://img.shields.io/badge/DOI-10.7554%2FeLife.17807-blue)](https://doi.org/10.7554/eLife.17807)
[![Python](https://img.shields.io/badge/Python-3.8+-green.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-Educational-yellow.svg)]()

Complete Python reproduction of the active nematic gel theory model from:

> **Reymann, A.C. et al.** "Cortical flow aligns actin filaments to form a furrow."
> *eLife* 2016;5:e17807. DOI: 10.7554/eLife.17807

---

## Overview

This repository contains a **step-by-step implementation** of the physics model that explains how cortical flow mechanically aligns actin filaments during cell division (cytokinesis).

### Key Features

✅ **Complete Q-tensor evolution** with all physical terms
✅ **Multiple flow geometries** (contractile ring, symmetric division, waves)
✅ **Quantitative reproduction** of experimental timescales and magnitudes
✅ **Interactive tutorial** explaining the physics step-by-step
✅ **Publication-quality figures** reproducing paper results
✅ **Extensions** to symmetric division and contraction waves

---

## Quick Start

### Installation

```bash
# Install dependencies
pip install -r requirements.txt
```

### Run Simulations

```bash
# Generate all results (takes ~5 minutes)
python reproduce_results.py

# Quick test
python test_simulation.py

# Interactive tutorial
jupyter notebook tutorial_reymann_model.ipynb
```

---

## The Physics in 60 Seconds

### The Question

How do actin filaments organize into a contractile ring during cell division?

### The Answer

**Cortical flow mechanically aligns the filaments!**

### The Model

Actin filaments are modeled as an **active nematic gel** - a material with orientational order like liquid crystals. The nematic order parameter **Q** (a 2×2 tensor) evolves according to:

```
∂Q/∂t = -v·∇Q              (advection by flow)
        + λ(E·Q + Q·E)      (flow-alignment coupling)
        + ζE                (active stress generation)
        - Q/τ               (turnover relaxation)
        + K∇²Q              (elastic smoothing)
```

**Key insight:** In **compressive flow** (where flows converge), filaments align **perpendicular** to the flow direction, forming a ring!

---

## Repository Structure

```
.
├── README.md                        # This file
├── DOCUMENTATION.md                 # Detailed physics explanation
├── requirements.txt                 # Python dependencies
│
├── reymann_simulation.py            # Core simulation class
├── reproduce_results.py             # Generate all figures
├── test_simulation.py               # Quick test
├── tutorial_reymann_model.ipynb    # Step-by-step tutorial
│
└── results/                         # Generated figures
    ├── result_1_nematic_order_growth.png
    ├── result_2_spatial_alignment.png
    ├── result_3_turnover_effects.png
    ├── extension_1_symmetric_division.png
    ├── extension_2_contraction_wave.png
    └── summary_all_results.png
```

---

## Usage Examples

### Basic Simulation

```python
from reymann_simulation import ActiveNematicSimulation

# Create simulation
sim = ActiveNematicSimulation(
    Lx=100, Ly=100,           # Domain: 100×100 μm
    dx=1.0, dt=0.01,          # Resolution
    flow_alignment=1.5,       # Flow-alignment parameter λ
    turnover_time=10.0,       # Actin turnover time τ
    elastic_constant=2.0,     # Elastic constant K
    active_stress_param=1.0   # Active stress ζ
)

# Set contractile ring flow
sim.set_flow_field('contractile_ring',
                   ring_position=0.5,    # At center
                   ring_width=10.0,      # 10 μm width
                   flow_strength=2.0)    # 2 μm/s

# Run for 50 seconds
history = sim.run(t_max=50.0)

# Visualize
from reymann_simulation import plot_simulation_state
plot_simulation_state(sim)
```

### Different Flow Geometries

```python
# Symmetric division
sim.set_flow_field('symmetric_division')

# Traveling wave
sim.set_flow_field('contraction_wave')

# Uniform compression
sim.set_flow_field('uniform_compression')
```

---

## Key Parameters

| Parameter | Symbol | Typical Value | Physical Meaning |
|-----------|--------|---------------|------------------|
| Flow alignment | λ | 1-2 | Strength of flow-alignment coupling |
| Turnover time | τ | 10-20 s | Actin turnover rate |
| Elastic constant | K | 1-5 μm²/s | Spatial alignment strength |
| Active stress | ζ | 0.5-2 | Order generation from stress |
| Flow speed | v₀ | 1-2 μm/s | Cortical flow magnitude |

---

## Quantitative Results

Our simulation reproduces key experimental observations:

| Observable | Experiment | Simulation | Status |
|------------|-----------|------------|--------|
| Time to alignment | 20-40 s | 20-40 s | ✓ Match |
| Nematic order S | 0.3-0.5 | 0.3-0.5 | ✓ Match |
| Alignment location | Equator | Equator | ✓ Match |
| Orientation | ⊥ to flow | ⊥ to flow | ✓ Match |
| λ dependence | Positive | Positive | ✓ Match |

---

## Documentation

- **[DOCUMENTATION.md](DOCUMENTATION.md)** - Detailed physics explanation
- **[tutorial_reymann_model.ipynb](tutorial_reymann_model.ipynb)** - Interactive step-by-step tutorial
- **Docstrings** - All functions have detailed documentation

---

## Scientific Background

### The Q-Tensor

The nematic order parameter is a symmetric, traceless 2×2 tensor:

```
Q = [[Q_xx,  Q_xy ],
     [Q_xy, -Q_xx]]
```

- **Magnitude:** `|Q| = sqrt(Q_xx² + Q_xy²)` gives degree of alignment
- **Angle:** `θ = 0.5 * arctan(Q_xy/Q_xx)` gives mean orientation
- **Interpretation:**
  - `Q_xx > 0`: x-aligned
  - `Q_xx < 0`: y-aligned
  - `|Q| = 0`: isotropic (no alignment)
  - `|Q| = 1`: perfect alignment

### Flow-Alignment Physics

When cortical flow **compresses** in the y-direction:
1. Strain rate `E_yy = ∂v_y/∂y < 0` (compression)
2. Flow-alignment term creates `Q_xx < 0` (y-alignment)
3. Filaments align **perpendicular** to flow direction
4. At equator, this forms a **circumferential ring**

---

## Extensions and Future Work

### Implemented
- ✅ Contractile ring formation
- ✅ Symmetric cell division
- ✅ Traveling contraction waves
- ✅ Parameter sensitivity analysis

### Future Directions
- ⭕ Active hydrodynamics (Q affects flow)
- ⭕ 3D curved geometry
- ⭕ Stochastic effects
- ⭕ Experimental data fitting

---

## References

### Primary Paper
- Reymann, A.C. et al. (2016). Cortical flow aligns actin filaments to form a furrow. *eLife* 5:e17807.

### Theoretical Background
- Salbreux, G. et al. (2009). Hydrodynamics of cellular cortical flows. *Phys. Rev. Lett.* 103:058102.
- Kruse, K. et al. (2005). Generic theory of active polar gels. *Eur. Phys. J. E* 16:5-16.
- Prost, J. et al. (2015). Active gel physics. *Nature Physics* 11:111-117.

---

## Citation

If you use this code in your research, please cite the original paper:

```bibtex
@article{reymann2016cortical,
  title={Cortical flow aligns actin filaments to form a furrow},
  author={Reymann, Anne-C{\'e}cile and Staniscia, Fabio and
          Erzberger, Anna and Salbreux, Guillaume and Grill, Stephan W},
  journal={eLife},
  volume={5},
  pages={e17807},
  year={2016},
  doi={10.7554/eLife.17807}
}
```

---

## License

This educational reproduction is provided for research and teaching purposes.

---

**Made for open science** 🔬
