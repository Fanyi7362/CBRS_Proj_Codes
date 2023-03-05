function [mcr, f] = hGetUSRPRateInformation(platform,sampleRate)
% HGETUSRPRATEINFORMATION function provides the master clock rate and the
% interpolation/decimation factor given a USRP platform and a desired
% sampleRate. If the sample rate is not realizable using the provided
% platform then an error is thrown informing the user of this. See
% comm.SDRuTranmitter or comm.SDRuReceiver documentation pages for further
% information on supported master clock rates and interpolation/decimation
% factors.
switch platform
    case 'N200/N210/USRP2'
        masterClockRate = 100e6;
        factor = [4:128 130:2:256 260:4:512];

    case {'N300', 'N310'}
        masterClockRate = [122.88e6 125e6 153.6e6];
        factor = [1:4 6:2:128 130:2:256 260:4:512 520:8:1024];

    case 'N320/N321'
        masterClockRate = [200e6 245.76e6 250e6];
        factor = [1:4 6:2:128 130:2:256 260:4:512 520:8:1024];

    case {'B200', 'B210'}
        minMasterClockRate = 5e6;
        maxMasterClockRate = 56e6;
        masterClockRate = minMasterClockRate:1e3:maxMasterClockRate;
        factor = [1:128 130:2:256 260:4:512];

    case {'X300', 'X310'}
        masterClockRate = [184.32e6 200e6];
        factor = [1:128 130:2:256 260:4:512];

    otherwise
        masterClockRate = nan;
        factor = nan;
end

possibleSampleRates = masterClockRate'./factor;
% do not consider smaller sample rates, to satisfy Nyquist:
possibleSampleRates(possibleSampleRates<sampleRate) = NaN;

err = abs(possibleSampleRates - sampleRate);
minErr = min(err,[],"all");
if isnan(minErr)
    error("lte:error","The sample rate %.2g is not realizable using the %s radio.",sampleRate,platform);
end

[idx1, idx2] = find(err==minErr);
mcr = masterClockRate(idx1(1));
f = factor(idx2(1));
end