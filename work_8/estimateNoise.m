function noiseCov = estimateNoise(frames, vad_flags)
    noiseFrames = frames(:, vad_flags == 0);
    if isempty(noiseFrames)
        noiseCov = eye(size(frames, 1)) * 1e-6;
    else
        noiseCov = cov(noiseFrames');
    end
end
