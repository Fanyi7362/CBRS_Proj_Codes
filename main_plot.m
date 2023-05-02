%% load data
% clear;close all

% csi_folder = './data0921_10total/site1_1805/trace025/csi_log_2020_09_06_19_08_19/';
csi_folder = './data/csi_log_2023_03_12_21_23_43/';

% filename_a1 = 'csi_amp_usrpIdx_0_freq_2355000000_N_-1_PRB_50_TX_4_RX_2.csiLog';
% filename_a2 = 'csi_amp_usrpIdx_1_freq_2355000000_N_-1_PRB_50_TX_4_RX_2.csiLog';
% filename_p1 = 'csi_phase_usrpIdx_0_freq_2355000000_N_-1_PRB_50_TX_4_RX_2.csiLog';
% filename_p2 = 'csi_phase_usrpIdx_1_freq_2355000000_N_-1_PRB_50_TX_4_RX_2.csiLog';

filename_a1 = 'csi_amp_usrpIdx_0_freq_3560000000_N_-1_PRB_50_TX_1_RX_2.csiLog';
filename_p1 = 'csi_phase_usrpIdx_0_freq_3560000000_N_-1_PRB_50_TX_1_RX_2.csiLog';


csi_a1  = load([csi_folder,filename_a1]);
csi_p1  = load([csi_folder,filename_p1]);

n_prb = 50;

%% data prep
amp_1 = reshape(csi_a1,2,[],n_prb);
pha_1 = reshape(csi_p1,2,[],n_prb);

csi_1 = amp_1.*exp(1i.*pha_1);

%% plot
k = 0;
ind = min(size(amp_1,2),size(amp_2,2));
st = round(ind*(k+0)/30)+1;
ed = round(ind*(k+30)/30);
interval = 20;

% figure(1)
% subplot(2,2,1)
% plot_phase_subcarr(pha_1(1,:,:)-pha_1(2,:,:),st,ed,interval);
% xlabel('subcarriers')
% ylabel('TX1RX1')
% set(gca,'Fontsize',20);
% subplot(2,2,2)
% plot_phase_subcarr(pha_1(2,:,:),st,ed,interval);
% xlabel('subcarriers')
% ylabel('TX1RX2') 
% set(gca,'Fontsize',20);
% subplot(2,2,3)
% plot_phase_subcarr(pha_2(1,:,:),st,ed,interval);
% xlabel('subcarriers')
% ylabel('TX2RX1') 
% set(gca,'Fontsize',20);
% subplot(2,2,4)
% plot_phase_subcarr(pha_2(2,:,:),st,ed,interval);
% xlabel('subcarriers')
% ylabel('TX2RX2')
% set(gca,'Fontsize',20);

% figure(2)
% subplot(2,2,1)
% plot_phasediff_subcarr(pha_1(1,:,:),pha_1(2,:,:),st,ed,interval);
% subplot(2,2,2)
% plot_phasediff_subcarr(pha_1(3,:,:),pha_1(4,:,:),st,ed,interval);
% subplot(2,2,3)
% plot_phasediff_subcarr(pha_1(1,:,:),pha_1(3,:,:),st,ed,interval);
% subplot(2,2,4)
% plot_phasediff_subcarr(pha_1(2,:,:),pha_1(4,:,:),st,ed,interval);

% figure(3)
% subplot(2,4,1)
% plot_cfo(pha_11,a,b,interval);
% subplot(2,4,2)
% plot_cfo(pha_12,a,b,interval);
% subplot(2,4,3)
% plot_cfo(pha_13,a,b,interval);
% subplot(2,4,4)
% plot_cfo(pha_14,a,b,interval);
% 
% figure(5)
% subplot(1,4,1)
% plot_amp(amp_2(1,:,:),st,ed,interval);
% subplot(1,4,2)
% plot_amp(amp_2(2,:,:),st,ed,interval);
% subplot(1,4,3)
% plot_amp(amp_2(3,:,:),st,ed,interval);
% subplot(1,4,4)
% plot_amp(amp_2(4,:,:),st,ed,interval);
% 
% figure(6)
% subplot(1,2,1)
% plot_amp(pha_1(1,:,:),st,ed,interval);
% subplot(1,2,2)
% plot_amp(pha_2(2,:,:),st,ed,interval);


%% functions
function plot_amp(amp_all,st,ed,interval)
    amp_all = squeeze(amp_all);
    s = surf(amp_all(st:interval:ed,:)');
%     s = pcolor(amp_all(st:interval:ed,:)');
    s.EdgeColor = 'none';
end

function plot_phase_rmSlope(phase_all,st,ed,interval)
    phase_all = squeeze(phase_all);
    x = 1:100;
    for i=st:interval:ed
        y = unwrap(phase_all(i,:));
%         y = y-y(1);
        p = polyfit(x,y,1);
        new_y = y - x.*p(1);
        new_y = new_y-new_y(50);
        plot(y);hold on
    end
end

function plot_phase_subcarr(phase_all,st,ed,interval)
    phase_all = squeeze(phase_all);
    for i=st:interval:ed
        phase = unwrap(phase_all(i,:));
        plot(phase);hold on
    end
end

function plot_phasediff_subcarr(phase_1,phase_2,st,ed,interval)
    phase_1 = squeeze(phase_1);
    phase_2 = squeeze(phase_2);
    phase_diff = phase_1-phase_2;
    for i=st:interval:ed
        phase = unwrap(phase_diff(i,:));
        plot(phase);hold on
    end
end

function plot_cfo(phase_1,st,ed,interval)

    for i=1:2:100
        ifft_phase_1 = ifft(phase_1(st:interval:ed,i));
        ifft_phase_1 = ifft_phase_1([round(end/2)+1:end,1:round(end/2)]);
        phase = unwrap(ifft_phase_1);
        plot(phase);hold on
    end
    
end