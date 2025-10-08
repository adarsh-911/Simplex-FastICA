clc; clearvars;

addpath('sw-test/utils');
addpath('sw-test/mix_signals');

emg_hc = load('dataset/emg_txtfiles/EMG_signalX_HC.txt')';
emg_ho = load('dataset/emg_txtfiles/EMG_signalX_HO.txt')';
emg_no_mov = load('dataset/emg_txtfiles/EMG_signalX_no_movement.txt')';
emg_wrist_pro = load('dataset/emg_txtfiles/EMG_signalX_Wrist_Pro.txt')';
emg_wrist_sup = load('dataset/emg_txtfiles/EMG_signalX_Wrist_Sup.txt')';

num_sources = 5;
samples_width = 51200;

X_mat_pure = [emg_hc(1:samples_width); emg_ho(1:samples_width); emg_no_mov(1:samples_width); emg_wrist_pro(1:samples_width); emg_wrist_sup(1:samples_width)];

A_mix_mat = randn(num_sources, num_sources);

if rank(A_mix_mat) < num_sources
  A_mix_mat = randn(num_sources, num_sources);
end

X_mat_mix = A_mix_mat * X_mat_pure;

for i = 1:num_sources
  X_mat_mix(i, :) = (X_mat_mix(i, :) - mean(X_mat_mix(i, :))) / std(X_mat_mix(i, :));
end

clipped_size = 10;

window_size = 1024;
num_windows = 50;

for k = 1:num_windows
  idx_st = (k - 1)*window_size + 1;
  idx_end = k*window_size;
  window_data = round(X_mat_mix(1, idx_st:idx_end) * 2^20);

  file_name = sprintf('dataset/testVectors/channel_1/window_mix_%03d.txt', k);

  dlmwrite(file_name, window_data(1:clipped_size), 'delimiter', '\n', 'precision', '%d');
end

for k = 1:num_windows
  idx_st = (k - 1)*window_size + 1;
  idx_end = k*window_size;
  window_data = round(X_mat_mix(2, idx_st:idx_end)* 2^20);

  file_name = sprintf('dataset/testVectors/channel_2/window_mix_%03d.txt', k);

  dlmwrite(file_name, window_data(1:clipped_size), 'delimiter', '\n', 'precision', '%d');
end

for k = 1:num_windows
  idx_st = (k - 1)*window_size + 1;
  idx_end = k*window_size;
  window_data = round(X_mat_mix(3, idx_st:idx_end)* 2^20);

  file_name = sprintf('dataset/testVectors/channel_3/window_mix_%03d.txt', k);

  dlmwrite(file_name, window_data(1:clipped_size), 'delimiter', '\n', 'precision', '%d');
end

for k = 1:num_windows
  idx_st = (k - 1)*window_size + 1;
  idx_end = k*window_size;
  window_data = round(X_mat_mix(4, idx_st:idx_end)* 2^20);

  file_name = sprintf('dataset/testVectors/channel_4/window_mix_%03d.txt', k);

  dlmwrite(file_name, window_data(1:clipped_size), 'delimiter', '\n', 'precision', '%d');
end

for k = 1:num_windows
  idx_st = (k - 1)*window_size + 1;
  idx_end = k*window_size;
  window_data = round(X_mat_mix(5, idx_st:idx_end)* 2^20);

  file_name = sprintf('dataset/testVectors/channel_5/window_mix_%03d.txt', k);

  dlmwrite(file_name, window_data(1:clipped_size), 'delimiter', '\n', 'precision', '%d');
end

% Plot
%plot_sigs(emg_hc, emg_ho, emg_no_mov, emg_wrist_pro, emg_wrist_sup);

%plot_sigs(X_mat_mix(1, :), X_mat_mix(2, :), X_mat_mix(3, :), X_mat_mix(4, :), X_mat_mix(5, :));

%waitforbuttonpress;