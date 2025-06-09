function y = overlapAdd(frames, wlen, inc)
    [~, fn] = size(frames);
    y = zeros((fn - 1) * inc + wlen, 1);
    for i = 1:fn
        idx = (i-1)*inc + (1:wlen);
        y(idx) = y(idx) + frames(:, i);
    end
end
