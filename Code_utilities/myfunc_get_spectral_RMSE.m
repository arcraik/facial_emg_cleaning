function [RMSE_spectral_speech, RMSE_spectral_nonspeech, RMSE_spectral_labels_speech, RMSE_spectral_labels_nonspeech] = myfunc_get_spectral_RMSE(pxx_pre_speech, pxx_pre_nonspeech, pxx_clean_speech, pxx_clean_nonspeech, frequency_indices, frequency_names, freq)

%indices must be a list of tuples
%names must match the length of indices

RMSE_spectral_speech = [];
RMSE_spectral_nonspeech = [];
RMSE_spectral_labels_speech = [];
RMSE_spectral_labels_nonspeech = [];

for i = 1:size(frequency_indices, 1)
    temp_indices = frequency_indices(i, :);
    ind1 = find(freq>=temp_indices(1), 1);
    ind2 = find(freq>=temp_indices(2), 1);
    
    RMSE_spectral_speech = [RMSE_spectral_speech; mean(sqrt(mean(((pxx_pre_speech(ind1:ind2,:)-pxx_clean_speech(ind1:ind2,:)).^2),1)),2)];
    RMSE_spectral_nonspeech = [RMSE_spectral_nonspeech; mean(sqrt(mean(((pxx_pre_nonspeech(ind1:ind2,:)-pxx_clean_nonspeech(ind1:ind2,:)).^2),1)),2)];
    RMSE_spectral_labels_speech = [RMSE_spectral_labels_speech; string("RMSE_spectral_speech_" + frequency_names(i))];
    RMSE_spectral_labels_nonspeech = [RMSE_spectral_labels_nonspeech; string("RMSE_spectral_nonspeech_" + frequency_names(i))];
end
                        