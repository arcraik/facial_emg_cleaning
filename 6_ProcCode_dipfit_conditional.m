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
        
        parfor x = 1:length(identifiers)
        
            identifier = identifiers(x);


            for qq = 1:total_session_count

                
                %% Set Variables
                session_number = qq;


                for xx = 1:2
                    
                    if xx == 1

                        file_name = char(identifier + "Session_" + num2str(session_number) + "_speech.set");
                    else
                        file_name = char(identifier + "Session_" + num2str(session_number) + "_nonspeech.set");
                    end
                    
                    folder_name_dipfit_EEG        = char("D:/Speech_Collection/Subject_data/" + subject_name + dipfit_save_base + "Session_" + num2str(session_number) + "/"); % Name of the file

                     %% Load Preprocessed Data and Events

                    EEG_pre = pop_loadset( file_name, folder_name_dipfit_EEG);
        
                            
                    %% ICA and Dipfit

                    coreg_array = [0.867934      -15.7607     -5.964064    0.07123846 -0.0005955347     -1.574096      99.97076      92.09498      105.9718];
                       
                    EEG_pre = pop_dipfit_settings(EEG_pre, 'mrifile', 'C:\eeglab2022.0\plugins\dipfit\standard_BESA\avg152t1.mat', 'hdmfile', 'C:\eeglab2022.0\plugins\dipfit\standard_BESA\standard_BESA.mat', 'coord_transform', coreg_array) ;
                    
                    EEG_pre.data = double(EEG_pre.data);
                    
                    EEG_pre = pop_multifit(EEG_pre, [], 'threshold', 40, 'rmout' , 'on');
                    
                    % Remove fieldtrip extension to prevent conflict with resample
                    rmpath('C:\eeglab2022.0\plugins\Fieldtrip-lite20220523\external\signal')
        
                    pop_saveset(EEG_pre, file_name, folder_name_dipfit_EEG);
                end

            end
        end
    end
end
            

