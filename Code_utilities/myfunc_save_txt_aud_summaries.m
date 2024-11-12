function myfunc_save_txt_aud_summaries(Audio, Audio_filtered_normalized, session_number, block_number, Audio_save, base_sentences, subject_name)

summary_sent = [];
count=0;
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

        temp_sent = base_sentences(index);
        fid = fopen(Audio_save + "All_audio/S" + num2str(session_number) + "_B" + num2str(block_number) + "_"+ num2str(count) + '_' +num2str(index) + '.txt','wt');
        fprintf(fid, temp_sent);
        fclose(fid);
        
        summary_sent = [summary_sent; num2str(count) + ". " + temp_sent];

        temp_audio = Audio_filtered_normalized(:,Audio.event(i).latency:Audio.event(i+4).latency);
        audiowrite(Audio_save + "All_audio/S" + num2str(session_number) + "_B" + num2str(block_number) + "_"+ num2str(count) + '_' +num2str(index) + '.wav', temp_audio, Audio.srate)

        count = count + 1;

    else 
        continue
    end
end

%% Save Block Sentence Summary

fid = fopen(Audio_save + "Session_" + num2str(session_number) + "_Block_" + num2str(block_number) + '_summary.txt','wt');
fprintf(fid, '%s\n',summary_sent);
fclose(fid);
