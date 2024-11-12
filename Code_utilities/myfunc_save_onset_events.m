function myfunc_save_phon_events(EEG, Audio, session_number, block_number, textgrids_save, subject_name)

count=0;
temp_events = zeros(size(EEG.data,2),1);

for i = 1:length(Audio.event)
    if strcmp(Audio.event(i).type, 'boundary') || strcmp(Audio.event(i).type, 'R 8') || strcmp(Audio.event(i).type, 'S 13') || strcmp(Audio.event(i).type, 'S 14') || i+4>length(Audio.event)
        continue
    elseif strcmp(Audio.event(i).type, 'S 11') && strcmp(Audio.event(i+2).type, 'S 12') && strcmp(Audio.event(i+4).type, 'S 15')
        index1 = Audio.event(i+1).type;
        index1 = (str2num(index1(2:end))-1)*10;
        index2 = Audio.event(i+3).type;
        index2 = (str2num(index2(2:end))-1);
        
        if index2==0
            index2=index2+10;
        end
        index = index1+index2;
        
        textgrid_filename = (textgrids_save + "S" + num2str(session_number) + "_B" + num2str(block_number) + "_" + string(count)+ '_' + string(index) + '.TextGrid');
        if ~isfile(textgrid_filename) || i+4>size(EEG.event, 2)
            count = count + 1;
            continue
        else
            text_grid = tgRead(textgrid_filename);

            for n = 1:length(text_grid.tier{1,2}.T1)
                
                starting_point = round(Audio.event(i).latency/Audio.srate*EEG.srate + (text_grid.tier{1,2}.T1(n)*EEG.srate));
                ending_point = round(Audio.event(i).latency/Audio.srate*EEG.srate + round(text_grid.tier{1,2}.T2(n)*EEG.srate));
                middel_point = round((starting_point+ending_point)/2);
                phoneme_duration = min(ending_point-starting_point, 100);

                if char(text_grid.tier{1,2}.Label(n))==""
                    continue
                else
                    %temp_events(starting_point+1) = char(text_grid.tier{1,2}.Label(n) + "_1");
                    %temp_events(middel_point) = char(text_grid.tier{1,2}.Label(n) + "_2");
                    %temp_events(ending_point) = char(text_grid.tier{1,2}.Label(n) + "_3");
                    temp_events(starting_point+1-round(phoneme_duration/2):starting_point+1) = 0:1/round(phoneme_duration/2):1;
                    temp_events(starting_point+1:starting_point+1+round(phoneme_duration/2)) = 1:-1/round(phoneme_duration/2):0;

                end

            end

            count = count + 1;
        end

    else 
        continue
    end
end

events_folder = char("D:\Speech_Collection\Subject_data\" + subject_name + "\Events\");
filename = char(events_folder + "Events_onsets_" + string(session_number) + '_' + string(block_number) + ".csv");
index_column = 1:size(temp_events, 1);
writematrix([temp_events, index_column'], filename)
