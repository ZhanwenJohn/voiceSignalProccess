%% 清除缓存
clear;
clc;
close all;

%% 预处理
% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);
y = y - mean(y);

u = filter([1 -.99], 1, y);  % 预加重
wlen = length(u);  % 帧长
p = 12;  % LPC阶数
a = lpc(u, p);  % 求出LPC系数

% 计算频率响应，设置为257个频率点（即包括0和fs/2）
N = 256;  % 频率响应点数
H = freqz(1, a, N);  % 计算频率响应
U = abs(H).^2;  % 计算功率谱

% 计算频率刻度
freq = (0:N-1) * fs / N;  % 修改频率刻度，使得长度与U匹配
df = fs / N;  % 频率分辨率
U_log = 10 * log10(U);  % 功率谱分贝值

% 绘制预加重波形
figure;
subplot(3,1,1);
plot(u, 'b');
axis([0 wlen -0.5 0.5]);
title('预加重波形');
xlabel('样点数');
ylabel('幅值');

% 绘制LPC计算波形
subplot(3,1,2);
plot(a);
xlabel('系数序号');ylabel('归一化幅值');
title(sprintf('%d阶LPC系数波形', p));

% 绘制功率谱
subplot(3,1,3);
plot(freq, U, 'b');  % 绘制功率谱
title('声道传递函数功率谱曲线');
xlabel('频率/Hz');
ylabel('幅值');

% 寻找峰值
[Loc, Val] = findpeaks(U);  % 在U中寻找峰值
ll = length(Loc);  % 有几个峰值

% 计算基频和带宽
F = zeros(1, ll);
Bw = zeros(1, ll);
for k = 1:ll
    m = Loc(k);  % 设置m-1,m和m+1
    m1 = m - 1;
    m2 = m + 1;
    p = Val(k);  % 设置P(m-1),P(m)和P(m+1)
    p1 = U(m1);
    p2 = U(m2);
    aa = (p1 + p2) / 2 - p;  % 按式(9-3-4)计算
    bb = (p2 - p1) / 2;
    cc = p;
    dm = -bb / 2 / aa;  % 按式(9-3-6)计算
    pp = -bb * bb / 4 / aa + cc;  % 按式(9-3-8)计算
    m_new = m + dm;
    bf = -sqrt(bb * bb - 4 * aa * (cc - pp / 2)) / aa;  % 按式(9-3-13)计算
    F(k) = (m_new - 1) * df;  % 按式(9-3-7)计算
    Bw(k) = bf * df;  % 按式(9-3-14)计算
    line([F(k) F(k)], [0 pp], 'color', 'r', 'linestyle', '-.');
end

% 输出峰值频率和带宽
fprintf('F =%5.2f   %5.2f   %5.2f   %5.2f\n', F);
fprintf('Bw=%5.2f   %5.2f   %5.2f   %5.2f\n', Bw);
