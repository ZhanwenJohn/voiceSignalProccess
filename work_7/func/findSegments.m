function [seg, count] = findSegments(SF)
% findSegments - 从语音帧标记中提取语音段结构体
% 输入：
%   SF - 标记数组（0=静音，1=语音）或语音帧索引数组
% 输出：
%   seg   - 包含 begin、end、duration 的结构体数组
%   count - 语音段个数

    % 判断输入是标签数组还是语音帧索引
    if islogical(SF) || all(SF == 0 | SF == 1)
        voicedIndex = find(SF);
    else
        voicedIndex = SF;
    end

    seg = struct('begin', {}, 'end', {}, 'duration', {});
    count = 0;

    if isempty(voicedIndex)
        return; % 无语音段
    end

    count = 1;
    seg(count).begin = voicedIndex(1);

    for i = 1:length(voicedIndex) - 1
        if voicedIndex(i+1) - voicedIndex(i) > 1
            seg(count).end = voicedIndex(i);
            count = count + 1;
            seg(count).begin = voicedIndex(i+1);
        end
    end

    seg(count).end = voicedIndex(end);

    % 计算每段长度
    for i = 1:count
        seg(i).duration = seg(i).end - seg(i).begin + 1;
    end
end