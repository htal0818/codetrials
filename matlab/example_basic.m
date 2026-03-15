% EXAMPLE_BASIC - Basic example of active nematic simulation
%
% This script demonstrates the basic usage of the ActiveNematicSimulation
% class to simulate actin filament alignment during cytokinesis.
%
% Based on: Reymann et al. eLife 2016;5:e17807

clear; close all; clc;

fprintf('=================================================================\n');
fprintf('Active Nematic Simulation - Basic Example\n');
fprintf('Reymann et al. (2016) Model\n');
fprintf('=================================================================\n\n');

%% 1. Create Simulation

fprintf('Creating simulation...\n');

sim = ActiveNematicSimulation(...
    'Lx', 100, ...                    % 100 μm domain
    'Ly', 100, ...
    'dx', 1.0, ...                    % 1 μm resolution
    'dt', 0.01, ...                   % 0.01 s time step
    'flow_alignment', 1.5, ...        % Flow-alignment parameter λ
    'turnover_time', 10.0, ...        % Actin turnover time τ (s)
    'elastic_constant', 2.0, ...      % Elastic constant K (μm²/s)
    'active_stress_param', 1.0 ...    % Active stress parameter ζ
);

fprintf('  Domain: %.0f × %.0f μm\n', sim.Lx, sim.Ly);
fprintf('  Resolution: %.1f μm\n', sim.dx);
fprintf('  Grid: %d × %d points\n\n', sim.nx, sim.ny);

%% 2. Set Flow Field

fprintf('Setting contractile ring flow field...\n');

sim.setFlowField('contractile_ring', ...
    'ring_position', 0.5, ...         % At center (y = 50 μm)
    'ring_width', 10.0, ...           % 10 μm width
    'flow_strength', 2.0 ...          % 2 μm/s magnitude
);

fprintf('  Flow type: Contractile ring\n');
fprintf('  Ring position: y = %.0f μm\n', 0.5 * sim.Ly);
fprintf('  Ring width: %.0f μm\n', 10.0);
fprintf('  Flow strength: %.1f μm/s\n\n', 2.0);

% Visualize initial flow field
figure('Position', [100, 100, 1200, 400]);

subplot(1, 3, 1);
imagesc([0 sim.Lx], [0 sim.Ly], sim.vy);
set(gca, 'YDir', 'normal');
colormap(gca, 'RdBu');
colorbar;
xlabel('x (\mum)');
ylabel('y (\mum)');
title('Flow v_y (toward equator)');
hold on;
yline(50, 'y--', 'LineWidth', 2);
hold off;

subplot(1, 3, 2);
speed = sqrt(sim.vx.^2 + sim.vy.^2);
imagesc([0 sim.Lx], [0 sim.Ly], speed);
set(gca, 'YDir', 'normal');
colormap(gca, 'hot');
colorbar;
hold on;
subsample = 5;
quiver(sim.X(1:subsample:end, 1:subsample:end), ...
       sim.Y(1:subsample:end, 1:subsample:end), ...
       sim.vx(1:subsample:end, 1:subsample:end), ...
       sim.vy(1:subsample:end, 1:subsample:end), ...
       2, 'k', 'LineWidth', 1);
yline(50, 'y--', 'LineWidth', 2);
hold off;
xlabel('x (\mum)');
ylabel('y (\mum)');
title('Flow Field (vectors)');

% Compute and plot compression
[dvx_dx, dvx_dy, dvy_dx, dvy_dy] = sim.computeVelocityGradient();
compression = -dvy_dy;

subplot(1, 3, 3);
plot(sim.Y(:, 1), mean(compression, 2), 'b-', 'LineWidth', 2);
hold on;
xline(50, 'r--', 'LineWidth', 2, 'DisplayName', 'Equator');
hold off;
xlabel('y position (\mum)');
ylabel('Compression -\partialv_y/\partialy (s^{-1})');
title('Compression Profile');
grid on;
legend('show');

sgtitle('Initial Flow Field Configuration', 'FontSize', 14, 'FontWeight', 'bold');

%% 3. Run Simulation

fprintf('Running simulation for 50 seconds...\n\n');

history = sim.run(50.0, 'update_interval', 1.0, 'verbose', true);

fprintf('\nSimulation complete!\n');
fprintf('  Final nematic order: S = %.3f\n', history.nematic_order(end));
fprintf('  Final average angle: %.1f degrees\n\n', history.alignment_angle(end));

%% 4. Visualize Results

fprintf('Generating visualizations...\n');

% Final state
sim.visualize('show_flow', true, 'show_directors', true);
sgtitle('Final Simulation State', 'FontSize', 14, 'FontWeight', 'bold');

% Time evolution
plotHistory(history);

% Spatial profile
figure('Position', [100, 100, 1200, 500]);

S_field = sqrt(sim.Qxx.^2 + sim.Qxy.^2);
S_profile = mean(S_field, 2);
Qxx_profile = mean(sim.Qxx, 2);
y = linspace(0, sim.Ly, sim.ny);

subplot(1, 2, 1);
imagesc([0 sim.Lx], [0 sim.Ly], S_field);
set(gca, 'YDir', 'normal');
colormap(gca, 'parula');
colorbar;
hold on;
yline(50, 'y--', 'LineWidth', 2);
[x_sub, y_sub, nx, ny_dir, S_sub] = sim.getDirectorField('subsample', 6);
quiver(x_sub, y_sub, nx, ny_dir, 0.5, 'k', 'LineWidth', 1.5);
hold off;
xlabel('x (\mum)');
ylabel('y (\mum)');
title('Final Nematic Order Field');

subplot(1, 2, 2);
yyaxis left;
plot(y, S_profile, 'b-', 'LineWidth', 2.5);
ylabel('Nematic Order S');
hold on;
plot(y, -Qxx_profile, 'g-', 'LineWidth', 2.5);

yyaxis right;
plot(y, mean(compression, 2), 'r--', 'LineWidth', 2);
ylabel('Compression (s^{-1})');
hold off;

xline(50, 'Color', [1 1 0], 'LineWidth', 2.5, 'Alpha', 0.5);
xlabel('y position (\mum)');
title('Spatial Profiles Along AP Axis');
legend('Order S', '-Q_{xx} (y-align)', 'Compression', 'Location', 'best');
grid on;

sgtitle('Alignment Peaks at Compression Zone', 'FontSize', 14, 'FontWeight', 'bold');

%% 5. Key Observations

fprintf('\n=================================================================\n');
fprintf('KEY OBSERVATIONS:\n');
fprintf('=================================================================\n');
fprintf('1. Nematic order grows from S ~ 0 to S ~ %.2f over %.0f seconds\n', ...
        history.nematic_order(end), history.times(end));
fprintf('2. Alignment is strongest at the equator (y = 50 μm)\n');
fprintf('3. Q_xx < 0 indicates y-alignment (perpendicular to flow)\n');
fprintf('4. Peak alignment coincides with peak compression\n');
fprintf('\nThese results match the experimental observations from\n');
fprintf('Reymann et al. (2016) eLife 5:e17807\n');
fprintf('=================================================================\n');
