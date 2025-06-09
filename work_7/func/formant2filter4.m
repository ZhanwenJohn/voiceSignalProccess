function [an, bn] = formant2filter4(formants, bandwidths, fs)
% formant2filter4 - 将共振峰和带宽转换为二阶滤波器系数
% 输入：
%   formants   - [3x1] 共振峰频率（单位：Hz）
%   bandwidths - [3x1] 带宽（单位：Hz）
%   fs         - 采样率（单位：Hz）
% 输出：
%   an - 4 个二阶滤波器的分母系数 [3x4]
%   bn - 4 个二阶滤波器的分子系数 [1x4]

    an = zeros(3, 4);  % 分母系数：每列一个滤波器（二阶）
    bn = zeros(1, 4);  % 分子系数：此处假设为单位增益或缩放

    for k = 1:3
        f = formants(k);
        bw = bandwidths(k);

        if f == 0 || bw == 0
            % 若值为0，生成单位滤波器
            an(:,k) = [1; 0; 0];
            bn(k) = 1;
            continue;
        end

        r = exp(-pi * bw / fs);           % 极点模长
        theta = 2 * pi * f / fs;          % 极点角度
        poles = [1, -2*r*cos(theta), r^2];% 二阶滤波器分母
        an(:,k) = poles(:);
        bn(k) = 1 - r;                    % 近似单位增益（简化设计）
    end

    % 第四个滤波器默认高频或噪声合成，可设置为单位滤波器
    an(:,4) = [1; 0; 0];
    bn(4) = 1;
end
