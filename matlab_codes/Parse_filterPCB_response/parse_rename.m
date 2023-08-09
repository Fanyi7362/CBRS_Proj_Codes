folder = './data/';
files = dir(fullfile(folder, 'RSSI_freq_*')); % list all files with prefix 'RSSI_freq_'
files = {files.name}'; % extract file names to a cell array
voltages = 2.50:0.25:6.00; % voltage values

% parse file names to extract frequencies and timestamps
freqs = cellfun(@(s) sscanf(s, 'RSSI_freq_%d_%d_%d_%d_%d_%d')', files, 'UniformOutput', false);
freqs = cell2mat(freqs); % convert to a matrix
[freqs, sortIdx] = sortrows(freqs); % sort by frequency and timestamp
files = files(sortIdx); % apply the same ordering to the file names

% rename files
counter = 0;
for f = unique(freqs(:,1))'
    % select files for current frequency
    currentFiles = files(freqs(:, 1) == f);
    if numel(currentFiles) ~= numel(voltages)
        error('Mismatch between number of files (%d) and voltage values (%d) for frequency %d.', numel(currentFiles), numel(voltages), f);
    end
    for v = 1:numel(voltages)
        % increment counter
        counter = counter + 1;
        % construct new file name
        newName = sprintf('RSSI_freq_%04d_%02d_%02d_%02d_%02d_%02d_%.2fV', freqs(counter, :), voltages(v));
        % rename file
        movefile(fullfile(folder, currentFiles{v}), fullfile(folder, newName));
    end
end
