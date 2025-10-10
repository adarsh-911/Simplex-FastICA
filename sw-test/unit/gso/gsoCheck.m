clc; clearvars;
format long g;

FRAC_WIDTH = 20;

S = load('sw-test/unit/gso/w_mat.mat');
W_exp = S.W_exp;

hex_stream = fileread('sw-test/unit/gso/out/sim.raw');

hex_stream = regexprep(hex_stream, '[^0-9a-fA-F]', '');
hex_stream = lower(hex_stream);

num_values = length(hex_stream) / 8;
hex_matrix = reshape(hex_stream, 8, [])';
unsigned_vals = uint32(hex2dec(hex_matrix));
w_out_est_dec = typecast(unsigned_vals(:), 'int32');

fprintf('\nEstimated w_out:\n');
%disp(w_out_est_dec(end:-1:1));

W_est = double(w_out_est_dec)/2^(FRAC_WIDTH);
W_est = W_est/norm(W_est);
W_est = W_est(end:-1:1);

disp(W_est);
fprintf('\nExpected w_out:\n');
disp(W_exp);

abs_error = abs(W_est - W_exp);

figure(1);
plot(abs_error, 'LineWidth', 1.5);
title('Error');
grid on;
waitforbuttonpress();