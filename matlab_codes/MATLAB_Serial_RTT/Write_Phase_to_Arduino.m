% Set the number of phase values that each Arduino device will receive
phases_per_device = 6;

% Set the number of Arduino devices
n_devices = 8;

% Define the preamble
preamble = uint16(0xAAAA);

ack_success = uint8(0xFF);  % Success acknowledgment
ack_error = uint8(0xAA);  % Error acknowledgment

% Set the timeout in seconds
TIMEOUT = 0.001;

% Generate random phase values
min_phase = 0;  % Define your min phase value
max_phase = 360;  % Define your max phase value

% Loop over each Arduino device
for i = 1:n_devices
    % Define the device name
    device_name = ['/dev/ttyACM', num2str(i)-1];

    % Open the device
    device = serialport(device_name, 460800);
    configureTerminator(device,"CR/LF");
    flush(device);
    
    % Generate phases_per_device number of random phases
    phase_array = arrayfun(@(x) hRandom_phase(min_phase, max_phase), 1:phases_per_device);

    ack = uint8(0x00);
    success = false;

    % Loop until success acknowledgment is received
    while ~success
        flush(device);

        % Get the start time
        start_serial = tic;        
        
        % Write the preamble to the device
        write(device, preamble, "uint16");

        % Loop over each phase value for the current device
        for j = 1:phases_per_device
            % Get the phase value from the generated array
            phase = phase_array(j);
            
            % Convert the phase value to an index
            phase_ind = round(phase / 22.5);

            % Convert the phase value to a binary string
            % Add padding 2 bits at the start and end
            phaseByte = bitshift(uint8(phase_ind), 2);

            % Write the phase value to the device
            write(device, phaseByte, "uint8");
        end

        % Get the current time as the start time
        start = tic;
        
        while true
            % Try to read the ack
            if device.NumBytesAvailable > 0
                ack = read(device, 1, "uint8");
            end

            % If read was successful, break the loop
            if ack ~= 0
                break;
            end

            % If the difference between now and start is greater than the timeout, break the loop
            if toc(start) > TIMEOUT
                disp('Timeout while waiting for acknowledgement');
                break;
            end
        end

        if ack == ack_success
            % Break out of the while loop
            elapsed_time = toc(start_serial);
            % Print the time elapsed in us
            fprintf('Arduino %d Success! Time elapsed: %f us\n', i, elapsed_time * 1e6);
            success = true;
        elseif ack == ack_error
            elapsed_time = toc(start_serial);
            fprintf('Arduino %d Fail! Time elapsed: %f us\n', i, elapsed_time * 1e6);
        else
            fprintf("Unexpected response from device: %02X\n", ack);
        end
    end

    % Clear device
    % device = [];
end