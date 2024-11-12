clear;clc;eeglab;

subject_names = ["Sbj1", "Sbj2", "Sbj3", "Sbj4", "Sbj5", "Sbj6", "Sbj7", "Sbj8", "Sbj9", "Sbj10"];
sessions_counts = [2, 1, 1, 1, 1, 1, 1, 1, 2, 1];
block_counts = [4, 4, 6, 4, 6, 4, 4, 4, 4, 3];

EMG_removal_types = ["CCA", "ICA", "EEMD_CCA", "EEMD_alone", "EEMD_ICA"];

testing = 1;

steps_on.do_clustering = 0;
steps_on.do_RMSE = 1;
steps_on.do_spectral = 1;
steps_on.plot_PSDs = 0;
performance_summary = struct;

for pp = 1:length(subject_names)
    
    subject_name = subject_names(pp);
    total_block_count = block_counts(pp);
    total_session_count = sessions_counts(pp);
    subject_label = anon_names(pp);
    
    for qq = 1:total_session_count
        
        for ll = 1:total_block_count


            
            clearvars -except qq pp ll anon_names subject_label subject_names sessions_counts block_counts subject_name total_block_count total_session_count metrics steps_on EMG_removal_types testing
    
            %% Set Variables
            
            session_number = qq;
            block_number = ll;
            folder_name_preprocessed_EEG        = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Preprocessed_test/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/"); % Name of the file
            folder_name_preprocessed_EMG        = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EMG_Preprocessed_test/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/"); % Name of the file
            events_save_file = char("D:/Speech_Collection/Subject_data/" + subject_name + "/Events/Events_speech_" + num2str(session_number) + '_' + num2str(block_number) + '.csv');

            disp('session number ' + string(session_number) + '; block number ' + string(block_number))
            
             %% Load Preprocessed Data and Events
            
            file_name = char("Block_" + num2str(block_number) + ".set"); 
            EEG_pre = pop_loadset( file_name, folder_name_preprocessed_EEG);
            EMG_pre = pop_loadset( file_name, folder_name_preprocessed_EMG);
            speech_events = readmatrix(events_save_file);
               
            indices_speech = [];
            indices_non_speech = [];

            for i=1:2:length(speech_events)
                
                indices_speech = [indices_speech speech_events(i,2):speech_events(i+1,2)];
                indices_non_speech = [indices_non_speech speech_events(i+1,2): (speech_events(i+1,2) + (speech_events(i+1,2) - speech_events(i,2)))];
                
            end
            
            disp('Preprocessed Data and Events loaded')
            
            %% Set Cleaning Method Variables
            
            for l = 1:length(EMG_removal_types)
                
                EMG_removal_type = EMG_removal_types(l);

                if testing == 1
                    test_option = "_final5";
                else
                    test_option = "";
                end


                if EMG_removal_type == "No_clean"
        
                    identifiers = [""];
                    cleaning_base = "/EEG_Preprocessed_test/";
                    
                else
                   [totalData,identifiers,raw] = xlsread(char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/" + EMG_removal_type + "/" + EMG_removal_type + "_identifiers.csv"));
                    cleaning_base = "/EEG_Cleaned" + test_option + "/" + EMG_removal_type + "/";
        
                end
                
                %% Load data and compute all Metrics
                
                for x = 1:length(identifiers)
                    
                    folder_name_cleaned_EEG        = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/" + EMG_removal_type + "/Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/"); % Name of the folder
                    
                    file_name = char(identifiers{x,1} + "Block_" + num2str(block_number) + ".set");
                    EEG_clean = pop_loadset( file_name, folder_name_cleaned_EEG);
                    
                    nw          = 4; % time-bandwidth product parameter
                    freq        = 0:0.1:EEG_pre.srate/2; % frequencies of interest   
                    pxx_pre_speech = pmtm(EEG_pre.data(:,indices_speech)',nw,freq,EEG_pre.srate);
                    pxx_pre_nonspeech = pmtm(EEG_pre.data(:,indices_non_speech)',nw,freq,EEG_pre.srate);
        
                    %% Spectral RMSE

                    freq_indice = 30;

                    freq_indice_delta = 4;
                    freq_indice_theta = 8;
                    freq_indice_alpha = 12;
                    freq_indice_beta = 31;
                    freq_indice_lowgamma = 50;
                    freq_indice_all = 100;
                    
                    
                    if steps_on.do_spectral == 1
                        

                        pxx_clean_speech = pmtm(EEG_clean.data(:,indices_speech)',nw,freq,EEG_clean.srate);
                        pxx_clean_nonspeech = pmtm(EEG_clean.data(:,indices_non_speech)',nw,freq,EEG_clean.srate);

                       if steps_on.plot_PSDs ==1
                            figure;
                            plot(freq, 10.*log10(mean(pxx_pre_speech(:,:), 2)),'linewidth',1.5)
                            hold on
                            plot(freq, 10.*log10(mean(pxx_clean_speech(:,:), 2)),'linewidth',1.5)
                            hold on
                            plot(freq, 10.*log10(mean(pxx_pre_nonspeech(:,:), 2)),'linewidth',1.5)
                            hold on
                            plot(freq, 10.*log10(mean(pxx_clean_nonspeech(:,:), 2)),'linewidth',1.5)
                           
                            title('Speech PSD Comparison for ' + subject_label + '; Session ' + string(session_number) + '; Block ' + string(block_number))
                            legend( 'PSD-preprocessed - Speech', 'PSD-cleaned - Speech','PSD-preprocessed - NonSpeech', 'PSD-cleaned - NonSpeech')
                            hold off

                        end




                        frequency_indices = [[0.1,freq_indice]; ...
                            [freq_indice, freq_indice_all];...
                            [1, freq_indice_delta];...
                            [freq_indice_delta, freq_indice_theta];...
                            [freq_indice_theta, freq_indice_alpha];...
                            [freq_indice_alpha, freq_indice_beta];...
                            [freq_indice_beta, freq_indice_lowgamma];...
                            [freq_indice_lowgamma, freq_indice_all]];
                            
                        frequency_names = ["lower"; ...
                            "upper";...
                            "delta";...
                            "theta";...
                            "alpha";...
                            "beta";...
                            "low_gamma";...
                            "upper_gamma"];

                        [RMSE_spectral_speech, RMSE_spectral_nonspeech, RMSE_spectral_labels_speech, RMSE_spectral_labels_nonspeech] = myfunc_get_spectral_RMSE(pxx_pre_speech, pxx_pre_nonspeech, pxx_clean_speech, pxx_clean_nonspeech, frequency_indices, frequency_names, freq);


                        [Relative_spectral_speech, Relative_spectral_nonspeech, Relative_spectral_labels_speech, Relative_spectral_labels_nonspeech] = myfunc_get_spectral_relatives(pxx_pre_speech, pxx_pre_nonspeech, pxx_clean_speech, pxx_clean_nonspeech, frequency_indices, frequency_names, freq);
   
                    %% Conditional RMSE

                        RMSE_speech = mean(sqrt(mean((EEG_pre.data(:,indices_speech)-EEG_clean.data(:,indices_speech)).^2,2)),1);
                        RMSE_non_speech = mean(sqrt(mean((EEG_pre.data(:,indices_non_speech)-EEG_clean.data(:,indices_non_speech)).^2,2)),1);
                        RMSE_ratio = RMSE_speech/RMSE_non_speech;
                        RMSE_difference = RMSE_speech - RMSE_non_speech;

                        RMSE_signal = [RMSE_speech; RMSE_non_speech; RMSE_ratio; RMSE_difference];
                        RMSE_signal_labels = ["RMSE_signal_speech"; "RMSE_signal_nonspeech"; "RMSE_signal_ratio"; "RMSE_signal_difference"];

                    %% Correlation to EMG
                        reconstructed_arti = EEG_pre.data - EEG_clean.data;    
                    
                        chan_locs = EEG_pre.chanlocs;
                        reconstructed_arti_power = mean(reconstructed_arti.^2,2);

                        chan_select = 29; %FP2
                        %chan_select = 1:61;

                        regression_model = fitlm(double(mean(reconstructed_arti(chan_select,:),1)), double(EMG_pre.data(1,:)));
                        R_squared = regression_model.Rsquared.Adjusted;

                        correlation_matrix1 = corrcoef(mean(reconstructed_arti(chan_select,:),1), EMG_pre.data(1,:));
                        correlation_matrix2 = corrcoef(mean(reconstructed_arti(chan_select,:),1), EMG_pre.data(2,:));

                        correlation_value = mean([correlation_matrix1(1,2), correlation_matrix2(1,2)]);

                        %figure; topoplot(reconstructed_arti_power, chan_locs); title("Average Power for Reconstructed Artifact")

                        Average_power_recon = mean(reconstructed_arti_power, 1);
                        max_power_recon = max(reconstructed_arti_power);
                       

                    %% Save to metrics structure

                        metrics.(subject_name).(EMG_removal_type).("Session_"+num2str(session_number)).("Block_" + num2str(block_number))(x,:) = [identifiers(x),...
                            num2cell(RMSE_signal'), R_squared, correlation_value,Average_power_recon,max_power_recon,...
                            num2cell(RMSE_spectral_speech'), num2cell(RMSE_spectral_nonspeech'), num2cell(Relative_spectral_speech'), num2cell(Relative_spectral_nonspeech')];
                    
                    end

                end
            end
        end
    end

    %% Collect average metrics (over sessions/blocks)
    
    cleaning_types = fieldnames(metrics.(subject_name));
    variable_names = [cellstr(RMSE_signal_labels'), "EMG-R-squared", "EMG-Correlation_value","Average_recon_power", "Max_recon_power",...
        cellstr(RMSE_spectral_labels_speech'), cellstr(RMSE_spectral_labels_nonspeech'),...
        cellstr(Relative_spectral_labels_speech'), cellstr(Relative_spectral_labels_nonspeech')];
    
    for p = 1:length(cleaning_types)
        
        session_names = fieldnames(metrics.(subject_name).(string(cleaning_types(p))));
        temp = 0;
        
        for m = 1:length(session_names)
            block_names = fieldnames(metrics.(subject_name).(string(cleaning_types(p))).(string(session_names(m))));
            for n = 1:length(block_names)
                temp = temp + str2double(string(metrics.(subject_name).(string(cleaning_types(p))).(string(session_names(m))).(string(block_names(n)))(:,2:length(variable_names)+1)));
                temp_labels = metrics.(subject_name).(string(cleaning_types(p))).(string(session_names(m))).(string(block_names(n)))(:,1);
            end
        end
        
        performance_summary.(subject_name).(string(cleaning_types(p))) = array2table((temp/(length(session_names)*length(block_names))), 'VariableNames', variable_names, 'RowNames', temp_labels);
        
        if steps_on.do_clustering==1
            % Getting clustering metrics
            cluster_cleaning_indeces = find(~cellfun(@isempty,strfind(string(clustering_metrics.Properties.RowNames), string(cleaning_types(p)))));
            temp_cluster_info = clustering_metrics(cluster_cleaning_indeces, :);
            performance_summary.(subject_name).(string(cleaning_types(p))) = [performance_summary.(subject_name).(string(cleaning_types(p))), temp_cluster_info];
        end
    end

    save(char("C:\Users\arcraik\Dropbox\Speech\Code_rev2\Matlab_Code\Performance_summaries\" + subject_name + "\performance_summary_" + date + ".mat"), 'performance_summary')
    disp('Performance Saved')
end
        


    
     
        
                
