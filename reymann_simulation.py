"""
Active Nematic Model for Cortical Flow and Actin Alignment
Reproduction of Reymann et al. eLife 2016;5:e17807

This module implements the active nematic gel theory to simulate how cortical flow
aligns actin filaments during cytokinesis in C. elegans embryos.

Physical Model:
--------------
The actin cortex is modeled as a 2D active nematic gel on the embryo surface.
The nematic order parameter Q is a symmetric, traceless 2x2 tensor that describes
the local orientation and degree of alignment of actin filaments.

Q = [[Qxx, Qxy],
     [Qxy, -Qxx]]  (traceless: Qyy = -Qxx)

The evolution equation for Q includes:
1. Advection by cortical flow
2. Flow-alignment coupling (filaments align with flow)
3. Relaxation to isotropic state (turnover)
4. Elastic interactions (spatial alignment)

Governing Equation (simplified 2D version):
dQ/dt = -v·∇Q                           (advection)
        + λ(∇v + ∇v^T)·Q                (flow-alignment, compression)
        - Q/τ                            (relaxation/turnover)
        + K∇²Q                           (elastic diffusion)

where:
- v: cortical flow velocity field
- λ: flow alignment parameter (dimensionless)
- τ: relaxation time (turnover time)
- K: elastic constant (spatial alignment)
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import patches
from scipy.ndimage import laplace
import warnings
warnings.filterwarnings('ignore')


class ActiveNematicSimulation:
    """
    Simulates active nematic dynamics on a 2D cortical surface.

    The Q-tensor field evolves according to active nematic hydrodynamics
    with cortical flow, capturing the physics of actin filament alignment.
    """

    def __init__(self, Lx=100, Ly=100, dx=1.0, dt=0.01,
                 flow_alignment=1.0, turnover_time=10.0,
                 elastic_constant=1.0, active_stress_param=0.0):
        """
        Initialize the simulation.

        Parameters
        ----------
        Lx, Ly : float
            Domain size in x and y directions (microns)
        dx : float
            Spatial resolution (microns)
        dt : float
            Time step (seconds)
        flow_alignment : float
            Flow alignment parameter λ (dimensionless)
            λ > 0: flow-aligning (filaments align with compression)
            λ < 0: flow-tumbling
        turnover_time : float
            Relaxation time τ for actin turnover (seconds)
        elastic_constant : float
            Elastic constant K for spatial alignment (μm²/s)
        active_stress_param : float
            Active stress parameter ζ - generates order from strain
            (dimensionless, typically 0-2)
        """
        # Grid parameters
        self.Lx = Lx
        self.Ly = Ly
        self.dx = dx
        self.dt = dt

        # Number of grid points
        self.nx = int(Lx / dx)
        self.ny = int(Ly / dx)

        # Physical parameters
        self.lambda_flow = flow_alignment
        self.tau = turnover_time
        self.K = elastic_constant
        self.zeta = active_stress_param  # Active stress parameter

        # Create coordinate grids
        self.x = np.linspace(0, Lx, self.nx)
        self.y = np.linspace(0, Ly, self.ny)
        self.X, self.Y = np.meshgrid(self.x, self.y)

        # Initialize Q-tensor field (Qxx, Qxy components)
        # Start with small random perturbations around isotropic state
        self.Qxx = 0.02 * np.random.randn(self.ny, self.nx)
        self.Qxy = 0.02 * np.random.randn(self.ny, self.nx)

        # Velocity field (will be set by flow field)
        self.vx = np.zeros((self.ny, self.nx))
        self.vy = np.zeros((self.ny, self.nx))

        # Time
        self.t = 0.0

    def set_flow_field(self, flow_type='contractile_ring',
                       ring_position=0.5, ring_width=10.0,
                       flow_strength=1.0):
        """
        Set the cortical flow field.

        Parameters
        ----------
        flow_type : str
            'contractile_ring': convergent flow toward equator (cytokinesis)
            'uniform_compression': uniform compression in one direction
            'vortex': rotational flow (for testing)
        ring_position : float
            Relative position of contractile ring (0-1, fraction of Ly)
        ring_width : float
            Width of the contractile ring (microns)
        flow_strength : float
            Magnitude of flow velocity (μm/s)
        """
        if flow_type == 'contractile_ring':
            # Convergent flow toward the equatorial plane
            # Models RhoA-dependent myosin accumulation at the equator
            y_ring = ring_position * self.Ly

            # Flow in y-direction: convergent toward ring
            dist_from_ring = self.Y - y_ring
            flow_profile = np.tanh(dist_from_ring / ring_width)

            self.vx = np.zeros_like(self.X)
            self.vy = -flow_strength * flow_profile

        elif flow_type == 'uniform_compression':
            # Uniform compression in y-direction
            self.vx = np.zeros_like(self.X)
            self.vy = -flow_strength * (self.Y - self.Ly/2) / (self.Ly/2)

        elif flow_type == 'vortex':
            # Rotational flow for testing
            cx, cy = self.Lx/2, self.Ly/2
            self.vx = -flow_strength * (self.Y - cy)
            self.vy = flow_strength * (self.X - cx)

        elif flow_type == 'symmetric_division':
            # Two contractile rings for symmetric division
            y1 = 0.33 * self.Ly
            y2 = 0.67 * self.Ly

            dist1 = self.Y - y1
            dist2 = self.Y - y2

            flow1 = np.tanh(dist1 / ring_width)
            flow2 = np.tanh(dist2 / ring_width)

            self.vx = np.zeros_like(self.X)
            self.vy = -flow_strength * (flow1 + flow2) / 2

        elif flow_type == 'contraction_wave':
            # Traveling contraction wave
            # Wave propagates in x-direction
            k_wave = 2 * np.pi / (self.Lx / 2)  # wavelength = Lx/2
            omega = flow_strength  # wave speed

            phase = k_wave * self.X - omega * self.t
            wave = np.sin(phase)

            self.vx = -flow_strength * np.cos(phase) * 0.5
            self.vy = -flow_strength * wave * (self.Y - self.Ly/2) / (self.Ly/2)

    def compute_velocity_gradient(self):
        """
        Compute velocity gradient tensor components needed for Q evolution.

        Returns
        -------
        dvx_dx, dvx_dy, dvy_dx, dvy_dy : arrays
            Components of velocity gradient tensor
        """
        # Use central differences for interior points
        dvx_dx = np.gradient(self.vx, self.dx, axis=1)
        dvx_dy = np.gradient(self.vx, self.dx, axis=0)
        dvy_dx = np.gradient(self.vy, self.dx, axis=1)
        dvy_dy = np.gradient(self.vy, self.dx, axis=0)

        return dvx_dx, dvx_dy, dvy_dx, dvy_dy

    def compute_advection(self):
        """
        Compute advection term: -v·∇Q

        Returns
        -------
        adv_Qxx, adv_Qxy : arrays
            Advection contributions to Qxx and Qxy
        """
        # Compute gradients of Q
        dQxx_dx = np.gradient(self.Qxx, self.dx, axis=1)
        dQxx_dy = np.gradient(self.Qxx, self.dx, axis=0)
        dQxy_dx = np.gradient(self.Qxy, self.dx, axis=1)
        dQxy_dy = np.gradient(self.Qxy, self.dx, axis=0)

        # Advection: -v·∇Q
        adv_Qxx = -(self.vx * dQxx_dx + self.vy * dQxx_dy)
        adv_Qxy = -(self.vx * dQxy_dx + self.vy * dQxy_dy)

        return adv_Qxx, adv_Qxy

    def compute_flow_alignment(self):
        """
        Compute flow-alignment term: λ * (strain_rate · Q + Q · strain_rate)

        This term couples the nematic order to the flow field, causing
        filaments to align with the direction of compression.

        For compressive flow (dvy/dy < 0), this creates Qxx < 0 (y-aligned order).

        Returns
        -------
        align_Qxx, align_Qxy : arrays
            Flow-alignment contributions to Qxx and Qxy
        """
        # Velocity gradient components
        dvx_dx, dvx_dy, dvy_dx, dvy_dy = self.compute_velocity_gradient()

        # Symmetric strain rate tensor: E = (∇v + ∇v^T) / 2
        Exx = dvx_dx
        Eyy = dvy_dy
        Exy = 0.5 * (dvx_dy + dvy_dx)

        # For 2D traceless tensor Q = [[Qxx, Qxy], [Qxy, -Qxx]]
        # The flow-alignment term is: λ * (E·Q + Q·E - Tr(E·Q)·I)

        # E·Q (matrix multiplication)
        # [[Exx, Exy],    [[Qxx,  Qxy],     [[Exx*Qxx + Exy*Qxy,  Exx*Qxy + Exy*(-Qxx)],
        #  [Exy, Eyy]]  ·  [Qxy, -Qxx]]  =   [Exy*Qxx + Eyy*Qxy,  Exy*Qxy + Eyy*(-Qxx)]]

        EQ_11 = Exx * self.Qxx + Exy * self.Qxy
        EQ_12 = Exx * self.Qxy - Exy * self.Qxx
        EQ_22 = Exy * self.Qxy - Eyy * self.Qxx

        # Q·E (matrix multiplication)
        QE_11 = self.Qxx * Exx + self.Qxy * Exy
        QE_12 = self.Qxx * Exy + self.Qxy * Eyy
        QE_22 = self.Qxy * Exy - self.Qxx * Eyy

        # Symmetric product
        sym_11 = EQ_11 + QE_11
        sym_12 = EQ_12 + QE_12
        sym_22 = EQ_22 + QE_22

        # Trace of symmetric product
        trace = sym_11 + sym_22

        # Subtract trace/2 from diagonal to make traceless
        align_Qxx = self.lambda_flow * (sym_11 - trace/2)
        align_Qxy = self.lambda_flow * sym_12

        return align_Qxx, align_Qxy

    def compute_relaxation(self):
        """
        Compute relaxation term: -Q/τ

        This represents actin turnover, driving the system toward
        an isotropic state.

        Returns
        -------
        relax_Qxx, relax_Qxy : arrays
            Relaxation contributions to Qxx and Qxy
        """
        relax_Qxx = -self.Qxx / self.tau
        relax_Qxy = -self.Qxy / self.tau

        return relax_Qxx, relax_Qxy

    def compute_elastic(self):
        """
        Compute elastic term: K∇²Q

        This represents the tendency of filaments to align with neighbors,
        smoothing out spatial variations in orientation.

        Returns
        -------
        elastic_Qxx, elastic_Qxy : arrays
            Elastic contributions to Qxx and Qxy
        """
        # Laplacian (∇²) of Q components
        lap_Qxx = laplace(self.Qxx) / (self.dx**2)
        lap_Qxy = laplace(self.Qxy) / (self.dx**2)

        elastic_Qxx = self.K * lap_Qxx
        elastic_Qxy = self.K * lap_Qxy

        return elastic_Qxx, elastic_Qxy

    def compute_active_stress(self):
        """
        Compute active stress term: ζ * E (generates order from strain)

        In active materials, stress can generate nematic order.
        This term makes the strain rate a "source" of alignment.

        Returns
        -------
        active_Qxx, active_Qxy : arrays
            Active stress contributions to Qxx and Qxy
        """
        if self.zeta == 0:
            return np.zeros_like(self.Qxx), np.zeros_like(self.Qxy)

        # Velocity gradient components
        dvx_dx, dvx_dy, dvy_dx, dvy_dy = self.compute_velocity_gradient()

        # Symmetric strain rate tensor
        Exx = dvx_dx
        Eyy = dvy_dy
        Exy = 0.5 * (dvx_dy + dvy_dx)

        # Make traceless (convert strain to deviatoric part)
        trace = Exx + Eyy
        Exx_dev = Exx - trace/2
        Eyy_dev = Eyy - trace/2  # = -Exx_dev for 2D

        # Active stress generates Q proportional to deviatoric strain
        active_Qxx = self.zeta * Exx_dev
        active_Qxy = self.zeta * Exy

        return active_Qxx, active_Qxy

    def step(self):
        """
        Advance the simulation by one time step using forward Euler method.
        """
        # Compute all terms in the evolution equation
        adv_Qxx, adv_Qxy = self.compute_advection()
        align_Qxx, align_Qxy = self.compute_flow_alignment()
        relax_Qxx, relax_Qxy = self.compute_relaxation()
        elastic_Qxx, elastic_Qxy = self.compute_elastic()
        active_Qxx, active_Qxy = self.compute_active_stress()

        # Total rate of change
        dQxx_dt = adv_Qxx + align_Qxx + relax_Qxx + elastic_Qxx + active_Qxx
        dQxy_dt = adv_Qxy + align_Qxy + relax_Qxy + elastic_Qxy + active_Qxy

        # Forward Euler update
        self.Qxx += self.dt * dQxx_dt
        self.Qxy += self.dt * dQxy_dt

        # Update time
        self.t += self.dt

    def run(self, t_max, update_interval=1.0):
        """
        Run the simulation for a given time.

        Parameters
        ----------
        t_max : float
            Total simulation time
        update_interval : float
            Time interval for progress updates

        Returns
        -------
        history : dict
            Dictionary containing time series of relevant quantities
        """
        n_steps = int(t_max / self.dt)

        # Storage for history
        times = []
        nematic_order = []
        alignment_angle = []

        print(f"Running simulation for {t_max} seconds ({n_steps} steps)...")

        for i in range(n_steps):
            self.step()

            if i % int(update_interval / self.dt) == 0:
                times.append(self.t)

                # Compute scalar nematic order parameter
                S = self.get_nematic_order_parameter()
                nematic_order.append(S)

                # Compute average alignment angle
                theta = self.get_average_angle()
                alignment_angle.append(theta)

                if i % int(10 * update_interval / self.dt) == 0:
                    print(f"  t = {self.t:.1f} s, S = {S:.3f}")

        history = {
            'times': np.array(times),
            'nematic_order': np.array(nematic_order),
            'alignment_angle': np.array(alignment_angle)
        }

        return history

    def get_nematic_order_parameter(self):
        """
        Compute the scalar nematic order parameter S.

        S = <|Q|> = <sqrt(Qxx² + Qxy²)>

        S = 0: isotropic (no alignment)
        S = 1: perfect alignment
        """
        Q_magnitude = np.sqrt(self.Qxx**2 + self.Qxy**2)
        S = np.mean(Q_magnitude)
        return S

    def get_average_angle(self):
        """
        Compute the average orientation angle of the nematic field.

        The director angle θ is given by:
        tan(2θ) = Qxy / Qxx
        """
        theta = 0.5 * np.arctan2(self.Qxy, self.Qxx)
        # Use circular mean for angles
        theta_avg = np.arctan2(np.mean(np.sin(2*theta)), np.mean(np.cos(2*theta))) / 2
        return np.degrees(theta_avg)

    def get_director_field(self, subsample=5):
        """
        Get the nematic director field for visualization.

        Parameters
        ----------
        subsample : int
            Subsample factor for visualization (plot every Nth point)

        Returns
        -------
        x_sub, y_sub : arrays
            Subsampled coordinate grids
        nx, ny : arrays
            Director components (unit vectors)
        S : array
            Local nematic order magnitude
        """
        # Subsample for cleaner visualization
        x_sub = self.X[::subsample, ::subsample]
        y_sub = self.Y[::subsample, ::subsample]
        Qxx_sub = self.Qxx[::subsample, ::subsample]
        Qxy_sub = self.Qxy[::subsample, ::subsample]

        # Compute director angle and magnitude
        theta = 0.5 * np.arctan2(Qxy_sub, Qxx_sub)
        S = np.sqrt(Qxx_sub**2 + Qxy_sub**2)

        # Director components (unit vector)
        nx = np.cos(theta)
        ny = np.sin(theta)

        return x_sub, y_sub, nx, ny, S


def plot_simulation_state(sim, fig=None, show_flow=True, show_directors=True):
    """
    Visualize the current state of the simulation.

    Parameters
    ----------
    sim : ActiveNematicSimulation
        Simulation instance
    fig : matplotlib.figure.Figure, optional
        Figure to plot on (creates new if None)
    show_flow : bool
        Whether to show flow field
    show_directors : bool
        Whether to show nematic directors
    """
    if fig is None:
        fig = plt.figure(figsize=(15, 5))
    else:
        fig.clear()

    # 1. Nematic order magnitude
    ax1 = fig.add_subplot(131)
    S_field = np.sqrt(sim.Qxx**2 + sim.Qxy**2)
    im1 = ax1.imshow(S_field, extent=[0, sim.Lx, 0, sim.Ly],
                     origin='lower', cmap='viridis', vmin=0, vmax=0.5)
    ax1.set_xlabel('x (μm)')
    ax1.set_ylabel('y (μm)')
    ax1.set_title(f'Nematic Order |Q| at t={sim.t:.1f}s')
    plt.colorbar(im1, ax=ax1, label='|Q|')

    if show_directors:
        x_sub, y_sub, nx, ny, S_sub = sim.get_director_field(subsample=5)
        # Scale directors by local order
        ax1.quiver(x_sub, y_sub, nx, ny, S_sub,
                  scale=20, cmap='plasma', alpha=0.7, width=0.003)

    # 2. Qxx component (alignment in x vs y)
    ax2 = fig.add_subplot(132)
    im2 = ax2.imshow(sim.Qxx, extent=[0, sim.Lx, 0, sim.Ly],
                     origin='lower', cmap='RdBu_r', vmin=-0.3, vmax=0.3)
    ax2.set_xlabel('x (μm)')
    ax2.set_ylabel('y (μm)')
    ax2.set_title('Qxx (x-alignment)')
    plt.colorbar(im2, ax=ax2, label='Qxx')

    # 3. Flow field
    ax3 = fig.add_subplot(133)
    if show_flow:
        speed = np.sqrt(sim.vx**2 + sim.vy**2)
        im3 = ax3.imshow(speed, extent=[0, sim.Lx, 0, sim.Ly],
                        origin='lower', cmap='Reds', alpha=0.5)

        # Subsample flow vectors
        subsample = 5
        x_sub = sim.X[::subsample, ::subsample]
        y_sub = sim.Y[::subsample, ::subsample]
        vx_sub = sim.vx[::subsample, ::subsample]
        vy_sub = sim.vy[::subsample, ::subsample]

        ax3.quiver(x_sub, y_sub, vx_sub, vy_sub, scale=50, width=0.003, color='black')
        ax3.set_title('Cortical Flow Field')
        plt.colorbar(im3, ax=ax3, label='Speed (μm/s)')
    else:
        ax3.imshow(sim.Qxy, extent=[0, sim.Lx, 0, sim.Ly],
                  origin='lower', cmap='RdBu_r')
        ax3.set_title('Qxy (diagonal alignment)')

    ax3.set_xlabel('x (μm)')
    ax3.set_ylabel('y (μm)')

    fig.tight_layout()
    return fig


def plot_history(history, fig=None):
    """
    Plot time evolution of nematic order parameters.

    Parameters
    ----------
    history : dict
        History dictionary from simulation.run()
    fig : matplotlib.figure.Figure, optional
        Figure to plot on
    """
    if fig is None:
        fig = plt.figure(figsize=(12, 4))

    ax1 = fig.add_subplot(121)
    ax1.plot(history['times'], history['nematic_order'], 'b-', linewidth=2)
    ax1.set_xlabel('Time (s)')
    ax1.set_ylabel('Nematic Order S')
    ax1.set_title('Growth of Nematic Order')
    ax1.grid(True, alpha=0.3)

    ax2 = fig.add_subplot(122)
    ax2.plot(history['times'], history['alignment_angle'], 'r-', linewidth=2)
    ax2.set_xlabel('Time (s)')
    ax2.set_ylabel('Average Angle (degrees)')
    ax2.set_title('Average Director Orientation')
    ax2.grid(True, alpha=0.3)

    fig.tight_layout()
    return fig


if __name__ == "__main__":
    # Example usage
    print("Active Nematic Simulation - Reymann et al. 2016 Model")
    print("=" * 60)

    # Create simulation
    sim = ActiveNematicSimulation(
        Lx=100, Ly=100, dx=1.0, dt=0.01,
        flow_alignment=1.5,
        turnover_time=10.0,
        elastic_constant=2.0
    )

    # Set contractile ring flow
    sim.set_flow_field('contractile_ring', ring_position=0.5,
                       ring_width=10.0, flow_strength=2.0)

    # Run simulation
    history = sim.run(t_max=50.0, update_interval=1.0)

    # Visualize
    fig1 = plot_simulation_state(sim)
    plt.savefig('simulation_final_state.png', dpi=150, bbox_inches='tight')
    print("\nSaved final state to simulation_final_state.png")

    fig2 = plot_history(history)
    plt.savefig('simulation_history.png', dpi=150, bbox_inches='tight')
    print("Saved time evolution to simulation_history.png")

    plt.show()
