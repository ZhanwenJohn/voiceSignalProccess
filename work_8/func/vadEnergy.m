function flags = vadEnergy(frames, win, threshold)
    energy = sum((frames .* win).^2);
    flags = energy > threshold * max(energy);
end
