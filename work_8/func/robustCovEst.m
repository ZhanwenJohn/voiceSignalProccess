function C = robustCovEst(frame)
    % shrinkage covariance estimate
    r = size(frame, 1);
    raw_cov = cov(toeplitz(frame));  % 基础估计
    shrinkage = 0.05;
    C = (1 - shrinkage) * raw_cov + shrinkage * eye(r) * trace(raw_cov)/r;
end
