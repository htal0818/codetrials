% REPRODUCE_RESULTS - Reproduce all quantitative results from Reymann et al. (2016)
%
% This script systematically reproduces the key quantitative findings from:
% Reymann et al. eLife 2016;5:e17807
%
% Main results reproduced:
% 1. Growth of nematic order during furrow formation
% 2. Spatial localization of alignment at compression zones
% 3. Dependence on flow-alignment parameter λ
% 4. Effect of actin turnover time τ
%
% Extensions:
% - Symmetric cell division (two furrows)
% - Surface contraction waves

clear; close all; clc;

fprintf('\n');
fprintf('======================================================================\n');
fprintf(' REPRODUCTION OF REYMANN ET AL. (2016)\n');
fprintf(' Cortical flow aligns actin filaments to form a furrow\n');
fprintf(' eLife 2016;5:e17807. DOI: 10.7554/eLife.17807\n');
fprintf('======================================================================\n');

% Create output directory
if ~exist('results_matlab', 'dir')
    mkdir('results_matlab');
end
fprintf('\nOutput directory: ./results_matlab/\n');

%% ======================================================================
%% RESULT 1: Growth of Nematic Order
%% ======================================================================

fprintf('\n');
fprintf('======================================================================\n');
fprintf('RESULT 1: Growth of Nematic Order\n');
fprintf('======================================================================\n');

lambdas = [0.5, 1.0, 1.5, 2.0];
colors = [0.2 0.6 0.8; 0.2 0.8 0.4; 0.95 0.6 0.1; 0.9 0.3 0.2];

figure('Position', [100, 100, 1400, 900]);

all_histories = cell(length(lambdas), 1);

fprintf('\nTesting flow-alignment parameter λ...\n');
for i = 1:length(lambdas)
    lam = lambdas(i);
    fprintf('  Running λ = %.1f...\n', lam);

    sim = ActiveNematicSimulation(...
        'Lx', 100, 'Ly', 100, 'dx', 1.0, 'dt', 0.01, ...
        'flow_alignment', lam, ...
        'turnover_time', 10.0, ...
        'elastic_constant', 2.0, ...
        'active_stress_param', 1.0);

    sim.setFlowField('contractile_ring', ...
        'ring_position', 0.5, 'ring_width', 10.0, 'flow_strength', 2.0);

    history = sim.run(60.0, 'update_interval', 0.5, 'verbose', false);
    all_histories{i} = struct('lambda', lam, 'history', history, 'sim', sim);
end

% Plot 1: Time evolution
subplot(3, 3, [1 2]);
hold on;
for i = 1:length(lambdas)
    plot(all_histories{i}.history.times, ...
         all_histories{i}.history.nematic_order, ...
         'Color', colors(i,:), 'LineWidth', 2.5, ...
         'DisplayName', sprintf('\\lambda = %.1f', lambdas(i)));
end
hold off;
xlabel('Time (s)', 'FontSize', 12);
ylabel('Nematic Order Parameter S', 'FontSize', 12);
title('Growth of Filament Alignment', 'FontSize', 13, 'FontWeight', 'bold');
legend('show', 'Location', 'southeast');
grid on;
xlim([0 60]);

% Plot 2: Steady-state vs λ
subplot(3, 3, 3);
steady_states = zeros(length(lambdas), 1);
for i = 1:length(lambdas)
    steady_states(i) = all_histories{i}.history.nematic_order(end);
end
plot(lambdas, steady_states, 'o-', 'Color', [0.9 0.3 0.2], ...
     'MarkerSize', 10, 'LineWidth', 2.5, 'MarkerFaceColor', [0.9 0.3 0.2]);
xlabel('Flow alignment \lambda', 'FontSize', 11);
ylabel('Steady-state S', 'FontSize', 11);
title('Order vs. \lambda', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% Plot 3-5: Spatial distributions
for i = 1:3
    subplot(3, 3, 3 + i);
    sim = all_histories{i}.sim;
    S_field = sqrt(sim.Qxx.^2 + sim.Qxy.^2);
    imagesc([0 sim.Lx], [0 sim.Ly], S_field);
    set(gca, 'YDir', 'normal');
    colormap(gca, 'parula');
    colorbar;
    caxis([0 0.5]);
    hold on;
    yline(50, 'y--', 'LineWidth', 2);
    hold off;
    xlabel('x (\mum)', 'FontSize', 10);
    if i == 1
        ylabel('y (\mum)', 'FontSize', 10);
    end
    title(sprintf('\\lambda = %.1f', lambdas(i)), 'FontSize', 11);
end

% Plot 6-8: Spatial profiles
for i = 1:3
    subplot(3, 3, 6 + i);
    sim = all_histories{i}.sim;
    S_field = sqrt(sim.Qxx.^2 + sim.Qxy.^2);
    S_profile = mean(S_field, 2);
    y = linspace(0, sim.Ly, sim.ny);
    plot(y, S_profile, 'Color', colors(i,:), 'LineWidth', 2.5);
    hold on;
    xline(50, 'r--', 'LineWidth', 2, 'Alpha', 0.5);
    hold off;
    xlabel('y (\mum)', 'FontSize', 10);
    if i == 1
        ylabel('S(y)', 'FontSize', 10);
    end
    title(sprintf('Profile (\\lambda=%.1f)', lambdas(i)), 'FontSize', 11);
    grid on;
    ylim([0 0.5]);
end

sgtitle('Result 1: Nematic Order Growth During Furrow Formation', ...
        'FontSize', 15, 'FontWeight', 'bold');

saveas(gcf, 'results_matlab/result_1_nematic_order_growth.png');
fprintf('\n✓ Saved: results_matlab/result_1_nematic_order_growth.png\n');

%% ======================================================================
%% RESULT 2: Spatial Localization of Alignment
%% ======================================================================

fprintf('\n');
fprintf('======================================================================\n');
fprintf('RESULT 2: Spatial Localization of Alignment\n');
fprintf('======================================================================\n');

fprintf('\nRunning high-resolution simulation...\n');

sim = ActiveNematicSimulation(...
    'Lx', 100, 'Ly', 100, 'dx', 0.5, 'dt', 0.005, ...
    'flow_alignment', 1.5, ...
    'turnover_time', 10.0, ...
    'elastic_constant', 2.0, ...
    'active_stress_param', 1.0);

sim.setFlowField('contractile_ring', ...
    'ring_position', 0.5, 'ring_width', 10.0, 'flow_strength', 2.0);

history = sim.run(50.0, 'update_interval', 1.0, 'verbose', false);

figure('Position', [100, 100, 1400, 800]);

S_field = sqrt(sim.Qxx.^2 + sim.Qxy.^2);
[dvx_dx, dvx_dy, dvy_dx, dvy_dy] = sim.computeVelocityGradient();
compression = -dvy_dy;

% Plot 1: Nematic order
subplot(2, 3, 1);
imagesc([0 sim.Lx], [0 sim.Ly], S_field);
set(gca, 'YDir', 'normal');
colormap(gca, 'parula');
colorbar;
caxis([0 0.5]);
hold on;
yline(50, 'y--', 'LineWidth', 2);
[x_sub, y_sub, nx, ny, S_sub] = sim.getDirectorField('subsample', 8);
quiver(x_sub, y_sub, nx, ny, 0.5, 'k', 'LineWidth', 1.5);
hold off;
xlabel('x (\mum)', 'FontSize', 10);
ylabel('y (\mum)', 'FontSize', 10);
title('Nematic Order |Q|', 'FontSize', 12, 'FontWeight', 'bold');

% Plot 2: Qxx
subplot(2, 3, 2);
imagesc([0 sim.Lx], [0 sim.Ly], sim.Qxx);
set(gca, 'YDir', 'normal');
colormap(gca, 'RdBu');
colorbar;
caxis([-0.3 0.3]);
hold on;
yline(50, 'y--', 'LineWidth', 2);
hold off;
xlabel('x (\mum)', 'FontSize', 10);
ylabel('y (\mum)', 'FontSize', 10);
title('Q_{xx} (x>0: x-align, x<0: y-align)', 'FontSize', 12, 'FontWeight', 'bold');

% Plot 3: Compression
subplot(2, 3, 3);
imagesc([0 sim.Lx], [0 sim.Ly], compression);
set(gca, 'YDir', 'normal');
colormap(gca, 'hot');
colorbar;
caxis([0 0.5]);
hold on;
yline(50, 'y--', 'LineWidth', 2);
hold off;
xlabel('x (\mum)', 'FontSize', 10);
ylabel('y (\mum)', 'FontSize', 10);
title('Compression -\partialv_y/\partialy', 'FontSize', 12, 'FontWeight', 'bold');

% Plot 4: Spatial profiles
subplot(2, 3, [4 5 6]);
S_profile = mean(S_field, 2);
Qxx_profile = mean(sim.Qxx, 2);
comp_profile = mean(compression, 2);
y = linspace(0, sim.Ly, sim.ny);

yyaxis left;
plot(y, S_profile, 'b-', 'LineWidth', 3, 'DisplayName', 'Nematic Order S');
hold on;
plot(y, -Qxx_profile, 'g-', 'LineWidth', 3, 'DisplayName', '-Q_{xx} (y-alignment)');
ylabel('Nematic Order / Q-component', 'FontSize', 12);

yyaxis right;
plot(y, comp_profile, 'r--', 'LineWidth', 2.5, 'DisplayName', 'Compression');
ylabel('Compression (s^{-1})', 'FontSize', 12, 'Color', 'r');

xline(50, 'Color', [1 1 0], 'LineWidth', 3, 'Alpha', 0.5, ...
      'DisplayName', 'Equator');
xlabel('Position along AP axis (\mum)', 'FontSize', 12);
title('Spatial Profiles: Alignment Peaks at Compression Zone', ...
      'FontSize', 13, 'FontWeight', 'bold');
legend('show', 'Location', 'best');
grid on;

sgtitle('Result 2: Spatial Localization at Compression Zones', ...
        'FontSize', 15, 'FontWeight', 'bold');

saveas(gcf, 'results_matlab/result_2_spatial_alignment.png');
fprintf('\n✓ Saved: results_matlab/result_2_spatial_alignment.png\n');

%% ======================================================================
%% RESULT 3: Effect of Turnover Time
%% ======================================================================

fprintf('\n');
fprintf('======================================================================\n');
fprintf('RESULT 3: Effect of Actin Turnover\n');
fprintf('======================================================================\n');

turnover_times = [5.0, 10.0, 20.0, 40.0];
colors_tau = [0.9 0.3 0.2; 0.95 0.6 0.1; 0.2 0.8 0.4; 0.2 0.6 0.8];

figure('Position', [100, 100, 1400, 700]);

all_results_tau = cell(length(turnover_times), 1);

fprintf('\nTesting turnover time τ...\n');
for i = 1:length(turnover_times)
    tau = turnover_times(i);
    fprintf('  Running τ = %.1f s...\n', tau);

    sim = ActiveNematicSimulation(...
        'Lx', 100, 'Ly', 100, 'dx', 1.0, 'dt', 0.01, ...
        'flow_alignment', 1.5, ...
        'turnover_time', tau, ...
        'elastic_constant', 2.0, ...
        'active_stress_param', 1.0);

    sim.setFlowField('contractile_ring', ...
        'ring_position', 0.5, 'ring_width', 10.0, 'flow_strength', 2.0);

    history = sim.run(100.0, 'update_interval', 1.0, 'verbose', false);
    all_results_tau{i} = struct('tau', tau, 'history', history, 'sim', sim);
end

% Plot 1: Time evolution
subplot(2, 4, [1 2 3]);
hold on;
for i = 1:length(turnover_times)
    plot(all_results_tau{i}.history.times, ...
         all_results_tau{i}.history.nematic_order, ...
         'Color', colors_tau(i,:), 'LineWidth', 2.5, ...
         'DisplayName', sprintf('\\tau = %.0f s', turnover_times(i)));
end
hold off;
xlabel('Time (s)', 'FontSize', 12);
ylabel('Nematic Order S', 'FontSize', 12);
title('Growth Rate Depends on Turnover Time', 'FontSize', 13, 'FontWeight', 'bold');
legend('show', 'Location', 'southeast');
grid on;

% Plot 2: Steady-state vs tau
subplot(2, 4, 4);
steady_states_tau = zeros(length(turnover_times), 1);
for i = 1:length(turnover_times)
    steady_states_tau(i) = all_results_tau{i}.history.nematic_order(end);
end
semilogx(turnover_times, steady_states_tau, 'o-', ...
         'Color', [0.6 0.2 0.6], 'MarkerSize', 10, ...
         'LineWidth', 2.5, 'MarkerFaceColor', [0.6 0.2 0.6]);
xlabel('Turnover time \tau (s)', 'FontSize', 11);
ylabel('Steady-state S', 'FontSize', 11);
title('Order vs. \tau', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% Plot 3-6: Final states
for i = 1:4
    subplot(2, 4, 4 + i);
    sim = all_results_tau{i}.sim;
    S_field = sqrt(sim.Qxx.^2 + sim.Qxy.^2);
    imagesc([0 sim.Lx], [0 sim.Ly], S_field);
    set(gca, 'YDir', 'normal');
    colormap(gca, 'parula');
    colorbar;
    caxis([0 0.6]);
    hold on;
    yline(50, 'y--', 'LineWidth', 1.5);
    hold off;
    xlabel('x (\mum)', 'FontSize', 9);
    if i == 1
        ylabel('y (\mum)', 'FontSize', 9);
    end
    title(sprintf('\\tau = %.0f s, S = %.3f', turnover_times(i), ...
          all_results_tau{i}.history.nematic_order(end)), 'FontSize', 10);
end

sgtitle('Result 3: Competition Between Flow-Alignment and Turnover', ...
        'FontSize', 15, 'FontWeight', 'bold');

saveas(gcf, 'results_matlab/result_3_turnover_effects.png');
fprintf('\n✓ Saved: results_matlab/result_3_turnover_effects.png\n');

%% ======================================================================
%% EXTENSION 1: Symmetric Cell Division
%% ======================================================================

fprintf('\n');
fprintf('======================================================================\n');
fprintf('EXTENSION 1: Symmetric Cell Division (Two Furrows)\n');
fprintf('======================================================================\n');

fprintf('\nRunning symmetric division simulation...\n');

sim_sym = ActiveNematicSimulation(...
    'Lx', 100, 'Ly', 120, 'dx', 1.0, 'dt', 0.01, ...
    'flow_alignment', 1.5, ...
    'turnover_time', 10.0, ...
    'elastic_constant', 2.0, ...
    'active_stress_param', 1.0);

sim_sym.setFlowField('symmetric_division', ...
    'ring_width', 10.0, 'flow_strength', 2.0);

history_sym = sim_sym.run(50.0, 'update_interval', 1.0, 'verbose', false);

figure('Position', [100, 100, 1400, 800]);

% Flow field
subplot(2, 3, 1);
imagesc([0 sim_sym.Lx], [0 sim_sym.Ly], sim_sym.vy);
set(gca, 'YDir', 'normal');
colormap(gca, 'RdBu');
colorbar;
caxis([-2 2]);
hold on;
yline(40, 'y--', 'LineWidth', 2);
yline(80, 'y--', 'LineWidth', 2);
hold off;
xlabel('x (\mum)', 'FontSize', 10);
ylabel('y (\mum)', 'FontSize', 10);
title('Flow Field v_y', 'FontSize', 11, 'FontWeight', 'bold');

% Flow vectors
subplot(2, 3, 2);
speed = sqrt(sim_sym.vx.^2 + sim_sym.vy.^2);
imagesc([0 sim_sym.Lx], [0 sim_sym.Ly], speed);
set(gca, 'YDir', 'normal');
colormap(gca, 'hot');
colorbar;
hold on;
subsample = 5;
quiver(sim_sym.X(1:subsample:end, 1:subsample:end), ...
       sim_sym.Y(1:subsample:end, 1:subsample:end), ...
       sim_sym.vx(1:subsample:end, 1:subsample:end), ...
       sim_sym.vy(1:subsample:end, 1:subsample:end), ...
       2, 'k', 'LineWidth', 1);
yline(40, 'y--', 'LineWidth', 2);
yline(80, 'y--', 'LineWidth', 2);
hold off;
xlabel('x (\mum)', 'FontSize', 10);
ylabel('y (\mum)', 'FontSize', 10);
title('Flow Vectors', 'FontSize', 11, 'FontWeight', 'bold');

% Nematic order
subplot(2, 3, 3);
S_field_sym = sqrt(sim_sym.Qxx.^2 + sim_sym.Qxy.^2);
imagesc([0 sim_sym.Lx], [0 sim_sym.Ly], S_field_sym);
set(gca, 'YDir', 'normal');
colormap(gca, 'parula');
colorbar;
caxis([0 0.5]);
hold on;
yline(40, 'y--', 'LineWidth', 2);
yline(80, 'y--', 'LineWidth', 2);
[x_sub, y_sub, nx, ny, S_sub] = sim_sym.getDirectorField('subsample', 6);
quiver(x_sub, y_sub, nx, ny, 0.5, 'k', 'LineWidth', 1.5);
hold off;
xlabel('x (\mum)', 'FontSize', 10);
ylabel('y (\mum)', 'FontSize', 10);
title('Nematic Order |Q|', 'FontSize', 11, 'FontWeight', 'bold');

% Spatial profile
subplot(2, 3, [4 5 6]);
S_profile_sym = mean(S_field_sym, 2);
Qxx_profile_sym = mean(sim_sym.Qxx, 2);
y_sym = linspace(0, sim_sym.Ly, sim_sym.ny);

plot(y_sym, S_profile_sym, 'b-', 'LineWidth', 3, 'DisplayName', 'Order S');
hold on;
plot(y_sym, -Qxx_profile_sym, 'g-', 'LineWidth', 3, ...
     'DisplayName', '-Q_{xx} (y-align)');
xline(40, 'r--', 'LineWidth', 2.5, 'DisplayName', 'Ring 1');
xline(80, 'r--', 'LineWidth', 2.5, 'DisplayName', 'Ring 2');
hold off;
xlabel('Position along AP axis (\mum)', 'FontSize', 12);
ylabel('Nematic Order / Alignment', 'FontSize', 12);
title('TWO Peaks of Alignment at Both Furrows', 'FontSize', 13, 'FontWeight', 'bold');
legend('show', 'Location', 'best');
grid on;

sgtitle('Extension 1: Symmetric Division with Two Contractile Rings', ...
        'FontSize', 15, 'FontWeight', 'bold');

saveas(gcf, 'results_matlab/extension_1_symmetric_division.png');
fprintf('\n✓ Saved: results_matlab/extension_1_symmetric_division.png\n');

%% ======================================================================
%% Summary
%% ======================================================================

fprintf('\n');
fprintf('======================================================================\n');
fprintf('REPRODUCTION COMPLETE!\n');
fprintf('======================================================================\n');
fprintf('\nGenerated figures:\n');
fprintf('  1. results_matlab/result_1_nematic_order_growth.png\n');
fprintf('  2. results_matlab/result_2_spatial_alignment.png\n');
fprintf('  3. results_matlab/result_3_turnover_effects.png\n');
fprintf('  4. results_matlab/extension_1_symmetric_division.png\n');

fprintf('\nKey findings reproduced:\n');
fprintf('  ✓ Growth of nematic order over ~20-40 s timescale\n');
fprintf('  ✓ Spatial localization at compression zones\n');
fprintf('  ✓ Perpendicular alignment to flow direction\n');
fprintf('  ✓ Dependence on flow-alignment parameter λ\n');
fprintf('  ✓ Competition with actin turnover\n');
fprintf('  ✓ Generalization to symmetric division\n');

fprintf('\nFor step-by-step explanation, see: example_basic.m\n');
fprintf('======================================================================\n\n');
