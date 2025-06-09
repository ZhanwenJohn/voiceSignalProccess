clc; clear; close all;
%% === 读取语音 ===
[x, fs] = audioread("voice/test.wav");
x = x(:, 1);
x = x - mean(x);
x = x / max(abs(x));
%% === 加噪处理 ===
SNR = 10;                          % 设置信噪比（单位 dB）
signal = Gnoisegen(x, SNR);        % 添加白噪声
snr1 = SNR_singlech(x, signal);    % 初始 SNR
%% === 分帧 ===
wlen = 512; inc = 128;
win = hamming(wlen);
x_framed = buffer(signal, wlen, wlen - inc, 'nodelay');
[~, fn] = size(x_framed);
%% === VAD检测（基于能量+过零率）===
T1 = 0.01;  % 能量门限
[voiceseg, vosl, SF, Ef] = pitch_vad1(x_framed, fn, T1);
global_noise = estimateNoise(x_framed, SF == 0);  % 用无话帧估计噪声
%% === 初始化 ===
X_klt_raw = zeros(size(x_framed));        % KLT增强后语音（未滤波）
X_klt_wiener = zeros(size(x_framed));     % Wiener滤波后语音
%% === 主处理循环 ===
for i = 1:fn
    frame = x_framed(:, i) .* win;
    C = robustCovEst(frame);
    [V, D] = eig(C);
    klt_coeff = V' * frame;
    % --- KLT增强 ---
    X_klt_raw(:, i) = V * klt_coeff;
    % --- Wiener滤波 ---
    signal_energy = diag(D);
    noise_proj = V' * global_noise * V;
    noise_energy = diag(V' * global_noise * V);
    gain = signal_energy ./ (signal_energy + noise_energy + eps);
    gain = max(gain, 0.18);  % 控制最小增益
    klt_coeff_filt = gain .* klt_coeff;
    X_klt_wiener(:, i) = V * klt_coeff_filt;
end
%% === 重叠相加恢复语音 ===
output_klt = overlapAdd(X_klt_raw, wlen, inc);
output_final = overlapAdd(X_klt_wiener, wlen, inc);
output_final = output_final / max(abs(output_final));
%% === 可视化 ===
t = (0:length(x)-1) / fs;
figure;
subplot(4,1,1); plot(t, x); title("原始语音信号"); ylabel("幅度"); grid on;
subplot(4,1,2); plot(t, signal); title(sprintf("加噪语音信号 (SNR = %.2f dB)", snr1)); ylabel("幅度"); grid on;
subplot(4,1,3); plot(t, output_klt(1:length(x))); title("KLT增强后语音"); ylabel("幅度"); grid on;
subplot(4,1,4); plot(t, output_final(1:length(x))); title("Wiener滤波后语音"); ylabel("幅度"); xlabel("时间/s"); grid on;
%% === 播放增强语音 ===
sound(output_final, fs);