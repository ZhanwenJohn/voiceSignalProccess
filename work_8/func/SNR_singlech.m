function snr_val = SNR_singlech(clean, noisy)
    noise = noisy - clean;
    snr_val = 10 * log10(sum(clean.^2) / sum(noise.^2));
end
