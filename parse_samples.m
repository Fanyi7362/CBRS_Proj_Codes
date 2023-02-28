samples = h_read_complex_binary("rx_samples.npy");
len_samps = length(samples);
samples_amp = abs(samples(1e4:10:end));
samples_fftamp = abs(fftshift(fft(samples(1e4:10:end))));
figure(1)
plot(1e4:10:len_samps, samples_amp);
figure(2)
plot(1e4:10:len_samps, samples_fftamp); 