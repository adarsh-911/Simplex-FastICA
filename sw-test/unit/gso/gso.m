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

fprintf('--- Input Vectors (columns of W) ---\n');
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
    Q(:, k) = v_k ;
    
end

% --- 3. Display the Final Results ---
fprintf('\n--- Final Orthonormal Vectors (columns of Q) ---\n');
disp(Q);

% --- Verification (Optional) ---
% To prove the vectors are orthogonal, their dot products should be close to 0.
fprintf('\n--- Verification Check ---\n');
fprintf('Dot product of Q1 and Q2 should be ~0: %f\n', dot(Q(:,1), Q(:,2)));
fprintf('Dot product of Q1 and Q3 should be ~0: %f\n', dot(Q(:,1), Q(:,3)));
fprintf('Dot product of Q2 and Q3 should be ~0: %f\n', dot(Q(:,2), Q(:,3)));

% To prove the vectors are normalized, their length (norm) should be 1.
fprintf('Norm of Q1 should be 1: %f\n', norm(Q(:,1)));
fprintf('Norm of Q2 should be 1: %f\n', norm(Q(:,2)));
fprintf('Norm of Q3 should be 1: %f\n', norm(Q(:,3)));
