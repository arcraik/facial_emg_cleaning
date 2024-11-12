function [corrs] = myfunc_auto_corr(signal_array)
    % signal array in channels (or components) by time
    for cv = 1:size(signal_array,1)
       autocc = abs(autocorr(signal_array(cv,:)));
       corrs(cv,:) = autocc(1,2);
    end

end
