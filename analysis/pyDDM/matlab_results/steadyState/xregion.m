function h = xregion(x_start, x_end, color, alpha)
    % XREGION Shade a region along the x-axis
    % Usage: h = xregion(x_start, x_end, color, alpha)
    % Inputs:
    %   x_start - start of the region
    %   x_end - end of the region
    %   color - color of the shaded region (default: 'light gray')
    %   alpha - transparency (default: 0.2)
    % Returns:
    %   h - handle to the patch object
    
    if nargin < 3
        color = [0.8 0.8 0.8]; % Light gray
    end
    if nargin < 4
        alpha = 0.25;
    end
    
    ylim_values = ylim;
    y_min = ylim_values(1);
    y_max = ylim_values(2);
    
    h = patch([x_start x_end x_end x_start], [y_min y_min y_max y_max], color, 'FaceAlpha', alpha, 'EdgeColor', 'none');
end

