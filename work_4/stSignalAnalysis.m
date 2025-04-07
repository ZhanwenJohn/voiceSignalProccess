%% 清除缓存并关闭所有窗口
clear;
close all;
clc;

%% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
if isequal(file,0)
    error('未选择文件，程序终止');
end
filename = fullfile(path, file);
[y, fs] = audioread(filename);
y = y(:, 1); % 如果是立体声，取单通道

%% 对整个信号进行 FFT
N = length(y);                    % 信号总长度
nfft = 2^nextpow2(N);             % FFT 点数，取下一个2的整数次幂
Y = fft(y, nfft);                 % 对整个信号进行 FFT

%% 取单边谱
halfN = floor(nfft/2) + 1;
Y_half = Y(1:halfN);
freq = (0:halfN-1) * fs / nfft;   % 构造频率轴

%% 计算幅度谱并转换为 dB
magY = abs(Y_half);
magY_db = 20 * log10(magY + eps); % eps 避免对数运算中的 -Inf

%% 计算功率谱
% 此处采用归一化：一般使用1/(fs*N)作为归一化因子，转换为功率谱密度
P = (1/(fs * N)) * abs(Y_half).^2;
% 注意单边谱功率需乘以2（除直流和Nyquist外）
if rem(nfft,2) == 0  % nfft为偶数
    P(2:end-1) = 2*P(2:end-1);
else               % nfft为奇数
    P(2:end) = 2*P(2:end);
end
P_db = 10 * log10(P + eps);

%% 绘图：幅度谱和功率谱
figure;

% 幅度谱图
subplot(2,1,1);
plot(freq, magY_db, 'b-', 'LineWidth', 1.5);
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
title('整个信号的幅度谱');
grid on;

% 功率谱图
subplot(2,1,2);
plot(freq, P_db, 'r-', 'LineWidth', 1.5);
xlabel('频率 (Hz)');
ylabel('功率 (dB)');
title('整个信号的功率谱');
grid on;
