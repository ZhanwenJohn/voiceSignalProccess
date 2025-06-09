clc; clear; close all;

%% 读取语音
[x, fs] = audioread("voice/test.wav"); 
x = x(:, 1);
x = x - mean(x);
x = x / max(abs(x));

%% 参数
wlen = 256; inc = 80;
win = hamming(wlen);
x_framed = buffer(x, wlen, wlen - inc, 'nodelay');
[~, fn] = size(x_framed);

%% 简单 VAD 标记
vad_flags = vadEnergy(x_framed, win, 0.01);  
global_noise = estimateNoise(x_framed, vad_flags); 

%% 初始化
X_klt_raw = zeros(size(x_framed));
X_klt_wiener = zeros(size(x_framed));

%% 主处理循环
for i = 1:fn
    frame = x_framed(:, i) .* win;
    C = robustCovEst(frame);
    [V, D] = eig(C);
    klt_coeff = V' * frame;

    X_klt_raw(:, i) = V * klt_coeff;

    % === Wiener 滤波 ===
    signal_energy = diag(D);
    noise_proj = V' * global_noise * V;
    noise_energy = diag(noise_proj);

    gain = signal_energy ./ (signal_energy + noise_energy + eps);
    gain = max(gain, 0.1);  % 加下限，避免抑制过度

    klt_coeff_filt = gain .* klt_coeff;
    X_klt_wiener(:, i) = V * klt_coeff_filt;
end

%% 重叠相加
output_raw = overlapAdd(X_klt_raw, wlen, inc);
output_final = overlapAdd(X_klt_wiener, wlen, inc);
output_final = output_final / max(abs(output_final));

%% 绘图
t = (0:length(x)-1)/fs;
subplot(3,1,1); plot(t, x, 'k'); title("原始语音信号"); xlabel("时间/s"); ylabel("幅度");
subplot(3,1,2); plot(t, output_raw(1:length(x)), 'k'); title("KLT增强后语音"); xlabel("时间/s"); ylabel("幅度");
subplot(3,1,3); plot(t, output_final(1:length(x)), 'k'); title("Wiener滤波后语音"); xlabel("时间/s"); ylabel("幅度");

%% 播放
sound(output_raw, fs);
