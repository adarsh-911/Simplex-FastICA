% =========================================================================
% Simple Classical Gram-Schmidt Orthogonalization
% =========================================================================
% This script demonstrates the standard, textbook Gram-Schmidt algorithm
% using basic MATLAB functions. It takes a set of vectors and produces
% a new set of vectors that are orthogonal and have a length of 1 (orthonormal).
% =========================================================================

clear;
clc;
format long g; % Use a nice format for displaying numbers

FRAC_WIDTH = 20;

% --- 1. Define the Input Vectors ---
% Let's create a matrix 'W' where each column is a vector.
% We will use the same W1, W2, and W3 from our previous tests.
W = [
    50,  10, 100;  % W1, W2, W3 (Column 1, 2, 3)
   -20,  90, 110;
    10, -40, 120;
    80,  25, 130;
   -30,  55, 140;
    45, -65, 150;
    60,   5, 160
];

W(:, 1) = randi([-100, 100], 1, size(W, 1));
W(:, 2) = randi([-100, 100], 1, size(W, 1));
W(:, 3) = randi([-100, 100], 1, size(W, 1));

W_inp = W(:, 3) * 2^(FRAC_WIDTH);

filename = sprintf('sw-test/unit/gso/_w_in.mem');
fid = fopen(filename, 'w');

hex_str1 = '';

for j = 1:size(W_inp, 1)
    val = double(W_inp(j, 1));
    if val < 0
        val = val + 2^(32);
    end
    hex_str1 = [dec2hex(val, 8), hex_str1];
end

fprintf(fid, '%s', hex_str1);
fclose(fid);

fprintf('--- Input Vectors (W) ---\n');
disp(W);

% Get the number of vectors
[~, num_vectors] = size(W);

% Create an empty matrix 'Q' to store the final orthogonal vectors
Q = zeros(size(W));

% --- 2. Perform the Gram-Schmidt Process ---
% Loop through each vector in W
for k = 1:num_vectors
    
    % Start with the current vector
    v_k = W(:, k);
    
    % Subtract the projections onto all *previous* orthogonal vectors
    % This inner loop does the main work of the algorithm
    for j = 1:(k-1)
        q_j = Q(:, j); % Get the previous orthogonal vector
        
        % Calculate the projection of v_k onto q_j
        projection = (dot(v_k, q_j) / dot(q_j, q_j)) * q_j;
        
        % Subtract the projection from our working vector
        v_k = v_k - projection;
    end
    
    % Now, v_k is orthogonal to all previous vectors.
    % We normalize it (make its length/norm = 1) and store it in Q.
    Q(:, k) = v_k / norm(v_k);
    
end

W_gso = Q(:, 1:2);

theta = zeros(size(W_gso, 1)-1, 2);

for i=1:2
  mag = W_gso(1, i);
  for j=2:size(W_gso,1)
    theta(j-1, 3-i) = atan2(mag, W_gso(j, i));
    mag = sqrt(mag^2 + W_gso(j, i)^2);
  end
end

theta(1, 2) = atan2(W_gso(2, 1), W_gso(1, 1));
theta(1, 1) = atan2(W_gso(2, 2), W_gso(1, 2));

for i = size(theta, 2):-1:1
  for j = 1:size(theta, 1)
    theta(j, i) = int16(theta(j, i) * 2^(15) / pi);
  end
end

hex_str = cell(1, 2);
hex_str(:) = {''};

for i = size(theta, 2):-1:1
  for j = 1:size(theta, 1)
    val = double(theta(j, i));
    if val < 0
      val = val + 2^(16);
    end
    hex_str{1, i} = [dec2hex(val, 4), hex_str{1, i}];
  end
end

disp(hex_str);

filename = sprintf('sw-test/unit/gso/_thetas.mem');
fid = fopen(filename, 'w');

for col = 1:size(hex_str, 2)    
    for row = 1:size(hex_str, 1)
      fprintf(fid, '%s', hex_str{row, col});
    end
end

fclose(fid);

W_exp = Q(:, 3);

save('sw-test/unit/gso/w_mat.mat', 'W_exp');
