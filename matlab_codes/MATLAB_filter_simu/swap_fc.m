function [data] = swap_fc(freq, data, fc)
    idx_ctr = findNearest(freq, fc);

    temp1 = data(idx_ctr+40:1:idx_ctr+121);
    temp2 = data(idx_ctr-40:-1:idx_ctr-121);
    [~, idx] = min(abs(temp2-temp1),[],2);

    idx_st = idx_ctr-40-idx;
    idx_ed = idx_ctr+40+idx;

    temp = data(idx_ed:-1:idx_st);
    data(idx_st:1:idx_ed) = temp;

end