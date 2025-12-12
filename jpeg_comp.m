img = imread('images/computer/256grayscale.jpg');
img = uint8(img);

load('dc_huffman_dict.mat');
load('ac_huffman_dict.mat');

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

block_size = 8;
[height, width] = size(img);

% Pad the image to be divisible by 8
pad_height = mod(height, 8);
pad_width = mod(width, 8);
if pad_height ~= 0 || pad_width ~= 0
    img = padarray(img, [8 - pad_height, 8 - pad_width], 'post');
end

compressed_dc = [];
compressed_ac = [];

for i = 1:block_size:size(img, 1)
    for j = 1:block_size:size(img, 2)
        block = img(i:i+7, j:j+7);

        block = block - 128;

        dct_block = dct2(block);

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

        zz = quantized_block(zigzag_indices);

        dc_coefficient = zz(1);
        ac_coefficients = zz(2:end);

        compressed_dc = [compressed_dc; dc_coefficient];
        compressed_ac = [compressed_ac; ac_coefficients];
    end
end

dc_differences = diff([0; compressed_dc]);
dc_symbols = dc_differences;

dc_encoded = {};
for i = 1:length(dc_symbols)
    symbol = dc_symbols(i);

    idx = [];
    for j = 1:size(dc_dict, 1)
        if dc_dict{j, 1} == symbol
            idx = j;
            break;
        end
    end
    if ~isempty(idx)
        dc_encoded{end+1} = dc_dict{idx, 2};
    else
        disp("DC symbol not found");
    end
end

ac_encoded = {};
for b = 1:size(compressed_ac, 1)
    block = compressed_ac(b, :);
    zero_count = 0;

    for k = 1:63
        coeff = block(k);

        if coeff == 0
            zero_count = zero_count + 1;

            if zero_count == 16
                symbol = hex2dec('F0');
                idx = [];
                for j = 1:size(ac_dict, 1)
                    if ac_dict{j, 1} == symbol
                        idx = j;
                        break;
                    end
                end
                if ~isempty(idx)
                    ac_encoded{end+1} = ac_dict{idx, 2};
                else
                    disp("AC symbol not found");
                end
                zero_count = 0;
            end
        else
            RUN = zero_count;
            SIZE = floor(log2(abs(coeff))) + 1;
            symbol = bitshift(RUN, 4) + SIZE;

            idx = [];
            for j = 1:size(ac_dict, 1)
                if ac_dict{j, 1} == symbol
                    idx = j;
                    break;
                end
            end
            if ~isempty(idx)
                ac_encoded{end+1} = ac_dict{idx, 2};

                if coeff > 0
                    bin_str = dec2bin(coeff, SIZE);
                else
                    bin_str = dec2bin(bitcmp(uint8(0)) + uint8(abs(coeff)), SIZE);
                end
                ac_encoded{end+1} = bin_str;
            else
                disp("AC symbol not found2");
            end

            zero_count = 0;
        end
    end
end

disp(size(dc_encoded));
disp(size(ac_encoded));

original_size_bits = numel(img) * 8;
compressed_dc_bits = sum(cellfun(@length, dc_encoded));
compressed_ac_bits = sum(cellfun(@length, ac_encoded));
compressed_size_bits = compressed_dc_bits + compressed_ac_bits;
compression_rate = original_size_bits / compressed_size_bits;
disp(['Compression Rate: ', num2str(compression_rate)]);
fprintf('1 / %.4f = %.4f\n', compression_rate, 1 / compression_rate);

