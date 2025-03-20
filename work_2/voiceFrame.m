clear;
close all;

%% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);
if size(y, 2) > 1
    y = mean(y, 2);
end

%% 设定帧长和帧移
frame_duration = 0.01;
frame_length = frame_duration * fs;
fprintf('计算窗口大小: %d\n', frame_length);
% 计算帧长
if mod(log2(frame_length), 1) == 0
    frame_length = frame_length * 2;
else
    frame_length = 2^(ceil(log2(frame_length)));
end
fprintf('实际窗口大小: %d\n', frame_length);
start_idx = 120000;
end_idx = start_idx + frame_length - 1;

%% 生成汉明窗
hamming_window = hamming(frame_length, 'periodic');

%% 汉明窗处理帧
frames = y(start_idx:end_idx)' .* hamming_window';

%% 绘制汉明窗
figure;
plot((0:frame_length-1) / fs, frames);
title('Hamming Window Wave');
xlabel('时间 (秒)');
ylabel('振幅');
grid on;

%% 生成矩形窗
rectangular_window = rectwin(frame_length);

%% 矩形窗处理帧
frames = y(start_idx:end_idx)' .* rectangular_window';

%% 绘制矩形窗
figure;
stem((0:frame_length-1) / fs, rectangular_window, 'b', 'filled');
xlabel('样本点');
ylabel('幅度');
title('Rectangular Window Wave');
grid on;