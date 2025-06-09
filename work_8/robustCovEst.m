function C = robustCovEst(x)
    X = x - mean(x);
    C = X * X';
end
