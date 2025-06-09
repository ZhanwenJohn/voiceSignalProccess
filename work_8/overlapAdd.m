function output = overlapAdd(frames, wlen, inc)
% overlapAdd - 重叠相加法还原信号
% 输入:
%   frames - 每列为一帧的矩阵 (wlen × 帧数)
%   wlen   - 每帧的长度
%   inc    - 帧移
% 输出:
%   output - 重构后的连续语音信号

    [L, fn] = size(frames);   % L:帧长, fn:帧数
    output_len = (fn - 1) * inc + L;
    output = zeros(output_len, 1);

    for i = 1:fn
        start = (i - 1) * inc + 1;
        output(start:start + L - 1) = output(start:start + L - 1) + frames(:, i);
    end
end
