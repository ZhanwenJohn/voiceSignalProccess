%% 清除缓存
clear;
close all;

%% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);
y = y(:, 1); % 单通道

%% 设置帧参数
frame_length = 1024;
frame_shift = 256;
hanning_win = hanning(frame_length);

%% 分帧处理
fn = fix((length(y) - frame_length) / frame_shift) + 1;   % 计算帧数
frames = zeros(frame_length, fn);                         % 预分配存储空间

for i = 1:fn
    start_idx = (i - 1) * frame_shift + 1;
    end_idx = start_idx + frame_length - 1;
    frames(:, i) = y(start_idx:end_idx);
end

%% 加窗处理
cepstrum = zeros(frame_length, fn); % 倒谱矩阵
for i = 1:fn
    frames(:, i) = frames(:, i) .* hanning_win;
    spectrum = fft(frames(:, i));
    log_spectrum = log(abs(spectrum) + eps);
    c = ifft(log_spectrum);
    cepstrum(:, i) = real(c);
end

%% 选择
frame_idx = 50;
if frame_idx > fn
    frame_idx = fn;
end
frame_win = frames(:, frame_idx);

%% 同态处理与还原
fft_frame = ifft(log(fft(frame_win) + eps));    %% esp防止log(0)
ifft_frame = ifft(exp(fft(fft_frame)));

%% X轴为样本点索引
x = 1:frame_length;

%% 绘图
figure;

subplot(2,1,1);
plot(x, frame_win, 'b-');
title('原始信号');
xlabel('样本点'); ylabel('幅度');

% subplot(3,1,2);
% plot(x, fft_frame, 'm-');
% title('倒谱分析信号');
% xlabel('样本点'); ylabel('幅度');

subplot(2,1,2);
plot(x, ifft_frame, 'r-');
title('同态还原信号');
xlabel('样本点'); ylabel('幅度');

%% 误差
relative_error = norm(frame_win - real(ifft_frame)) / norm(frame_win);
disp(['同态处理还原的相对误差：', num2str(relative_error)]);

%% 基音周期估计
f0_estimates = zeros(1, fn); % 基音周期 F0 从倒谱的低阶系数中估计
for i = 1:fn
    c = cepstrum(:, i);
    % 估计基音周期为倒谱系数的最大周期（峰值位置）
    [~, max_lag] = max(c(2:frame_length));  % 排除第一个系数
    f0_estimates(i) = fs / max_lag;         % 基音频率 F0
end

% 绘制基音周期和共振峰波形
figure;
subplot(2,1,1);
plot((0:length(y)-1) / fs, y);
xlabel('时间 (秒)');
ylabel('幅度');
title('原始语音信号');

subplot(2,1,2);
plot((1:fn) * frame_shift / fs, f0_estimates);
xlabel('时间 (秒)');
ylabel('基音频率 (Hz)');
title('基音频率随时间变化');
