clear;
close all;

%% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);
if size(y, 2) > 1
    y = mean(y, 2);
end

%% 设定帧长
frame_duration = 0.05;
frame_length = frame_duration * fs;
fprintf('计算窗口大小: %d\n', frame_length);
start_id = 12512;

%% 生成海明窗
hamming_window = hamming(frame_length);

%% 海明窗处理帧
hm_frames = y(start_id:start_id+frame_length-1)' .* hamming_window';

%% 绘制海明窗窗
figure;
subplot(2,1,1);
plot((0:frame_length-1) / fs, hm_frames);
title('Hamming Window Wave');
xlabel('sample point');
ylabel('Amplitude');

%% 生成矩形窗
% rectangular_length = frame_length / 4;
rectangular_window = rectwin(frame_length);
rectangular_frams = y(start_id:start_id+frame_length-1)' .* rectangular_window';

%% 绘制矩形窗
subplot(2,1,2);
stem((0:frame_length-1) / fs, rectangular_frams);
xlabel('sample point');
ylabel('Amplitude');
title('Rectangular Window Wave');

%% 绘制语谱图
figure;
spectrogram(y);
title('Spectrogram');

%% 清浊音分析
time = (0:length(y)-1) / fs;
energy = sum(y.^2) / length(y);
zcr = sum(abs(diff(sign(y)))) / length(y);

if energy > 0.01 && zcr < 0.1
    disp('语音信号中存在清音');
else
    disp('语音信号中存在浊音');
end