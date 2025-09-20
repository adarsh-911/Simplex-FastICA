% clc; clear;

% Example data (replace with your actual data)
mixing_withlables = dataset_mixdata;  % 256000 rows, 2 columns

segment_length = 1024;   % Samples per segment
num_segments = 250;      % Total segments

% Preallocate segmented data
segments_mix_lb = zeros(segment_length, 2, num_segments);

% Create output folder
output_folder_mix_with_labels = 'C:\Users\LENOVO\Documents\MATLAB\segment_emg_data\mix_data_segment\Segments_with labels_Txt';
if ~exist(output_folder_mix_with_labels, 'dir')
    mkdir(output_folder_mix_with_labels);
end

% Segment and save each one
for i = 1:num_segments
    idx_start = (i-1)*segment_length + 1;
    idx_end = i*segment_length;
    segments_mix_lb(:,:,i) = mixing_withlables(idx_start:idx_end, :);

    % File name
    filename_mix = fullfile(output_folder_mix_with_labels, sprintf('mix_window_with_lables_%03d.txt', i));
    
    % Save segment as TXT (2 columns, tab-separated)
    writematrix(segments_mix_lb(:,:,i), filename_mix, 'Delimiter', 'tab');
end

disp('✅ All segments saved as separate .txt files in "Segments_Txt" folder.');
