% Define the x values
x = linspace(0, pi, 1000);

% Compute the y values for each function
y1 = cos(x);
y2 = cos(2*x);

% Create the plot
figure; % opens a new figure window

% Plot the functions
plot(x, y1, '-b', 'LineWidth', 2); % plot cos(x) in blue
hold on; % allows multiple plots on the same figure
plot(x, y2, '-r', 'LineWidth', 2); % plot cos(2x) in red

% Add straight lines
plot([0, pi], [0, 0], '-k', 'LineWidth', 1); % straight line from (0,0) to (pi,0)
plot([0, 0], [-1, 1], '-k', 'LineWidth', 1); % straight line from (0,-1) to (0,1)
plot([pi, pi], [-1, 1], '-k', 'LineWidth', 1); % straight line from (pi,-1) to (pi,1)

% Label the axes and the plot
xlabel('Resonator locations');
ylabel('Voltage');
title('Plot of cos(x) and cos(2x)');
legend(["n=1"; "n=2"]); % display the legend
grid on; % display the grid

% Set the x-axis limits to [0, pi] and y-axis limits to [-1, 1]
xlim([0 pi]);
ylim([-1, 1]);

% Set x-axis tick locations and labels
xticks([0, pi/2, pi]);
xticklabels({'Left End', 'Center', 'Right End'});

% Remove all y-axis ticks
yticks([]);
