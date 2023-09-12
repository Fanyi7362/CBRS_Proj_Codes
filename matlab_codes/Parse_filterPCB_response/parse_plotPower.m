folder = './data/';
% voltages = 2.00:0.25:6.00; % all voltage values from 2.00V to 6.00V
% voltages_toPlot = 2.00:0.25:6.00; % voltage values to plot
voltages = [0,0.25,0.50,2,3,4]; % all voltage values from 2.00V to 6.00V
voltages_toPlot = [0,0.25,0.50,2,3,4]; % voltage values to plot
freqs = 3550:5:3700; % frequencies

figure; % create a new figure
hold on; % keep all plots on the same axes

% preallocate power array
power = zeros(numel(freqs), numel(voltages));

% iterate over frequencies
for f = 1:numel(freqs)
    % iterate over all voltages
    for v = 1:numel(voltages)
        % construct the name of the folder for the current voltage
        foldername = sprintf('data_%04dV', voltages(v)*100);
        
        % construct the name of the current file
        filename = sprintf('RSSI_freq_%04d_*', freqs(f));
        
        % find files that match the current frequency and voltage
        files = dir(fullfile(folder, foldername, filename));
        if numel(files) ~= 1
            error('Expected one file for frequency %d and voltage %.2fV, found %d.', freqs(f), voltages(v), numel(files));
        end

        % read the last line of the current file
        fid = fopen(fullfile(folder, foldername, files(1).name), 'rt');
        lastline = '';
        tline = fgets(fid);
        while ischar(tline)
            lastline = tline;
            tline = fgets(fid);
        end
        fclose(fid);

        % extract power_peak value from the last line
        power(f, v) = sscanf(lastline, 'power_peak: %f');
    end
end

% calculate average power at each frequency
avg_power = mean(power, 2);

% adjust power values based on the standard at 3700MHz
% power = power - avg_power + mean(power(freqs == 3700, :));

% iterate over voltages to plot
for v = find(ismember(voltages, voltages_toPlot))
    % plot the power vs frequency curve for the current voltage
    plot(freqs, power(:, v));
end

% add a legend and labels
legend(arrayfun(@(v) sprintf('%.2fV', v), voltages_toPlot, 'UniformOutput', false));
xlabel('Frequency (MHz)');
ylabel('Adjusted Power Peak (dBm)');
grid on;
hold off;
