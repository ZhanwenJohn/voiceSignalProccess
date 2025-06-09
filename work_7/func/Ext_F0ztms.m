function [Dpitch,Dfreq,Ef,SF,voiceseg,vosl,vseg,vsl,T2] ...
    = Ext_F0ztms(x1,fs,wlen,inc,T1,r2,miniL,mnlong,ThrC,Doption)
% Ext_F0ztms - 基于能量熵比与主体-延伸法的语音端点检测与基音估计
% 输入：
%   x1      - 输入语音信号
%   fs      - 采样率
%   wlen    - 帧长（单位：点）
%   inc     - 帧移（单位：点）
%   T1      - 熵比门限，用于初始判断
%   r2      - 熵比平滑因子
%   miniL   - 最短语音段长度（帧）
%   mnlong  - 最短元音主体段（帧），用于主体-延伸
%   ThrC    - 双门限 [高门限，低门限]
%   Doption - 是否进行基音检测（0=不检测，1=检测）
%
% 输出：
%   Dpitch    - 每帧的基音周期（单位：点）
%   Dfreq     - 每帧的基音频率（单位：Hz）
%   Ef        - 每帧能量熵比
%   SF        - 每帧的语音/静音判断（1=语音，0=静音）
%   voiceseg  - 语音段结构体（含起止帧等信息）
%   vosl      - 语音段个数
%   vseg, vsl - 同 voiceseg/vosl
%   T2        - 每帧的动态双门限

x1 = x1(:);  % 转为列向量
N = length(x1);
fn = floor((N - wlen) / inc) + 1;
win = hamming(wlen);

% 分帧
frames = zeros(wlen, fn);
for i = 1:fn
    start = (i-1)*inc + 1;
    frames(:,i) = x1(start:start+wlen-1) .* win;
end

% 每帧能量
E = sum(frames.^2, 1);
E = E / max(E);

% 每帧能量熵（分布熵）
P = frames.^2;
Psum = sum(P,1) + eps;
P = P ./ Psum;
H = -sum(P .* log(P + eps), 1);
H = H / max(H);

% 能量熵比
Ef = E ./ (H + eps);

% 平滑处理
Ef = filter([1 -r2], 1, Ef);

% 双门限判断
T2 = zeros(1,fn);
high = ThrC(1);
low  = ThrC(2);
SF = zeros(1,fn);
state = 0;
for i = 1:fn
    if state == 0
        T2(i) = high;
        if Ef(i) > high
            SF(i) = 1;
            state = 1;
        end
    else
        T2(i) = low;
        if Ef(i) < low
            SF(i) = 0;
            state = 0;
        else
            SF(i) = 1;
        end
    end
end

% 平滑：去除过短的语音段
SF = smoothSegments(SF, miniL);

% 提取语音段信息
[voiceseg, vosl] = findSegments(SF);
vseg = voiceseg;
vsl = vosl;

% 基音周期/频率估计（如果需要）
Dpitch = zeros(1,fn);
Dfreq = zeros(1,fn);

if Doption == 1
    for i = 1:fn
        if SF(i) == 1
            frame = frames(:,i);
            r = xcorr(frame);
            r = r(wlen:end);
            r(1:round(fs/500)) = 0; % 忽略过短周期
            [~, lag] = max(r);
            Dpitch(i) = lag;
            Dfreq(i) = fs / lag;
        end
    end
end

end

%% 辅助函数1：平滑段（去除短语音段）
function SFout = smoothSegments(SF, minLen)
    SFout = SF;
    d = diff([0 SF 0]);
    start = find(d==1);
    endd  = find(d==-1) - 1;
    for k = 1:length(start)
        if endd(k) - start(k) + 1 < minLen
            SFout(start(k):endd(k)) = 0;
        end
    end
end
