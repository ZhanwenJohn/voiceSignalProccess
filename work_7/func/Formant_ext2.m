function Frmt = Formant_ext2(x, wlen, inc, fs, SF, Doption)
% Formant_ext2 - 用于语音共振峰频率提取的LPC方法
% 输入：
%   x      - 预加重后的语音信号
%   wlen   - 帧长
%   inc    - 帧移
%   fs     - 采样频率
%   SF     - 有话标志（0=静音，1=语音）
%   Doption- 0=只提取语音帧的共振峰
%
% 输出：
%   Frmt   - [3 x N] 每帧提取出的前三个共振峰频率

    x = x(:);
    N = length(x);
    fn = fix((N - wlen) / inc) + 1;
    Frmt = zeros(3, fn);  % 每帧提取3个共振峰

    p = 12;               % LPC阶数
    win = hamming(wlen); % 加窗

    for i = 1:fn
        start = (i - 1) * inc + 1;
        frame = x(start : start + wlen - 1) .* win;

        if Doption == 0 && SF(i) == 0
            continue;
        end

        a = lpc(frame, p); % 计算LPC系数
        rts = roots(a);    % 求解极点
        rts = rts(imag(rts) >= 0.01); % 只保留上半平面
        angz = atan2(imag(rts), real(rts)); % 极角
        frqs = angz * (fs / (2*pi));        % 转换为Hz

        % 去除直流和高频噪声
        frqs = sort(frqs);
        frqs = frqs(frqs > 90 & frqs < fs/2); % 通常只保留90Hz以上的部分

        if length(frqs) >= 3
            Frmt(:,i) = frqs(1:3);
        elseif ~isempty(frqs)
            Frmt(1:length(frqs), i) = frqs;
        end
    end
end
