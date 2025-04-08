%% 清除缓存
clear;
close all;

%% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);
time = (0:length(y)-1) / fs;
y = y(:, 1); % 取单通道音频

%% 设定帧参数
frame_length = 512;    % 帧长
frame_shift = 128;      % 帧移

%% 分帧处理
fn = fix((length(y) - frame_length) / frame_shift) + 1;   % 计算帧数
frame_time = (((1:fn)-1)*frame_shift + frame_length/2)/fs; % 每帧中心对应的时间（秒）
frames = zeros(frame_length, fn);                         % 预分配存储空间

for i = 1:fn
    start_idx = (i - 1) * frame_shift + 1;  % 计算起始索引
    end_idx = start_idx + frame_length - 1; % 计算结束索引
    frames(:, i) = y(start_idx:end_idx);    % 逐帧提取
end

%% 计算 Hanning 窗
hanning_win = hanning(frame_length); % 计算 Hanning 窗
for i = 1:fn
    frames(:, i) = frames(:, i) .* hanning_win; % 每帧加窗
end

%% 计算短时幅度谱
fft_frames = fft(frames, frame_length, 2);% 对每一帧进行 FFT
mag_S = abs(fft_frames).^2 + eps;
mag_mean = mean(mag_S, 1);
mag_db = 20*log10(mag_mean(1:frame_length/2 + 1));
freq = (0:frame_length/2)*fs/frame_length;

%% 计算短时功率谱
[S, F, T] = spectrogram(y, frame_length, frame_shift, frame_length, fs);  % 短时傅里叶变换
P = abs(S).^2;  
P_mean = mean(P, 1);


%% 绘制波形
figure;
% 原始语音
subplot(3,1,1);
plot(time, y);
title('原始语音信号');
xlabel('时间/s');
ylabel('幅值');
grid on;

% 绘制短时幅度谱
subplot(3,1,2);
plot(freq, mag_db, 'b-');
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
title('短时幅度谱');
grid on;

% 绘制短时功率谱
subplot(3, 1, 3);
plot(T, P_mean, 'b-');
xlabel('时间/s');
ylabel('功率 (dB)');
title('短时功率谱');
grid on;
