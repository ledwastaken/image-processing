function out = haar1d_rows(M)
    [r,c] = size(M);
    out = zeros(r,c);

    half = c/2;

    for i = 1:r
        for k = 1:half
            out(i,k)       = (M(i,2*k-1) + M(i,2*k)) / 2;
            out(i,k+half)  = (M(i,2*k-1) - M(i,2*k)) / 2;
        end
    end
end

function [A,H,V,D] = haar1d_cols(M)
    [r,c] = size(M);
    half = r/2;

    % Initializing the 4 different ouputs
    A = zeros(half, c/2);
    H = zeros(half, c/2);
    V = zeros(half, c/2);
    D = zeros(half, c/2);

    % Retrieve left half and right half
    L = M(:, 1:c/2);
    R = M(:, c/2+1:end);

    for j = 1:c/2
        for k = 1:half
            a1 = (L(2*k-1,j) + L(2*k,j))/2;
            d1 = (L(2*k-1,j) - L(2*k,j))/2;

            a2 = (R(2*k-1,j) + R(2*k,j))/2;
            d2 = (R(2*k-1,j) - R(2*k,j))/2;

            A(k,j) = a1;   % low pass in both directions
            H(k,j) = d1;   % high vertically, low horizontally
            V(k,j) = a2;   % low vertically, high horizontally
            D(k,j) = d2;   % high vertically and horizontally
        end
    end
end

function [A, H, V, D] = apply_haar2(img, N)
    A = double(img);

    H = cell(1, N);
    V = cell(1, N);
    D = cell(1, N);

    for level = 1:N
        % apply 1d haar to rows
        A_row = haar1d_rows(A);

        % apply 1d haar to columns
        [A_new, H_band, V_band, D_band] = haar1d_cols(A_row);

        H{level} = H_band;
        V{level} = V_band;
        D{level} = D_band;

        % Continue with next level inside approximation block
        A = A_new;
    end
end

function [haar_img] = build_haar_img(a, h, v, d)
    N = numel(h);

    haar_img = mat2gray(a);

    % Build up the image level by level
    for level = N:-1:1
        % Current size after upscaling
        targetSize = size(h{level});

        % Upscale the composite to match detail bands of current level
        haar_img = imresize(haar_img, targetSize);

        % Normalize detail bands
        H = mat2gray(h{level});
        V = mat2gray(v{level});
        D = mat2gray(d{level});

        % Combine block:
        % [Approx | Horizontal]
        % [Vertical | Diagonal]
        haar_img = [haar_img, H; V, D];
    end
end

function img_rec = apply_inv_haart2(a, h, v, d, levels_kept)
    N = numel(h);

    A = double(a);

    for level = N:-1:1
        H = double(h{level});
        V = double(v{level});
        D = double(d{level});

        if level > levels_kept
            H = zeros(size(h{level}));
            V = zeros(size(h{level}));
            D = zeros(size(h{level}));
        end

        [r, c] = size(A);
        % H, V, D must be same size r x c

        % Initialize L and R
        L = zeros(2*r, c);
        R = zeros(2*r, c);

        % fill L and R
        for i = 1:r
            r1 = 2*i-1;
            r2 = 2*i;

            L(r1, :) = A(i, :) + H(i, :);
            L(r2, :) = A(i, :) - H(i, :);

            R(r1, :) = V(i, :) + D(i, :);
            R(r2, :) = V(i, :) - D(i, :);
        end

        % Merge L and R
        M = [L, R];

        % inverse row transform -> produce X of size 2r x 2c
        X = zeros(2*r, 2*c);
        half = c;
        for row = 1:2*r
            for k = 1:half
                col1 = k;
                col2 = k + half;
                X(row, 2*k-1) = M(row, col1) + M(row, col2);
                X(row, 2*k  ) = M(row, col1) - M(row, col2);
            end
        end

        % this X becomes the approximation for the next (outer) level
        A = X;
    end

    img_rec = A;
end

img = imread("images/computer/256grayscale.jpg");
img = im2double(img);

N = 3;
[a, h, v, d] = apply_haar2(img, N);

img_haar = build_haar_img(a, h, v, d);
full_inv_haar_img = apply_inv_haart2(a, h, v, d, 4);

figure;
imshow(img_haar);

MSE = zeros(N+1,1);
RMSE = zeros(N+1,1);
PSNR = zeros(N+1,1);

figure;
for level = 0:N
    inv_haar_img = apply_inv_haart2(a, h, v, d, level);

    subplot(2,2,level + 1);
    imshow(inv_haar_img);
    title(sprintf('%d levels kept', level));

    MSE(level+1) = mean((img(:) - inv_haar_img(:)).^2);
    RMSE(level+1) = sqrt(MSE(level+1));
    PSNR(level+1) = 10 * log10(1 / MSE(level+1));
end

levels = 0:N;

figure;
subplot(3,1,1);
plot(levels, MSE, '-o','LineWidth',1.5);
xlabel('Levels kept'); ylabel('MSE');
title('MSE vs Levels kept'); grid on;

subplot(3,1,2);
plot(levels, RMSE, '-o','LineWidth',1.5);
xlabel('Levels kept'); ylabel('RMSE');
title('RMSE vs Levels kept'); grid on;

subplot(3,1,3);
plot(levels, PSNR, '-o','LineWidth',1.5);
xlabel('Levels kept'); ylabel('PSNR (dB)');
title('PSNR vs Levels kept'); grid on;

sgtitle('Image reconstruction quality at each level');
