classdef ActiveNematicSimulation < handle
    % ACTIVENEMATICSIMULATION Simulates active nematic dynamics on 2D cortical surface
    %
    % This class implements the Q-tensor evolution for active nematic gel theory
    % to model how cortical flow aligns actin filaments during cytokinesis.
    %
    % Based on: Reymann et al. eLife 2016;5:e17807
    %
    % Usage:
    %   sim = ActiveNematicSimulation('Lx', 100, 'Ly', 100, ...
    %                                 'flow_alignment', 1.5, ...
    %                                 'turnover_time', 10.0);
    %   sim.setFlowField('contractile_ring');
    %   history = sim.run(50.0);
    %   sim.visualize();

    properties
        % Domain parameters
        Lx          % Domain size in x (μm)
        Ly          % Domain size in y (μm)
        dx          % Spatial resolution (μm)
        dt          % Time step (s)
        nx          % Number of grid points in x
        ny          % Number of grid points in y

        % Physical parameters
        lambda_flow      % Flow alignment parameter λ
        tau              % Turnover time τ (s)
        K                % Elastic constant (μm²/s)
        zeta             % Active stress parameter ζ

        % Fields
        Qxx         % Q-tensor xx component
        Qxy         % Q-tensor xy component
        vx          % Flow velocity x component (μm/s)
        vy          % Flow velocity y component (μm/s)
        X           % Meshgrid x coordinates
        Y           % Meshgrid y coordinates

        % Time
        t           % Current simulation time (s)
    end

    methods
        function obj = ActiveNematicSimulation(varargin)
            % Constructor - Initialize simulation with parameters
            %
            % Parameters (name-value pairs):
            %   'Lx' - Domain size in x (default: 100 μm)
            %   'Ly' - Domain size in y (default: 100 μm)
            %   'dx' - Spatial resolution (default: 1.0 μm)
            %   'dt' - Time step (default: 0.01 s)
            %   'flow_alignment' - Flow alignment parameter λ (default: 1.0)
            %   'turnover_time' - Actin turnover time τ (default: 10.0 s)
            %   'elastic_constant' - Elastic constant K (default: 1.0 μm²/s)
            %   'active_stress_param' - Active stress ζ (default: 0.0)

            % Parse input parameters
            p = inputParser;
            addParameter(p, 'Lx', 100.0);
            addParameter(p, 'Ly', 100.0);
            addParameter(p, 'dx', 1.0);
            addParameter(p, 'dt', 0.01);
            addParameter(p, 'flow_alignment', 1.0);
            addParameter(p, 'turnover_time', 10.0);
            addParameter(p, 'elastic_constant', 1.0);
            addParameter(p, 'active_stress_param', 0.0);
            parse(p, varargin{:});

            % Set domain parameters
            obj.Lx = p.Results.Lx;
            obj.Ly = p.Results.Ly;
            obj.dx = p.Results.dx;
            obj.dt = p.Results.dt;

            % Calculate grid size
            obj.nx = round(obj.Lx / obj.dx);
            obj.ny = round(obj.Ly / obj.dx);

            % Set physical parameters
            obj.lambda_flow = p.Results.flow_alignment;
            obj.tau = p.Results.turnover_time;
            obj.K = p.Results.elastic_constant;
            obj.zeta = p.Results.active_stress_param;

            % Create coordinate grids
            x = linspace(0, obj.Lx, obj.nx);
            y = linspace(0, obj.Ly, obj.ny);
            [obj.X, obj.Y] = meshgrid(x, y);

            % Initialize Q-tensor with small random perturbations
            obj.Qxx = 0.02 * randn(obj.ny, obj.nx);
            obj.Qxy = 0.02 * randn(obj.ny, obj.nx);

            % Initialize velocity field (will be set by setFlowField)
            obj.vx = zeros(obj.ny, obj.nx);
            obj.vy = zeros(obj.ny, obj.nx);

            % Initialize time
            obj.t = 0.0;
        end

        function setFlowField(obj, flow_type, varargin)
            % Set the cortical flow velocity field
            %
            % Parameters:
            %   flow_type - Type of flow:
            %               'contractile_ring', 'symmetric_division',
            %               'contraction_wave', 'uniform_compression', 'vortex'
            %   Additional name-value pairs:
            %   'ring_position' - Position of ring (0-1, default: 0.5)
            %   'ring_width' - Width of ring (μm, default: 10.0)
            %   'flow_strength' - Flow magnitude (μm/s, default: 1.0)

            p = inputParser;
            addParameter(p, 'ring_position', 0.5);
            addParameter(p, 'ring_width', 10.0);
            addParameter(p, 'flow_strength', 1.0);
            parse(p, varargin{:});

            ring_pos = p.Results.ring_position;
            ring_width = p.Results.ring_width;
            flow_strength = p.Results.flow_strength;

            switch lower(flow_type)
                case 'contractile_ring'
                    % Convergent flow toward equatorial plane
                    y_ring = ring_pos * obj.Ly;
                    dist_from_ring = obj.Y - y_ring;
                    flow_profile = tanh(dist_from_ring / ring_width);

                    obj.vx = zeros(size(obj.X));
                    obj.vy = -flow_strength * flow_profile;

                case 'uniform_compression'
                    % Uniform compression in y-direction
                    obj.vx = zeros(size(obj.X));
                    obj.vy = -flow_strength * (obj.Y - obj.Ly/2) / (obj.Ly/2);

                case 'vortex'
                    % Rotational flow (for testing)
                    cx = obj.Lx / 2;
                    cy = obj.Ly / 2;
                    obj.vx = -flow_strength * (obj.Y - cy);
                    obj.vy = flow_strength * (obj.X - cx);

                case 'symmetric_division'
                    % Two contractile rings
                    y1 = 0.33 * obj.Ly;
                    y2 = 0.67 * obj.Ly;

                    dist1 = obj.Y - y1;
                    dist2 = obj.Y - y2;

                    flow1 = tanh(dist1 / ring_width);
                    flow2 = tanh(dist2 / ring_width);

                    obj.vx = zeros(size(obj.X));
                    obj.vy = -flow_strength * (flow1 + flow2) / 2;

                case 'contraction_wave'
                    % Traveling contraction wave
                    k_wave = 2 * pi / (obj.Lx / 2);
                    omega = flow_strength;

                    phase = k_wave * obj.X - omega * obj.t;
                    wave = sin(phase);

                    obj.vx = -flow_strength * cos(phase) * 0.5;
                    obj.vy = -flow_strength * wave .* ...
                             (obj.Y - obj.Ly/2) / (obj.Ly/2);

                otherwise
                    error('Unknown flow type: %s', flow_type);
            end
        end

        function [dvx_dx, dvx_dy, dvy_dx, dvy_dy] = computeVelocityGradient(obj)
            % Compute velocity gradient tensor components
            [dvx_dx, dvx_dy] = gradient(obj.vx, obj.dx);
            [dvy_dx, dvy_dy] = gradient(obj.vy, obj.dx);
        end

        function [adv_Qxx, adv_Qxy] = computeAdvection(obj)
            % Compute advection term: -v·∇Q
            [dQxx_dx, dQxx_dy] = gradient(obj.Qxx, obj.dx);
            [dQxy_dx, dQxy_dy] = gradient(obj.Qxy, obj.dx);

            adv_Qxx = -(obj.vx .* dQxx_dx + obj.vy .* dQxx_dy);
            adv_Qxy = -(obj.vx .* dQxy_dx + obj.vy .* dQxy_dy);
        end

        function [align_Qxx, align_Qxy] = computeFlowAlignment(obj)
            % Compute flow-alignment term: λ(E·Q + Q·E - Tr(E·Q)I)
            %
            % This term couples nematic order to flow, causing filaments
            % to align with compression direction

            [dvx_dx, dvx_dy, dvy_dx, dvy_dy] = obj.computeVelocityGradient();

            % Strain rate tensor E = (∇v + ∇v^T)/2
            Exx = dvx_dx;
            Eyy = dvy_dy;
            Exy = 0.5 * (dvx_dy + dvy_dx);

            % Matrix products E·Q and Q·E
            % Q = [[Qxx, Qxy], [Qxy, -Qxx]]
            EQ_11 = Exx .* obj.Qxx + Exy .* obj.Qxy;
            EQ_12 = Exx .* obj.Qxy - Exy .* obj.Qxx;
            EQ_22 = Exy .* obj.Qxy - Eyy .* obj.Qxx;

            QE_11 = obj.Qxx .* Exx + obj.Qxy .* Exy;
            QE_12 = obj.Qxx .* Exy + obj.Qxy .* Eyy;
            QE_22 = obj.Qxy .* Exy - obj.Qxx .* Eyy;

            % Symmetric product
            sym_11 = EQ_11 + QE_11;
            sym_12 = EQ_12 + QE_12;
            sym_22 = EQ_22 + QE_22;

            % Make traceless
            trace = sym_11 + sym_22;
            align_Qxx = obj.lambda_flow * (sym_11 - trace/2);
            align_Qxy = obj.lambda_flow * sym_12;
        end

        function [relax_Qxx, relax_Qxy] = computeRelaxation(obj)
            % Compute relaxation term: -Q/τ
            % Represents actin turnover
            relax_Qxx = -obj.Qxx / obj.tau;
            relax_Qxy = -obj.Qxy / obj.tau;
        end

        function [elastic_Qxx, elastic_Qxy] = computeElastic(obj)
            % Compute elastic term: K∇²Q
            % Represents spatial alignment tendency
            lap_Qxx = del2(obj.Qxx, obj.dx);
            lap_Qxy = del2(obj.Qxy, obj.dx);

            elastic_Qxx = obj.K * lap_Qxx;
            elastic_Qxy = obj.K * lap_Qxy;
        end

        function [active_Qxx, active_Qxy] = computeActiveStress(obj)
            % Compute active stress term: ζE_dev
            % Generates nematic order from strain

            if obj.zeta == 0
                active_Qxx = zeros(size(obj.Qxx));
                active_Qxy = zeros(size(obj.Qxy));
                return;
            end

            [dvx_dx, dvx_dy, dvy_dx, dvy_dy] = obj.computeVelocityGradient();

            % Strain rate tensor
            Exx = dvx_dx;
            Eyy = dvy_dy;
            Exy = 0.5 * (dvx_dy + dvy_dx);

            % Deviatoric part (traceless)
            trace = Exx + Eyy;
            Exx_dev = Exx - trace/2;
            Exy_dev = Exy;

            % Active stress
            active_Qxx = obj.zeta * Exx_dev;
            active_Qxy = obj.zeta * Exy_dev;
        end

        function step(obj)
            % Advance simulation by one time step (Forward Euler)

            % Compute all terms
            [adv_Qxx, adv_Qxy] = obj.computeAdvection();
            [align_Qxx, align_Qxy] = obj.computeFlowAlignment();
            [relax_Qxx, relax_Qxy] = obj.computeRelaxation();
            [elastic_Qxx, elastic_Qxy] = obj.computeElastic();
            [active_Qxx, active_Qxy] = obj.computeActiveStress();

            % Total rate of change
            dQxx_dt = adv_Qxx + align_Qxx + relax_Qxx + ...
                      elastic_Qxx + active_Qxx;
            dQxy_dt = adv_Qxy + align_Qxy + relax_Qxy + ...
                      elastic_Qxy + active_Qxy;

            % Update Q-tensor
            obj.Qxx = obj.Qxx + obj.dt * dQxx_dt;
            obj.Qxy = obj.Qxy + obj.dt * dQxy_dt;

            % Update time
            obj.t = obj.t + obj.dt;
        end

        function history = run(obj, t_max, varargin)
            % Run simulation for specified time
            %
            % Parameters:
            %   t_max - Total simulation time (s)
            %   'update_interval' - Time between progress updates (default: 1.0 s)
            %   'verbose' - Display progress (default: true)
            %
            % Returns:
            %   history - Structure with fields:
            %             .times - Time points
            %             .nematic_order - Scalar order parameter S(t)
            %             .alignment_angle - Average director angle (deg)

            p = inputParser;
            addParameter(p, 'update_interval', 1.0);
            addParameter(p, 'verbose', true);
            parse(p, varargin{:});

            update_interval = p.Results.update_interval;
            verbose = p.Results.verbose;

            n_steps = round(t_max / obj.dt);
            n_updates = round(update_interval / obj.dt);

            % Pre-allocate storage
            n_saves = ceil(n_steps / n_updates) + 1;
            times = zeros(n_saves, 1);
            nematic_order = zeros(n_saves, 1);
            alignment_angle = zeros(n_saves, 1);

            if verbose
                fprintf('Running simulation for %.1f seconds (%d steps)...\n', ...
                        t_max, n_steps);
            end

            save_idx = 1;
            times(save_idx) = obj.t;
            nematic_order(save_idx) = obj.getNematicOrder();
            alignment_angle(save_idx) = obj.getAverageAngle();

            % Main loop
            for i = 1:n_steps
                obj.step();

                if mod(i, n_updates) == 0
                    save_idx = save_idx + 1;
                    times(save_idx) = obj.t;
                    nematic_order(save_idx) = obj.getNematicOrder();
                    alignment_angle(save_idx) = obj.getAverageAngle();

                    if verbose && mod(i, 10*n_updates) == 0
                        fprintf('  t = %.1f s, S = %.3f\n', ...
                                obj.t, nematic_order(save_idx));
                    end
                end
            end

            % Trim arrays
            times = times(1:save_idx);
            nematic_order = nematic_order(1:save_idx);
            alignment_angle = alignment_angle(1:save_idx);

            % Create output structure
            history.times = times;
            history.nematic_order = nematic_order;
            history.alignment_angle = alignment_angle;

            if verbose
                fprintf('Simulation complete!\n');
                fprintf('Final nematic order: S = %.3f\n', ...
                        nematic_order(end));
            end
        end

        function S = getNematicOrder(obj)
            % Compute scalar nematic order parameter
            % S = <|Q|> = mean(sqrt(Qxx² + Qxy²))
            Q_magnitude = sqrt(obj.Qxx.^2 + obj.Qxy.^2);
            S = mean(Q_magnitude(:));
        end

        function theta_avg = getAverageAngle(obj)
            % Compute average director orientation angle (degrees)
            theta = 0.5 * atan2(obj.Qxy, obj.Qxx);
            % Circular mean
            theta_avg = atan2(mean(sin(2*theta(:))), ...
                              mean(cos(2*theta(:)))) / 2;
            theta_avg = rad2deg(theta_avg);
        end

        function [x_sub, y_sub, nx, ny, S_sub] = getDirectorField(obj, varargin)
            % Get director field for visualization
            %
            % Parameters:
            %   'subsample' - Subsampling factor (default: 5)
            %
            % Returns:
            %   x_sub, y_sub - Subsampled coordinates
            %   nx, ny - Director components (unit vectors)
            %   S_sub - Local nematic order magnitude

            p = inputParser;
            addParameter(p, 'subsample', 5);
            parse(p, varargin{:});

            subsample = p.Results.subsample;

            % Subsample
            x_sub = obj.X(1:subsample:end, 1:subsample:end);
            y_sub = obj.Y(1:subsample:end, 1:subsample:end);
            Qxx_sub = obj.Qxx(1:subsample:end, 1:subsample:end);
            Qxy_sub = obj.Qxy(1:subsample:end, 1:subsample:end);

            % Compute director angle and magnitude
            theta = 0.5 * atan2(Qxy_sub, Qxx_sub);
            S_sub = sqrt(Qxx_sub.^2 + Qxy_sub.^2);

            % Director components
            nx = cos(theta);
            ny = sin(theta);
        end

        function visualize(obj, varargin)
            % Visualize current simulation state
            %
            % Parameters:
            %   'show_flow' - Show flow field (default: true)
            %   'show_directors' - Show nematic directors (default: true)

            p = inputParser;
            addParameter(p, 'show_flow', true);
            addParameter(p, 'show_directors', true);
            parse(p, varargin{:});

            show_flow = p.Results.show_flow;
            show_directors = p.Results.show_directors;

            figure('Position', [100, 100, 1400, 450]);

            % Panel 1: Nematic order magnitude
            subplot(1, 3, 1);
            S_field = sqrt(obj.Qxx.^2 + obj.Qxy.^2);
            imagesc([0 obj.Lx], [0 obj.Ly], S_field);
            set(gca, 'YDir', 'normal');
            colormap(gca, 'parula');
            colorbar;
            caxis([0 0.5]);
            xlabel('x (\mum)');
            ylabel('y (\mum)');
            title(sprintf('Nematic Order |Q| at t=%.1fs', obj.t));

            if show_directors
                hold on;
                [x_sub, y_sub, nx, ny, S_sub] = obj.getDirectorField();
                quiver(x_sub, y_sub, nx, ny, 0.5, 'k', 'LineWidth', 1.5);
                hold off;
            end

            % Panel 2: Qxx component
            subplot(1, 3, 2);
            imagesc([0 obj.Lx], [0 obj.Ly], obj.Qxx);
            set(gca, 'YDir', 'normal');
            colormap(gca, 'RdBu');
            colorbar;
            caxis([-0.3 0.3]);
            xlabel('x (\mum)');
            ylabel('y (\mum)');
            title('Q_{xx} (x-alignment)');

            % Panel 3: Flow field or Qxy
            subplot(1, 3, 3);
            if show_flow
                speed = sqrt(obj.vx.^2 + obj.vy.^2);
                imagesc([0 obj.Lx], [0 obj.Ly], speed);
                set(gca, 'YDir', 'normal');
                colormap(gca, 'hot');
                colorbar;
                hold on;
                subsample = 5;
                quiver(obj.X(1:subsample:end, 1:subsample:end), ...
                       obj.Y(1:subsample:end, 1:subsample:end), ...
                       obj.vx(1:subsample:end, 1:subsample:end), ...
                       obj.vy(1:subsample:end, 1:subsample:end), ...
                       2, 'k', 'LineWidth', 1);
                hold off;
                xlabel('x (\mum)');
                ylabel('y (\mum)');
                title('Cortical Flow Field');
            else
                imagesc([0 obj.Lx], [0 obj.Ly], obj.Qxy);
                set(gca, 'YDir', 'normal');
                colormap(gca, 'RdBu');
                colorbar;
                caxis([-0.3 0.3]);
                xlabel('x (\mum)');
                ylabel('y (\mum)');
                title('Q_{xy} (diagonal alignment)');
            end
        end
    end
end
