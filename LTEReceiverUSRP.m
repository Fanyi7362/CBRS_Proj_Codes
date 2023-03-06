%% Receiver Design: System Architecture
% Follow these steps to understand how the LTE receiver functions.

% 1. If using an SDR, capture a suitable number of frames of an LTE signal.
% 2. Determine and correct the frequency offset of the received signal.
% 3. Determine the cell identity by performing a blind cell search.
% 4. Synchronize the captured signal to the start of an LTE frame.
% 5. Extract an LTE resource grid by OFDM demodulating the received signal.
% 6. Perform a channel estimation for the received signal.
% 7. Determine the cell-wide settings by decoding the MIB for each captured frame.
% 8. Decode the CFI and PDCCH for each subframe within the captured signal.

% This example plots the power spectral density of the captured waveform 
% and shows visualizations of the received LTE resource grid, estimated channel, 
% and equalized PBCH symbols for each frame.

clear;
%% Setup
rxsim.ReceiveOnSDR = true;
fileName = "capturedLTERCDLWaveform.mat";
saveToFile = "hest_long.mat";
dcodeMIB = true;

if rxsim.ReceiveOnSDR
    rxsim.SDRDeviceName = "B210";        % SDR that is used for waveform reception
    rxsim.RadioIdentifier = '31993A8';      % Value used to identify radio, for example, IP address, USB port, or serial number
    rxsim.RadioSampleRate = 30.72e6;      % Configured for 15.36e6 Hz capture bandwidth
    rxsim.RadioCenterFrequency = 1940000000; % Center frequency in Hz
    rxsim.FramesPerCapture = 10;     % Number of contiguous LTE frames to capture
    rxsim.NumCaptures = 1;          % Number of captures for the SDR to perform
    rxsim.NumAntennas = 1;          % Number of receive antennas

    % Derived parameter
    captureTime = (rxsim.FramesPerCapture + 1)* 10e-3; % Increase capture frame by 1 to account for a full frame not being captured

else
    rx = load(fileName);
    rxsim.NumCaptures = rx.numCaptures;
    rxsim.RadioSampleRate = rx.radioSampleRate;
end

%% Configure SDR Hardware
if rxsim.ReceiveOnSDR
    if matches(rxsim.SDRDeviceName, ["AD936x", "FMCOMMS5", "Pluto", "E3xx"])
        sdrReceiver = sdrrx( ...
            rxsim.SDRDeviceName, ...
            CenterFrequency=rxsim.RadioCenterFrequency, ...
            BasebandSampleRate=rxsim.RadioSampleRate);
        if matches(rxsim.SDRDeviceName, ["AD936x", "FMCOMMS5", "E3xx"])
            sdrReceiver.ShowAdvancedProperties = true;
            sdrReceiver.BypassUserLogic = true;
            sdrReceiver.IPAddress = rxsim.RadioIdentifier;
        else
            sdrReceiver.RadioID = rxsim.RadioIdentifier;
        end
    else
        % For the USRP SDRs
        sdrReceiver = comm.SDRuReceiver(...
            Platform=rxsim.SDRDeviceName,...
            CenterFrequency=rxsim.RadioCenterFrequency);
        [sdrReceiver.MasterClockRate, sdrReceiver.DecimationFactor] = ...
            hGetUSRPRateInformation(rxsim.SDRDeviceName,rxsim.RadioSampleRate);
        if matches(rxsim.SDRDeviceName, ["B200", "B210"])
            % Change the serial number as needed for USRP B200/B210
            sdrReceiver.SerialNum = rxsim.RadioIdentifier;
        else
            sdrReceiver.IPAddress = rxsim.RadioIdentifier;
        end
        sdrReceiver.EnableBurstMode = true;
        sdrReceiver.SamplesPerFrame = 10e-3*rxsim.RadioSampleRate;
        sdrReceiver.NumFramesInBurst = rxsim.FramesPerCapture + 1; % Increase capture frame by 1 to account for a full frame not being captured
    end
    sdrReceiver.OutputDataType = "double";
    numSamplesToCapture = ceil(captureTime*rxsim.RadioSampleRate);
    sdrReceiver.ChannelMapping = 1:rxsim.NumAntennas;
end
% Set up the spectrum analyzer to display the received waveform. 
spectrumScope = spectrumAnalyzer( ...
    SampleRate=rxsim.RadioSampleRate, ...
    SpectrumType="power-density", ...
    Title="Baseband LTE Signal Spectrum", ...
    YLabel="Power Spectral Density");

%% LTE Setup
enb.DuplexMode = "FDD";
enb.CyclicPrefix = "Normal";
enb.CellRefP = 4;

% Bandwidth: {1.4 MHz, 3 MHz, 5 MHz, 10 MHz, 20 MHz}
SampleRateLUT = [1.92 3.84 7.68 15.36 30.72]*1e6;
NDLRBLUT = [6 15 25 50 100];
enb.NDLRB = NDLRBLUT(SampleRateLUT==rxsim.RadioSampleRate);
if rxsim.ReceiveOnSDR
    fprintf("\nSDR hardware sampling rate configured to capture %d LTE RBs.\n",enb.NDLRB);
end

cec.FreqWindow = 9;               % Frequency averaging window in resource elements (REs)
cec.TimeWindow = 9;               % Time averaging window in REs
cec.InterpType = "cubic";         % Cubic interpolation
cec.PilotAverage = "UserDefined"; % Pilot averaging method
cec.InterpWindow = "Centred";     % Interpolation windowing method
cec.InterpWinSize = 3;            % Interpolate up to 3 subframes simultaneously

%% Signal Capture and Processing
constellation = comm.ConstellationDiagram("Title","Equalized PDCCH Symbols") ;
channelEstimatePlot = figure("Visible","Off");

enbDefault = enb;
samplesPerFrame = 10e-3*rxsim.RadioSampleRate; % LTE frame period is 10 ms

% Perform LTE receiver processing.
start = 1;
for i = 1:rxsim.NumCaptures
    % Set default LTE parameters
    enb = enbDefault;

    % rxWaveform holds |rxsim.FramesPerCapture| number of consecutive
    % frames worth of contiguous baseband LTE samples.
    if rxsim.ReceiveOnSDR
        % SDR Capture
        fprintf("\nStarting a new RF capture.\n")
        rxWaveform(start:start+numSamplesToCapture-1,1) = captureWaveform(sdrReceiver,numSamplesToCapture);
    else
        rxWaveform(start:start+numSamplesToCapture-1,1) = rx.capturedData(:,:,i);
    end

    start = start+numSamplesToCapture;
end

% Show power spectral density of captured burst
% 1382400 = 9*153600; 
n_short = 0.09*rxsim.RadioSampleRate;
rxWaveform_short = rxWaveform(1:n_short);
spectrumScope(rxWaveform_short);
release(spectrumScope);

% Perform frequency offset correction
frequencyOffset = lteFrequencyOffset(enb,rxWaveform_short);
rxWaveform = lteFrequencyCorrect(enb,rxWaveform,frequencyOffset);
fprintf("Corrected a frequency offset of %g Hz.\n",frequencyOffset)

% Perform the blind cell search to obtain cell identity and timing
% offset Use "PostFFT" secondary synchronization signal (SSS) detection
% method to improve speed
cellSearch.SSSDetection = "PostFFT";
cellSearch.MaxCellCount = 1;
[NCellID,frameOffset] = lteCellSearch(enb,rxWaveform_short,cellSearch);
fprintf("Detected a cell identity of %i.\n", NCellID);
enb.NCellID = NCellID; % From lteCellSearch

% Sync the captured samples to the start of an LTE frame, and trim off
% any samples that are part of an incomplete frame.
rxWaveform = rxWaveform(frameOffset+1:end,:);
tailSamples = mod(length(rxWaveform),samplesPerFrame);
rxWaveform = rxWaveform(1:end-tailSamples,:);
enb.NSubframe = 0;

% OFDM demodulation
rxGrid = lteOFDMDemodulate(enb,rxWaveform);

% Perform channel estimation
% time dimension downsampled by 20
% rxGrid_short takes first 10 frame
rxGrid_down = rxGrid(1:12:end,1:20:end);
rxGrid_short = rxGrid(:,1:1400);
[hest,nest] = lteDLChannelEstimate(enb,cec,rxGrid_short);

sfDims = lteResourceGridSize(enb);
Lsf = sfDims(2); % OFDM symbols per subframe
LFrame = 10*Lsf; % OFDM symbols per frame
numFullFrames = size(rxGrid_short,2)/140;

tic
N_frames = numFullFrames;
frame_downsamp = 10;
hest_long = zeros(size(rxGrid,1),size(rxGrid,2)/frame_downsamp,1,4);
for i=1:N_frames/frame_downsamp
    frame_step = size(rxGrid,2)/(N_frames/frame_downsamp);
    subframe_step = size(rxGrid,2)/N_frames;
    idx_hest = ((i-1)*subframe_step+1):(i*subframe_step);
    idx_rxgrid = ((i-1)*frame_step+1):((i-1)*frame_step+subframe_step);
    [hest_long(:,idx_hest,:,:),nest_long] = lteDLChannelEstimate(enb,cec,rxGrid(:, idx_rxgrid));
end
toc


if dcodeMIB
% For each frame, decode the MIB and CFI
    for frame = 0:(numFullFrames-1)
        fprintf("\nPerforming MIB decode for frame %i of %i in burst...\n", ...
            frame+1,numFullFrames)
    
        % Extract subframe 0 from each frame of the received resource grid
        % and channel estimate.
        enb.NSubframe = 0;
        rxsf = rxGrid_short(:,frame*LFrame+(1:Lsf),:);
        hestsf = hest(:,frame*LFrame+(1:Lsf),:,:);
    
        % PBCH demodulation. Extract REs corresponding to the PBCH from the
        % received grid and channel estimate grid for demodulation. Assume
        % 4 cell-specific reference signals for PBCH decode as initially
        % the value is unknown.
        enb.CellRefP = 4;
        pbchIndices = ltePBCHIndices(enb);
        [pbchRx,pbchHest] = lteExtractResources(pbchIndices,rxsf,hestsf);
        [~,~,nfmod4,mib,CellRefP] = ltePBCHDecode(enb,pbchRx,pbchHest,nest);
    
        % If PBCH decoding is not successful, go to next iteration of for-
        % loop
        if ~CellRefP
            fprintf("  No PBCH detected for frame = %d.\n",frame);
            continue;
        end
    
        % With successful PBCH decoding, decode the MIB and obtain system
        % information including system bandwidth
        enb = lteMIB(mib,enb);
        enb.CellRefP = CellRefP; % From ltePBCHDecode
        % Incorporate the nfmod4 value output from the function
        % ltePBCHDecode, as the NFrame value established from the MIB is
        % the system frame number modulo 4.
        enb.NFrame = enb.NFrame+nfmod4;
        fprintf("  Successful MIB Decode.\n")
        fprintf("  Frame number: %d.\n",enb.NFrame);
    
        % The eNodeB transmission bandwidth can be greater than the
        % captured bandwidth, so limit the bandwidth for processing
        enb.NDLRB = min(enbDefault.NDLRB,enb.NDLRB);
    
        % Process subframes within frame
        for sf = 0:9
            % Extract subframe
            enb.NSubframe = sf;
            rxsf = rxGrid_short(:,frame*LFrame+sf*Lsf+(1:Lsf));
    
            % Perform channel estimation with the correct number of
            % CellRefP
            [hestsf,nestsf] = lteDLChannelEstimate(enb,cec,rxsf);
    
            % Physical CFI channel (PCFICH) demodulation Extract REs
            % corresponding to the PCFICH from the received grid and
            % channel estimate for demodulation.
            pcfichIndices = ltePCFICHIndices(enb);
            [pcfichRx,pcfichHest] = lteExtractResources(pcfichIndices,rxsf,hestsf);
            [cfiBits,recsym] = ltePCFICHDecode(enb,pcfichRx,pcfichHest,nestsf);
    
            % CFI decoding
            enb.CFI = lteCFIDecode(cfiBits);
            fprintf("    Subframe %d, decoded CFI value: %d.\n",sf,enb.CFI);
    
            % PDCCH demodulation. Extract REs corresponding to the PDCCH
            % from the received grid and channel estimate for demodulation.
            pdcchIndices = ltePDCCHIndices(enb);
            [pdcchRx,pdcchHest] = lteExtractResources(pdcchIndices,rxsf,hestsf);
            [pdcchBits,pdcchEq] = ltePDCCHDecode(enb,pdcchRx,pdcchHest,nestsf);
    
            release(constellation);
            constellation(pdcchEq);
        end
    
    %     % Plot channel estimate between CellRefP 0 and the receive antenna
    %     focalFrameIdx = frame*LFrame+(1:LFrame);
    %     figure(channelEstimatePlot);
    %     surf(abs(hest(:,focalFrameIdx,1,1)));
    %     xlabel("OFDM Symbol Index");
    %     ylabel("Subcarrier Index");
    %     zlabel("Magnitude");
    %     title("Estimate of Channel Magnitude Frequency Response");
    end
end

save(saveToFile, "hest_long");
figure(1);
% s = surf(abs(hest_long(1:1:end,1:1:end,1,1)));
s = surf(abs(hest(1:1:end,1:1:end,1,1)));
s.EdgeColor = 'none';
xlabel("OFDM Symbol Index");
ylabel("Subcarrier Index");
zlabel("Magnitude");
title("Estimate of Channel Magnitude Frequency Response");


if rxsim.ReceiveOnSDR
    release(sdrReceiver);
end
release(constellation);  % Release constellation diagram object

%% Local Functions
function waveform = captureWaveform(sdrReceiver,numSamplesToCapture)
% CAPTUREWAVEFORM returns a column vector of complex values given an
% SDRRECEIVER object and a scalar NUMSAMPLESTOCAPTURE value.
% For a comm.SDRuReceiver object, use the burst capture technique to
% acquire the waveform
    if isa(sdrReceiver,'comm.SDRuReceiver')
        waveform = complex(zeros(numSamplesToCapture,length(sdrReceiver.ChannelMapping)));
        samplesPerFrame = sdrReceiver.SamplesPerFrame;
        for i = 1:sdrReceiver.NumFramesInBurst
            waveform(samplesPerFrame*(i-1)+(1:samplesPerFrame),:) = sdrReceiver();
        end
    else
        waveform = capture(sdrReceiver,numSamplesToCapture);
    end
end