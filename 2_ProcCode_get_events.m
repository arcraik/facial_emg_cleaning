clear;clc;eeglab;

subject_names = ["Sbj1", "Sbj2", "Sbj3", "Sbj4", "Sbj5", "Sbj6", "Sbj7", "Sbj8", "Sbj9", "Sbj10"];
sessions_counts = [2, 1, 1, 1, 1, 1, 1, 1, 2, 1];
block_counts = [4, 4, 6, 4, 6, 4, 4, 4, 4, 3];

do_speech = 0;
do_phonemes = 0;
do_onsets = 1;

for pp = 1:length(subject_names)
    subject_name = subject_names(pp);
    total_block_count = block_counts(pp);
    total_session_count = sessions_counts(pp);
      
    for qq = 1:total_session_count
        for ll = 1:total_block_count
            clearvars -except qq pp ll total_session_count sessions_count sessions_counts total_block_count block_counts subject_name subject_names do_speech do_phonemes do_onsets
    
            %% Set Variables and Folder paths
    
            session_number = qq;
            block_number = ll;
            folder_name = "D:/Speech_Collection/Subject_data/" + subject_name + "/EEG/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/"; % Name of the file
            textgrids_save = "D:/Speech_Collection/Subject_data/" + subject_name + "/Audio/All_textgrids/";
        
            disp('session number ' + string(session_number) + '; block number ' + string(block_number))

             %% Load Data
            
            vhdr_file = "Block_" + num2str(block_number) + ".vhdr"; 
            [EEG, com] = pop_loadbv(folder_name, vhdr_file);
            
            disp('Data loaded')
            
            %% Grab audio before downsampling
    
            Audio = pop_select(EEG, 'channel',find(strcmp({EEG.chanlocs.labels}, 'Stimtrak')==1));
            EEG = pop_select(EEG, 'nochannel',find(strcmp({EEG.chanlocs.labels}, 'Stimtrak')==1));
            
            %% Downsample EEG
    
            Fs_new = 200;
            EEG         = pop_resample(EEG,Fs_new); 
            EEG.data    = double(EEG.data);
            
            disp('Downsampled')
    
            %% Remove bad events
    
            EEG.event = EEG.event(~strcmp({EEG.event.code},'Response'));
            Audio.event = Audio.event(~strcmp({Audio.event.code},'Response'));
            EEG.urevent = EEG.urevent(~strcmp({EEG.urevent.code},'Response'));
            Audio.urevent = Audio.urevent(~strcmp({Audio.urevent.code},'Response'));

            %% Events - Phonemes

            if do_phonemes ==1
                myfunc_save_phon_events(EEG, Audio, session_number, block_number, textgrids_save, subject_name)
            end

            %% Events - Speech

            if do_speech == 1
                
                myfunc_save_speech_events(EEG, Audio, session_number, block_number, textgrids_save, subject_name)
                
            end
            
            %% phoneme onsets
            if do_onsets == 1
                
                myfunc_save_onset_events(EEG, Audio, session_number, block_number, textgrids_save, subject_name)
                
            end
        end
    end
end
        
    
    
    
    
    
        
                
