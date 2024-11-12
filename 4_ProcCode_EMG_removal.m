clear;clc;eeglab;

subject_names = ["Sbj1", "Sbj2", "Sbj3", "Sbj4", "Sbj5", "Sbj6", "Sbj7", "Sbj8", "Sbj9", "Sbj10"];
sessions_counts = [2, 1, 1, 1, 1, 1, 1, 1, 2, 1];
block_counts = [4, 4, 6, 4, 6, 4, 4, 4, 4, 3];

steps_on.do_EEMD = 1;

steps_on.do_EEMD_alone_corr = 1;
steps_on.do_EEMD_alone_PSD = 1;

steps_on.do_EEMD_CCA = 1;
steps_on.do_EEMD_CCA_PSD = 1;
steps_on.do_EEMD_CCA_corr = 1;

steps_on.do_EEMD_ICA = 1;
steps_on.do_EEMD_ICA_PSD = 1;
steps_on.do_EEMD_ICA_corr = 1;

identifiers_on.save_EEMD_identifiers = 1;

steps_on.do_cca = 1;
steps_on.do_cca_corr = 1;
steps_on.do_cca_psd = 1;

identifiers_on.save_cca_identifiers = 1;

steps_on.do_ica = 1;
steps_on.do_ica_corr = 1;
steps_on.do_ica_psd = 1;
steps_on.do_ica_iclabel = 1;

identifiers_on.save_ica_identifiers = 1;

testing.save_corr_thresh_file = 0;
testing.testing = 1;
testing.use_saved_corrs = 1;

if testing.use_saved_corrs==1
    corr_average_file = char("D:/Speech_Collection/Subject_data/corr_subject_average.mat");
    corr_averages = load(corr_average_file);
    thresholds.corr_average = corr_averages.corr_subject_average.averages;
end


for pp = 1:length(subject_names)
    subject_name = subject_names(pp);
    total_block_count = block_counts(pp);
    total_session_count = sessions_counts(pp);

    %corrs.(subject_name).("EMD") = [];
    corrs.(subject_name).("EMD_alone_corr") = [];
    corrs.(subject_name).("EMD_alone_PSD") = [];
    corrs.(subject_name).("EMD_corr_CCA") = [];
    corrs.(subject_name).("EMD_PSD_CCA") = [];
    corrs.(subject_name).("EMD_corr_ICA") = [];
    corrs.(subject_name).("EMD_PSD_ICA") = [];
    corrs.(subject_name).("CCA_corr") = [];
    corrs.(subject_name).("CCA_PSD") = [];
    corrs.(subject_name).("ICA_corr") = [];
    corrs.(subject_name).("ICA_PSD") = [];
    corrs.(subject_name).("ICA_iclabel") = [];
      
    for qq = 1:total_session_count

        for ll = 1:total_block_count

            clearvars -except qq pp ll subject_names thresholds subject_name total_session_count sessions_counts total_block_count block_counts corrs testing steps_on identifiers_on thresholds_found
    
            if testing.testing==1
                test_option = "_final5";
                pre_test_option = "_test";
            else
                test_option = "";
                pre_test_option = "";
            end
            
            %% Set Variables

            session_number = qq;
            block_number = ll;
            folder_name_EEG        = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Preprocessed" + pre_test_option + "/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/"); % Name of the file
            folder_name_EMG        = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EMG_Preprocessed" + pre_test_option + "/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/"); % Name of the file
            
            disp('session number ' + string(session_number) + '; block number ' + string(block_number))
            
             %% Load Data
            
            set_file = char("Block_" + num2str(block_number) + ".set"); 
            [EEG] = pop_loadset(set_file, folder_name_EEG);
            [EMG] = pop_loadset(set_file, folder_name_EMG);

            disp('Data loaded')
                            
            %% EEMD removal

            if ((steps_on.do_EEMD == 1) || (identifiers_on.save_EEMD_identifiers == 1))

                % EEMD variables
                Noiselevel = 0.2;
                NE = 10;
                fs = EEG.srate;
                numImf_eemd = 6;
                
                % Thresholds
                EMD_threshold_levels = [0.95];  
                                
                % CCA variables
                tlag = 1;

    
                if steps_on.do_EEMD ==1
                    tic
                    EEG_EMD_CCA = EEG;
                    existingdata = double(EEG.data);
                    disp('Starting EMD Decomposition')
                    [Ydecompose,Imfnumber] = EEMD_mdecompose(existingdata,Noiselevel,NE,fs,numImf_eemd);
                    componumber=Imfnumber;
                    corrs_EMD = myfunc_auto_corr(Ydecompose);
                    toc
                end

                %% EMD alone
                identifiers_EMD_alone = {};
                
                if testing.use_saved_corrs == 1
                    EMD_alone_threshold_levels = [thresholds.corr_average.EMD_alone_corr; .95];

                else
                    EMD_alone_threshold_levels = [.95];
                end
                
                for z = 1:length(EMD_alone_threshold_levels)    
                    
                    identifier = char("EEMD_alone_corr_" + num2str(round((EMD_alone_threshold_levels(z)*100))) + "_");

                    identifiers_EMD_alone{length(identifiers_EMD_alone)+1, 1} = identifier;

                    if steps_on.do_EEMD_alone_corr==1


                        acthreshold1_EMD = 0;
                        acthreshold2_EMD = EMD_alone_threshold_levels(z);
                        disp("Selecting EMD Components with " + num2str(acthreshold2_EMD))
                        
                        [Z_m,Y_m, corrs_EMD_alone_corr] = choose_compo(Ydecompose,acthreshold1_EMD,acthreshold2_EMD,10000,10000,10000,10000,10000,10000);
                        disp(char(num2str(size(Z_m,1)) +" of " + num2str(size(Ydecompose,1)) + " EMD components identified as potentially artifactual"))

                        [Youtput, Y_cleaned_Imfs] = multiEEG_recon(zeros(size(Z_m)),Y_m,existingdata,componumber,fs);
                        
                        %figure; multichannelplot_normal_chen1(real(Youtput), fs);
                            
                        EEG_EMD_alone = EEG;
                        EEG_EMD_alone.data = real(Youtput);
                
                        % Saving Blocks
                        filepath_EEMD_alone = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/EEMD_alone/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                        
                        filename = char(identifier + "Block_" + num2str(block_number));
                        pop_saveset(EEG_EMD_alone, filename, filepath_EEMD_alone);
        
                        clear Z_m Y_m Youtput Y_cleaned_Imfs EEG_EMD_CCA

                    end
                end                
                

                if testing.use_saved_corrs == 1
                    EMD_alone_PSD_levels = thresholds.corr_average.EMD_alone_PSD;
                else
                    EMD_alone_PSD_levels = [1/6];
                end

                if steps_on.do_EEMD_alone_PSD == 1
                    tic
                    disp("Starting PSD")
                    nw          = 4; % time-bandwidth product parameter
                    freq        = [0:0.1:100]; % frequencies of interest, comparing power in 0-15 and 15-30   
                    pxx = pmtm(Ydecompose(:,:)',nw,freq,fs)'; 
                    max_freq = 30;
                    emg_freq_split = 15;
                    [PSD_mult_EMD_alone] = myfunc_PSD_mult(pxx, freq, max_freq, emg_freq_split);
                    toc
                end

                for z = 1:length(EMD_alone_PSD_levels)    
                    
                    identifier = char("EEMD_alone_PSD_" + num2str(round(EMD_alone_PSD_levels(z)*100)) + "_");

                    identifiers_EMD_alone{length(identifiers_EMD_alone)+1, 1} = identifier;

                    if steps_on.do_EEMD_alone_PSD==1

                        acthreshold1_EMD_alone_PSD = 0;
                        acthreshold2_EMD_alone_PSD = EMD_alone_PSD_levels(z);
                        disp("Selecting EMD PSD Components with " + num2str(acthreshold2_EMD_alone_PSD))
                        
                        comp_to_remove = find(PSD_mult_EMD_alone>=acthreshold2_EMD_alone_PSD);
                        Yemdpsd = Ydecompose;
                        Yemdpsd(comp_to_remove,:)=0;


                        num_comp_removed = length(find(PSD_mult_EMD_alone>=acthreshold2_EMD_alone_PSD)  );

                        disp("Removing " + num2str(num_comp_removed) + " Components")
                        
                        [Youtput, Y_cleaned_Imfs] = multiEEG_recon(zeros([num_comp_removed, size(Yemdpsd,2)]),Yemdpsd,existingdata,componumber,fs);

                        
                        %figure; multichannelplot_normal_chen1(real(Youtput), fs);
                            
                        EEG_EMD_alone_PSD = EEG;
                        EEG_EMD_alone_PSD.data = real(Youtput);
                
                        % Saving Blocks
                        filepath_EEMD_alone_PSD = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/EEMD_alone/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                        
                        filename = char(identifier + "Block_" + num2str(block_number));
                        pop_saveset(EEG_EMD_alone_PSD, filename, filepath_EEMD_alone_PSD);
        
                        clear Yemdpsd Youtput EEG_EMD_alone_PSD

                    end
                end
                
                if testing.use_saved_corrs == 1
                    EMD_CCA_threshold_levels = [thresholds.corr_average.EMD_corr_CCA; .95];
                else
                    EMD_CCA_threshold_levels = [.9];
                end
                
                for x = 1:length(EMD_threshold_levels)    
                    
                    if steps_on.do_EEMD==1
                        acthreshold1_EMD = 0;
                        acthreshold2_EMD = EMD_threshold_levels(x);
                        disp("Selecting EMD Components with " + num2str(acthreshold2_EMD))
                        
                        [Z_m,Y_m, corrs_EMD] = choose_compo(Ydecompose,acthreshold1_EMD,acthreshold2_EMD,10000,10000,10000,10000,10000,10000);
                        disp(char(num2str(size(Z_m,1)) +" of " + num2str(size(Ydecompose,1)) + " EMD components identified as potentially artifactual"))
                       
                    end
                    %% EMD CCA                    
                    identifiers_CCA = {};
                    if steps_on.do_EEMD_CCA==1 
                        tic
                        disp('Starting CCA')
                        [Ybss,B,WC]= myCCA(Z_m,fs,tlag);
                        corrs_EMD_CCA = myfunc_auto_corr(Ybss);
                        toc
                    end

                    for z = 1:length(EMD_CCA_threshold_levels)    
                        
                        identifier = char("EEMD_corr_CCA_" + num2str(EMD_threshold_levels(x)*100) + "_" + num2str(round(EMD_CCA_threshold_levels(z)*100)) + "_");

                        identifiers_CCA{length(identifiers_CCA)+1, 1} = identifier;

                        if steps_on.do_EEMD_CCA_corr==1

                            acthreshold1_CCA = 0;
                            acthreshold2_CCA = EMD_CCA_threshold_levels(z);
                            disp("Selecting EMD-CCA Components with " + num2str(acthreshold2_CCA))
                            
                            [Ycca,W, corrs_EMD_CCA] = CCA_threshold(Ybss,B,WC,acthreshold1_CCA,acthreshold2_CCA,10000,10000,10000,10000,10000,10000);
                            num_comp_removed = length(find(corrs_EMD_CCA<=acthreshold2_CCA)  );
                            disp("Removing " + num2str(num_comp_removed) + " Components")
                            
                            [Youtput, Y_cleaned_Imfs] = multiEEG_recon(Ycca,Y_m,existingdata,componumber,fs);
                            
                            %figure; multichannelplot_normal_chen1(real(Youtput), fs);
                                
                            EEG_EMD_CCA = EEG;
                            EEG_EMD_CCA.data = real(Youtput);
                    
                            % Saving Blocks
                            filepath_EEMD_CCA = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/EEMD_CCA/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                            
                            filename = char(identifier + "Block_" + num2str(block_number));
                            pop_saveset(EEG_EMD_CCA, filename, filepath_EEMD_CCA);
            
                            clear Ycca W Youtput EEG_EMD_CCA

                        end
                    end

                    if testing.use_saved_corrs == 1
                        EMD_CCA_PSD_levels = thresholds.corr_average.EMD_PSD_CCA;
                    else
                        EMD_CCA_PSD_levels = [1/6];
                    end


                    if steps_on.do_EEMD_CCA_PSD == 1
                        disp("Starting PSD")
                        nw          = 4; % time-bandwidth product parameter
                        freq        = [0:0.1:100]; % frequencies of interest, comparing power in 0-15 and 15-30   
                        pxx = pmtm(Ybss(:,:)',nw,freq,fs)'; 
                        max_freq = 30;
                        emg_freq_split = 15;
                        [PSD_mult_EMD_CCA] = myfunc_PSD_mult(pxx, freq, max_freq, emg_freq_split);
                    end

                    for z = 1:length(EMD_CCA_PSD_levels)    
                        
                        identifier = char("EEMD_PSD_CCA_" + num2str(EMD_threshold_levels(x)*100) + "_" + num2str(round(EMD_CCA_PSD_levels(z)*100)) + "_");

                        identifiers_CCA{length(identifiers_CCA)+1, 1} = identifier;

                        if steps_on.do_EEMD_CCA_PSD==1

                            acthreshold1_CCA = 0;
                            acthreshold2_CCA = EMD_CCA_PSD_levels(z);
                            disp("Selecting EMD-CCA Components with " + num2str(acthreshold2_CCA))
                            

                            [Ycca,W, PSD_mult_EMD_CCA] = CCA_threshold_PSD_craik(Ybss,B,WC,acthreshold2_CCA, fs, pxx, freq, max_freq, emg_freq_split);
                            %[Ycca,W, corrs_CCA] = CCA_threshold(Ybss,B,WC,acthreshold1_CCA,acthreshold2_CCA,10000,10000,10000,10000,10000,10000);
                            num_comp_removed = length(find(PSD_mult_EMD_CCA>=acthreshold2_CCA)  );

                            disp("Removing " + num2str(num_comp_removed) + " Components")
                            
                            [Youtput, Y_cleaned_Imfs] = multiEEG_recon(Ycca,Y_m,existingdata,componumber,fs);
                            
                            %figure; multichannelplot_normal_chen1(real(Youtput), fs);
                                
                            EEG_EMD_CCA_PSD = EEG;
                            EEG_EMD_CCA_PSD.data = real(Youtput);
                    
                            % Saving Blocks
                            filepath_EEMD_CCA_PSD = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/EEMD_CCA/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                            
                            filename = char(identifier + "Block_" + num2str(block_number));
                            pop_saveset(EEG_EMD_CCA_PSD, filename, filepath_EEMD_CCA_PSD);
            
                            clear Ycca W Youtput EEG_EMD_CCA_PSD

                        end
                    end

                    %% EMD ICA
                    identifiers_ICA = {};

                    if testing.use_saved_corrs == 1
                        EMD_ICA_threshold_levels = [thresholds.corr_average.EMD_corr_ICA; .95];
                    else
                        EMD_ICA_threshold_levels = [.9];
                    end
                    
                    if steps_on.do_EEMD_ICA==1 
                        tic
                        disp('Starting ICA')
                        [Sica,Wica,WC,P_ica] = mysobi(Z_m,fs);
                        corrs_EMD_ICA = myfunc_auto_corr(Sica);
                        toc
                    end

                    for z = 1:length(EMD_ICA_threshold_levels)    
                        
                        identifier = char("EEMD_corr_ICA_" + num2str(EMD_threshold_levels(x)*100) + "_" + num2str(round(EMD_ICA_threshold_levels(z)*100)) + "_");
                        identifiers_ICA{length(identifiers_ICA)+1, 1} = identifier;
                        
                        if steps_on.do_EEMD_ICA_corr==1
                            
                            acthreshold1_ICA = 0;
                            acthreshold2_ICA = EMD_ICA_threshold_levels(z);
                            disp("Selecting EMD-ICA Components with " + num2str(acthreshold2_ICA))

                            [Yica,W, corrs_EMD_ICA] = ICA_threshold_sobi(Sica,WC,Wica,P_ica,acthreshold1_ICA,acthreshold2_ICA,10000,10000,10000,10000,10000,10000);
                            num_comp_removed = length(find(corrs_EMD_ICA<=acthreshold2_ICA)  );  
                            disp("Removing " + num2str(num_comp_removed) + " Components")

                            [Youtput, Y_cleaned_Imfs] = multiEEG_recon(Yica,Y_m,existingdata,componumber,fs);
                            
                            %figure; multichannelplot_normal_chen1(real(Youtput), fs);
                                
                            EEG_EMD_ICA = EEG;
                            EEG_EMD_ICA.data = real(Youtput);
                    
                            % Saving Blocks
                            filepath_EEMD_ICA = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/EEMD_ICA/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                            
                            filename = char(identifier + "Block_" + num2str(block_number));
                            pop_saveset(EEG_EMD_ICA, filename, filepath_EEMD_ICA);
            
                            clear Yica W Youtput EEG_EMD_ICA
                        end
                    end

                    if testing.use_saved_corrs == 1
                        EMD_ICA_PSD_levels = thresholds.corr_average.EMD_PSD_ICA;
                    else
                        EMD_ICA_PSD_levels = [1/6];
                    end

                    if steps_on.do_EEMD_ICA_PSD == 1
                        disp("Starting PSD")
                        nw          = 4; % time-bandwidth product parameter
                        freq        = [0:0.1:100]; % frequencies of interest, comparing power in 0-15 and 15-30   
                        pxx = pmtm(Sica(:,:)',nw,freq,fs)'; 
                        max_freq = 30;
                        emg_freq_split = 15;
                        [PSD_mult_EMD_ICA] = myfunc_PSD_mult(pxx, freq, max_freq, emg_freq_split);
                    end

                    for z = 1:length(EMD_ICA_PSD_levels)    
                        
                        identifier = char("EEMD_PSD_ICA_" + num2str(EMD_threshold_levels(x)*100) + "_" + num2str(round(EMD_ICA_PSD_levels(z)*100)) + "_");
                        identifiers_ICA{length(identifiers_ICA)+1, 1} = identifier;
                        
                        if steps_on.do_EEMD_ICA_PSD==1
                            
                            acthreshold1_ICA = 0;
                            acthreshold2_ICA = EMD_ICA_PSD_levels(z);
                            disp("Selecting EMD-ICA Components with " + num2str(acthreshold2_ICA))

                            [Yica,W, PSD_mult_EMD_ICA] = ICA_threshold_psd_craik(Sica,WC,Wica,P_ica,acthreshold2_ICA, fs, pxx, freq, max_freq, emg_freq_split);
                            
                            num_comp_removed = length(find(PSD_mult_EMD_ICA>=acthreshold2_ICA)  );  
                            disp("Removing " + num2str(num_comp_removed) + " Components")

                            [Youtput, Y_cleaned_Imfs] = multiEEG_recon(Yica,Y_m,existingdata,componumber,fs);
                            
                            %figure; multichannelplot_normal_chen1(real(Youtput), fs);
                                
                            EEG_EMD_ICA_PSD = EEG;
                            EEG_EMD_ICA_PSD.data = real(Youtput);
                    
                            % Saving Blocks
                            filepath_EEMD_ICA_PSD = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/EEMD_ICA/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                            
                            filename = char(identifier + "Block_" + num2str(block_number));
                            pop_saveset(EEG_EMD_ICA_PSD, filename, filepath_EEMD_ICA_PSD);
            
                            clear Yica W Youtput EEG_EMD_ICA_PSD
                        end
                    end
                end
                
                if steps_on.do_EEMD == 1                  
                    corrs.(subject_name).("EMD") = [corrs.(subject_name).("EMD"); corrs_EMD];
                    clear existingdata Ydecompose Z_m Y_m Ybss B WC
                end
                
                if steps_on.do_EEMD_alone_corr == 1                  
                    corrs.(subject_name).("EMD_alone_corr") = [corrs.(subject_name).("EMD_alone_corr"); corrs_EMD_alone_corr];
                end

                if steps_on.do_EEMD_alone_PSD == 1   
                    corrs.(subject_name).("EMD_alone_PSD") = [corrs.(subject_name).("EMD_alone_PSD"); PSD_mult_EMD_alone];
                end
                
                if steps_on.do_EEMD_CCA_corr == 1                  
                    corrs.(subject_name).("EMD_corr_CCA") = [corrs.(subject_name).("EMD_corr_CCA"); corrs_EMD_CCA];
                end
               
                if steps_on.do_EEMD_CCA_PSD== 1                  
                    corrs.(subject_name).("EMD_PSD_CCA") = [corrs.(subject_name).("EMD_PSD_CCA"); PSD_mult_EMD_CCA];
                end

                if steps_on.do_EEMD_ICA_corr == 1                  
                    corrs.(subject_name).("EMD_corr_ICA") = [corrs.(subject_name).("EMD_corr_ICA"); corrs_EMD_ICA];
                end

                if steps_on.do_EEMD_ICA_PSD == 1                  
                    corrs.(subject_name).("EMD_PSD_ICA") = [corrs.(subject_name).("EMD_PSD_ICA"); PSD_mult_EMD_ICA];
                end

                if identifiers_on.save_EEMD_identifiers == 1 
                    writecell(identifiers_EMD_alone, char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/EEMD_alone/EEMD_alone_identifiers.csv")); 
                    writecell(identifiers_CCA, char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/EEMD_CCA/EEMD_CCA_identifiers.csv")); 
                    writecell(identifiers_ICA, char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/EEMD_ICA/EEMD_ICA_identifiers.csv")); 
                end

            end
            
            %% CCA Removal

            if ((steps_on.do_cca == 1) || (identifiers_on.save_cca_identifiers == 1) || (steps_on.do_cca_corr == 1) || (steps_on.do_cca_psd == 1))
                
                identifiers = {};

                % CCA variables
                
                if testing.use_saved_corrs == 1
                    CCA_corr_levels = thresholds.corr_average.CCA_corr;
                else
                    CCA_corr_levels = [.9];
                end

                tlag = 1;

                if steps_on.do_cca == 1
                    existingdata = double(EEG.data);
                    fs = EEG.srate;
                    disp("Starting CCA")
                    [Ybss,B,WC]= myCCA(existingdata,fs,tlag);
                    corrs_CCA = myfunc_auto_corr(Ybss);
                    clear existingdata
                end

                for x = 1:length(CCA_corr_levels)
                    
                    identifier = char("CCA_corr_" + num2str(round(CCA_corr_levels(x)*100)) + "_");
                    identifiers{length(identifiers)+1, 1} = identifier;
                    
                    if steps_on.do_cca_corr == 1
                        acthreshold1_CCA = 0;
                        acthreshold2_CCA = CCA_corr_levels(x);
                        disp("Selecting CCA (corr) Components with " + num2str(acthreshold2_CCA))
                        
                        [Ycca, W, corrs_CCA] = CCA_threshold(Ybss,B,WC,acthreshold1_CCA,acthreshold2_CCA,10000,10000,10000,10000,10000,10000);
                        num_comp_removed = length(find(corrs_CCA<=acthreshold2_CCA)  );
                        disp("Removing " + num2str(num_comp_removed) + " Components")
                        %multichannelplot_normal_chen1(real(Youtput), fs);
                        
                        EEG_CCA_corr = EEG;
                        EEG_CCA_corr.data = real(Ycca);
        
                        % Saving Blocks
                        filepath_CCA = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/CCA/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                        
                        filename = char(identifier + "Block_" + num2str(block_number));
                        pop_saveset(EEG_CCA_corr, filename, filepath_CCA);
        
                        clear Ycca W EEG_CCA_corr
                    end
                end


                % CCA PSD variables
                if testing.use_saved_corrs == 1
                    CCA_PSD_levels = thresholds.corr_average.CCA_PSD;
                else
                    CCA_PSD_levels = [1/6];
                end

                tlag = 1;

                if steps_on.do_cca_psd == 1
                    existingdata = double(EEG.data);
                    disp("Starting PSD")
                    nw          = 4; % time-bandwidth product parameter
                    freq        = [0:0.1:100]; % frequencies of interest, comparing power in 0-15 and 15-30   
                    pxx = pmtm(existingdata(:,:)',nw,freq,fs)'; 
                    max_freq = 30;
                    emg_freq_split = 15;
                    [PSD_mult_CCA] = myfunc_PSD_mult(pxx, freq, max_freq, emg_freq_split);
                    clear existingdata
                end

                for x = 1:length(CCA_PSD_levels)
                    
                    identifier = char("CCA_PSD_" + num2str(round(CCA_PSD_levels(x)*100)) + "_");
                    identifiers{length(identifiers)+1, 1} = identifier;
                    
                    if steps_on.do_cca_psd == 1
                        psd_threshold1 = CCA_PSD_levels(x);
                        disp("Selecting CCA (PSD) Components with " + num2str(psd_threshold1))
                        [Ycca,W, PSD_mult_CCA] = CCA_threshold_PSD_craik(Ybss,B,WC,psd_threshold1, fs, pxx, freq, max_freq, emg_freq_split);
                        
                        num_comp_removed = length(find(PSD_mult_CCA>=psd_threshold1)  );  
                        disp("Removing " + num2str(num_comp_removed) + " Components")  
    
                        %multichannelplot_normal_chen1(real(Youtput), fs);
                        
                        EEG_CCA_PSD = EEG;
                        EEG_CCA_PSD.data = real(Ycca);
        
                        % Saving Blocks
                        filepath_CCA = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/CCA/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                        
                        filename = char(identifier + "Block_" + num2str(block_number));
                        pop_saveset(EEG_CCA_PSD, filename, filepath_CCA);
        
                        clear Ycca W EEG_CCA_PSD
                    end
                end
            
            
                if steps_on.do_cca==1
                    corrs.(subject_name).("CCA_corr") = [corrs.(subject_name).("CCA_corr"); corrs_CCA];

                end

                if steps_on.do_cca_psd==1
                    corrs.(subject_name).("CCA_PSD")= [corrs.(subject_name).("CCA_PSD"); PSD_mult_CCA];

                end

                if identifiers_on.save_cca_identifiers == 1                    
                    writecell(identifiers, char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/CCA/CCA_identifiers.csv")); 
                end
            
            end

            %% ICA removal

            if ((steps_on.do_ica_corr == 1) || (identifiers_on.save_ica_identifiers == 1) ||  (steps_on.do_ica == 1)  ||  (steps_on.do_ica_psd == 1))  %|| (do_ica_eeglab == 1)
                
                identifiers = {};

                if testing.use_saved_corrs == 1
                    ICA_levels = thresholds.corr_average.ICA_corr;
                else
                    ICA_levels = [.9];
                end   


                if steps_on.do_ica == 1
                    existingdata = double(EEG.data);
                    fs = EEG.srate;
                    disp('Starting ICA')
                    [Sica,Wica,WC,P_ica] = mysobi(existingdata,fs);
                    corrs_ICA = myfunc_auto_corr(Sica);
                end

   
                for x = 1:length(ICA_levels)
                    
                    identifier = char("ICA_corr_" + num2str(round(ICA_levels(x)*100)) + "_");
                    identifiers{length(identifiers)+1, 1} = identifier;

                    if steps_on.do_ica_corr == 1
                        
                        acthreshold1_ICA = 0;
                        acthreshold2_ICA = ICA_levels(x);

                        [Yica,W, corrs_ICA] = ICA_threshold_sobi(Sica,WC,Wica,P_ica,acthreshold1_ICA,acthreshold2_ICA,10000,10000,10000,10000,10000,10000);
                        num_comp_removed = length(find(corrs_ICA<=acthreshold2_ICA)  );  
                        disp("Removing " + num2str(num_comp_removed) + " Components")                            
                        %multichannelplot_normal_chen1(real(Youtput), fs);
                        
                        EEG_ICA_corr = EEG;
                        EEG_ICA_corr.data = real(Yica);
        
                        % Saving Blocks
                        filepath_ICA = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/ICA/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                        filename = char(identifier + "Block_" + num2str(block_number));
                        pop_saveset(EEG_ICA_corr, filename, filepath_ICA);
        
                        clear Yica W EEG_ICA_corr
                    end

                end
                
                if testing.use_saved_corrs == 1
                    ICA_PSD_levels = thresholds.corr_average.ICA_PSD;
                else
                    ICA_PSD_levels = [1/6];
                end


                if steps_on.do_ica_psd == 1
                    existingdata = double(EEG.data);
                    fs = EEG.srate;
                    tic
                    disp("Starting PSD")
                    nw          = 4; % time-bandwidth product parameter
                    freq        = [0:0.1:100]; % frequencies of interest, comparing power in 0-15 and 15-30   
                    pxx = pmtm(Sica(:,:)',nw,freq,fs)';   
                    max_freq = 30;
                    emg_freq_split = 15;
                    [PSD_mult_ICA] = myfunc_PSD_mult(pxx, freq, max_freq, emg_freq_split);
                    clear existingdata
                    toc
                end

                for x = 1:length(ICA_PSD_levels)
                    
                    identifier = char("ICA_PSD_" + num2str(round(ICA_PSD_levels(x)*100)) + "_");
                    identifiers{length(identifiers)+1, 1} = identifier;

                    if steps_on.do_ica_psd == 1
                        
                        psdthreshold1 = ICA_PSD_levels(x);

                        [Yica,W, PSD_mult_ICA] = ICA_threshold_psd_craik(Sica,WC,Wica,P_ica,psdthreshold1, fs, pxx, freq, max_freq, emg_freq_split);
                        
                        num_comp_removed = length(find(PSD_mult_ICA>=psdthreshold1)  );  
                        disp("Removing " + num2str(num_comp_removed) + " Components")                         
                        %multichannelplot_normal_chen1(real(Youtput), fs);
                        
                        EEG_ICA_PSD = EEG;
                        EEG_ICA_PSD.data = real(Yica);
        
                        % Saving Blocks
                        filepath_ICA = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/ICA/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                        filename = char(identifier + "Block_" + num2str(block_number));
                        pop_saveset(EEG_ICA_PSD, filename, filepath_ICA);
        
                        clear Yica W EEG_ICA_PSD
                    end
                end

                if steps_on.do_ica_iclabel == 1

                    disp('Starting ICA')
                    tic
                    EEG_ICA_eeglab_full = pop_runica(EEG, 'icatype', 'sobi');
                    EEG_ICA_eeglab_full = pop_iclabel(EEG_ICA_eeglab_full,'default');
                    confid_iclabel = EEG_ICA_eeglab_full.etc.ic_classification.ICLabel.classifications(:,2);  
                    toc
                end
                                
                if testing.use_saved_corrs == 1
                    ICA_iclabel_levels = thresholds.corr_average.ICA_iclabel;
                else
                    ICA_iclabel_levels = [.9];
                end


                for x = 1:length(ICA_iclabel_levels)
                    
                    ICA_eeglab_thresh = ICA_iclabel_levels(x);
                    
                    identifier = char("ICA_iclabel_" + num2str(round(ICA_iclabel_levels(x)*100)) + "_");
                    identifiers{length(identifiers)+1, 1} = identifier;

                    if steps_on.do_ica_iclabel == 1
                    
                        EEG_ICA_eeglab = pop_icflag(EEG_ICA_eeglab_full,[NaN NaN;ICA_eeglab_thresh 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
                        EEG_ICA_eeglab = pop_subcomp(EEG_ICA_eeglab, find(EEG_ICA_eeglab.reject.gcompreject), 0);
                        
                        filepath_ICA = char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/ICA/" + "Session_" + num2str(session_number) + "/Block_" + num2str(block_number) + "/");
                        filename = char(identifier + "Block_" + num2str(block_number));
                        pop_saveset(EEG_ICA_eeglab, filename, filepath_ICA);
                        
                        clear EEG_ICA_eeglab
                        
                    end
                end    

                if steps_on.do_ica_iclabel == 1
                    corrs.(subject_name).("ICA_iclabel")= [corrs.(subject_name).("ICA_iclabel"); confid_iclabel];
                end

                if steps_on.do_ica_corr == 1
                    corrs.(subject_name).("ICA_corr")= [corrs.(subject_name).("ICA_corr"); corrs_ICA];
                end

                if steps_on.do_ica_psd == 1
                    corrs.(subject_name).("ICA_PSD") = [corrs.(subject_name).("ICA_PSD"); PSD_mult_ICA];
                end

                if identifiers_on.save_ica_identifiers == 1                    
                    writecell(identifiers, char("D:/Speech_Collection/Subject_data/" + subject_name + "/EEG_Cleaned" + test_option + "/ICA/ICA_identifiers.csv")); 
                end
            end

            %% Break if not doing any actual EMG removal
            steps_on_fields = fields(steps_on);
            steps_on_array = [];

            for nn = 1:length(steps_on_fields)
                steps_on_array = [steps_on_array; steps_on.(char(steps_on_fields(nn)))];
            end
            
            if isempty(find(steps_on_array, 1))
               
               disp("Cutting off script since only identifiers")
               
               break
           end
        end
    end
    
    if ~isempty(find(steps_on_array, 1))
        figure;
        field_names = fields(corrs.(subject_name));
        num_clusters = 4;
        PSD_mult_cutoff = 0.4;

        for pp = 1:length(field_names)
            subplot(length(field_names), 1, pp)
            if isempty(corrs.(subject_name).(string(field_names(pp))))
                continue
            end
            temp_corrs = corrs.(subject_name).(string(field_names(pp)));
            num_bins = 100;
    
            if ~isempty(strfind(string(field_names(pp)), "PSD"))
                temp_corrs = temp_corrs(find(temp_corrs<PSD_mult_cutoff));
                [idx, C] =  kmeans(temp_corrs, num_clusters);
                F_mid = conv(sort(C), [0.5 0.5], 'valid');
                thresholds_found.(subject_name).(string(field_names(pp))) = F_mid;
%                 histogram(temp_corrs, round(max(temp_corrs)/(plot_limit/100))); xlim([0,plot_limit]); title(char(field_names(pp)) + subject_name); hold on; xline(F_mid, 'LineWidth', 2, 'Color', 'r'); hold off;
                histogram(temp_corrs, num_bins); title(char(field_names(pp)) + subject_name); hold on; xline(F_mid, 'LineWidth', 2, 'Color', 'r'); hold off;

            else
                [idx, C] =  kmeans(temp_corrs, num_clusters);
                F_mid = conv(sort(C), [0.5 0.5], 'valid');
                thresholds_found.(subject_name).(string(field_names(pp))) = F_mid;
                histogram(temp_corrs, num_bins); title(char(field_names(pp)) + subject_name); hold on; xline(F_mid, 'LineWidth', 2, 'Color', 'r'); hold off;
            end
        end
    end

end

if testing.save_corr_thresh_file == 1
    corrs_file = char("D:/Speech_Collection/Subject_data/all_corrs.mat");
    save(corrs_file, 'corrs')   
end

if ~isempty(find(steps_on_array, 1))
    threshold_fields = string(fieldnames(thresholds_found));

    corr_subject_collection = fieldnames(thresholds_found.(subject_name))';
    corr_subject_collection{2,1} = [];
    corr_subject_collection = struct(corr_subject_collection{:});
    
    corr_fieldnames = string(fieldnames(corr_subject_collection));
    
    
    for i = 1:length(threshold_fields)
        for j = 1:length(fieldnames(corr_subject_collection))
            corr_subject_collection.(corr_fieldnames(j)) = [corr_subject_collection.(corr_fieldnames(j)), thresholds_found.(threshold_fields(i)).(corr_fieldnames(j))];
        end
    end

    for j = 1:length(fieldnames(corr_subject_collection))
               
        
        [S,M] = std(corr_subject_collection.(corr_fieldnames(j)), 0, 2);
        
        corr_averages.averages.(corr_fieldnames(j)) = [M];
        corr_averages.variances.(corr_fieldnames(j)) = [S];
       
    end    

end

if testing.save_corr_thresh_file == 1
    corr_collection_file = char("D:/Speech_Collection/Subject_data/corr_collection.mat");
    save(corr_collection_file, 'corr_subject_collection')   
    corr_average_file = char("D:/Speech_Collection/Subject_data/corr_averages.mat");
    save(corr_average_file, 'corr_averages') 
end

