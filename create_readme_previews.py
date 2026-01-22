"""
Create preview images for README.md

This script generates thumbnail/preview versions of the main result figures
to be embedded directly in the README for visual appeal.
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from reymann_simulation import ActiveNematicSimulation

print("Creating README preview images...")
print("=" * 70)

# Set style for clean previews
plt.rcParams['figure.dpi'] = 150
plt.rcParams['font.size'] = 10

# ============================================================================
# Preview 1: Basic Simulation Result
# ============================================================================
print("\n1. Basic simulation result...")

sim = ActiveNematicSimulation(
    Lx=100, Ly=100, dx=1.0, dt=0.01,
    flow_alignment=1.5,
    turnover_time=10.0,
    elastic_constant=2.0,
    active_stress_param=1.0
)

sim.set_flow_field('contractile_ring', ring_position=0.5,
                   ring_width=10.0, flow_strength=2.0)

history = sim.run(t_max=50.0, update_interval=5.0)

fig = plt.figure(figsize=(12, 4))

# Nematic order field
ax1 = plt.subplot(1, 3, 1)
S_field = np.sqrt(sim.Qxx**2 + sim.Qxy**2)
im1 = ax1.imshow(S_field, extent=[0, sim.Lx, 0, sim.Ly],
                 origin='lower', cmap='viridis', vmin=0, vmax=0.5)
ax1.axhline(y=50, color='yellow', linestyle='--', linewidth=2, alpha=0.7)
ax1.set_xlabel('x (μm)', fontsize=11)
ax1.set_ylabel('y (μm)', fontsize=11)
ax1.set_title('Nematic Order Field', fontsize=12, fontweight='bold')
plt.colorbar(im1, ax=ax1, label='S', shrink=0.8)

# Add director overlay
x_sub, y_sub, nx, ny, S_sub = sim.get_director_field(subsample=6)
ax1.quiver(x_sub, y_sub, nx, ny, color='k', linewidth=1.5, alpha=0.7)

# Qxx field
ax2 = plt.subplot(1, 3, 2)
im2 = ax2.imshow(sim.Qxx, extent=[0, sim.Lx, 0, sim.Ly],
                 origin='lower', cmap='RdBu_r', vmin=-0.3, vmax=0.3)
ax2.axhline(y=50, color='yellow', linestyle='--', linewidth=2, alpha=0.7)
ax2.set_xlabel('x (μm)', fontsize=11)
ax2.set_ylabel('y (μm)', fontsize=11)
ax2.set_title('Orientation (Q_xx < 0 = y-aligned)', fontsize=12, fontweight='bold')
plt.colorbar(im2, ax=ax2, label='Q_xx', shrink=0.8)

# Time evolution
ax3 = plt.subplot(1, 3, 3)
ax3.plot(history['times'], history['nematic_order'], 'b-', linewidth=2.5)
ax3.set_xlabel('Time (s)', fontsize=11)
ax3.set_ylabel('Nematic Order S', fontsize=11)
ax3.set_title('Growth of Alignment', fontsize=12, fontweight='bold')
ax3.grid(True, alpha=0.3)
ax3.set_xlim([0, 50])

plt.suptitle('Contractile Ring Formation: Actin Alignment at Equator',
             fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('results/preview_basic_result.png', dpi=150, bbox_inches='tight')
print("   ✓ Saved: results/preview_basic_result.png")
plt.close()

# ============================================================================
# Preview 2: Parameter Comparison
# ============================================================================
print("\n2. Parameter comparison...")

fig = plt.figure(figsize=(12, 4))

# Different λ values
ax1 = plt.subplot(1, 3, 1)
for lam, color in zip([0.5, 1.0, 1.5, 2.0],
                      ['#3498db', '#2ecc71', '#f39c12', '#e74c3c']):
    sim_test = ActiveNematicSimulation(
        Lx=100, Ly=100, dx=1.0, dt=0.01,
        flow_alignment=lam,
        turnover_time=10.0,
        elastic_constant=2.0,
        active_stress_param=1.0
    )
    sim_test.set_flow_field('contractile_ring', ring_position=0.5,
                            ring_width=10.0, flow_strength=2.0)
    hist = sim_test.run(t_max=50.0, update_interval=2.0)
    ax1.plot(hist['times'], hist['nematic_order'], color=color,
             linewidth=2, label=f'λ = {lam}')

ax1.set_xlabel('Time (s)', fontsize=11)
ax1.set_ylabel('Nematic Order S', fontsize=11)
ax1.set_title('Effect of Flow-Alignment λ', fontsize=12, fontweight='bold')
ax1.legend(fontsize=9)
ax1.grid(True, alpha=0.3)

# Different τ values
ax2 = plt.subplot(1, 3, 2)
for tau, color in zip([5.0, 10.0, 20.0, 40.0],
                      ['#e74c3c', '#f39c12', '#2ecc71', '#3498db']):
    sim_test = ActiveNematicSimulation(
        Lx=100, Ly=100, dx=1.0, dt=0.01,
        flow_alignment=1.5,
        turnover_time=tau,
        elastic_constant=2.0,
        active_stress_param=1.0
    )
    sim_test.set_flow_field('contractile_ring', ring_position=0.5,
                            ring_width=10.0, flow_strength=2.0)
    hist = sim_test.run(t_max=80.0, update_interval=2.0)
    ax2.plot(hist['times'], hist['nematic_order'], color=color,
             linewidth=2, label=f'τ = {tau:.0f} s')

ax2.set_xlabel('Time (s)', fontsize=11)
ax2.set_ylabel('Nematic Order S', fontsize=11)
ax2.set_title('Effect of Turnover Time τ', fontsize=12, fontweight='bold')
ax2.legend(fontsize=9)
ax2.grid(True, alpha=0.3)

# Spatial profile
ax3 = plt.subplot(1, 3, 3)
sim_final = ActiveNematicSimulation(
    Lx=100, Ly=100, dx=1.0, dt=0.01,
    flow_alignment=1.5,
    turnover_time=10.0,
    elastic_constant=2.0,
    active_stress_param=1.0
)
sim_final.set_flow_field('contractile_ring', ring_position=0.5,
                         ring_width=10.0, flow_strength=2.0)
sim_final.run(t_max=50.0, update_interval=5.0)

S_field = np.sqrt(sim_final.Qxx**2 + sim_final.Qxy**2)
S_profile = np.mean(S_field, axis=1)
y = np.linspace(0, sim_final.Ly, sim_final.ny)

ax3.plot(y, S_profile, 'b-', linewidth=2.5)
ax3.axvline(x=50, color='r', linestyle='--', linewidth=2,
            alpha=0.6, label='Equator')
ax3.set_xlabel('y position (μm)', fontsize=11)
ax3.set_ylabel('Nematic Order S', fontsize=11)
ax3.set_title('Spatial Localization', fontsize=12, fontweight='bold')
ax3.legend(fontsize=9)
ax3.grid(True, alpha=0.3)

plt.suptitle('Parameter Dependencies: Flow-Alignment and Turnover',
             fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('results/preview_parameters.png', dpi=150, bbox_inches='tight')
print("   ✓ Saved: results/preview_parameters.png")
plt.close()

# ============================================================================
# Preview 3: Symmetric Cell Division (200 μm diameter cell)
# ============================================================================
print("\n3. Symmetric cell division (200 μm diameter)...")

fig = plt.figure(figsize=(8, 10))

# Symmetric division - 200 μm diameter cell
sim_sym = ActiveNematicSimulation(
    Lx=200, Ly=240, dx=1.0, dt=0.01,
    flow_alignment=1.5,
    turnover_time=10.0,
    elastic_constant=2.0,
    active_stress_param=1.0
)
sim_sym.set_flow_field('symmetric_division', ring_width=20.0, flow_strength=2.0)
sim_sym.run(t_max=50.0, update_interval=5.0)

S_field_sym = np.sqrt(sim_sym.Qxx**2 + sim_sym.Qxy**2)
im1 = plt.imshow(S_field_sym, extent=[0, sim_sym.Lx, 0, sim_sym.Ly],
                 origin='lower', cmap='viridis', vmin=0, vmax=0.5)
plt.axhline(y=80, color='yellow', linestyle='--', linewidth=2, alpha=0.7, label='Division furrows')
plt.axhline(y=160, color='yellow', linestyle='--', linewidth=2, alpha=0.7)
plt.xlabel('x (μm)', fontsize=12)
plt.ylabel('y (μm)', fontsize=12)
plt.title('Symmetric Division in 200 μm Diameter Cell\n(Two Furrows at 1/3 and 2/3 positions)',
          fontsize=13, fontweight='bold')
plt.colorbar(im1, label='Nematic Order S', shrink=0.7)
plt.legend(loc='upper right', fontsize=10)

# Add director overlay
x_sub, y_sub, nx, ny, S_sub = sim_sym.get_director_field(subsample=10)
plt.quiver(x_sub, y_sub, nx, ny, color='k', linewidth=1.5, alpha=0.7)

plt.tight_layout()
plt.savefig('results/preview_extensions.png', dpi=150, bbox_inches='tight')
print("   ✓ Saved: results/preview_extensions.png")
plt.close()

# ============================================================================
# Preview 4: Flow Field Visualization
# ============================================================================
print("\n4. Flow field visualization...")

fig = plt.figure(figsize=(12, 4))

sim_flow = ActiveNematicSimulation(
    Lx=100, Ly=100, dx=1.0, dt=0.01,
    flow_alignment=1.5,
    turnover_time=10.0,
    elastic_constant=2.0,
    active_stress_param=1.0
)

sim_flow.set_flow_field('contractile_ring', ring_position=0.5,
                        ring_width=10.0, flow_strength=2.0)

# Flow velocity
ax1 = plt.subplot(1, 3, 1)
im1 = ax1.imshow(sim_flow.vy, extent=[0, sim_flow.Lx, 0, sim_flow.Ly],
                 origin='lower', cmap='RdBu_r')
ax1.axhline(y=50, color='yellow', linestyle='--', linewidth=2)
ax1.set_xlabel('x (μm)', fontsize=11)
ax1.set_ylabel('y (μm)', fontsize=11)
ax1.set_title('Flow Field v_y', fontsize=12, fontweight='bold')
plt.colorbar(im1, ax=ax1, label='v_y (μm/s)', shrink=0.8)

# Flow vectors
ax2 = plt.subplot(1, 3, 2)
speed = np.sqrt(sim_flow.vx**2 + sim_flow.vy**2)
ax2.imshow(speed, extent=[0, sim_flow.Lx, 0, sim_flow.Ly],
           origin='lower', cmap='Reds', alpha=0.4)
subsample = 5
ax2.quiver(sim_flow.X[::subsample, ::subsample],
           sim_flow.Y[::subsample, ::subsample],
           sim_flow.vx[::subsample, ::subsample],
           sim_flow.vy[::subsample, ::subsample],
           scale=50, width=0.003, color='black')
ax2.axhline(y=50, color='yellow', linestyle='--', linewidth=2)
ax2.set_xlabel('x (μm)', fontsize=11)
ax2.set_ylabel('y (μm)', fontsize=11)
ax2.set_title('Flow Vectors', fontsize=12, fontweight='bold')

# Compression
dvx_dx, dvx_dy, dvy_dx, dvy_dy = sim_flow.compute_velocity_gradient()
compression = -dvy_dy

ax3 = plt.subplot(1, 3, 3)
im3 = ax3.imshow(compression, extent=[0, sim_flow.Lx, 0, sim_flow.Ly],
                 origin='lower', cmap='hot', vmin=0, vmax=0.5)
ax3.axhline(y=50, color='cyan', linestyle='--', linewidth=2)
ax3.set_xlabel('x (μm)', fontsize=11)
ax3.set_ylabel('y (μm)', fontsize=11)
ax3.set_title('Compression -∂v_y/∂y', fontsize=12, fontweight='bold')
plt.colorbar(im3, ax=ax3, label='s⁻¹', shrink=0.8)

plt.suptitle('Cortical Flow: Convergence Creates Compression at Equator',
             fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('results/preview_flow_field.png', dpi=150, bbox_inches='tight')
print("   ✓ Saved: results/preview_flow_field.png")
plt.close()

print("\n" + "=" * 70)
print("All preview images created successfully!")
print("\nGenerated files:")
print("  - results/preview_basic_result.png")
print("  - results/preview_parameters.png")
print("  - results/preview_extensions.png")
print("  - results/preview_flow_field.png")
print("\nThese can be embedded in README.md to showcase the simulations.")
print("=" * 70)
