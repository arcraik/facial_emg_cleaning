clear; clc; eeglab;

subject_names = ["Sbj1", "Sbj2", "Sbj3", "Sbj4", "Sbj5", "Sbj6", "Sbj7", "Sbj8", "Sbj9", "Sbj10"];
sessions_counts = [2, 1, 1, 1, 1, 1, 1, 1, 2, 1];
block_counts = [4, 4, 6, 4, 6, 4, 4, 4, 4, 3];

saving_on = 1;

for pp = 1:length(subject_names)
    
    subject_name = subject_names(pp);
    total_block_count = block_counts(pp);
    total_session_count = sessions_counts(pp);
    
    for yy = 2%1:total_session_count
        
        session_number = yy;
        
        %% Set save folders for audio and MFCC's
        
        Audio_save = "D:/Speech_Collection/Subject_data/" + subject_name + "/Audio/";
        MFCC_save = "D:/Speech_Collection/Subject_data/" + subject_name + "/MFCC/" + "Session_" + num2str(session_number);

        for x =1:total_block_count
            %% Load Data
                        
            block_number = x;
            folder_name        = "D:/Speech_Collection/Subject_data/" + subject_name + "/EEG/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/"; % Name of the file
            vhdr_file = "Block_" + num2str(block_number) + ".vhdr";
            [EEG, com] = pop_loadbv(folder_name, vhdr_file);
            Audio = pop_select(EEG, 'channel',find(strcmp({EEG.chanlocs.labels}, 'Stimtrak')==1));

            clear EEG
                        
            %% High pass filter
            
            Fc_hpf      = 80; 
            filt_order  = 4;     
            [a,b]       = butter(filt_order, Fc_hpf/(Audio.srate/2),'high');
            Audio_filtered    = filtfilt(a,b,double(Audio.data)')'; 
            
            %% Low pass filter
            
            Fc_lpf      = 5000; 
            [a,b]       = butter(filt_order,Fc_lpf/(Audio.srate/2),'low');  
            Audio_filtered    = filtfilt(a,b,double(Audio_filtered)')';
                        
            %% Save block audio
            
            Audio_filtered_normalized = Audio_filtered/max(Audio_filtered);
            audiowrite(Audio_save + "Session_" + num2str(session_number) + "_Block_" + num2str(block_number) + '_filtered.wav', Audio_filtered_normalized, Audio.srate)
            
            %% Extract and save MFCC
            
            fs_m = 200;
            %window = hamming(fs/fs_m); %no overlap
            %overlap = 0;
            window = hamming((3*size(Audio_filtered_normalized', 1))/(size(Audio_filtered_normalized', 1)*fs_m/Audio.srate-1)); %This is for o/w = 2/3
            overlap = 2/3*numel(window);
            MFCCs = mfcc(Audio_filtered_normalized',Audio.srate, NumCoeffs=24, OverlapLength=overlap, Window=window);
            writematrix(MFCCs,MFCC_save +"/Block_" + num2str(block_number) + '/MFCC' + num2str(session_number) + '_' + num2str(block_number) + '.csv')
    
            %% Remove Response Events
            
            Audio.event = Audio.event(~strcmp({Audio.event.code},'Response'));
            Audio.urevent = Audio.urevent(~strcmp({Audio.event.code},'Response'));
    
            %% Sentences for protocol
            
            base_sentences = myfunc_grab_sentences();
            
            %% Sentence Text File and Single Sentence Audio Saving
            if saving_on==1
                myfunc_save_txt_aud_summaries(Audio, Audio_filtered_normalized, session_number, block_number, Audio_save, base_sentences, subject_name);
            end
        end
    end
end
