%% 清除缓存
clear;clc;close all;
%% 读取音频信号
[xx, fs] = audioread("test.wav");
xx=xx-mean(xx);                           % 去除直流分量
x=xx/max(abs(xx));                        % 归一化
N=length(x);                              % 数据长度
time=(0:N-1)/fs;                          % 时间刻度
wlen=256;                                 % 帧长
inc=64;                                   % 帧移
overlap=wlen-inc;                         % 重叠长度
tempr1=(0:overlap-1)'/overlap;            % 斜三角窗函数w1
tempr2=(overlap-1:-1:0)'/overlap;         % 斜三角窗函数w2
n2=1:wlen/2+1;                            % 正频率的下标值
%% 分帧处理
fn = fix((N - wlen) / inc) + 1;  % 帧数
X = zeros(wlen, fn);
for i = 1:fn
    start_idx = (i - 1) * inc + 1;
    end_idx = start_idx + wlen - 1;
    X(:, i) = x(start_idx:end_idx);  % 对每一帧进行分帧处理
end
%% 计算 hanning 窗
wind = hanning(wlen); % 计算 hanning 窗
%% hanning 加窗
for i = 1:fn
    X(:, i) = X(:, i) .* wind; % 加窗
end
T1=0.1; r2=0.5;                           % 端点检测参数
miniL=10;                                 % 有话段最短帧数
mnlong=5;                                 % 元音主体最短帧数
ThrC=[10 15];                             % 阈值
p=12;                                     % LPC阶次
frameTime = (0:fn-1) * inc / fs + (wlen / (2 * fs));% 计算每帧的时间坐标
for i=1 : fn                              % 计算每帧的线性预测系数和增益
    u=X(:,i);
    [ar,g]=lpc(u,p);
    AR_coeff(:,i)=ar;
    Gain(i)=g;
end
%% 基音检测
[Dfreq, loc] = pitch(xx, fs, ...
    'WindowLength', wlen, ...
    'OverlapLength', overlap, ...
    'Method', 'PEF');
Dpitch = round(fs ./ Dfreq); % 换算为基音周期（采样点数）
% 使用简单能量门限判断是否有语音（语音活动检测 VAD 替代 SF）
frame_energy = sum(X.^2);
threshold = 0.01; % 经验阈值，你可以调整
SF = frame_energy > threshold;
% 其余变量你可以用空占位或自定义方式替代
Ef = frame_energy / max(frame_energy); % 能熵比（简化版）
T2 = ones(1, fn) * T1;                 % 可根据需要自行修改
voiceseg = []; vosl = 0; vseg = []; vsl = 0;
%%
%%
tal=0;                                    % 初始化前导零点
zint=zeros(p,1);
for i=1:fn
    ai=AR_coeff(:,i);                     % 获取第i帧的预测系数
    sigma_square=Gain(i);                 % 获取第i帧的增益系数
    sigma=sqrt(sigma_square);
    
    if SF(i)==0                           % 无话帧
        excitation = randn(wlen,1);       % 产生白噪声
        [synt_frame,zint]=filter(sigma,ai,excitation,zint); % 用白噪声合成语音
    else                                  % 有话帧
        PT=round(Dpitch(i));              % 取周期值
        exc_syn1 =zeros(wlen+tal,1);      % 初始化脉冲发生区
        exc_syn1(mod(1:tal+wlen,PT)==0) = 1;  % 在基音周期的位置产生脉冲，幅值为1
        exc_syn2=exc_syn1(tal+1:tal+inc); % 计算帧移inc区间内脉冲个数
        index=find(exc_syn2==1);
        excitation=exc_syn1(tal+1:tal+wlen);% 这一帧的激励脉冲源
        
        if isempty(index)                 % 帧移inc区间内没有脉冲
            tal=tal+inc;                  % 计算下一帧的前导零点
        else                              % 帧移inc区间内有脉冲
            eal=length(index);            % 计算有几个脉冲
            tal=inc-index(eal);           % 计算下一帧的前导零点
        end
        gain=sigma/sqrt(1/PT);            % 增益
        [synt_frame,zint]=filter(gain, ai,excitation,zint); % 用脉冲合成语音
    end
        if i==1                           % 若为第1帧
            output=synt_frame;            % 不需要重叠相加,保留合成数据
        else
            M=length(output);             % 按线性比例重叠相加处理合成数据
            output=[output(1:M-overlap); output(M-overlap+1:M).*tempr2+...
                synt_frame(1:overlap).*tempr1; synt_frame(overlap+1:wlen)];
        end
end
ol=length(output);                        % 把输出output延长至与输入信号xx等长
if ol<N
    output1=[output; zeros(N-ol,1)];
else
    output1=output(1:N);
end
bn=[0.964775   -3.858862   5.788174   -3.858862   0.964775]; % 滤波器系数
an=[1.000000   -3.928040   5.786934   -3.789685   0.930791];
output=filter(bn,an,output1);             % 高通滤波
output=output/max(abs(output));           % 幅值归一

% 通过声卡发音,比较原始语音和合成语音
sound(x, fs);
pause(length(x)/fs + 0.5)   % 播放完原始语音后暂停
sound(output, fs);
%作图
figure(1)
pos = get(gcf,'Position');
set(gcf,'Position',[pos(1), pos(2)-100,pos(3),(pos(4)+85)])
subplot 411; plot(time,xx,'k'); axis([0 max(time) -1 1.2]);
xlabel('(a)'); 
title('信号波形'); ylabel('幅值')
subplot 412; plot(frameTime,Ef,'k'); hold on
axis([0 max(time) 0 1.2]); plot(frameTime,T2,'k','linewidth',2);
line([0 max(time)],[T1 T1],'color','k','linestyle','-.');
title('能熵比图'); axis([0 max(time) 0 1.2]); ylabel('幅值')
xlabel('(b)'); 
text(3.2,T1+0.05,'T1');
for k=1 : vsl
        line([frameTime(vseg(k).begin) frameTime(vseg(k).begin)],...
        [0 1.2],'color','k','Linestyle','-');
        line([frameTime(vseg(k).end) frameTime(vseg(k).end)],...
        [0 1.2],'color','k','Linestyle','--');
    if k==vsl
        Tx=T2(floor((vseg(k).begin+vseg(k).end)/2));
    end
end
if exist('Tx', 'var')
    text(2.65, Tx + 0.05, 'T2');
else
    warning('未检测到有效语音段，跳过 T2 标注');
end
subplot 413; plot(frameTime,Dpitch,'k'); 
axis([0 max(time) 0 110]);title('基音周期');ylabel('样点值')
xlabel( '(c)'); 
subplot 414; plot(frameTime,Dfreq,'k'); 
axis([0 max(time) 0 250]);title('基音频率');ylabel('频率/Hz')
xlabel(['时间/s' 10 '(d)']); 

figure(2)
subplot 211; plot(time,x,'b'); title('原始语音波形');
axis([0 max(time) -1 1.1]); xlabel('时间/s'); ylabel('幅值')
subplot 212; plot(time,output,'b');  title('合成语音波形');
axis([0 max(time) -1 1.1]); xlabel('时间/s'); ylabel('幅值');
