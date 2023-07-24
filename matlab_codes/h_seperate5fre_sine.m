d_rx1=read_complex_binary("receive1_ping_sine_fband01.ch_0_binary");
d_rx2=read_complex_binary("receive1_ping_sine_fband01.ch_1_binary");

f_band = 1;
ant_1to5 = [912.75, 912.875, 913, 913.125, 913.25];


f_rx1 = fftshift(fft(d_rx1(1+2e6:5e6)));%(1:3e6) is the location of signals
f_rx2 = fftshift(fft(d_rx2(1+2e6:5e6)));%(1:3e6) is the location of signals
len_5M = length(f_rx1); % len_5M--5mHz

nsamps_625k = len_5M/8;
nsamps_125k = len_5M/40;

fc1 = len_5M/10; %913MHz
fc_sine = len_5M*4/10; %914.5MHz
% fc2 = len*3/10;
% fc3 = len*5/10;
% fc4 = len*7/10;
% fc5 = len*9/10;

%get sine signals
f_sine_rx1 = [f_rx1(fc_sine:fc_sine+nsamps_125k/2-1);f_rx1(fc_sine-nsamps_125k/2:fc_sine-1)];
data_sine_rx1 = ifft(f_sine_rx1);
f_sine_rx2 = [f_rx2(fc_sine:fc_sine+nsamps_125k/2-1);f_rx2(fc_sine-nsamps_125k/2:fc_sine-1)];
data_sine_rx2 = ifft(f_sine_rx2);

%get LORA signals at 1st band
f_5ant_fc1_pong_rx1 = [f_rx1(fc1:fc1+nsamps_625k/2-1);f_rx1(fc1-nsamps_625k/2:fc1-1)];
data_5ant_fc1_pong_rx1 = ifft(f_5ant_fc1_pong_rx1);
f_5ant_fc1_pong_rx2 = [f_rx2(fc1:fc1+nsamps_625k/2-1);f_rx2(fc1-nsamps_625k/2:fc1-1)];
data_5ant_fc1_pong_rx2 = ifft(f_5ant_fc1_pong_rx2);


%seperate 5 pongs from 5 antennas at 1st band
%rx1
f_5ant_fc1_pong_rx1 = fftshift(f_5ant_fc1_pong_rx1);
len_625K = length(f_5ant_fc1_pong_rx1); 
nsamps_125k = len_625K/5;

fc_ant50 = len_625K*1/10; %912.75MHz
fc_ant51 = len_625K*3/10; %912.875MHz
fc_ant52 = len_625K*5/10; %913MHz
fc_ant53 = len_625K*7/10; %913.125MHz
fc_ant54 = len_625K*9/10; %913.25MHz

f_ants_fc1_pong_rx1 = zeros(5, nsamps_125k);
data_ants_fc1_pong_rx1 = zeros(5, nsamps_125k);

f_ants_fc1_pong_rx1(1,:) = [f_5ant_fc1_pong_rx1(fc_ant50+1:fc_ant50+nsamps_125k/2);...
    f_5ant_fc1_pong_rx1(fc_ant50-nsamps_125k/2+1:fc_ant50)];
f_ants_fc1_pong_rx1(2,:) = [f_5ant_fc1_pong_rx1(fc_ant51+1:fc_ant51+nsamps_125k/2);...
    f_5ant_fc1_pong_rx1(fc_ant51-nsamps_125k/2+1:fc_ant51)];
f_ants_fc1_pong_rx1(3,:) = [f_5ant_fc1_pong_rx1(fc_ant52+1:fc_ant52+nsamps_125k/2);...
    f_5ant_fc1_pong_rx1(fc_ant52-nsamps_125k/2+1:fc_ant52)];
f_ants_fc1_pong_rx1(4,:) = [f_5ant_fc1_pong_rx1(fc_ant53+1:fc_ant53+nsamps_125k/2);...
    f_5ant_fc1_pong_rx1(fc_ant53-nsamps_125k/2+1:fc_ant53)];
f_ants_fc1_pong_rx1(5,:) = [f_5ant_fc1_pong_rx1(fc_ant54+1:fc_ant54+nsamps_125k/2);...
    f_5ant_fc1_pong_rx1(fc_ant54-nsamps_125k/2+1:fc_ant54)];

data_ants_fc1_pong_rx1(1,:) = ifft(f_ants_fc1_pong_rx1(1,:));
data_ants_fc1_pong_rx1(2,:) = ifft(f_ants_fc1_pong_rx1(2,:));
data_ants_fc1_pong_rx1(3,:) = ifft(f_ants_fc1_pong_rx1(3,:));
data_ants_fc1_pong_rx1(4,:) = ifft(f_ants_fc1_pong_rx1(4,:));
data_ants_fc1_pong_rx1(5,:) = ifft(f_ants_fc1_pong_rx1(5,:));


%seperate 5 pongs from 5 antennas at 1st band
%rx2
f_5ant_fc1_pong_rx2 = fftshift(f_5ant_fc1_pong_rx2);
len_625K = length(f_5ant_fc1_pong_rx2); 
nsamps_125k = len_625K/5;

fc_ant50 = len_625K*1/10; %912.75MHz
fc_ant51 = len_625K*3/10; %912.875MHz
fc_ant52 = len_625K*5/10; %913MHz
fc_ant53 = len_625K*7/10; %913.125MHz
fc_ant54 = len_625K*9/10; %913.25MHz

f_ants_fc1_pong_rx2 = zeros(5, nsamps_125k);
data_ants_fc1_pong_rx2 = zeros(5, nsamps_125k);

f_ants_fc1_pong_rx2(1,:) = [f_5ant_fc1_pong_rx2(fc_ant50+1:fc_ant50+nsamps_125k/2);...
    f_5ant_fc1_pong_rx2(fc_ant50-nsamps_125k/2+1:fc_ant50)];
f_ants_fc1_pong_rx2(2,:) = [f_5ant_fc1_pong_rx2(fc_ant51+1:fc_ant51+nsamps_125k/2);...
    f_5ant_fc1_pong_rx2(fc_ant51-nsamps_125k/2+1:fc_ant51)];
f_ants_fc1_pong_rx2(3,:) = [f_5ant_fc1_pong_rx2(fc_ant52+1:fc_ant52+nsamps_125k/2);...
    f_5ant_fc1_pong_rx2(fc_ant52-nsamps_125k/2+1:fc_ant52)];
f_ants_fc1_pong_rx2(4,:) = [f_5ant_fc1_pong_rx2(fc_ant53+1:fc_ant53+nsamps_125k/2);...
    f_5ant_fc1_pong_rx2(fc_ant53-nsamps_125k/2+1:fc_ant53)];
f_ants_fc1_pong_rx2(5,:) = [f_5ant_fc1_pong_rx2(fc_ant54+1:fc_ant54+nsamps_125k/2);...
    f_5ant_fc1_pong_rx2(fc_ant54-nsamps_125k/2+1:fc_ant54)];

data_ants_fc1_pong_rx2(1,:) = ifft(f_ants_fc1_pong_rx2(1,:));
data_ants_fc1_pong_rx2(2,:) = ifft(f_ants_fc1_pong_rx2(2,:));
data_ants_fc1_pong_rx2(3,:) = ifft(f_ants_fc1_pong_rx2(3,:));
data_ants_fc1_pong_rx2(4,:) = ifft(f_ants_fc1_pong_rx2(4,:));
data_ants_fc1_pong_rx2(5,:) = ifft(f_ants_fc1_pong_rx2(5,:));


%get phase difference of master_sine between rx1 and rx2
[~,ind_max] = max(abs(fft(data_sine_rx1)));
sin_phase_125kband = angle(fft(data_sine_rx1) ./ fft(data_sine_rx2));
sin_phase_diff_1 = sin_phase_125kband(ind_max);

%get phase difference of pongs between rx1 and rx2
chirpMaker;

packet_rx1 = data_ants_fc1_pong_rx1(1,:).';
packet_rx2 = data_ants_fc1_pong_rx2(1,:).';
MASTER_rx1=zeros(1,nsamps_125k-16200);
for ii=1:(nsamps_125k-16200)
    MASTER_rx1(ii) = max(abs(fft(packet_rx1(ii:ii+1024*6-1) .* [repmat(down,4,1);repmat(up,2,1)])))...
        ./mean(abs(fft(packet_rx1(ii:ii+1024*6-1) .* [repmat(down,4,1);repmat(up,2,1)])));
end
[~,a_rx1]=max(MASTER_rx1);
%a_rx1 = 10792;
two_down_chirps_rx1 = (packet_rx1(a_rx1+1024*4:a_rx1+1024*6-1));
two_down_chirps_rx2 = (packet_rx2(a_rx1+1024*4:a_rx1+1024*6-1));

z = angle(two_down_chirps_rx1./two_down_chirps_rx2);
pong_phase_diff = angle(fft(two_down_chirps_rx1) ./ fft(two_down_chirps_rx2));

ang_mean=mean(pong_phase_diff(1025:2048));
tem_fit = [pong_phase_diff(1:512);pong_phase_diff(1537:2048)]; % take a stable part of the phase_diff
ang_line = polyfit([1:512,1537:2048], tem_fit.', 1);

sin_phase_diff_2 = ang_line(2)+ang_line(1)*1024/62.5*(914.5-ant_1to5(1)-f_band+1+0.0625)*10^3;

%get C
C = sin_phase_diff_1-sin_phase_diff_2;


