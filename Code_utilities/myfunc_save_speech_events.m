function myfunc_save_speech_events(EEG, Audio, session_number, block_number, textgrids_save, subject_name)

count=0;
event_count = 1;
temp_events = zeros(1000,2);

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
            
             % Pre-speech
            Speech_onset = round(Audio.event(i).latency/Audio.srate*EEG.srate + (text_grid.tier{1,2}.T1(2)*EEG.srate));
            temp_events(event_count, :) = [1, Speech_onset];

             % Post_speech
            Speech_offset = round(Audio.event(i).latency/Audio.srate*EEG.srate + (text_grid.tier{1,2}.T1(end)*EEG.srate));
            temp_events(event_count+1, :) = [0, Speech_offset];

            event_count = event_count + 2;
            count = count + 1;
        end

    else 
        continue
    end
end

temp_events = temp_events(1:event_count-1, :);
events_folder = char("D:\Speech_Collection\Subject_data\" + subject_name + "\Events\");
filename = char(events_folder+ "Events_speech_" + string(session_number) + '_' + string(block_number) + ".csv");
writematrix(temp_events, filename)
