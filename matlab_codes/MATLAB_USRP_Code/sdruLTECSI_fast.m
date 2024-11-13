%% Connect to Radio
% first go to Add on -> Communications Toolbox Support Package for USRP
% Radio -> to configure the USRP
tic
radioFound = false;
radiolist = findsdru;
for i = 1:length(radiolist)
  if strcmp(radiolist(i).Status, 'Success')
    if strcmp(radiolist(i).Platform, 'B210')
        radio = comm.SDRuReceiver('Platform','B210', ...
                 'SerialNum', radiolist(i).SerialNum);
        radio.MasterClockRate = 1.92e6 * 4; % Need to exceed 5 MHz minimum
        radio.DecimationFactor = 4;         % Sampling rate is 1.92e6
        radioFound = true;
        break;
    end
    if (strcmp(radiolist(i).Platform, 'X300') || ...
        strcmp(radiolist(i).Platform, 'X310'))
        radio = comm.SDRuReceiver('Platform',radiolist(i).Platform, ...
                 'IPAddress', radiolist(i).IPAddress);
        radio.MasterClockRate = 120e6;
        radio.DecimationFactor = 6;        % Sampling rate is 20e6
        radioFound = true;
    end
  end
end

if ~radioFound
    error(message('sdru:examples:NeedMIMORadio'));
end

radio.ChannelMapping = 1;     % Receive signals from both channels
radio.CenterFrequency = 3610000000;
radio.Gain = 30;
radio.SamplesPerFrame = radio.MasterClockRate/radio.DecimationFactor/100; % One frame is 10 ms long
radio.OutputDataType = 'double';
radio.EnableBurstMode = true;
radio.NumFramesInBurst = 100;
radio.OverrunOutputPort = true;

radio

%% Capture Signal

burstCaptures = zeros(radio.SamplesPerFrame, radio.NumFramesInBurst,1); 

len = 0;
for frame = 1:radio.NumFramesInBurst
    while len == 0
        [data,len,lostSamples] = step(radio);
        burstCaptures(:,frame,:) = data;
    end
    len = 0;
end
release(radio);

trace = reshape(burstCaptures,[],1);
sr = radio.SamplesPerFrame * 100 ; % LTE sampling rate

% eNodeBOutput = eNodeBOutput(3e5:end-1e5,:);
eNodeBOutput = trace(5e5:13.5e5);

save('LTE_trace_1940_0327_40','trace','eNodeBOutput','sr')
toc