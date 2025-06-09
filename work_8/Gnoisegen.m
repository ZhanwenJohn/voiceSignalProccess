function y_noisy = Gnoisegen(x, SNR_dB)
    signal_power = mean(x.^2);
    SNR_linear = 10^(SNR_dB / 10);
    noise_power = signal_power / SNR_linear;
    noise = sqrt(noise_power) * randn(size(x));
    y_noisy = x + noise;
end
