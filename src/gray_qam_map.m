
function symbols = gray_qam_map(bits, M)
%GRAY_QAM_MAP Gray-coded QPSK, 16-QAM or 64-QAM mapper.
% Input bits must be a column vector containing 0s and 1s.
% Output symbols have unit average energy.

bits = bits(:);
k = log2(M);

if ~ismember(M, [4 16 64])
    error('M must be 4, 16, or 64.');
end

if any(bits ~= 0 & bits ~= 1)
    error('Input must contain only binary 0 and 1 values.');
end

if mod(length(bits), k) ~= 0
    error('Number of bits must be divisible by log2(M).');
end

groups = reshape(bits, k, []).';

if M == 4
    % Gray-coded QPSK
    I = 1 - 2*groups(:,1);
    Q = 1 - 2*groups(:,2);
    symbols = (I + 1j*Q)/sqrt(2);
    return;
end

% Split bits into the in-phase and quadrature components.
n = k/2;
Ibits = groups(:,1:n);
Qbits = groups(:,n+1:end);


% Convert bit groups to decimal Gray-code values
weights = 2.^(n-1:-1:0).';

Igray = double(Ibits) * weights;
Qgray = double(Qbits) * weights;

Iindex = Igray;
Qindex = Qgray;


% Gray-to-binary conversion.
shift = 1;
while shift < 2^n
    Iindex = bitxor(Iindex, bitshift(Iindex, -shift));
    Qindex = bitxor(Qindex, bitshift(Qindex, -shift));
    shift = shift*2;
end

% Convert indices into equally spaced amplitude levels.
L = 2^n;
I = 2*double(Iindex) - (L-1);
Q = 2*double(Qindex) - (L-1);

% Normalize average symbol energy to one.
symbols = (I + 1j*Q)/sqrt((2/3)*(M-1));
end
