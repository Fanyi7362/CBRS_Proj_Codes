% Number of PRBs
n_prb = 25;

% Base directory
% baseDir = '~/fanyi/LTEScope_CSI/build/lib/csi_main/';
baseDir = '~/fanyi/LTEScope_CSI/build/lib/csi_main/old_data/loop_amplifier_256states/';

% Get all folders in the base directory
allFolders = dir([baseDir 'csi_log_2023*']);
numFolders = length(allFolders);
% Preallocate storage for all amp_1 data
all_amp_1 = zeros(numFolders, 25);

% Iterate through each folder and extract the data
for folderIdx = 1:numFolders
    csi_folder = [allFolders(folderIdx).folder, '/', allFolders(folderIdx).name, '/'];
    
    % Construct the filenames
    filename_a1 = sprintf('csi_amp_usrpIdx_0_freq_3630000000_N_-1_PRB_%d_TX_1_RX_1.csiLog', n_prb);
    filename_p1 = sprintf('csi_phase_usrpIdx_0_freq_3630000000_N_-1_PRB_%d_TX_1_RX_1.csiLog', n_prb);

    % Load the data
    csi_a1 = load([csi_folder, filename_a1]);
    csi_p1 = load([csi_folder, filename_p1]);

    % Data preparation
    amp_1 = reshape(csi_a1, 1, [], n_prb);
    pha_1 = reshape(csi_p1, 1, [], n_prb);
    csi_1 = amp_1 .* exp(1i .* pha_1);
    
    % Extract the specific data and store it in the preallocated storage
    all_amp_1(folderIdx, :) = (amp_1(1, 100, :));
end

% Plot all amp_1 data on the same figure
figure;
hold on;
for folderIdx = 1:numFolders
    plot(all_amp_1(folderIdx, :));
end
hold off;
xlabel('Subcarrier Index');
ylabel('Amplitude');
title('Amplitude of CSI at 100th Index for Each csi_log Folder');
% legend(arrayfun(@(x) ['Log ' num2str(x)], 1:numFolders, 'UniformOutput', false));
