function [Relative_spectral_speech, Relative_spectral_nonspeech, Relative_spectral_labels_speech, Relative_spectral_labels_nonspeech] = myfunc_get_spectral_relatives(pxx_pre_speech, pxx_pre_nonspeech, pxx_clean_speech, pxx_clean_nonspeech, frequency_indices, frequency_names, freq)

%indices must be a list of tuples
%names must match the length of indices

Relative_spectral_speech = [];
Relative_spectral_nonspeech = [];
Relative_spectral_labels_speech = [];
Relative_spectral_labels_nonspeech = [];

total_power_pre_speech = mean(bandpower(mean(pxx_pre_speech, 2),freq,[0.01, 100],'psd'));
total_power_pre_nonspeech = mean(bandpower(mean(pxx_pre_nonspeech, 2),freq,[0.01, 100],'psd'));
total_power_clean_speech = mean(bandpower(mean(pxx_clean_speech, 2),freq,[0.01, 100],'psd'));
total_power_clean_nonspeech = mean(bandpower(mean(pxx_clean_nonspeech, 2),freq,[0.01, 100],'psd'));

for i = 1:size(frequency_indices, 1)
    temp_indices = frequency_indices(i, :);
    ind1 = temp_indices(1);
    ind2 = temp_indices(2);
    
    temp_speech_pre_rel_bandpower = mean(bandpower(mean(pxx_pre_speech, 2),freq,[ind1, ind2],'psd'))/total_power_pre_speech;
    temp_nonspeech_pre_rel_bandpower = mean(bandpower(mean(pxx_pre_nonspeech, 2),freq,[ind1, ind2],'psd'))/total_power_pre_nonspeech;
    temp_speech_clean_rel_bandpower = mean(bandpower(mean(pxx_clean_speech, 2),freq,[ind1, ind2],'psd'))/total_power_clean_speech;
    temp_nonspeech_clean_rel_bandpower = mean(bandpower(mean(pxx_clean_nonspeech, 2),freq,[ind1, ind2],'psd'))/total_power_clean_nonspeech;

    Relative_spectral_speech = [Relative_spectral_speech; (temp_speech_clean_rel_bandpower - temp_speech_pre_rel_bandpower)/temp_speech_pre_rel_bandpower];
    Relative_spectral_nonspeech = [Relative_spectral_nonspeech; (temp_nonspeech_clean_rel_bandpower - temp_nonspeech_pre_rel_bandpower)/temp_nonspeech_pre_rel_bandpower];
    Relative_spectral_labels_speech = [Relative_spectral_labels_speech; string("Relative_spectral_speech_" + frequency_names(i))];
    Relative_spectral_labels_nonspeech = [Relative_spectral_labels_nonspeech; string("Relative_spectral_nonspeech_" + frequency_names(i))];
end
                        