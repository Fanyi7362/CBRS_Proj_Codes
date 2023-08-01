clear;
close all;
%% Connect to Radio
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

radio.ChannelMapping = 1;     % 1, 2, or [1 2]
radio.CenterFrequency = 3700000000;
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

% Set eNodeB basic parameters
enb = struct;                   % eNodeB config structure
enb.DuplexMode = DuplexMode;         % assume FDD duxplexing mode
enb.CyclicPrefix = 'Normal';    % assume normal cyclic prefix
enb.NDLRB = 25;                  % Number of resource blocks
ofdmInfo = lteOFDMInfo(enb);    % Needed to get the sampling rate

if (isempty(eNodeBOutput))
    fprintf('\nReceived signal must not be empty.\n');
    return;
end

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
enb.CellRefP = 1;   
                    
fprintf('Performing OFDM demodulation...\n\n');

griddims = lteResourceGridSize(enb); % Resource grid dimensions
L = griddims(2);                     % Number of OFDM symbols in a subframe 
% OFDM demodulate signal 
rxgrid = lteOFDMDemodulate(enb, downsampled);    
if (isempty(rxgrid))
    fprintf('After timing synchronization, signal is shorter than one subframe so no further demodulation will be performed.\n');
    return;
end

rsmeas = hRSMeasurements(enb,rxgrid);
rxRSRP = rsmeas.RSRPdBm;

fprintf('%s\n',separator);
fprintf('RSRP: %7.2fdBm\n', rxRSRP);
fprintf('%s\n\n',separator);

release(radio);
release(radio);