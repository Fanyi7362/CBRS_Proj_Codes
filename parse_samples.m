samples = h_read_complex_binary("rx_samples1.bin");
len_samps = length(samples);
samples_amp = abs(samples(1:10:end));
samples_fft = fft(samples(1:10:end));
% samples_fft(1:end/50) = 1;
samples_fftamp = abs(fftshift(samples_fft));
samples_amp = abs(ifft(samples_fft));
samples_pha = angle(samples(1:10:end));
figure(1)
plot(1:length(samples_amp), samples_amp);
figure(2)
plot(1:length(samples_fftamp), samples_fftamp); 
figure(3)
xlabel('Sample Index')
ylabel('phase')
set(gca,'Fontsize',12);
set(gca, 'FontName', 'Times New Roman')
plot(1:length(samples_pha), samples_pha, 'lineWidth', 0.5, 'LineStyle', '-', 'Color', [0 0 0]);hold on
% text(0.6, 95,'90%', 'FontSize',22, 'Color', [0.3 0.3 0.3], 'FontName', 'Times New Roman')
% legend({'Idle','Idle-Connected','Connected'},'Fontsize',24,'NumColumns',3)
% yticks([0:25:100])
% xlim([0.5 3.5])
figure(4)
plot(1:length(samples_pha)/50, unwrap(samples_pha(1:end/50))); 