clear;clc;eeglab;

subject_names = ["Sbj1", "Sbj2", "Sbj3", "Sbj4", "Sbj5", "Sbj6", "Sbj7", "Sbj8", "Sbj9", "Sbj10"];
sessions_counts = [2, 1, 1, 1, 1, 1, 1, 1, 2, 1];
block_counts = [4, 4, 6, 4, 6, 4, 4, 4, 4, 3];

do_hinf = 1;
do_CAR = 0;
do_lpf = 1;
sanity_test = 1;
ASR_on_off = 0;
testing_on = 1;

for pp = 1:length(subject_names)
    
    subject_name = subject_names(pp);

    if strcmp(subject_name, "Alberto")
        use_baseline = 0;
    else
        use_baseline = 1;
    end

    subject_label = anon_names(pp);
    
    total_block_count = block_counts(pp);

    total_session_count = sessions_counts(pp);

    for qq = 1:total_session_count

        session_number = qq;
        
        
        for ll = 1:total_block_count
            
            clearvars -except qq pp ll total_session_count sessions_counts total_block_count block_counts subject_name subject_names do_hinf do_CAR do_lpf session_number sanity_test ASR_on_off testing_on subject_label anon_names use_baseline
    
            %% Set Variables
            
            block_number = ll;
            disp('session number ' + string(session_number) + '; block number ' + string(block_number))
            folder_name        = "D:/Speech_Collection/Subject_data/" + subject_name + "/EEG/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/"; % Name of the file

             %% Load Data
            
            vhdr_file = "Block_" + num2str(block_number) + ".vhdr"; 
            [EEG, com] = pop_loadbv(folder_name, vhdr_file);
            disp(char("Data loaded for " + subject_name))
            
            %% Grab audio before downsampling
    
            events = struct2table(EEG.event);
            final_row = find(strcmp( events.code, 'Stimulus' ), 1, 'last');
            final_timepoint = events.latency(final_row)+25000;
            EEG = pop_select(EEG, 'point', [1, final_timepoint]);

            Audio = pop_select(EEG, 'channel',find(strcmp({EEG.chanlocs.labels}, 'Stimtrak')==1));
            EEG = pop_select(EEG, 'nochannel',find(strcmp({EEG.chanlocs.labels}, 'Stimtrak')==1));
            
            %% Downsample
            % EEGlab resample also does LPF (so reduced anti-aliasing effects)
            Fs_new = 200;
            EEG         = pop_resample(EEG,Fs_new); 
            EEG.data    = double(EEG.data);

            disp('Downsampled')
    
            %% High Pass filter
    
            if sanity_test == 1
                tempEEG = pop_select(EEG, 'nochannel',[find(strcmp({EEG.chanlocs.labels}, 'O1')==1),find(strcmp({EEG.chanlocs.labels}, 'O2')==1), find(strcmp({EEG.chanlocs.labels}, 'HEOG')==1),find(strcmp({EEG.chanlocs.labels}, 'VEOG')==1)]);
                EEG1_b4_HPF = tempEEG.data;
                clearvars tempEEG
            end


            Fc_hpf      = 0.1; % Cut off frequency
            filt_order  = 4;     
            [a,b]       = butter(filt_order,Fc_hpf/(EEG.srate/2),'high');
            EEG.data    = filtfilt(a,b,double(EEG.data)')'; 
    
            disp('High pass filtered')
           
            %% Grab HEOG and VEOG from EEG data
            
            eyes = pop_select(EEG, 'channel',[find(strcmp({EEG.chanlocs.labels}, 'HEOG')==1),find(strcmp({EEG.chanlocs.labels}, 'VEOG')==1)]);

            EEG = pop_select(EEG, 'nochannel',[find(strcmp({EEG.chanlocs.labels}, 'HEOG')==1),find(strcmp({EEG.chanlocs.labels}, 'VEOG')==1)]);

            %% Line Noise Removal 
           
            if sanity_test == 1
                tempEEG = pop_select(EEG, 'nochannel',[find(strcmp({EEG.chanlocs.labels}, 'O1')==1),find(strcmp({EEG.chanlocs.labels}, 'O2')==1), find(strcmp({EEG.chanlocs.labels}, 'HEOG')==1),find(strcmp({EEG.chanlocs.labels}, 'VEOG')==1)]);
                EEG2_b4_LN = tempEEG.data;
                clearvars tempEEG
            end

            % Notch filter to remove power line noise from passive EOG
            % electrodes (we are only using EOG to remove eye blinks, so we
            % want to get rid of ALL power line noise)
            Q_fact   = 20;
            Fc       = 60;
            wo       = Fc/(eyes.srate/2);  
            bw = wo/Q_fact;
            [b,a]    = iirnotch(wo,bw); 
            eyes.data = filtfilt(b,a,double(eyes.data'))'; 
                        
            % Zapline to remove power line from EEG data (so we can
            % preserve gamma for EEG
            EEG.data = double(EEG.data);
            EEG      = clean_data_with_zapline_plus_eeglab_wrapper(EEG,...
                                                          struct('noisefreqs','line'));
            EEG.data = double(EEG.data);

            disp('Zapline done');

            %% H-inf

            if sanity_test == 1
                tempEEG = pop_select(EEG, 'nochannel',[find(strcmp({EEG.chanlocs.labels}, 'O1')==1),find(strcmp({EEG.chanlocs.labels}, 'O2')==1), find(strcmp({EEG.chanlocs.labels}, 'HEOG')==1),find(strcmp({EEG.chanlocs.labels}, 'VEOG')==1)]);
                EEG3_b4_HI = tempEEG.data;
                clearvars tempEEG
            end

            HEOG = pop_select(eyes, 'channel',find(strcmp({eyes.chanlocs.labels}, 'HEOG')==1));
            VEOG = pop_select(eyes, 'channel',find(strcmp({eyes.chanlocs.labels}, 'VEOG')==1));

            if do_hinf==1
                
                hinf_p0_init = 0.5;      
                gamma = 1.15; 
                q = 3.5*10^-9; %200 Hz - 3.5*10^-9
                EEG = myfunc_hinf(EEG, VEOG, HEOG, hinf_p0_init, gamma, q);

            end
            
            if (subject_name=='Isra' && session_number==1)
                EEG = pop_runica(EEG, 'icatype', 'sobi');
                EEG = pop_iclabel(EEG,'default');
                EEG = pop_icflag(EEG,[NaN NaN;NaN NaN;0.4 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
                EEG = pop_subcomp(EEG, find(EEG.reject.gcompreject), 0);
            end
            
            %% Low Pass filter (EEGLab resampling already includes LPF filter at half desired sampling rate)
            
            if sanity_test == 1
                tempEEG = pop_select(EEG, 'nochannel',[find(strcmp({EEG.chanlocs.labels}, 'O1')==1),find(strcmp({EEG.chanlocs.labels}, 'O2')==1), find(strcmp({EEG.chanlocs.labels}, 'HEOG')==1),find(strcmp({EEG.chanlocs.labels}, 'VEOG')==1)]);
                EEG4_b4_LPF = tempEEG.data;
                clearvars tempEEG
            end        

            if do_lpf == 1
                
                Fc_lpf      = EEG.srate/2 - 1; % Cut off frequency
                [a,b]       = butter(filt_order,Fc_lpf/(EEG.srate/2),'low');  % Create the butterworth filter coefficients
                EEG.data    = filtfilt(a,b,double(EEG.data)')';
                disp('Low pass filtered')   

            end
                        

            %% ASR (for burst removal, removal/interpolation of really bad channels)

            if sanity_test == 1
                tempEEG = pop_select(EEG, 'nochannel',[find(strcmp({EEG.chanlocs.labels}, 'O1')==1),find(strcmp({EEG.chanlocs.labels}, 'O2')==1), find(strcmp({EEG.chanlocs.labels}, 'HEOG')==1),find(strcmp({EEG.chanlocs.labels}, 'VEOG')==1)]);
                EEG5_b4_ASR = tempEEG.data;
                clearvars tempEEG
            end    
            
            EEG_orig = EEG;
            EMG = pop_select(EEG, 'channel',[find(strcmp({EEG.chanlocs.labels}, 'O1')==1),find(strcmp({EEG.chanlocs.labels}, 'O2')==1)]);
            EEG = pop_select(EEG, 'nochannel',[find(strcmp({EEG.chanlocs.labels}, 'O1')==1),find(strcmp({EEG.chanlocs.labels}, 'O2')==1)]);

            if ASR_on_off==1
                
                % Find bad channels
                chancorr_crit = 0.6; %Corr threshold
                line_crit = 100; % Set to 100 as we do not want to remove channels based on line noise
                channel_crit_maxbad_time = 0.4;
                burst_crit = 15; % SD's over mean to remove bursts
                
                [EEG_ASR,removed_channels_1] = clean_channels(EEG,chancorr_crit,line_crit,[],channel_crit_maxbad_time); 

                if ~isempty(find(removed_channels_1))
                    
                    disp("Some channels are below corr threshold. Interpolating these.")
                    disp(string(find(removed_channels_1)))
                    EEG = eeg_interp(EEG, find(removed_channels_1));
                end

                if use_baseline == 1
                    % remove response events
                    EEG_orig.event = EEG_orig.event(~strcmp({EEG_orig.event.code},'Response'));
                    EEG_orig.urevent = EEG_orig.urevent(~strcmp({EEG_orig.urevent.code},'Response'));
    
                    % rest and rest_end will be events 2 and 3
                    rest_start = EEG_orig.event(2).latency;
                    rest_end = EEG_orig.event(3).latency;
    
                    % Get rest data for baseline
                    EEG_baseline = pop_select(EEG_orig, 'point', [rest_start rest_end]);
                    EEG_baseline = pop_select(EEG_baseline, 'nochannel',[find(strcmp({EEG_baseline.chanlocs.labels}, 'O1')==1),find(strcmp({EEG_baseline.chanlocs.labels}, 'O2')==1)]);
                    EEG.data = double(EEG.data);
                    EEG = clean_asr(EEG,burst_crit,[],[],[],EEG_baseline);
                else
                    EEG.data = double(EEG.data);
                    EEG       = clean_artifacts(EEG, 'FlatlineCriterion','off',...  % Remove flatline channels
                    'Highpass','off',... % Keep it off as we already performed high pass filter
                    'ChannelCriterion','off',... % Auto removal of channels
                    'LineNoiseCriterion', 'off',... % Keep it off if dont want to remove channels based on line noise criterion
                    'BurstCriterion',burst_crit, ... % Standard deviation cutoff for removal of bursts; Try modifying this and check if is not cleaning too much/too little
                    'WindowCriterion','off');

                end
            end
            
            %% Common Average Reference
                        
            if sanity_test == 1
                tempEEG = pop_select(EEG, 'nochannel',[find(strcmp({EEG.chanlocs.labels}, 'O1')==1),find(strcmp({EEG.chanlocs.labels}, 'O2')==1), find(strcmp({EEG.chanlocs.labels}, 'HEOG')==1),find(strcmp({EEG.chanlocs.labels}, 'VEOG')==1)]);
                EEG6_b4_CA = tempEEG.data;
                clearvars tempEEG
            end          
            
            if do_CAR ==1
                EEG  = pop_reref(EEG,[]); 
                disp('Common Average Referenced done')
            end

            %% PSD as sanity check

            if sanity_test == 1
                tempEEG = pop_select(EEG, 'nochannel',[find(strcmp({EEG.chanlocs.labels}, 'O1')==1),find(strcmp({EEG.chanlocs.labels}, 'O2')==1), find(strcmp({EEG.chanlocs.labels}, 'HEOG')==1),find(strcmp({EEG.chanlocs.labels}, 'VEOG')==1)]);
                EEG7_final = tempEEG.data;
                clearvars tempEEG
            end   

            %% Saving Blocks
    
            if testing_on == 1 
                testing_option = "_test";
            else
                testing_option = "";
            end

            filepath_EEG = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Preprocessed" + testing_option + "/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
            filepath_EMG = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EMG_Preprocessed" + testing_option + "/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
            filename = char('Block_' + string(block_number));
            pop_saveset(EEG, filename, filepath_EEG);
            pop_saveset(EMG, filename, filepath_EMG);
    
        end
    end
end
        
        
        
                
