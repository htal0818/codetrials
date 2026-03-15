"""Quick test of the corrected simulation."""
import numpy as np
import matplotlib.pyplot as plt
from reymann_simulation import ActiveNematicSimulation

print("Testing corrected simulation...")

# Create simulation with parameters that should show clear alignment
sim = ActiveNematicSimulation(
    Lx=100, Ly=100, dx=1.0, dt=0.01,
    flow_alignment=2.0,  # Strong flow-alignment
    turnover_time=20.0,  # Slow turnover
    elastic_constant=5.0,  # Strong elastic coupling
    active_stress_param=1.5  # Active stress generates order from strain
)

# Add small initial perturbation to seed growth
sim.Qxx = 0.05 * np.random.randn(sim.ny, sim.nx)
sim.Qxy = 0.05 * np.random.randn(sim.ny, sim.nx)

# Set strong convergent flow
sim.set_flow_field('contractile_ring', ring_position=0.5,
                   ring_width=10.0, flow_strength=5.0)  # Stronger flow

# Run for shorter time
print("\nRunning 30 second simulation...")
history = sim.run(t_max=30.0, update_interval=1.0)

print(f"\nFinal nematic order: S = {history['nematic_order'][-1]:.3f}")
print(f"Maximum S during simulation: {np.max(history['nematic_order']):.3f}")

# Plot results
fig, axes = plt.subplots(1, 3, figsize=(15, 4))

# Time evolution
axes[0].plot(history['times'], history['nematic_order'], 'b-', linewidth=2)
axes[0].set_xlabel('Time (s)')
axes[0].set_ylabel('Nematic Order S')
axes[0].set_title('Growth of Order')
axes[0].grid(True, alpha=0.3)

# Final order field
S_field = np.sqrt(sim.Qxx**2 + sim.Qxy**2)
im = axes[1].imshow(S_field, extent=[0, sim.Lx, 0, sim.Ly],
                    origin='lower', cmap='viridis')
axes[1].axhline(y=50, color='yellow', linestyle='--', linewidth=2)
axes[1].set_xlabel('x (μm)')
axes[1].set_ylabel('y (μm)')
axes[1].set_title('Final Nematic Order')
plt.colorbar(im, ax=axes[1])

# Spatial profile
S_profile = np.mean(S_field, axis=1)
axes[2].plot(sim.y, S_profile, 'b-', linewidth=2)
axes[2].axvline(x=50, color='r', linestyle='--', linewidth=2)
axes[2].set_xlabel('y position (μm)')
axes[2].set_ylabel('S(y)')
axes[2].set_title('Spatial Profile')
axes[2].grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('test_corrected_simulation.png', dpi=150)
print("\nSaved: test_corrected_simulation.png")
plt.close()

# Check if compression creates alignment
dvx_dx, dvx_dy, dvy_dx, dvy_dy = sim.compute_velocity_gradient()
compression = -dvy_dy

print(f"\nCompression at equator: {compression[sim.ny//2, sim.nx//2]:.3f} s^-1")
print(f"S at equator: {S_profile[sim.ny//2]:.3f}")
print(f"Qxx at equator: {np.mean(sim.Qxx[sim.ny//2-5:sim.ny//2+5, :]):.3f}")

if history['nematic_order'][-1] > 0.1:
    print("\n✓ SUCCESS: Flow-alignment is working!")
else:
    print("\n✗ Issue: Order is still too small")
    print("  Need to adjust parameters or add noise term")
