%% 清除缓存
clear;clc;close all;
%% 读取音频信号
[x, fs] = audioread("test.wav");
x=x-mean(x);                           % 去除直流分量
x1=x/max(abs(x));                       % 归一化
N=length(x);                              % 数据长度
y1=x(1000:8000);
sound(y1);
y2=x(12000:18000);
sound(y2);
y=[y1;y2];
sound(y);
subplot(3,1,1);
plot(y1,'k');
title('截取的第一段波形');xlabel('样本点');ylabel('幅值');
subplot(3,1,2);
plot(y2,'k');
title('截取的第二段波形');xlabel('样本点');ylabel('幅值');
subplot(3,1,3);
plot(y,'k');
title('合成波形');xlabel('样本点');ylabel('幅值');
