%% Minimal Fast ICA demo with EMG signals
% Parameters: d = mixed observations, r = independent components, frame_size = samples per frame
% Loads EMG data, mixes signals, performs centering and whitening, writes hex files, plots results

rng(42);

d = 5;
r = 5;
frame_size = 1024;

emg_files = {'../../dataset/emg_txtfiles/EMG_signalX_Wrist_Sup.txt', '../../dataset/emg_txtfiles/EMG_signalX_Wrist_Pro.txt', ...
             '../../dataset/emg_txtfiles/EMG_signalX_no_movement.txt', '../../dataset/emg_txtfiles/EMG_signalX_HO.txt', '../../dataset/emg_txtfiles/EMG_signalX_HC.txt'};

Ztrue = [];
for i = 1:min(r, length(emg_files))
    data = load(emg_files{i});
    if i == 1, Ztrue = zeros(r, length(data)); end
    Ztrue(i,:) = data';
end

num_frames = floor(size(Ztrue,2) / frame_size);

A = randomMixingMatrix(d, r);

idx1 = 1:frame_size;
Ztrue_frame1 = Ztrue(:, idx1);
Zmixed_frame1 = A * Ztrue_frame1;
[Zc_frame1, ~] = centerRows(Zmixed_frame1);
[Zwhite_frame1, ~] = whitenRows(Zc_frame1);
Zfica_frame1 = fastICA(Zwhite_frame1, r);

for frame = 1:num_frames
    idx = (frame-1)*frame_size + (1:frame_size);
    
    Zmixed = A * Ztrue(:, idx);
    [Zc, ~] = centerRows(Zmixed);
    [Zwhite, ~] = whitenRows(Zc);
    
    % normalisation
    data_hex = uint32(round((Zwhite / max(abs(Zwhite(:)))) * 2147483647) + 2147483648);
    fid = fopen(sprintf('frame_%d.hex', frame), 'w');
    [~, n] = size(Zwhite);
    for i = 1:n
        hex_format = repmat('%08X ', 1, d);
        fprintf(fid, [hex_format(1:end-1) '\n'], data_hex(:,i));
    end
    fclose(fid);
end

fprintf('Processed %d frames, wrote hex files 1-%d\n', num_frames, num_frames);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting starts from here - Individual plots
cm = hsv(max([d, r]));

figure('Name', 'ICA on EMG Signals (Frame 1)', 'Position', [100, 100, 1200, 800]);

% True EMG Signals (Sources) - Individual subplots
signal_names = {'Wrist Sup', 'Wrist Pro', 'No Move', 'Hand Open', 'Hand Close'};
for i = 1:r
    subplot(3, r, i);
    plot(Ztrue_frame1(i,:), '-', 'Color', cm(i,:), 'LineWidth', 1.5);
    title(sprintf('Source %d: %s', i, signal_names{min(i, length(signal_names))}));
    xlabel('Sample');
    ylabel('Amplitude');
    axis tight;
    grid on;
end

% Mixed Signals - Individual subplots
for i = 1:d
    subplot(3, d, d + i);
    plot(Zmixed_frame1(i,:), '-', 'Color', cm(i,:), 'LineWidth', 1.5);
    title(sprintf('Mixed Signal %d', i));
    xlabel('Sample');
    ylabel('Amplitude');
    axis tight;
    grid on;
end

% Recovered Independent Components - Individual subplots
for i = 1:r
    subplot(3, r, 2*r + i);
    plot(Zfica_frame1(i,:), '-', 'Color', cm(i,:), 'LineWidth', 1.5);
    title(sprintf('ICA Component %d', i));
    xlabel('Sample');
    ylabel('Amplitude');
    axis tight;
    grid on;
end

% Add main title
sgtitle('EMG Signal Processing: Original Sources, Mixed Signals, and ICA Recovery', 'FontSize', 14, 'FontWeight', 'bold');

% Adjust spacing between subplots
subplot_spacing = 0.05;
for i = 1:3*r
    sp = subplot(3, r, i);
    pos = get(sp, 'Position');
    pos(3) = pos(3) * 0.9;  
    pos(4) = pos(4) * 0.8;  
    set(sp, 'Position', pos);
end