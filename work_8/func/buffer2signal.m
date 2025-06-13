function x = buffer2signal(X, inc)
% 从帧恢复信号（重叠相加）
[wlen, fn] = size(X);
x = zeros((fn-1)*inc + wlen, 1);
for i = 1:fn
    idx = (i-1)*inc + 1;
    x(idx:idx+wlen-1) = x(idx:idx+wlen-1) + X(:, i);
end
end
