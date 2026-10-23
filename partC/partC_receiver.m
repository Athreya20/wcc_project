function out = partC_receiver(r, P)
%PARTC_RECEIVER Question 8C: pilot-aided adaptive-QAM frame receiver.
% out = partC_receiver(receivedSamples, parameters)
% Frame: 32 known QPSK pilots | Part A's 34-bit QPSK header |
%        payload bits | CRC-16/CCITT-FALSE | zero padding to a symbol.
% Assumes frame start and symbol timing are known (as in Parts A and B).
% Requires gray_qam_map.m from ../src; does not use the true channel or bits.

r = r(:);
out = struct('valid', false, 'crcOK', false, 'mode', NaN, ...
    'payload', [], 'snrDb', NaN, 'cqi', NaN, 'headerOK', false);

% Matched RRC filter and symbol sampling at Part A's 1:sps:end instants.
y = conv(r, P.rrc, 'same');
y = y(1:P.sps:end);
if numel(y) < P.Npilot + 17
    return;
end

% Estimate one complex flat-fading coefficient and post-filter noise power.
% Ignore the first/last few pilots to avoid frame edges and header transition.
known = P.pilots(6:P.Npilot-5);
observed = y(6:P.Npilot-5);
hhat = sum(observed .* conj(known))/sum(abs(known).^2);
residual = observed - hhat*known;
noisePower = mean(abs(residual).^2);
out.snrDb = 10*log10(max(abs(hhat)^2, realmin)/max(noisePower, realmin));
out.cqi = min(31, max(0, round(out.snrDb))); % 5-bit CQI, 0..31 dB
if abs(hhat) < 1e-8
    return;
end
z = y/hhat; % one-tap complex gain/phase correction

% The header uses QPSK in every mode, as in Part A.
hdr = z(P.Npilot + (1:17));
headerBits = reshape([real(hdr)<0, imag(hdr)<0].', [], 1);
headerBits = double(headerBits);
sync = [1;1;0;1;0;0;1;1; 1;0;0;1;0;0;0;1];
if ~isequal(headerBits(1:16), sync)
    return;
end
modeID = 2*headerBits(17) + headerBits(18);
payloadLength = sum(headerBits(19:34) .* 2.^(15:-1:0).');
if modeID > 2 || payloadLength ~= P.Npay
    return;
end
out.headerOK = true;
out.mode = modeID + 1;
M = [4 16 64];
M = M(out.mode);
k = log2(M);
nSymbols = ceil((payloadLength + 16)/k);
start = P.Npilot + 18;
if numel(z) < start + nSymbols - 1
    return;
end

% Minimum-distance decisions use the exact Gray mapper from Part A.
labels = zeros(M, k);
for v = 0:M-1
    labels(v+1,:) = bitget(v, k:-1:1);
end
points = gray_qam_map(reshape(labels.', [], 1), M);
received = z(start:start+nSymbols-1);
decisions = zeros(nSymbols, 1);
for n = 1:nSymbols
    [~, decisions(n)] = min(abs(received(n)-points).^2);
end
bits = reshape(labels(decisions,:).', [], 1);
out.payload = bits(1:payloadLength);
frameWithCRC = bits(1:payloadLength+16);
out.crcOK = crc16_remainder(frameWithCRC) == 0;
out.valid = out.headerOK && out.crcOK;
end

function reg = crc16_remainder(bits)
% CRC-16/CCITT-FALSE: poly 0x1021, initial 0xFFFF, MSB-first, no xorout.
reg = uint16(65535);
poly = uint16(hex2dec('1021'));
for i = 1:numel(bits)
    top = bitget(reg, 16);
    reg = bitshift(reg, 1);
    if xor(logical(top), logical(bits(i)))
        reg = bitxor(reg, poly);
    end
end
end
