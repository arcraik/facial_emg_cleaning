clear;clc;eeglab;

subject_names = ["Sbj1", "Sbj2", "Sbj3", "Sbj4", "Sbj5", "Sbj6", "Sbj7", "Sbj8", "Sbj9", "Sbj10"];
sessions_counts = [2, 1, 1, 1, 1, 1, 1, 1, 2, 1];
block_counts = [4, 4, 6, 4, 6, 4, 4, 4, 4, 3];

EMG_removal_types = ["No_clean", "EEMD_CCA", "EEMD_ICA", "EEMD_alone", "CCA", "ICA"];

testing = 1;

for pp = 1:length(subject_names)
    subject_name = subject_names(pp);
    total_block_count = block_counts(pp);
    total_session_count = sessions_counts(pp);

    for i = 1:length(EMG_removal_types)
        
        EMG_removal_type = EMG_removal_types(i);
        
        if testing == 1
            test_option = "_final5";
        else
            test_option = "";
        end
        
        if EMG_removal_type == "No_clean"

            identifiers = [""];
            cleaning_base = "/EEG_Preprocessed_test/";
            dipfit_save_base = "/EEG_Dipfit/Preprocessed/";
            
        else
           [totalData,identifiers,raw] = xlsread(char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/" + EMG_removal_type + "/" + EMG_removal_type + "_identifiers.csv"));
            cleaning_base = "/EEG_Cleaned" + test_option + "/" + EMG_removal_type + "/";
            dipfit_save_base = "/EEG_Dipfit/" + EMG_removal_type + "/";

        end

        for x = 1:length(identifiers)
        
            identifier = identifiers{x};
            disp(identifier)

            for qq = 1:total_session_count

            session_number = qq;
            
                for ll = 1:total_block_count
                    
                    %% Set Variables

                    block_number = ll;
                    folder_name_preprocessed_EEG        = char("D:/Speech_Collection/Subject_data/" + subject_name + cleaning_base + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/"); % Name of the file
                    folder_name_saved_dipfit        = char("D:/Speech_Collection/Subject_data/" + subject_name + dipfit_save_base + "Session_" + num2str(session_number) + "/"); % Name of the file
                    disp('session number ' + string(session_number) + '; block number ' + string(block_number))
                    
                     %% Load Preprocessed Data and Events
                    
                    file_name = char(identifier + "Block_" + num2str(block_number)); 
                    EEG_pre = pop_loadset(char(file_name + ".set"), folder_name_preprocessed_EEG);
                    EEG_pre.data = double(EEG_pre.data);

                    %% Seperate into speech/non-speech epochs

                    events_save_file = char("D:/Speech_Collection/Subject_data/" + subject_name + "/Events/Events_speech_" + num2str(session_number) + '_' + num2str(block_number) + '.csv');
                    speech_events = readmatrix(events_save_file);
                    events = EEG_pre.event(1);
                    durations = [];

                    for t = 1:length(speech_events)

                        temp_events = struct();
                        
                        temp_events.latency=speech_events(t,2); temp_events.duration=1; temp_events.channel = 0;
                        temp_events.bvtime = []; temp_events.bvmknum = t+1; temp_events.visible = []; 
                        temp_events.code = 'Stimulus'; temp_events.urevent = t+1;

                        if speech_events(t,1) == 1
                            
                            temp_events.type = 'speech_onset';
                            
                            if t+1 <= length(speech_events)
                                durations = [durations; speech_events(t+1, 2) - speech_events(t, 2)];
                            end

                        else
                            temp_events.type = 'speech_offset'; 
                        end
                        
                        fields = fieldnames(events);

                        for f = 1:length(fieldnames(events))
                            fname = fields{f};
                            events(t+1).(fname) = temp_events.(fname);
                        end

                    end

                    EEG_pre.event = events;
                    EEG_pre.urevent = rmfield(events, 'urevent');

                    epoch_average = round(mean(durations)) / EEG_pre.srate;

                    EEG_speech = pop_epoch(EEG_pre, {'speech_onset'}, [0 3]);
                    EEG_speech.event = EEG_speech.event(strcmp({EEG_speech.event.type},'speech_onset'));
                    EEG_speech.urevent = EEG_speech.urevent(strcmp({EEG_speech.urevent.type},'speech_onset'));

                    EEG_nonspeech = pop_epoch(EEG_pre, {'speech_offset'}, [0 3]);
                    EEG_nonspeech.event = EEG_nonspeech.event(strcmp({EEG_nonspeech.event.type},'speech_offset'));
                    EEG_nonspeech.urevent = EEG_nonspeech.urevent(strcmp({EEG_nonspeech.urevent.type},'speech_offset'));

                    if exist('EEG_speech_collection','var') == 0
                        EEG_speech_collection = EEG_speech;
                        EEG_nonspeech_collection = EEG_nonspeech;
                    else
                        EEG_speech_collection = pop_mergeset(EEG_speech_collection, EEG_speech, 1);
                        EEG_nonspeech_collection = pop_mergeset(EEG_nonspeech_collection, EEG_nonspeech, 1);
                    end
                end
                            
                %% ICA
                original_rank = rank(single(EEG_pre.data))-1;

                EEG_speech_collection.data = double(EEG_speech_collection.data);
                EEG_nonspeech_collection.data = double(EEG_nonspeech_collection.data);

                file_name_save = char(identifier + "Session_" + num2str(session_number)); 

                % ICA
                EEG_speech_collection.data = double(EEG_speech_collection.data);
                EEG_speech_collection = pop_runica(EEG_speech_collection, 'icatype', 'sobi', 'ncomps', size(EEG_speech_collection.data, 1)-1);

                pop_saveset(EEG_speech_collection, char(file_name_save + "_speech.set"), folder_name_saved_dipfit);
                
                EEG_nonspeech_collection.data = double(EEG_nonspeech_collection.data);
                EEG_nonspeech_collection = pop_runica(EEG_nonspeech_collection, 'icatype', 'sobi', 'ncomps', size(EEG_speech_collection.data, 1)-1);

                pop_saveset(EEG_nonspeech_collection, char(file_name_save + "_nonspeech.set"), folder_name_saved_dipfit);

                clear EEG_speech EEG_nonspeech EEG_speech_collection EEG_nonspeech_collection

            end
        end
    end          
end

