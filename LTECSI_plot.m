% load('LTE_trace')

figure(2);
% s = surf(abs(hest_long(1:12:end,1:14:end,1,1)));
% phase_diff = angle(hest_array(301:900,:,1,1)) -angle(hest_array(301:900,:,2,1));
% s = surf(unwrap(phase_diff) );
s = surf(abs(hest_array(301:900,:,1,1)));
s.EdgeColor = 'none';
xlabel("OFDM Symbol Index");
ylabel("Subcarrier Index");
zlabel("Magnitude");
title("Estimate of Channel Magnitude Frequency Response");