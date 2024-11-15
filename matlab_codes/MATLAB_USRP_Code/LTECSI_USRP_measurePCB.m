clear;
close all;
%% Connect to Radio
tic
radioFound = false;
radiolist = findsdru;
for i = 1:length(radiolist)
  if strcmp(radiolist(i).Status, 'Success')
    if (strcmp(radiolist(i).Platform, 'X300') || ...
        strcmp(radiolist(i).Platform, 'X310'))
        radio = comm.SDRuReceiver('Platform',radiolist(i).Platform, ...
                 'IPAddress', radiolist(i).IPAddress);
        radio.MasterClockRate = 184.32e6;
        radio.DecimationFactor = 16;        % 12: 15.36e6, 8: 23.04e6
        radioFound = true;
        break;
    end    
    if strcmp(radiolist(i).Platform, 'B210')
        radio = comm.SDRuReceiver('Platform','B210', ...
                 'SerialNum', radiolist(i).SerialNum);
        radio.MasterClockRate = 1.92e6 * 4; % Need to exceed 5 MHz minimum
        radio.DecimationFactor = 4;         % Sampling rate is 1.92e6
        radioFound = true;       
    end
  end
end

if ~radioFound
    error(message('sdru:examples:NeedMIMORadio'));
end

radio.ChannelMapping = [1 2];     % 1, 2, or [1 2]
radio.CenterFrequency = 3630000000;
DuplexMode = 'FDD';
radio.Gain = 20;
% Sampling rate is 30.72 MHz. LTE frames are 10 ms long
radio.SamplesPerFrame = radio.MasterClockRate/radio.DecimationFactor/100; 
radio.OutputDataType = 'double';
radio.EnableBurstMode = true;
% Increase capture frame by 1 to account for a full frame not being captured
radio.NumFramesInBurst = 20+1; 
radio.OverrunOutputPort = true;


%% Capture Signal
separator = repmat('-',1,50);
fprintf('%s\n',separator);
fprintf('Start capturing\n');
fprintf('%s\n',separator);
pause(1)

samplesPerFrame = radio.SamplesPerFrame;
nRxAnts = size(radio.ChannelMapping,2);
burstCaptures = zeros(radio.SamplesPerFrame, radio.NumFramesInBurst,nRxAnts);
len = 0;
for frame = 1:radio.NumFramesInBurst
    while len == 0
        [data,len,lostSamples] = step(radio);
        burstCaptures(:,frame,:) = data;
    end
    len = 0;
end

fprintf('%s\n',separator);
fprintf('End capturing\n');
fprintf('%s\n',separator);

trace_1 = reshape(burstCaptures,[],nRxAnts);
clear burstCaptures

% LTE sampling rate
RadioSampleRate = radio.MasterClockRate/radio.DecimationFactor ; 
n_short = 0.21*RadioSampleRate;
eNodeBOutput =  trace_1(1:n_short,:);

% Check for presence of LTE Toolbox
if isempty(ver('lte')) 
    error(message('sdru:examples:NeedLST'));
end

% Prior to decoding the MIB, the UE does not know the full system bandwidth. 
% The primary and secondary synchronization signals (PSS and SSS) and the 
% PBCH (containing the MIB) all lie in the central 72 subcarriers 
% (6 resource blocks) of the system bandwidth, allowing the UE to initially 
% demodulate just this central region. 
% Therefore the bandwidth is initially set to 6 resource blocks. 
% The I/Q waveform needs to be resampled accordingly. 
% At this stage we also display the spectrum of the input signal |eNodeBOutput|.

% plots
if (~exist('channelFigure','var') || ~isvalid(channelFigure))
    channelFigure = figure('Visible','off');        
end
[spectrumAnalyzer,synchCorrPlot,pdcchConstDiagram] = ...
    hSIB1RecoveryExamplePlots(channelFigure,RadioSampleRate);

% Set eNodeB basic parameters
enb = struct;                   % eNodeB config structure
enb.DuplexMode = DuplexMode;         % assume FDD duxplexing mode
enb.CyclicPrefix = 'Normal';    % assume normal cyclic prefix
enb.NDLRB = 6;                  % Number of resource blocks
ofdmInfo = lteOFDMInfo(enb);    % Needed to get the sampling rate

if (isempty(eNodeBOutput))
    fprintf('\nReceived signal must not be empty.\n');
    return;
end

% Display received signal spectrum
fprintf('\nPlotting received signal spectrum...\n');
% step(spectrumAnalyzer, awgn(eNodeBOutput, 100.0));
step(spectrumAnalyzer, eNodeBOutput);

if (RadioSampleRate~=ofdmInfo.SamplingRate)
    fprintf('\nResampling from %0.3fMs/s to %0.3fMs/s for cell search / MIB decoding...\n',RadioSampleRate/1e6,ofdmInfo.SamplingRate/1e6);
else
    fprintf('\nResampling not required; received signal is at desired sampling rate for cell search / MIB decoding (%0.3fMs/s).\n',RadioSampleRate/1e6);
end

% Downsample received signal
nSamples = floor(ofdmInfo.SamplingRate/round(RadioSampleRate)*size(eNodeBOutput,1));
nRxAnts = size(eNodeBOutput, 2);
downsampled = zeros(nSamples, nRxAnts);

% for i=1:nRxAnts
%    n dowsampled(:,i) = resample(eNodeBOutput(:,i), ofdmInfo.SamplingRate, round(RadioSampleRate));
% end

fc_guard = size(eNodeBOutput,1)/2;
for i=1:nRxAnts
    fft_eNBOutput = fftshift(fft(eNodeBOutput(:,i)));
    fft_wavaform = [fft_eNBOutput(fc_guard:fc_guard+nSamples/2-1);fft_eNBOutput(fc_guard-nSamples/2:fc_guard-1)];
    downsampled(:,i) = ifft(fft_wavaform);
end
    
%% Cell Search and Synchronization
% Call <matlab:doc('lteCellSearch') lteCellSearch> to obtain the cell 
% identity and timing offset |offset| to the first frame head. 
% A plot of the correlation between the received signal and the PSS/SSS 
% for the detected cell identity is produced.

% Cell search to find cell identity and timing offset
fprintf('\nPerforming cell search...\n');

% Set up duplex mode and cyclic prefix length combinations for search; if
% either of these parameters is configured in |enb| then the value is
% assumed to be correct
if (~isfield(enb,'DuplexMode'))
    duplexModes = {'TDD' 'FDD'};
else
    duplexModes = {enb.DuplexMode};
end
if (~isfield(enb,'CyclicPrefix'))
    cyclicPrefixes = {'Normal' 'Extended'};
else
    cyclicPrefixes = {enb.CyclicPrefix};
end

% Perform cell search across duplex mode and cyclic prefix length
% combinations and record the combination with the maximum correlation; 
% if multiple cell search is configured, this example will decode the 
% first (strongest) detected cell
searchalg.MaxCellCount = 1;
searchalg.SSSDetection = 'PostFFT';
peakMax = -Inf;
for duplexMode = duplexModes
    for cyclicPrefix = cyclicPrefixes
        enb.DuplexMode = duplexMode{1};
        enb.CyclicPrefix = cyclicPrefix{1};
        [enb.NCellID, offset, peak] = lteCellSearch(enb, downsampled, searchalg);
        enb.NCellID = enb.NCellID(1);
        offset = offset(1);
        peak = peak(1);
        if (peak>peakMax)
            enbMax = enb;
            offsetMax = offset;
            peakMax = peak;
        end
    end
end

% Use the cell identity, cyclic prefix length, duplex mode and timing
% offset which gave the maximum correlation during cell search
enb = enbMax;
offset = offsetMax;

% Compute the correlation for each of the three possible primary cell
% identities; the peak of the correlation for the cell identity established
% above is compared with the peak of the correlation for the other two
% primary cell identities in order to establish the quality of the
% correlation.
corr = cell(1,3);
idGroup = floor(enbMax.NCellID/3);
for i = 0:2
    enb.NCellID = idGroup*3 + mod(enbMax.NCellID + i,3);
    [~,corr{i+1}] = lteDLFrameOffset(enb, downsampled);
    corr{i+1} = sum(corr{i+1},2);
end
threshold = 1.3 * max([corr{2}; corr{3}]); % multiplier of 1.3 empirically obtained
if (max(corr{1})<threshold)    
    warning('sdru:examples:WeakSignal','Synchronization signal correlation was weak; detected cell identity may be incorrect.');
end
enb.NCellID = enbMax.NCellID;

% plot PSS/SSS correlation and threshold
synchCorrPlot.YLimits = [0 max([corr{1}; threshold])*1.1];
synchCorrPlot([corr{1} threshold*ones(size(corr{1}))]);

% perform timing synchronisation
fprintf('Timing offset to frame start: %d samples\n',offset);
downsampled = downsampled(1+offset:end,:); 
tailSamples = mod(length(downsampled),samplesPerFrame);
downsampled = downsampled(1:end-tailSamples,:);
enb.NSubframe = 0;

% % show cell-wide settings
% fprintf('Cell-wide settings after cell search:\n');
% disp(enb);

%% Frequency offset estimation and correction
% Prior to OFDM demodulation, any significant frequency offset must be
% removed. The frequency offset in the I/Q waveform is estimated and
% corrected using <matlab:doc('lteFrequencyOffset') lteFrequencyOffset> and
% <matlab:doc('lteFrequencyCorrect') lteFrequencyCorrect>. The frequency
% offset is estimated by means of correlation of the cyclic prefix and
% therefore can estimate offsets up to +/- half the subcarrier spacing i.e.
% +/- 7.5kHz.

fprintf('\nPerforming frequency offset estimation...\n');
% Note that the duplexing mode is set to FDD here because timing synch has
% not yet been performed - for TDD we cannot use the duplexing arrangement 
% to indicate which time periods to use for frequency offset estimation
% prior to doing timing synch.
delta_f = lteFrequencyOffset(setfield(enb,'DuplexMode','FDD'), downsampled); %#ok<SFLD>
fprintf('Frequency offset: %0.3fHz\n',delta_f);
downsampled = lteFrequencyCorrect(enb, downsampled, delta_f);


%% OFDM Demodulation and Channel Estimation  
% The OFDM downsampled I/Q waveform is demodulated to produce a resource
% grid |rgrid|. This is used to perform channel estimation. |hest| is the
% channel estimate, |nest| is an estimate of the noise (for MMSE
% equalization) and |cec| is the channel estimator configuration.
%
% For channel estimation the example assumes 4 cell specific reference
% signals. This means that channel estimates to each receiver antenna from
% all possible cell-specific reference signal ports are available. The true
% number of cell-specific reference signal ports is not yet known. The
% channel estimation is only performed on the first subframe, i.e. using
% the first |L| OFDM symbols in |rxgrid|.
%
% A conservative 9-by-9 pilot averaging window is used, in time and
% frequency, to reduce the impact of noise on pilot estimates during
% channel estimation.

% Channel estimator configuration
cec.PilotAverage = 'UserDefined';     % Type of pilot averaging
cec.FreqWindow = 9;                   % Frequency window size    
cec.TimeWindow = 9;                   % Time window size    
cec.InterpType = 'cubic';             % 2D interpolation type
cec.InterpWindow = 'Centered';        % Interpolation window type
cec.InterpWinSize = 1;                % Interpolation window size  

% Assume 4 cell-specific reference signals for initial decoding attempt;
% ensures channel estimates are available for all cell-specific reference
% signals
enb.CellRefP = 4;   
                    
fprintf('Performing OFDM demodulation...\n\n');

griddims = lteResourceGridSize(enb); % Resource grid dimensions
L = griddims(2);                     % Number of OFDM symbols in a subframe 
% OFDM demodulate signal 
rxgrid = lteOFDMDemodulate(enb, downsampled);    
if (isempty(rxgrid))
    fprintf('After timing synchronization, signal is shorter than one subframe so no further demodulation will be performed.\n');
    return;
end
% Perform channel estimation
if (strcmpi(enb.DuplexMode,'TDD'))
    enb.TDDConfig = 2;
    enb.SSC = 1; % special subframe configuration [possible: 1,2,3,6,7,8]
end
[hest, nest] = lteDLChannelEstimate(enb, cec, rxgrid(:,1:L,:));

%% PBCH Demodulation, BCH Decoding, MIB parsing
% The MIB is now decoded along with the number of cell-specific reference
% signal ports transmitted as a mask on the BCH CRC. The function
% <matlab:doc('ltePBCHDecode') ltePBCHDecode> establishes frame timing
% modulo 4 and returns this in the |nfmod4| parameter. It also returns the
% MIB bits in vector |mib| and the true number of cell-specific reference
% signal ports which is assigned into |enb.CellRefP| at the output of this
% function call. If the number of cell-specific reference signal ports is
% decoded as |enb.CellRefP=0|, this indicates a failure to decode the BCH.
% The function <matlab:doc('lteMIB') lteMIB> is used to parse the bit
% vector |mib| and add the relevant fields to the configuration structure
% |enb|. After MIB decoding, the detected bandwidth is present in
% |enb.NDLRB|. 

% Decode the MIB
% Extract resource elements (REs) corresponding to the PBCH from the first
% subframe across all receive antennas and channel estimates
fprintf('Performing MIB decoding...\n');
pbchIndices = ltePBCHIndices(enb);
[pbchRx, pbchHest] = lteExtractResources( ...
    pbchIndices, rxgrid(:,1:L,:), hest(:,1:L,:,:));

% Decode PBCH
[bchBits, pbchSymbols, nfmod4, mib, enb.CellRefP] = ltePBCHDecode( ...
    enb, pbchRx, pbchHest, nest); 

% Parse MIB bits
enb = lteMIB(mib, enb); 

% Incorporate the nfmod4 value output from the function ltePBCHDecode, as
% the NFrame value established from the MIB is the System Frame Number
% (SFN) modulo 4 (it is stored in the MIB as floor(SFN/4))
enb.NFrame = enb.NFrame+nfmod4;

% Display cell wide settings after MIB decoding
fprintf('Cell-wide settings after MIB decoding:\n');
disp(enb);

if (enb.CellRefP==0)
    fprintf('MIB decoding failed (enb.CellRefP=0).\n\n');
%     return;
end
if (enb.NDLRB==0)
    fprintf('MIB decoding failed (enb.NDLRB=0).\n\n');
    return;
end

%% OFDM Demodulation on Full Bandwidth
% Now that the signal bandwidth is known, the signal is resampled to the
% nominal sampling rate used by LTE Toolbox for that bandwidth (see
% <matlab:doc('lteOFDMModulate') lteOFDMModulate> for details). Frequency
% offset estimation and correction is performed on the resampled signal.
% Timing synchronization and OFDM demodulation are then performed.

fprintf('Restarting reception now that bandwidth (NDLRB=%d) is known...\n',enb.NDLRB);

% Resample now we know the true bandwidth
ofdmInfo = lteOFDMInfo(enb);
if (RadioSampleRate~=ofdmInfo.SamplingRate)
    fprintf('\nResampling from %0.3fMs/s to %0.3fMs/s...\n',RadioSampleRate/1e6,ofdmInfo.SamplingRate/1e6);
else
    fprintf('\nResampling not required; received signal is at desired sampling rate for NDLRB=%d (%0.3fMs/s).\n',enb.NDLRB,RadioSampleRate/1e6);
end

% eNodeBOutput = trace(5e5+1:end-5e5,1);

nSamples = ceil(ofdmInfo.SamplingRate/round(RadioSampleRate)*size(eNodeBOutput,1));
resampled = zeros(nSamples, nRxAnts);
for i = 1:nRxAnts
    resampled(:,i) = resample(eNodeBOutput(:,i), ofdmInfo.SamplingRate, round(RadioSampleRate));
end

% resampled = trace(5e5+1:end-5e5,1);

% Perform frequency offset estimation and correction
fprintf('\nPerforming frequency offset estimation...\n');
% Note that the duplexing mode is set to FDD here because timing synch has
% not yet been performed - for TDD we cannot use the duplexing arrangement 
% to indicate which time periods to use for frequency offset estimation
% prior to doing timing synch.
nSamples_10frame = ceil(ofdmInfo.SamplingRate/10);
delta_f = lteFrequencyOffset(setfield(enb,'DuplexMode','FDD'), resampled(1:nSamples_10frame,nRxAnts)); %#ok<SFLD>
fprintf('Frequency offset: %0.3fHz\n',delta_f);
resampled = lteFrequencyCorrect(enb, resampled, delta_f);

% Find beginning of frame
fprintf('\nPerforming timing offset estimation...\n');
offset2 = lteDLFrameOffset(enb, resampled(1:nSamples_10frame,nRxAnts)); 
fprintf('Timing offset to frame start: %d samples\n',offset2);
% aligning signal with the start of the frame
resampled = resampled(1+offset2:end,:);   
samplesPerFrame = ofdmInfo.SamplingRate/100;
tailSamples = mod(size(resampled,1),samplesPerFrame);
resampled = resampled(1:end-tailSamples,:);

% OFDM demodulation
fprintf('\nPerforming OFDM demodulation...\n\n');
rxgrid = lteOFDMDemodulate(enb, resampled);   

%% CSI

if (isempty(rxgrid))
    fprintf('Received signal does not contain a subframe carrying SIB1.\n\n');
end

% While we have more data left, attempt to decode CSI
hest_array = zeros([size(rxgrid),enb.CellRefP]);

fprintf('%s\n',separator);
fprintf('extracting CSI\n');
fprintf('%s\n\n',separator);

Nsymbols=1;
Nsubframes_perEst = 1;
while (size(rxgrid,2) > 0)

    % Extract current subframe
    rxframe = rxgrid(:,1:L*Nsubframes_perEst,:);
    
    % Perform channel estimation
    hest = []; % subcarriers, symbols, rxAnts, txAnts
    [hest,nest] = lteDLChannelEstimate(enb, cec, rxframe);    
    hest_array(:,Nsymbols:(Nsymbols+L*Nsubframes_perEst-1),:,:) = hest(:,:,:,:);

    if (size(rxgrid,2)>=L*Nsubframes_perEst)
        rxgrid(:,1:(L*Nsubframes_perEst),:) = [];   % Remove 1 frame
    else
        rxgrid = []; % Less than 1 frame left
    end
 
    Nsymbols = Nsymbols+L*Nsubframes_perEst;
    
    if (size(rxgrid,2)<L*Nsubframes_perEst)
        rxgrid = []; % Less than 1 frame left
    end
    enb.NSubframe = mod(enb.NSubframe + Nsubframes_perEst,10);
    Frame_increase = floor((enb.NSubframe+Nsubframes_perEst)/10);
    enb.NFrame = mod(enb.NFrame + Frame_increase,1024);
        
end

figure(channelFigure);
surf(abs(hest_array(:,:,1,1)));
hSIB1RecoveryExamplePlots(channelFigure);
channelFigure.CurrentAxes.XLim = [0 size(hest_array,2)+1];
channelFigure.CurrentAxes.YLim = [0 size(hest_array,1)+1];

if nRxAnts>1
    fprintf('%s\n',separator);
    fprintf('plotting second figure\n');
    fprintf('%s\n\n',separator);
    figure(2);
    phase_diff = angle(hest_array(:,:,1,1)) -angle(hest_array(:,:,2,1));
    s = surf(unwrap(phase_diff) );
    s.EdgeColor = 'none';
    xlabel("OFDM Symbol Index");
    ylabel("Subcarrier Index");
    zlabel("Magnitude");
    title("Estimate of Channel Magnitude Frequency Response");
end

fprintf('%s\n',separator);
fprintf('Calculating mean dB\n');
hest_db = mag2db(abs(hest_array(:,:,:,1)));
meandB = mean(hest_db, 'all');
fprintf('Calculated mean dB: %f db\n', meandB);
fprintf('%s\n\n',separator);

save('LTE_trace','trace_1','eNodeBOutput','hest_array','RadioSampleRate')

release(radio);
toc