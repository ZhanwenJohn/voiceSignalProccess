%% 清除缓存
clear;
clc;
close all;

%% 读取音频信号
[x, fs] = audioread("test.wav");
x = x - mean(x);   % 去均值
x = x / max(abs(x));   % 归一化

%% 获取信号长度和时间坐标
x1 = length(x);
time = (0:x1-1) / fs;

%% LPC分析参数
p = 12;             % LPC阶数
wlen = 256;         % 帧长
inc = 64;           % 帧移

%% 分帧处理
msoverlap = wlen - inc;
fn = fix((x1 - wlen) / inc) + 1;  % 帧数
frames = zeros(wlen, fn);

for i = 1:fn
    start_idx = (i - 1) * inc + 1;
    end_idx = start_idx + wlen - 1;
    frames(:, i) = x(start_idx:end_idx);  % 对每一帧进行分帧处理
end

%% 存储LPC系数和预测误差
aCoeff = zeros(p+1, fn);  % 存储LPC系数
resid = zeros(wlen, fn);   % 存储每帧的预测误差

for i = 1:fn
    u = frames(:, i);  % 获取当前帧
    A = lpc(u, p);     % 计算LPC系数
    aCoeff(:, i) = A;  % 存储LPC系数
    errSig = filter(A, 1, u);  % 计算预测误差
    resid(:, i) = errSig;  % 存储误差信号
end

%% 合成语音信号
outspeech = zeros(x1, 1);  % 初始化合成语音信号

for i = 1:fn
    A = aCoeff(:, i);      % 获取LPC系数
    residFrame = resid(:, i);  % 获取预测误差
    synFrame = filter(1, A', residFrame);  % 使用LPC系数合成帧
    start_idx = (i - 1) * inc + 1;
    end_idx = start_idx + wlen - 1;
    
    % 叠加合成信号
    outspeech(start_idx:end_idx) = outspeech(start_idx:end_idx) + synFrame;
end

o1 = length(outspeech);
if o1<x1
    outspeech = [outspeech zeros(1, x1-o1)];
end

%% 播放语音信号
sound(outspeech, fs);

%% 绘制原始语音信号与合成语音信号
figure;
% 原始语音信号
subplot(2, 1, 1);
plot(time, x, 'k');
title('原始语音信号');
xlabel('时间/s');
ylabel('幅值');
% 基于LPC合成的语音信号
subplot(2, 1, 2);
plot(time, outspeech, 'k');
title('基于LPC合成的语音信号');
xlabel('时间/s');
ylabel('幅值');
