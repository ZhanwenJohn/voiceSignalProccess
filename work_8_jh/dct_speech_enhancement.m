function [enhanced_signal] = dct_speech_enhancement(noisy_signal, fs)
% DCT语音增强算法
% 输入:
%   noisy_signal - 带噪语音信号
%   fs - 采样率 (Hz)
% 输出:
%   enhanced_signal - 增强后的语音信号

% 参数设置
frame_length = round(0.025 * fs);  % 25ms帧长
hop_length = round(0.5 * frame_length);  % 50%重叠
window = hann(frame_length, 'periodic'); % 汉宁窗
alpha = 2.5;     % 过减因子
beta = 0.1;      % 谱减下限
noise_margin = 3; % 噪声更新阈值 (dB)
n_est_frames = 5; % 初始噪声估计帧数

% 预处理：确保为列向量
noisy_signal = noisy_signal(:);
signal_length = length(noisy_signal);

% 计算帧数
num_frames = floor((signal_length - frame_length) / hop_length) + 1;

% 初始化变量
enhanced_frames = zeros(frame_length, num_frames);
noise_power = zeros(frame_length, 1);
min_power = inf(frame_length, 1);

% 1. 分帧处理
frames = buffer(noisy_signal, frame_length, frame_length - hop_length, 'nodelay');

% 2. 初始噪声估计（前n_est_frames帧）
for i = 1:n_est_frames
    frame = frames(:, i) .* window;
    dct_coeffs = dct(frame);  % DCT变换
    
    % 更新噪声功率估计
    noise_power = noise_power + abs(dct_coeffs).^2;
    
    % 更新最小功率跟踪
    current_power = abs(dct_coeffs).^2;
    min_power = min(min_power, current_power);
end
noise_power = noise_power / n_est_frames;  % 平均噪声功率

% 3. 处理所有帧
for i = 1:num_frames
    % 当前帧加窗
    frame = frames(:, i) .* window;
    
    % DCT变换
    dct_coeffs = dct(frame);
    magnitude = abs(dct_coeffs);
    phase = angle(dct_coeffs);
    
    % 计算当前帧功率
    signal_power = magnitude.^2;
    
    % 更新最小功率跟踪（用于噪声估计）
    min_power = min(min_power, signal_power);
    
    % 动态噪声更新（仅当非语音段时更新）
    snr_db = 10*log10(signal_power ./ (noise_power + eps));
    if mean(snr_db) < noise_margin
        noise_power = 0.98*noise_power + 0.02*signal_power;
    end
    
    % 谱减法（幅度谱处理）
    gain = max(1 - alpha * sqrt(noise_power ./ (signal_power + eps)), beta);
    enhanced_magnitude = magnitude .* gain;
    
    % 重建复数DCT系数
    enhanced_dct = enhanced_magnitude .* exp(1i*phase);
    
    % 逆DCT
    enhanced_frame = idct(real(enhanced_dct));
    
    % 存储增强后的帧
    enhanced_frames(:, i) = enhanced_frame .* window; % 加窗补偿
end

% 4. 重叠相加合成
enhanced_signal = zeros(signal_length, 1);
for i = 1:num_frames
    start_idx = (i-1)*hop_length + 1;
    end_idx = start_idx + frame_length - 1;
    
    % 处理边界情况
    if end_idx > signal_length
        enhanced_frames(:, i) = enhanced_frames(1:signal_length-start_idx+1, i);
        end_idx = signal_length;
    end
    
    % 重叠相加
    enhanced_signal(start_idx:end_idx) = ...
        enhanced_signal(start_idx:end_idx) + enhanced_frames(1:(end_idx-start_idx+1), i);
end

% 5. 后处理：归一化防止削波
enhanced_signal = 0.8 * enhanced_signal / max(abs(enhanced_signal));
end