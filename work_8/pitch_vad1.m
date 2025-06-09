function [voiceseg, vosl, SF, Ef] = pitch_vad1(y, fn, T1)
wlen = size(y, 1);
energy = sum(y.^2);
Ef = energy / max(energy);

zcr = zeros(1, fn);
for k = 1:fn
    x = y(:,k);
    x1 = x(1:end-1);
    x2 = x(2:end);
    zcr(k) = sum(abs(sign(x2) - sign(x1))) / (2 * wlen);
end

SF = (Ef > T1);
min_seg_length = 3;
SF = smooth_sf(SF, min_seg_length);

voiceseg = find_segments(SF);
vosl = length(voiceseg);
end

function SF = smooth_sf(SF, min_len)
SF = SF(:)';
diff_SF = diff([0, SF, 0]);
start_idx = find(diff_SF == 1);
end_idx = find(diff_SF == -1) - 1;
valid_segs = (end_idx - start_idx + 1) >= min_len;
start_idx = start_idx(valid_segs);
end_idx = end_idx(valid_segs);
SF = zeros(size(SF));
for k = 1:length(start_idx)
    SF(start_idx(k):end_idx(k)) = 1;
end
end

function voiceseg = find_segments(SF)
voiceseg = struct('begin', {}, 'end', {}, 'duration', {});
diff_SF = diff([0, SF, 0]);
start_idx = find(diff_SF == 1);
end_idx = find(diff_SF == -1) - 1;
for k = 1:length(start_idx)
    voiceseg(k).begin = start_idx(k);
    voiceseg(k).end = end_idx(k);
    voiceseg(k).duration = end_idx(k) - start_idx(k) + 1;
end
end
