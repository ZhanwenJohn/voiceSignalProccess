%%  pr10_5_4 
%% 清除缓存
clear;
clc;
close all;
%% 读取音频信号
[xx, fs] = audioread("test.wav");
xx=xx-mean(xx);                           % 去除直流分量
x1=xx/max(abs(xx));                       % 归一化
x=filter([1 -.99],1,x1);                  % 预加重
N=length(x);                              % 数据长度
time=(0:N-1)/fs;                          % 信号的时间刻度
wlen=128;                                 % 帧长
inc=32;                                   % 帧移
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
Etemp=sum(X.*X);                          % 计算每帧能量
Etemp=Etemp/max(Etemp);                   % 能量归一化
T1=0.1; r2=0.5;                           % 端点检测参数
miniL=10;                                 % 有话段最短帧数
mnlong=5;                                 % 元音主体最短帧数
ThrC=[10 12];                             % 阈值
p=12;                                     % LPC阶次
frameTime = (0:fn-1) * inc / fs + (wlen / (2 * fs));% 计算每帧的时间坐标
% 基音检测
Doption = 1;
[Dpitch,Dfreq,Ef,SF,voiceseg,vosl,vseg,vsl,T2]=...
   Ext_F0ztms(xx,fs,wlen,inc,T1,r2,miniL,mnlong,ThrC,Doption);
const=fs/(2*pi);                            % 常数 
Frmt=ones(3,fn)*nan;                        % 初始化
Bw=ones(3,fn)*nan;
zint=zeros(2,4);                            % 初始化
tal=0;
cepstL=6;                                   % 倒频率上窗函数的宽度
wlen2=wlen/2;                               % 取帧长一半
df=fs/wlen;                                 % 计算频域的频率刻度
for i=1 : fn
%% 共振峰和带宽的提取
    u=X(:,i);                               % 取一帧数据
    u2=u.*wind;		                        % 信号加窗函数
    U=fft(u2);                              % 按式(10-5-6)计算FFT
    U2=abs(U(1:wlen2)).^2;                  % 计算功率谱
    U_abs=log(U2);                          % 按式(10-5-7)计算对数
    Cepst=ifft(U_abs);                      % 按式(10-5-8)计算IDFT
    cepst=zeros(1,wlen2);           
    cepst(1:cepstL)=Cepst(1:cepstL);        % 按式(10-5-9)乘窗函数
    cepst(end-cepstL+2:end)=Cepst(end-cepstL+2:end);
    spect=real(fft(cepst));                 % 按式(10-5-10)计算DFT
    [Loc,Val]=findpeaks(spect);             % 寻找峰值
    Spe=exp(spect);                         % 按式(10-5-11)计算线性功率谱值
    ll = min(3, length(Loc));
    F = nan(3,1);       % 初始化为空值，避免未定义错误
    bw = nan(3,1);      % 同上
    count = 0; % 有效共振峰数量计数
    for k = 1 : ll
        m = round(Loc(k));  % 保证为整数
        if isnan(m) || m < 2 || m > length(Spe)-1
            continue; % 非法索引跳过
        end
        m1 = m - 1; m2 = m + 1;
        pp = Spe(m);
        pp1 = Spe(m1); pp2 = Spe(m2);    
        aa = (pp1 + pp2)/2 - pp;
        bb = (pp2 - pp1)/2;
        cc = pp;    
        if abs(aa) < 1e-6
            continue;
        end
        dm = -bb / (2 * aa);
        Pp = -bb^2 / (4 * aa) + cc;
        m_new = m + dm;
        delta = bb^2 - 4 * aa * (cc - Pp / 2);
        if delta < 0
            continue;
        end    
        bf = sqrt(delta) / abs(aa);
        count = count + 1;
        F(count) = (m_new - 1) * df;
        bw(count) = bf * df;
    end
    Frmt(:,i)=F;                            % 把共振峰频率存放在Frmt中
    Bw(:,i)=bw;                             % 把带宽存放在Bw中
    
end

%% 语音合成
output = [];
validFrameCount = 0;

for i = 1 : fn
    % 第 i 帧的共振峰频率和带宽
    yf = Frmt(:, i);
    bw = Bw(:, i);

    % 若共振峰数据无效，跳过
    if any(isnan(yf)) || any(isnan(bw))
        warning("帧 %d 共振峰或带宽无效，跳过", i);
        continue;
    end

    try
        [an, bn] = formant2filter4(yf, bw, fs);  % 滤波器系数
    catch
        warning("帧 %d 滤波器生成失败，跳过", i);
        continue;
    end

    synt_frame = zeros(wlen, 1);

    % 激励信号生成
    if SF(i) == 0
        excitation = randn(wlen, 1);  % 白噪声激励
    else
        PT = round(Dpitch(i));
        if PT <= 1 || PT > wlen
            warning("帧 %d 激励周期非法 PT=%d，跳过", i, PT);
            continue;
        end
        exc_syn1 = zeros(wlen + tal, 1);
        exc_syn1(mod(1:tal+wlen, PT) == 0) = 1;
        excitation = exc_syn1(tal+1 : tal + wlen);
        exc_syn2 = exc_syn1(tal+1 : tal + inc);
        index = find(exc_syn2 == 1);
        tal = isempty(index) * (tal + inc) + ~isempty(index) * (inc - index(end));
    end

    % 多滤波器并联合成
    try
        for k = 1 : 4
            An = an(:, k);
            Bn = bn(k);
            [out(:, k), zint(:, k)] = filter(Bn(1), An, excitation, zint(:, k));
            synt_frame = synt_frame + out(:, k);
        end
    catch
        warning("帧 %d 滤波器合成失败，跳过", i);
        continue;
    end

    % 归一化与累加
    Et = sum(synt_frame.^2);
    if Et == 0 || ~isfinite(Et)
        warning("帧 %d 合成能量非法，跳过", i);
        continue;
    end

    rt = Etemp(i) / Et;
    if ~isfinite(rt) || rt <= 0
        warning("帧 %d 归一因子非法 rt=%.3f，跳过", i, rt);
        continue;
    end

    synt_frame = sqrt(rt) * synt_frame;
    synt_speech_HF(:, i) = synt_frame;

    % 重叠-加窗叠接
    if isempty(output)
        output = synt_frame;
    else
        M = length(output);
        output = [output(1:M-overlap);
                  output(M-overlap+1:M).*tempr2 + synt_frame(1:overlap).*tempr1;
                  synt_frame(overlap+1:wlen)];
    end

    validFrameCount = validFrameCount + 1;
end
ol=length(output);                          % 把输出output延长至与输入信号xx等长
if ol<N
    output=[output; zeros(N-ol,1)];
end
% 检查合成结果有效性
if validFrameCount == 0
    error("没有帧被成功合成，合成失败，请检查参数或信号。");
end
% 截断或补齐
if length(output) < N
    output = [output; zeros(N - length(output), 1)];
else
    output = output(1:N);
end
fprintf("合成完成：共成功处理 %d 帧，有效率 %.2f%%\\n", validFrameCount, 100 * validFrameCount / fn);
out1=output;
b=[0.964775   -3.858862   5.788174   -3.858862   0.964775];  % 滤波器系数
a=[1.000000   -4.918040   9.675693   -9.518749   4.682579   -0.921483];
output = filter(b, a, out1);           % 滤波器处理
if all(isfinite(output)) && any(abs(output) > 0)
    output = output / max(abs(output));  % 正常归一化
else
    warning('合成语音为0或包含NaN，跳过归一化');
end
fprintf('输出语音最大值：%.4f，最小值：%.4f\n', max(output), min(output));
% 通过声卡发音,比较原始语音和合成语音
sound(xx,fs);
pause(1)
sound(output,fs);
%% 作图
figure(1)
pos = get(gcf,'Position');
set(gcf,'Position',[pos(1), pos(2)-100,pos(3),(pos(4)+85)])
subplot 411; plot(time,x1,'k'); axis([0 max(time) -1 1.1]);
title('信号波形'); ylabel('幅值'); 
subplot 412; plot(frameTime,Ef,'k'); hold on
axis([0 max(time) 0 1.2]); plot(frameTime,T2,'k','linewidth',2);
line([0 max(time)],[T1 T1],'color','k','linestyle','-.');
title('能熵比图'); axis([0 max(time) 0 1.2]);  ylabel('幅值');
text(3.2,T1+0.05,'T1');
Tx = NaN;  % 设置默认值，避免未定义
for k = 1 : vsl
    line([frameTime(vseg(k).begin) frameTime(vseg(k).begin)], [0 1.2],'color','k','Linestyle','-');
    line([frameTime(vseg(k).end) frameTime(vseg(k).end)], [0 1.2],'color','k','Linestyle','--');
    if k == vsl
        idx = floor((vseg(k).begin + vseg(k).end)/2);
        if idx >= 1 && idx <= length(T2)
            Tx = T2(idx);
        end
    end
end

% 绘制 T2 标注（如果 Tx 已经定义为合法值）
if ~isnan(Tx)
    text(2.65, Tx+0.05, 'T2');
end
subplot 413; plot(frameTime,Dpitch,'k'); 
axis([0 max(time) 0 110]);title('基音周期'); ylabel('样点值');
subplot 414; plot(frameTime,Dfreq,'k'); 
axis([0 max(time) 0 250]);title('基音频率'); ylabel('频率/Hz');
xlabel('时间/s'); 

figure(2)
subplot 211; plot(time,x1,'k'); title('原始语音波形');
axis([0 max(time) -1 1.1]); xlabel('时间/s'); ylabel('幅值')
subplot 212; plot(time,output,'k');  title('合成语音波形');
axis([0 max(time) -1 1.1]); xlabel('时间/s'); ylabel('幅值');

