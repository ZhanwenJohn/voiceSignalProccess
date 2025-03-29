%% 清除缓存
clear;
close all;

%% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);
y = y(:, 1); % 取单通道音频

%% 设定帧参数
frame_length = 200;    % 帧长
frame_shift = 80;      % 帧移

%% 分帧处理
fn = fix((length(y) - frame_length) / frame_shift) + 1;   % 计算帧数
frames = zeros(frame_length, fn);                         % 预分配存储空间

for i = 1:fn
    start_idx = (i - 1) * frame_shift + 1;  % 计算起始索引
    end_idx = start_idx + frame_length - 1; % 计算结束索引
    frames(:, i) = y(start_idx:end_idx);    % 逐帧提取
end

%% 计算 Hamming 窗
hamming_win = hamming(frame_length); % 计算 Hamming 窗

%% Hamming 加窗
for i = 1:fn
    frames(:, i) = frames(:, i) .* hamming_win; % 加窗
end

%% 计算短时能量
En = zeros(1, fn);
for i = 1:fn
    frame = frames(:, i);
    En(i) = sum(frame .^ 2);    % 能量计算
end

%% 计算短时自相关函数
frame_idx = 100;                   % 选择帧进行自相关分析
if frame_idx > fn
    frame_idx = fn;                % 避免索引超出帧数
end
frame = frames(:, frame_idx);      % 取出目标帧
y_corr = xcorr(frame, 'biased');   % 归一化计算自相关
y_corr = y_corr(frame_length:end); % 仅取正值部分
self_relate_lags = (0:length(y_corr)-1) / fs;  % 计算滞后时间（秒）

%% AMDF算法分析
amdf_max_lag = 80;  % 设置最大滞后范围
AMDF = zeros(amdf_max_lag, 1);
for k = 1:amdf_max_lag
    diff_sum = sum(abs(frame(1:end-k) - frame(1+k:end)));
    AMDF(k) = diff_sum / (frame_length - k);
end
amdf_lags = (1:amdf_max_lag) / fs * 1000; % 转换为毫秒单位

%% 绘制波形
figure;

% 原始语音
subplot(4,1,1);
plot(y);
title('原始语音信号');
xlabel('时间/s');
ylabel('幅值');
grid on;

% 短时能量
subplot(4,1,2);
plot(En);
title('短时能量仿真分析');
xlabel('帧数');
ylabel('能量');

% 短时自相关
subplot(4,1,3);
plot(y_corr);
title('短时自相关分析');
xlabel('自相关序号');
ylabel('幅值');

% AMDF算法
subplot(4,1,4);
plot(AMDF);
title('AMDF算法分析');
xlabel('滞后时间 (ms)');
ylabel('AMDF 值');
