image_files = dir(fullfile('jpeg', '*.jpg'));

quantization_matrix = [
    16  11  10  16  24  40  51  61;
    12  12  14  19  26  58  60  55;
    14  13  16  24  40  57  69  56;
    14  17  22  29  51  87  80  62;
    18  22  37  56  68 109 103  77;
    24  35  55  64  81 104 113  92;
    49  64  78  87 103 121 120 101;
    72  92  95  98 112 100 103  99
];

all_dc_coefficients = [];
all_ac_coefficients = [];


%length(image_files)
    %img = imread(fullfile('jpeg', image_files(k).name));

for k = 1:1
    %img = imread("images/computer/256grayscale.jpg");
    img = imread(fullfile('jpeg', "COSI-1 (1).jpg"));
    img = rgb2gray(img);
    img = uint8(img);

     % Pad the image to be divisible by 8
    [height, width] = size(img);
    pad_height = mod(height, 8);
    pad_width = mod(width, 8);
    if pad_height ~= 0 || pad_width ~= 0
        img = padarray(img, [8 - pad_height, 8 - pad_width], 'post');
    end

    disp(["Number of blocks: ", floor(height / 8) * floor(width / 8)])

    % Process each 8x8 block
    for i = 1:8:size(img, 1)
        for j = 1:8:size(img, 2)
            block = img(i:i+7, j:j+7);

            % Subtract 128 (DC shift)
            block = block - 128;

            % Apply DCT
            dct_block = dct2(block);

            % Quantize the DCT coefficients
            quantized_block = round(dct_block ./ quantization_matrix);

            zigzag_indices = [
                1  2  6  7 15 16 28 29;
                3  5  8 14 17 27 30 43;
                4  9 13 18 26 31 42 44;
                10 12 19 25 32 41 45 54;
                11 20 24 33 40 46 53 55;
                21 23 34 39 47 52 56 61;
                22 35 38 48 51 57 60 62;
                36 37 49 50 58 59 63 64
            ];

            % 64 values in zigzag
            zz = quantized_block(zigzag_indices);

            dc_coefficient = zz(1);
            ac_coefficients = zz(2:end);

            all_dc_coefficients = [all_dc_coefficients; dc_coefficient];
            all_ac_coefficients = [all_ac_coefficients; ac_coefficients];
        end
    end
end

function s = compute_size(value)
    if value == 0
        s = 0;
        return;
    end
    s = floor(log2(abs(value))) + 1;
end

dc_symbols = [];

prev_dc = 0;
for i = 1:size(all_dc_coefficients, 1)
    current_dc = all_dc_coefficients(i);

    dc_diff = current_dc - prev_dc;
    dc_symbols(end+1) = dc_diff;
    prev_dc = current_dc;
end

ac_symbols = [];

for b = 1:size(all_ac_coefficients, 1)
    block = all_ac_coefficients(b, :);
    dc_coeff = all_dc_coefficients(b);

    zero_count = 0;

    fprintf('\n');
    fprintf('%6.2f ', dc_coeff);
    fprintf('%6.2f ', block(2:8));
    fprintf('\n');

    for i = 8:8:length(block)
        endIdx = min(i+7, length(block));
        fprintf('%6.2f ', block(i:endIdx));
        fprintf('\n');
    end

    for k = 1:63
        coeff = block(k);

        if coeff == 0
            zero_count = zero_count + 1;

            if zero_count == 16
                ac_symbols(end+1) = hex2dec('F0');
                zero_count = 0;
            end
        else
            RUN = zero_count;
            SIZE = compute_size(coeff);
            symbol = bitshift(RUN,4) + SIZE;
            ac_symbols(end+1) = symbol;

            fprintf('[(%d, %d), %d], ', RUN, SIZE, coeff);

            zero_count = 0;
        end
    end

    fprintf('\n');
end

symbols = unique(ac_symbols);
counts = histc(ac_symbols, symbols);
probs = counts / sum(counts);
ac_dict = huffmandict(symbols, probs);

save('ac_huffman_dict.mat', 'ac_dict');

symbols = unique(dc_symbols);
counts = histc(dc_symbols, symbols);
probs = counts / sum(counts);
dc_dict = huffmandict(symbols, probs);

save('dc_huffman_dict.mat', 'dc_dict');
