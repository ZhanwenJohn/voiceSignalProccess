function [voiceseg, vosl, SF, Ef] = pitch_vad1(y, fn, T1)
% 基音端点检测（基于短时能量和过零率）
% 输入:
%   y: 分帧后的语音信号（每列为一帧）
%   fn: 总帧数
%   T1: 能量阈值（用于有话段判断）
% 输出:
%   voiceseg: 有话段信息（结构体数组，包含begin/end/duration）
%   vosl: 有话段数量
%   SF: 有话帧标记（1表示有话，0表示无声）
%   Ef: 短时能量

wlen = size(y, 1);              % 帧长
energy = sum(y.^2);             % 计算每帧能量
Ef = energy / max(energy);      % 能量归一化

% 过零率计算（辅助判断清音）
zcr = zeros(1, fn);
for k = 1:fn
    x = y(:, k);                % 取一帧
    x1 = x(1:end-1);
    x2 = x(2:end);
    zcr(k) = sum(abs(sign(x2) - sign(x1))) / (2 * wlen); % 过零率公式
end

% 有话段初步标记（基于能量阈值）
SF = (Ef > T1);                % 能量高于阈值则为有话帧

% 平滑处理（合并相邻有话帧，去除孤立噪声点）
min_seg_length = 3;             % 最小有话段长度（帧数）
SF = smooth_sf(SF, min_seg_length);

% 提取有话段信息
voiceseg = find_segments(SF);
vosl = length(voiceseg);  % 语音段数量

end

%% 子函数：平滑处理
function SF = smooth_sf(SF, min_len)
% 合并相邻有话段，去除短于min_len的段
SF = SF(:)';                    % 转为行向量
diff_SF = diff([0, SF, 0]);     % 差分找边界
start_idx = find(diff_SF == 1); % 有话段起点
end_idx = find(diff_SF == -1) - 1; % 有话段终点

% 合并相邻段并过滤短段
valid_segs = (end_idx - start_idx + 1) >= min_len;
start_idx = start_idx(valid_segs);
end_idx = end_idx(valid_segs);

% 重构SF
SF = zeros(size(SF));
for k = 1:length(start_idx)
    SF(start_idx(k):end_idx(k)) = 1;
end
end

%% 子函数：提取有话段信息
function voiceseg = find_segments(SF)
% 从SF标记中提取有话段信息
voiceseg = struct('begin', {}, 'end', {}, 'duration', {});
diff_SF = diff([0, SF, 0]);     % 差分找边界
start_idx = find(diff_SF == 1); % 有话段起点
end_idx = find(diff_SF == -1) - 1; % 有话段终点

for k = 1:length(start_idx)
    voiceseg(k).begin = start_idx(k);
    voiceseg(k).end = end_idx(k);
    voiceseg(k).duration = end_idx(k) - start_idx(k) + 1;
end
end
