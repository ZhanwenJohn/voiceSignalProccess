%% 清除缓存
clear;
close all;

%% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);
y = y(:, 1); % 单通道音频

%% 设置帧参数
frame_length = 1024;    % 帧长
frame_shift = 256;      % 帧移
hanning_win = hanning(frame_length); % Hanning窗

%% 分帧处理
fn = fix((length(y) - frame_length) / frame_shift) + 1;   % 计算帧数
frames = zeros(frame_length, fn);                         % 预分配存储空间

for i = 1:fn
    start_idx = (i - 1) * frame_shift + 1;
    end_idx = start_idx + frame_length - 1;
    frames(:, i) = y(start_idx:end_idx);
end

%% 计算倒谱分析
cepstrum = zeros(frame_length, fn); % 倒谱矩阵

for i = 1:fn
    frame = frames(:, i);           % 获取当前帧
    frame = frame .* hanning_win;   % 加窗

    % 对信号进行 FFT
    spectrum = fft(frame);
    
    % 计算对数功率谱
    log_spectrum = log(abs(spectrum) + eps);
    
    % 对数功率谱进行逆傅里叶变换
    c = ifft(log_spectrum);
    cepstrum(:, i) = real(c);
end

%% 绘制倒谱
figure;
plot(c);
xlabel('帧数');ylabel('倒谱系数索引');
title('倒谱分析');
grid on;

%% 基音周期估计
f0_estimates = zeros(1, fn); % 基音周期 F0 从倒谱的低阶系数中估计
for i = 1:fn
    c = cepstrum(:, i);
    % 估计基音周期为倒谱系数的最大周期（峰值位置）
    [~, max_lag] = max(c(2:frame_length));  % 排除第一个系数
    f0_estimates(i) = fs / max_lag;         % 基音频率 F0
end

% 绘制基音周期（F0）
figure;

subplot(3,1,1);
plot((0:length(y)-1) / fs, y);
xlabel('时间 (秒)');
ylabel('幅度');
title('原始语音信号');

subplot(3,1,2);
plot((1:fn) * frame_shift / fs, f0_estimates);
xlabel('时间 (秒)');ylabel('基音频率 (Hz)');
title('基音频率随时间变化');

%% 共振峰频率估计
formant_estimates = zeros(3, fn); % 假设有3个共振峰

for i = 1:fn
    c = cepstrum(:, i);
    
    % 取倒谱的高阶系数
    high_order_cepstrum = c(10:end);  % 去掉低阶倒谱系数（基音周期部分）
    
    % 找到局部最大值作为共振峰频率的估计
    [peaks, locs] = findpeaks(high_order_cepstrum);
    
    % 提取前3个共振峰频率
    formant_estimates(:, i) = locs(1:3) * fs / frame_length;
end

% 绘制共振峰频率
subplot(3,1,3);
plot((1:fn) * frame_shift / fs, formant_estimates');
xlabel('时间 (秒)');ylabel('频率 (Hz)');
title('共振峰频率随时间变化');
legend('F1', 'F2', 'F3');

