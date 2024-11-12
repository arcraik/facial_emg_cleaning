clearvars -except summary;clc;eeglab;

subject_names = ["Sbj1", "Sbj2", "Sbj3", "Sbj4", "Sbj5", "Sbj6", "Sbj7", "Sbj8", "Sbj9", "Sbj10"];
sessions_counts = [2, 1, 1, 1, 1, 1, 1, 1, 2, 1];
block_counts = [4, 4, 6, 4, 6, 4, 4, 4, 4, 3];

subject_brain_maps = ["ih", "ih", "ih", "rh", "ih", "ih", "rh", "rh", "ih"];

EMG_removal_types = ["No_clean", "EEMD_CCA", "EEMD_ICA", "EEMD_alone", "CCA", "ICA"];

metrics_file_name = "Clustering_metrics_clusters.mat";

if exist('summary','var') == 0
    summary = struct();
end

testing=1;
    
 for n = 1:length(EMG_removal_types)
    
    EMG_removal_type = EMG_removal_types(n);
    
    if testing == 1
        test_option = "_final5";
    else
        test_option = "";
    end
    
    if EMG_removal_type == "No_clean"

        identifiers = [""];
        cleaning_base = "/EEG_Preprocessed_test/";
        dipfit_save_base = "/EEG_Dipfit/Preprocessed/";
        study_save_base = "/EEG_Dipfit_allsubjects/Preprocessed/";
        
    else

       [totalData,identifiers,raw] = xlsread(char("D:/Speech_Collection/Subject_data/" + "Identifiers" + "/EEG_Cleaned" + test_option + "/" + EMG_removal_type + "/" + EMG_removal_type + "_identifiers.csv"));
        cleaning_base = "/EEG_Cleaned" + test_option + "/" + EMG_removal_type + "/";
        dipfit_save_base = "/EEG_Dipfit/" + EMG_removal_type + "/";
        study_save_base = "/EEG_Dipfit_allsubjects/" + EMG_removal_type + "/";
        
    end
    
    for x = 1:length(identifiers)
    
        identifier = identifiers{x};
        study_block_collection_speech = {};
        study_block_collection_nonspeech = {};
        
        for pp = 1:length(subject_names)
            subject_name = subject_names(pp);
            total_session_count = sessions_counts(pp);
        
            for qq = 1:total_session_count

                % Set Variables
                session_number = qq;         
                folder_name_preprocessed_EEG        = char("D:/Speech_Collection/Subject_data/" + subject_name + dipfit_save_base + "Session_" + num2str(session_number) + "/"); % Name of the file
                set_file_name = char(identifier+"Session_" + num2str(session_number)); 
                
                [EEG_temp_speech] = pop_loadset(strcat(set_file_name,  char("_speech.set")), folder_name_preprocessed_EEG);
                [EEG_temp_nonspeech] = pop_loadset(strcat(set_file_name,  char("_nonspeech.set")), folder_name_preprocessed_EEG);

                if exist('EEG_session_speech','var') == 0
                    EEG_session_speech = EEG_temp_speech;
                    EEG_session_nonspeech = EEG_temp_nonspeech;
                else
                    EEG_session_speech = pop_mergeset(EEG_session_speech, EEG_temp_speech, 1);
                    EEG_session_nonspeech = pop_mergeset(EEG_session_nonspeech, EEG_temp_nonspeech, 1);
                end
                
                clear EEG_temp_speech EEG_temp_nonspeech
                               
            end

            folder_name_epoched_preprocessed_EEG = char("D:/Speech_Collection/Subject_data/" + subject_name + dipfit_save_base + "Dipfit_studies/");
            subject_set_name = char(subject_name + "_" + identifier);
            
            pop_saveset(EEG_session_speech, strcat(subject_set_name, char("full_speech.set")), folder_name_epoched_preprocessed_EEG);
            pop_saveset(EEG_session_nonspeech, strcat(subject_set_name, char("full_nonspeech.set")), folder_name_epoched_preprocessed_EEG);
            
            clear EEG_session_speech EEG_session_nonspeech
    
            study_block_collection_speech(1,pp) = {{'index' pp 'load' strcat(folder_name_epoched_preprocessed_EEG, subject_set_name, char("full_speech.set")) 'subject' char(subject_name) 'session' qq}};
            study_block_collection_nonspeech(1,pp) = {{'index' pp 'load' strcat(folder_name_epoched_preprocessed_EEG, subject_set_name, char("full_nonspeech.set")) 'subject' char(subject_name) 'session' qq}};
        
        end
        
        dipfit_criteria = .40;
        study_block_collection_speech(1,length(subject_names)+1) = {{'dipselect' dipfit_criteria}};
        study_block_collection_nonspeech(1,length(subject_names)+1) = {{'dipselect' dipfit_criteria}};
    
        study_name = char("All_subjects" + "_EEG_" + identifier);
        study_save_folder = char("D:/Speech_Collection/Subject_data" + study_save_base + "Dipfit_studies/") ;

        STUDY_speech = STUDY;
        STUDY_nonspeech = STUDY;
        
        [STUDY_speech, ALLEEG_speech] = std_editset( STUDY_speech, [], 'name',strcat(study_name, '_speech'),...
            'task', 'EMG cleaning',...
            'filename', strcat(study_name, '_speech.study'),'filepath', study_save_folder,...
            'commands', study_block_collection_speech);

        [STUDY_nonspeech, ALLEEG_nonspeech] = std_editset( STUDY_nonspeech, [], 'name',strcat(study_name, '_nonspeech'),...
            'task', 'EMG cleaning',...
            'filename', strcat(study_name, '_nonspeech.study'),'filepath', study_save_folder,...
            'commands', study_block_collection_nonspeech);
    
        for kkk = 1:length(STUDY_speech.datasetinfo)
            STUDY_speech.datasetinfo(kkk).subject = strcat(STUDY_speech.datasetinfo(kkk).subject, '_speech');
            STUDY_speech.subject(kkk) =  strcat(STUDY_speech.subject(kkk), '_speech');
            STUDY_speech.design.cases.value(kkk) = strcat(STUDY_speech.design.cases.value(kkk), '_speech');
            
            STUDY_nonspeech.datasetinfo(kkk).subject = strcat(STUDY_nonspeech.datasetinfo(kkk).subject, '_nonspeech');
            STUDY_nonspeech.subject(kkk) =  strcat(STUDY_nonspeech.subject(kkk), '_nonspeech');
            STUDY_nonspeech.design.cases.value(kkk) = strcat(STUDY_nonspeech.design.cases.value(kkk), '_nonspeech');
        end
    
        
        %% Save a study...
         STUDY_speech = pop_savestudy(STUDY_speech, ALLEEG_speech, 'savemode', 'standard','resavedatasets','on');
         STUDY_nonspeech = pop_savestudy(STUDY_nonspeech, ALLEEG_nonspeech, 'savemode', 'standard','resavedatasets','on');
         
         
        %% Load a study...
        [STUDY_speech, ALLEEG_speech] = pop_loadstudy('filename', strcat(study_save_folder, strcat(study_name, '_speech.study')));
        [STUDY_nonspeech, ALLEEG_nonspeech] = pop_loadstudy('filename', strcat(study_save_folder, strcat(study_name, '_nonspeech.study')));

        % Reject outliers?
        reject_outlier = 0;
        stdcutoff      = 3;
        
        % Number of total subjects (or number of datasets really)
        submax = length(subject_names);
        
        %% Compute measures

        spec_option = 'off';
        scalp_option = 'off';

        [STUDY_speech, ALLEEG_speech] = std_precomp(STUDY_speech, ALLEEG_speech, 'components', 'recompute', 'on',...
        'erp','off',...
        'scalp',scalp_option,...
        'spec',spec_option,...
        'itc','off');

        [STUDY_nonspeech, ALLEEG_nonspeech] = std_precomp(STUDY_nonspeech, ALLEEG_nonspeech, 'components', 'recompute', 'on',...
        'erp','off',...
        'scalp',scalp_option,...
        'spec',spec_option,...
        'itc','off');

        if strcmp(spec_option,'on') && strcmp(scalp_option,'on')
       
            options{1,1} = STUDY_speech;
            options{1,2} = ALLEEG_speech;
            options{1,3} = 1;
            options{1,4} = {'spec', 'npca', 3, 'weight', 1, 'freqrange', [0.1, 99]};
            options{1,5} = {'scalp', 'npca', 3, 'weight', 1, 'abso', 1};
            options{1,6} = {'dipoles', 'weight', 1};
            options{1,7} = {'moments', 'weight', 1};
        elseif strcmp(spec_option,'off') && strcmp(scalp_option,'on')
            options{1,1} = STUDY_speech;
            options{1,2} = ALLEEG_speech;
            options{1,3} = 1;

            options{1,4} = {'scalp', 'npca', 3, 'weight', 1, 'abso', 1};
            options{1,5} = {'dipoles', 'weight', 1};
            options{1,6} = {'moments', 'weight', 1};
        else
            options{1,1} = STUDY_speech;
            options{1,2} = ALLEEG_speech;
            options{1,3} = 1;
            options{1,4} = {'dipoles', 'weight', 1};
            options{1,5} = {'moments', 'weight', 1};
        end
    
    
        
        [STUDY_speech, ALLEEG_speech] = std_preclust(options{:});

        options{1,1} = STUDY_nonspeech;
        options{1,2} = ALLEEG_nonspeech;

        [STUDY_nonspeech, ALLEEG_nonspeech] = std_preclust(options{:});
        
        
        %  Obtain all dipole xyz coordinates as a list               %
        dipXyz_speech = [];

        % Obtain xyz, dip moment, maxProj channel xyz.   
        for rr = 1:length(ALLEEG_speech)
            xyz = zeros(length(ALLEEG_speech(rr).dipfit.model),3);
            
            for modelIdx = 1:length(ALLEEG_speech(rr).dipfit.model)
         
                if isempty(ALLEEG_speech(rr).dipfit.model(modelIdx).momxyz) || (ALLEEG_speech(rr).dipfit.model(modelIdx).rv>=dipfit_criteria)
                    continue
                end
                
                % Choose the larger dipole if symmetrical.
                currentXyz = ALLEEG_speech(rr).dipfit.model(modelIdx).posxyz;
                currentMom = ALLEEG_speech(rr).dipfit.model(modelIdx).momxyz; % nAmm.
                if size(currentMom,1) == 2
                    [~,largerOneIdx] = max([norm(currentMom(1,:)) norm(currentMom(2,:))]);
                    currentXyz = ALLEEG_speech(rr).dipfit.model(modelIdx).posxyz(largerOneIdx,:);
                end
                xyz(modelIdx,:) = currentXyz;
            end
            dipXyz_speech = [dipXyz_speech; xyz];
        end

        numclusts = size(nonzeros(dipXyz_speech(:,1)), 1)-1;
    
        [STUDY_speech] = pop_clust(STUDY_speech, ALLEEG_speech, 'algorithm',...
            'kmeans', 'clus_num', numclusts);
        
        dipXyz_nonspeech = [];

        % Obtain xyz, dip moment, maxProj channel xyz.   
        for rr = 1:length(ALLEEG_speech)
        
            xyz = zeros(length(ALLEEG_nonspeech(rr).dipfit.model),3);
            
            for modelIdx = 1:length(ALLEEG_nonspeech(rr).dipfit.model)
         
                if isempty(ALLEEG_nonspeech(rr).dipfit.model(modelIdx).momxyz) || (ALLEEG_nonspeech(rr).dipfit.model(modelIdx).rv>=dipfit_criteria)
                    continue
                end
                
                % Choose the larger dipole if symmetrical.
                currentXyz = ALLEEG_nonspeech(rr).dipfit.model(modelIdx).posxyz;
                currentMom = ALLEEG_nonspeech(rr).dipfit.model(modelIdx).momxyz; % nAmm.
                if size(currentMom,1) == 2
                    [~,largerOneIdx] = max([norm(currentMom(1,:)) norm(currentMom(2,:))]);
                    currentXyz = ALLEEG_nonspeech(rr).dipfit.model(modelIdx).posxyz(largerOneIdx,:);
                end
                xyz(modelIdx,:) = currentXyz;
            end
            dipXyz_nonspeech = [dipXyz_nonspeech; xyz];
        end
    
        numclusts = size(nonzeros(dipXyz_nonspeech(:,1)), 1)-1;
    
        [STUDY_nonspeech] = pop_clust(STUDY_nonspeech, ALLEEG_nonspeech, 'algorithm',...
            'kmeans', 'clus_num', numclusts);
         
        % Optimize the number of clusters 
        kmeansClusters_speech = [];
        for clustIdx = 3:50 %30
            kmeansClusters_speech(:,clustIdx) = kmeans(dipXyz_speech, clustIdx, 'emptyaction', 'singleton', 'maxiter', 10000, 'replicate', 100);
        end
         % You'll want to modify the number of clusters at the top before you start
         % move on!
        kmeansClusters_speech = kmeansClusters_speech(:,3:50);
        eva1 = evalclusters(dipXyz_speech, kmeansClusters_speech, 'CalinskiHarabasz');
        eva2 = evalclusters(dipXyz_speech, kmeansClusters_speech, 'Silhouette');
        %eva3 = evalclusters(dipXyz_speech, kmeansClusters_speech, 'gap'); % Slow and not consistent value.
        eva4 = evalclusters(dipXyz_speech, kmeansClusters_speech, 'DaviesBouldin');
         
        figure
        subplot(1,3,1)
        plot(eva1); title('CalinskiHarabasz');
        subplot(1,3,2)
        plot(eva2); title('Silhouette');
        subplot(1,3,3)
        plot(eva4); title('DaviesBouldin');

        kmeansClusters_nonspeech = [];
        for clustIdx = 3:50 % 30
            kmeansClusters_nonspeech(:,clustIdx) = kmeans(dipXyz_nonspeech, clustIdx, 'emptyaction', 'singleton', 'maxiter', 10000, 'replicate', 100);
        end

        kmeansClusters_nonspeech = kmeansClusters_nonspeech(:,3:50);
        eva1 = evalclusters(dipXyz_nonspeech, kmeansClusters_nonspeech, 'CalinskiHarabasz');
        eva2 = evalclusters(dipXyz_nonspeech, kmeansClusters_nonspeech, 'Silhouette');
        eva3 = evalclusters(dipXyz_nonspeech, kmeansClusters_nonspeech, 'DaviesBouldin');

        opt_k = [eva1.OptimalK, eva2.OptimalK, eva4.OptimalK];
        
        numclusts = eva1.OptimalK;
        disp(char(string(numclusts) + " clusters"))
        
        reject_outlier = 1;
        if reject_outlier == 1
            [STUDY_speech] = pop_clust(STUDY_speech, ALLEEG_speech, 'algorithm',...
                'kmeans', 'clus_num', numclusts , 'outliers', stdcutoff );
            [STUDY_nonspeech] = pop_clust(STUDY_nonspeech, ALLEEG_nonspeech, 'algorithm',...
                'kmeans', 'clus_num', numclusts , 'outliers', stdcutoff );
        
        elseif reject_outlier == 0
            [STUDY_speech] = pop_clust(STUDY_speech, ALLEEG_speech, 'algorithm',...
                'kmeans', 'clus_num', numclusts );
            [STUDY_nonspeech] = pop_clust(STUDY_nonspeech, ALLEEG_nonspeech, 'algorithm',...
                'kmeans', 'clus_num', numclusts );
        end

        %% View dipoles
        %Only need if want to plot clusters
        
        %[STUDY] = pop_clustedit(STUDY, ALLEEG);
        %[STUDY_speech] = pop_clustedit(STUDY_speech, ALLEEG_speech);
        %[STUDY_nonspeech] = pop_clustedit(STUDY_nonspeech, ALLEEG_nonspeech);
        
    
        %% Compute centroid for each cluster
    
        [STUDY_speech, centroid_speech] = std_centroid(STUDY_speech, ALLEEG_speech, [] ,'dipole');
        STUDY_speech.centroids   = centroid_speech;

        [STUDY_nonspeech, centroid_nonspeech] = std_centroid(STUDY_nonspeech, ALLEEG_nonspeech, [] ,'dipole');
        STUDY_nonspeech.centroids   = centroid_nonspeech;
    
        STUDY_speech = pop_savestudy(STUDY_speech, ALLEEG_speech, 'savemode', 'standard','resavedatasets','on');
        STUDY_nonspeech = pop_savestudy(STUDY_nonspeech, ALLEEG_nonspeech, 'savemode', 'standard','resavedatasets','on');

        %% Get Talyarch coordinates from centroid positon
    
        mni_coords_speech = zeros(length(centroid_speech),3);
        for i = 1:length(centroid_speech)
            mni_coords_speech(i,1:3) = centroid_speech{i}.dipole.posxyz;
        end
    
        taly_conversion = 'mni2'; %'icbm' or 'mni2'
        
        if strcat(taly_conversion, 'mni2')
            taly_coords_speech = mni2tal(mni_coords_speech')';
        else
            taly_coords_speech = icbm_spm2tal(mni_coords_speech);
        end


        mni_coords_nonspeech = zeros(length(centroid_nonspeech),3);
        for i = 1:length(centroid_nonspeech)
            mni_coords_nonspeech(i,1:3) = centroid_nonspeech{i}.dipole.posxyz;
        end
    
        taly_conversion = 'mni2'; %'icbm' or 'mni2'
        
        if strcat(taly_conversion, 'mni2')
            taly_coords_nonspeech = mni2tal(mni_coords_nonspeech')';
        else
            taly_coords_nonspeech = icbm_spm2tal(mni_coords_nonspeech);
        end
    
        %%
        % Now likely use mni2tal to get talyard coordinates
        % Then get broadmann areas
        
        brodmann_pick = subject_brain_maps(pp); % 'ih' or 'rh'
        brodmann_areas_files = dir(char("BA_coordinates/" + brodmann_pick + "/"));
        
        centroids_summary_speech = cell(length(taly_coords_speech),4);
    
        for i = 1:size(taly_coords_speech,1)
            centroid_taly_speech = taly_coords_speech(i,:);
            centroid_BA_summary_speech = cell(length(brodmann_areas_files)-2, 2);
            for j = 3:length(brodmann_areas_files)
                brodman_coords = readmatrix("BA_coordinates/" + brodmann_pick + "/" + brodmann_areas_files(j).name);
                distances_BA_taly_speech = sqrt((centroid_taly_speech(1)-brodman_coords(:,2)).^2 + (centroid_taly_speech(2)-brodman_coords(:,3)).^2 + (centroid_taly_speech(3)-brodman_coords(:,4)).^2);
                centroid_BA_summary_speech{j-2,1} = brodmann_areas_files(j).name;
                centroid_BA_summary_speech{j-2,2} = min(distances_BA_taly_speech);
            end
            [min_distance, BA_index] = min(cell2mat(centroid_BA_summary_speech(:,2)));
            centroids_summary_speech{i, 1} = centroid_BA_summary_speech{BA_index,1};
            centroids_summary_speech{i, 2} = min_distance;
            centroids_summary_speech{i, 3} = centroid_speech{i,1}.dipole.rv;
            centroids_summary_speech{i, 4} = mean(abs(ALLEEG_speech.dipfit.model(dipfit_indices_speech(i)).datapot));
            centroids_summary_speech{i, 5} = ALLEEG_speech.dipfit.model(dipfit_indices_speech(i)).diffmap;
            centroids_summary_speech{i, 6} = ALLEEG_speech.dipfit.model(dipfit_indices_speech(i)).sourcepot;
            centroids_summary_speech{i, 7} = ALLEEG_speech.dipfit.model(dipfit_indices_speech(i)).datapot;
        end

        
        dipfit_indices_nonspeech =  [find(~cellfun(@isempty,{ALLEEG_nonspeech.dipfit.model(:).posxyz}))];
    
        for i = 1:length(taly_coords_nonspeech)
            centroid_taly_nonspeech = taly_coords_nonspeech(i,:);
            centroid_BA_summary_nonspeech = cell(length(brodmann_areas_files)-2, 2);
            for j = 3:length(brodmann_areas_files)
                brodman_coords = readmatrix("BA_coordinates/" + brodmann_pick + "/" + brodmann_areas_files(j).name);
                distances_BA_taly_nonspeech = sqrt((centroid_taly_nonspeech(1)-brodman_coords(:,2)).^2 + (centroid_taly_nonspeech(2)-brodman_coords(:,3)).^2 + (centroid_taly_nonspeech(3)-brodman_coords(:,4)).^2);
                centroid_BA_summary_nonspeech{j-2,1} = brodmann_areas_files(j).name;
                centroid_BA_summary_nonspeech{j-2,2} = min(distances_BA_taly_nonspeech);
            end
            [min_distance, BA_index] = min(cell2mat(centroid_BA_summary_nonspeech(:,2)));
            centroids_summary_nonspeech{i, 1} = centroid_BA_summary_nonspeech{BA_index,1};
            centroids_summary_nonspeech{i, 2} = min_distance;
            centroids_summary_nonspeech{i, 3} = centroid_nonspeech{i,1}.dipole.rv;
            centroids_summary_nonspeech{i, 4} = mean(abs(ALLEEG_nonspeech.dipfit.model(dipfit_indices_nonspeech(i)).datapot));
            centroids_summary_nonspeech{i, 5} = ALLEEG_nonspeech.dipfit.model(dipfit_indices_nonspeech(i)).diffmap;
            centroids_summary_nonspeech{i, 6} = ALLEEG_nonspeech.dipfit.model(dipfit_indices_nonspeech(i)).sourcepot;
            centroids_summary_nonspeech{i, 7} = ALLEEG_nonspeech.dipfit.model(dipfit_indices_nonspeech(i)).datapot;
        end

        
        if strcmp(identifier, "")
            
            temp_cluster = STUDY_speech.cluster;
            temp_BA_names = [{'Parent'}; centroids_summary_speech(:,1)];
            temp_distances = [{'Parent'}; centroids_summary_speech(:,2)];
            temp_residuals = [{'Parent'}; centroids_summary_speech(:,3)];
            [temp_cluster.('BA_names')] = temp_BA_names{:};
            [temp_cluster.('distances')] = temp_distances{:};
            [temp_cluster.('rv')] = temp_residuals{:};
            
            summary.('not_cleaned').('speech_cluster_model') = temp_cluster;
            
            
            temp_cluster = STUDY_nonspeech.cluster;
            temp_BA_names = [{'Parent'}; centroids_summary_nonspeech(:,1)];
            temp_distances = [{'Parent'}; centroids_summary_nonspeech(:,2)];
            temp_residuals = [{'Parent'}; centroids_summary_nonspeech(:,3)];
            [temp_cluster.('BA_names')] = temp_BA_names{:};
            [temp_cluster.('distances')] = temp_distances{:};
            [temp_cluster.('rv')] = temp_residuals{:};

            summary.('not_cleaned').('nonspeech_cluster_model') = temp_cluster;
            
            ALLEEG_filepath = "D:\Speech_Collection\Subject_data\EEG_Dipfit_allsubjects\Preprocessed\ALLEEGs\";

            summary.('not_cleaned').('opt_K') = opt_k;

            save(char( ALLEEG_filepath + "not_cleaned_speech_ALLEEG.mat"), "ALLEEG_speech")
            save(char( ALLEEG_filepath + "not_cleaned_nonspeech_ALLEEG.mat"), "ALLEEG_nonspeech")

        else
            temp_cluster = STUDY_speech.cluster;
            temp_BA_names = [{'Parent'}; centroids_summary_speech(:,1)];
            temp_distances = [{'Parent'}; centroids_summary_speech(:,2)];
            temp_residuals = [{'Parent'}; centroids_summary_speech(:,3)];
            [temp_cluster.('BA_names')] = temp_BA_names{:};
            [temp_cluster.('distances')] = temp_distances{:};
            [temp_cluster.('rv')] = temp_residuals{:};
            summary.(identifier).('speech_model') = [ALLEEG_speech(1:length(subject_names)).dipfit];
            summary.(identifier).('speech_cluster_model') = temp_cluster;

            temp_cluster = STUDY_nonspeech.cluster;
            temp_BA_names = [{'Parent'}; centroids_summary_nonspeech(:,1)];
            temp_distances = [{'Parent'}; centroids_summary_nonspeech(:,2)];
            temp_residuals = [{'Parent'}; centroids_summary_nonspeech(:,3)];
            [temp_cluster.('BA_names')] = temp_BA_names{:};
            [temp_cluster.('distances')] = temp_distances{:};
            [temp_cluster.('rv')] = temp_residuals{:};

            summary.(identifier).('nonspeech_cluster_model') = temp_cluster;
            summary.(identifier).('opt_K') = opt_k;

            ALLEEG_filepath = "D:\Speech_Collection\Subject_data\EEG_Dipfit_allsubjects\" + EMG_removal_type + "\ALLEEGs\";

            save(char( ALLEEG_filepath + identifier + "_speech_ALLEEG.mat"), "ALLEEG_speech")
            save(char( ALLEEG_filepath + identifier + "_nonspeech_ALLEEG.mat"), "ALLEEG_nonspeech")
        end

    end
end

var_names = ["BA" "distance_to_BA" "residual_var" "mean_power" "diffmap" "sourcepot" "datapot"];
temp_EMG_names = fields(summary);
for i = 1:size(temp_EMG_names, 1)
    temp_EMG_name = string(temp_EMG_names(i));
    
    [out, idx_speech] = sort(cell2mat(summary.(temp_EMG_name).speech(:,3)));
    summary.(temp_EMG_name).speech(:,:) = summary.(temp_EMG_name).speech(idx_speech,:);
    summary.(temp_EMG_name).speech = cell2table(summary.(temp_EMG_name).speech, VariableNames=var_names);


    [out, idx_nonspeech] = sort(cell2mat(summary.(temp_EMG_name).nonspeech(:,3)));
    summary.(temp_EMG_name).nonspeech(:,:) = summary.(temp_EMG_name).nonspeech(idx_nonspeech,:);
    summary.(temp_EMG_name).nonspeech = cell2table(summary.(temp_EMG_name).nonspeech, VariableNames=var_names);
end

filepath_dipfit_stats = char("D:/Speech_Collection/Subject_data/EEG_Dipfit_allsubjects/" + metrics_file_name);   
save(filepath_dipfit_stats, 'summary')
