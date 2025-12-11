img = imread("images/computer/256grayscale.jpg");
img = im2double(img);

dct_img = dct2(img);
fft_img = fft2(img);
fft_img_shifted = fftshift(fft_img); % Center the FFT for visualization

figure;
subplot(2, 1, 1);
imshow(log(abs(dct_img)), []);

subplot(2, 1, 2);
imshow(log(abs(fft_img_shifted)), []);

N = 64;

MSE_dct = zeros(N,1);
RMSE_dct = zeros(N,1);
PSNR_dct = zeros(N,1);
MSE_fft = zeros(N,1);
RMSE_fft = zeros(N,1);
PSNR_fft = zeros(N,1);

step_size = 256 / N;

figure;
for i = 1:N
    % Calculate the current mask size
    level = floor(i * step_size);

    % DCT
    mask_dct = zeros(size(dct_img));
    mask_dct(1:level, 1:level) = 1;
    dct_img_masked = dct_img .* mask_dct;
    reconstructed_dct = idct2(dct_img_masked);

    % FFT reconstruction
    mask_fft = zeros(size(fft_img_shifted));
    center = floor(size(fft_img_shifted)/2) + 1;
    start = center - floor(level/2);
    finish = center + floor(level/2) - 1;
    mask_fft(start(1):finish(1), start(2):finish(2)) = 1;
    fft_img_masked = fft_img_shifted .* mask_fft;
    fft_img_masked = ifftshift(fft_img_masked);
    reconstructed_fft = real(ifft2(fft_img_masked));

    MSE_dct(i) = mean((img(:) - reconstructed_dct(:)).^2);
    RMSE_dct(i) = sqrt(MSE_dct(i));
    PSNR_dct(i) = 10 * log10(1 / MSE_dct(i));

    MSE_fft(i) = mean((img(:) - reconstructed_fft(:)).^2);
    RMSE_fft(i) = sqrt(MSE_fft(i));
    PSNR_fft(i) = 10 * log10(1 / MSE_fft(i));

    %subplot(sqrt(N), sqrt(N), i);
    %imshow(reconstructed_fft);
end

figure;
subplot(3,1,1);
plot(1:N, MSE_dct, 'b', 1:N, MSE_fft, 'r');
legend('DCT', 'FFT');
title('MSE vs. Reconstruction Steps');
subplot(3,1,2);
plot(1:N, RMSE_dct, 'b', 1:N, RMSE_fft, 'r');
legend('DCT', 'FFT');
title('RMSE vs. Reconstruction Steps');
subplot(3,1,3);
plot(1:N, PSNR_dct, 'b', 1:N, PSNR_fft, 'r');
legend('DCT', 'FFT');
title('PSNR vs. Reconstruction Steps');