% Define the COM port and Baud rate
port = "COM4";  % replace with your port
baudrate = 9600;

% Create a serial port object
s = serialport(port, baudrate);

% Set the read timeout to 10 seconds
configureTerminator(s,"CR/LF");
s.Timeout = 10;

% Initialize an empty array to store the timestamps
timestamps = [];

% Read data from the serial port for 1 minute
tic;  % start a timer
while toc < 10  % run for 10 seconds
    if s.NumBytesAvailable > 0  % if there's data to read
        data = readline(s);  % read the data
        timestamps = [timestamps; str2double(data)];  % convert to double and store in the array
    end
end

% Close the serial port
delete(s);

figure(1)
h = histogram(timestamps);