%% 清除缓存
clear;
close all;

%% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);
y = y(:, 1); % 取单通道音频

%% 设定帧参数
frame_length = 256;    % 帧长
frame_shift = 64;      % 帧移

%% 分帧处理
fn = fix((length(y) - frame_length) / frame_shift) + 1;   % 计算帧数
frame_time = (((1:fn)-1)*frame_shift + frame_length/2)/fs;% 计算每帧对应的时间
frames = zeros(frame_length, fn);                         % 预分配存储空间

for i = 1:fn
    start_idx = (i - 1) * frame_shift + 1;  % 计算起始索引
    end_idx = start_idx + frame_length - 1; % 计算结束索引
    frames(:, i) = y(start_idx:end_idx);    % 逐帧提取
end

%% 计算 Hanning 窗
hanning_win = hanning(frame_length); % 计算 Hanning 窗

for i = 1:fn
    frames(:, i) = frames(:, i) .* hanning_win; % 加窗
end

%% 计算短时傅里叶变换（STFT）
fft_frames = fft(frames);           % 对每一帧进行 FFT

frame_length2 = floor(frame_length/2) + 1;
S = fft_frames(1:frame_length2, :); % 取每帧 FFT 的前半部分（直流到Nyquist）

freq = (0:frame_length2-1)*fs/frame_length; % 构造频率轴（单位 Hz）

magS = abs(S);                      % 计算幅度谱，并转换为dB（加上 eps 避免对数为负无穷）
magS_db = 20*log10(magS + eps);

%% 选择一帧进行绘制（波形图形式显示幅度谱）
frame_idx = 100;
if frame_idx > fn
    frame_idx = fn;
end
mag_spec = magS_db(:, frame_idx);

figure;
plot(freq, mag_spec, 'b-', 'LineWidth', 1.5);
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
title(sprintf('第 %d 帧的幅度谱', frame_idx));
grid on;

