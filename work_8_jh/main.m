clc; clear; close all;
% 1. 生成测试信号（干净语音+噪声）
[clean, fs] = audioread('test.wav');  % 替换为您的干净语音文件
SNR = 5;                          % 设置信噪比（单位 dB）
signal = Gnoisegen(clean, SNR);        % 添加白噪声
snr1 = SNR_singlech(clean, signal);    % 初始 SNR
sound(signal, fs);

% 2. 执行语音增强
enhanced_signal = dct_speech_enhancement(signal, fs);

% 3. 结果可视化
t = (0:length(clean)-1)/fs;
figure;
subplot(3,1,1); plot(t, clean); title('Clean Speech'); xlabel('Time (s)');
subplot(3,1,2); plot(t, signal); title('Noisy Speech (SNR=5dB)'); 
subplot(3,1,3); plot(t, enhanced_signal); title('Enhanced Speech (DCT Method)');

% 4. 频谱对比
nfft = 1024;
figure;
subplot(3,1,1); spectrogram(clean, hann(256), 128, nfft, fs, 'yaxis'); 
title('Clean Spectrogram');
subplot(3,1,2); spectrogram(signal, hann(256), 128, nfft, fs, 'yaxis'); 
title('Noisy Spectrogram');
subplot(3,1,3); spectrogram(enhanced_signal, hann(256), 128, nfft, fs, 'yaxis'); 
title('Enhanced Spectrogram');

% 5. 试听结果
%soundsc(enhanced_signal, fs);