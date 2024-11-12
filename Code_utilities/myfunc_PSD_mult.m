function [PSD_mult] = myfunc_PSD_mult(pxx, freq, max_freq, emg_freq_split)
    % pxx in channels (or components) X PSD 
        max_index = find(freq>=max_freq,1);
        split_index = find(freq>=emg_freq_split, 1);
        power_all = sum(pxx(:,1:max_index), 2);
        power_above = sum(pxx(:,split_index:max_index), 2);
        PSD_mult = power_above./power_all;

end