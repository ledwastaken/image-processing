function resized_img = my_imresize(img, new_size)
    [old_height, old_width] = size(img);
    new_height = new_size(1);
    new_width = new_size(2);

    img = imgaussfilt(img, 0.5);

    [x_new, y_new] = meshgrid(1:new_width, 1:new_height);

    x_old = (x_new - 0.5) * (old_width / new_width) + 0.5;
    y_old = (y_new - 0.5) * (old_height / new_height) + 0.5;

    resized_img = interp2(img, x_old, y_old, 'bilinear');
end

img = imread('images/computer/grayscale.jpg');
original_resized_img = imread('images/computer/256grayscale.jpg');
img = im2double(img);
original_resized_img = im2double(original_resized_img);

disp(size(img));

% Resize the image to 128x128
resized_img = my_imresize(img, [256, 256]);

disp(size(resized_img));

% Display the original and resized images
figure;
subplot(2,1,1);
imshow(img);
title('Original Image');
subplot(2,1,2);
imshow(resized_img);
title('Resized Image');

ssim_value = ssim(resized_img, original_resized_img);
disp(['SSIM: ', num2str(ssim_value)]);
