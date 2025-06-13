
function C = robustCov(frame)
% 用中值估计构造更鲁棒协方差矩阵
N = length(frame);
X = toeplitz(frame);
med = median(X, 2);
Xc = X - med;
C = (Xc * Xc') / (size(Xc, 2) - 1);
