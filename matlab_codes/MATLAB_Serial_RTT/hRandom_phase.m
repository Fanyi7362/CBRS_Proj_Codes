function phase = hRandom_phase(min, max)
    imin = floor(min / 22.5);
    imax = floor(max / 22.5);
    irandom = floor((imax - imin + 1) .* rand() + imin);
    phase = irandom * 22.5;
end