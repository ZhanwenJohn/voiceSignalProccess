clear;
close all;

%% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);

%% 计算波形参数
time = (0:length(y)-1) / fs;  % 时间轴
signal_length = length(y);     % 信号长度
duration = signal_length / fs; % 音频时长（秒）
max_amplitude = max(abs(y));   % 最大振幅
rms_amplitude = rms(y);        % 均方根振幅

%% 绘制语音波形
figure;
plot(time, y);
xlabel('Time (s)');
ylabel('Amplitude');
title('Voice Signal Wave');
grid on;

%% 显示基本参数
fprintf('采样率: %d Hz\n', fs);
fprintf('信号长度: %d 样本点\n', signal_length);
fprintf('音频时长: %.2f 秒\n', duration);
fprintf('最大振幅: %.4f\n', max_amplitude);
fprintf('均方根振幅: %.4f\n', rms_amplitude);
