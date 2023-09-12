%% Read data
% Specify the file path
filePath = './data/S_parameter.csv';

% Specify the range to read from. 
% A2 means the cell at the intersection of column A and row 2
range = 'A2';

% Read the matrix from the specified range
data = readmatrix(filePath, 'Range', range);

data_filter_rp = data(:,[1,5,6]);
n_curves = 7;
data_filter_rp = reshape(data_filter_rp, [201, n_curves, 3]);
data_filter_rp = permute(data_filter_rp, [2 1 3]);

freqs = data_filter_rp(1,:,2);
amps = data_filter_rp(:,:,3);

%% Interpolation
newFreqs = (1:0.005:8);
newAmps = zeros(n_curves, length(newFreqs));

% Loop through each row of amps and interpolate the amplitude values at the new frequencies
for i = 1:size(amps, 1)
    newAmps(i, :) = interp1(freqs, amps(i, :), newFreqs, 'linear');
end


%% Plot curve
idx_st = findNearest(newFreqs, 2.5);
idx_ed = findNearest(newFreqs, 4.75);

figure; % create a new figure
hold on; % keep all plots on the same axes

% iterate over capacitance
for ii = 1:size(data_filter_rp,1)
    % plot the power vs frequency curve for the current voltage
    plot(newFreqs(idx_st:idx_ed), newAmps(ii, idx_ed:-1:idx_st));
end

% Coordinates of the rectangle
x1 = 3.55;
y1 = -30;
x2 = 3.7;
y2 = 0;

% x1 = 3.55;
% y1 = -4;
% x2 = 3.7;
% y2 = 4;

% Plot the rectangle
hold on;
%fill([x1 x2 x2 x1], [y1 y1 y2 y2], 'r', 'FaceAlpha', 0.3);
hold off;


% add a legend and labels
legend(['0.22pF'; '0.23pF'; '0.24pF'; '0.25pF'; '0.26pF'; '0.27pF'; '0.28pF']);
xlabel('Frequency (MHz)');
ylabel('Magnitude (dB)');
grid on;
hold off;
