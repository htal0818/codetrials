function fig = plotHistory(history, varargin)
% PLOTHISTORY Plot time evolution of nematic order parameters
%
% Parameters:
%   history - Structure with fields:
%             .times - Time array
%             .nematic_order - Nematic order parameter S(t)
%             .alignment_angle - Director orientation angle (deg)
%
% Optional name-value pairs:
%   'figure_handle' - Existing figure to plot on (default: create new)
%
% Returns:
%   fig - Figure handle

    p = inputParser;
    addParameter(p, 'figure_handle', []);
    parse(p, varargin{:});

    if isempty(p.Results.figure_handle)
        fig = figure('Position', [100, 100, 1200, 400]);
    else
        fig = p.Results.figure_handle;
        figure(fig);
        clf(fig);
    end

    % Panel 1: Nematic order evolution
    subplot(1, 2, 1);
    plot(history.times, history.nematic_order, 'b-', 'LineWidth', 2.5);
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Nematic Order Parameter S', 'FontSize', 12);
    title('Growth of Alignment', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    xlim([0 max(history.times)]);
    ylim([0 max([0.5, max(history.nematic_order)*1.1])]);

    % Panel 2: Average orientation angle
    subplot(1, 2, 2);
    plot(history.times, history.alignment_angle, 'r-', 'LineWidth', 2.5);
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Average Director Angle (degrees)', 'FontSize', 12);
    title('Director Orientation', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    xlim([0 max(history.times)]);

    sgtitle('Time Evolution of Nematic Order', 'FontSize', 14, 'FontWeight', 'bold');
end
