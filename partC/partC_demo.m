function partC_demo()
%PARTC_DEMO Run Question 8C with Part A's mapper and Part B's channel.
% From the repository root, addpath('src','partB','partC'); partC_demo
% No Communications Toolbox needed. This uses a documented extended frame
% (pilots + CRC), so it is not a direct decoder of the original A/B frame.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));
addpath(fullfile(here, '..', 'partB'));
assert(exist('gray_qam_map', 'file') == 2, 'Missing src/gray_qam_map.m');
assert(exist('partB_channel', 'file') == 2, 'Missing partB/partB_channel.m');
rng(8);
P.sps = 8; P.Rs = 1000; P.Fs = 8000;
P.Npay = 1200; P.Npilot = 32;
P.rrc = rrc_filter(0.35, 10, P.sps);
P.pilots = repmat([1+1j; 1-1j; -1+1j; -1-1j]/sqrt(2), 8, 1);
N = 120; % Frames over a slow-varying channel
F = partB_channel('init', 0.1, 32);
avgEsN0 = 27; feedbackDelay = 2; % delay in whole frames
feedback = nan(N, 1); modeLog = zeros(N, 1);
snrLog = nan(N, 1); crcLog = false(N, 1);
berLog = nan(N, 1); throughput = zeros(N, 1);
timeLog = zeros(N, 1); mode = 1; t0 = 0;
firstRecovered = [];

for frame = 1:N
    % Feedback is available only after measurement and the stated delay.
    lastAvailable = frame - 1 - feedbackDelay;
    if lastAvailable >= 1
        q = feedback(lastAvailable);
        mode = choose_mode(q, mode, 19.81, 25.89, 1.5);
    end
    txPayload = randi([0 1], P.Npay, 1);
    s = make_extended_frame(txPayload, mode, P);
    [r, ~] = partB_channel(s, t0, P, F, avgEsN0);
    out = partC_receiver(r, P);
    feedback(frame) = out.cqi; % value is computed from received pilots
    snrLog(frame) = out.snrDb;
    modeLog(frame) = mode;
    crcLog(frame) = out.valid;
    duration = numel(s)/P.Fs;
    timeLog(frame) = t0;
    if numel(out.payload) == P.Npay
        berLog(frame) = mean(out.payload ~= txPayload); % validation only
    end
    if out.valid
        throughput(frame) = P.Npay/duration; % accepted payload bit/s
        if isempty(firstRecovered), firstRecovered = out.payload; end
    end
    t0 = t0 + duration;
end

fprintf('Frames: %d | PER: %.2f%% | payload BER: %.4g\n', ...
    N, 100*(1-mean(crcLog)), mean(berLog(~isnan(berLog))));
fprintf('Useful throughput: %.1f bit/s | CRC passes: %d/%d\n', ...
    sum(crcLog)*P.Npay/t0, sum(crcLog), N);
fprintf('Mode count QPSK/16-QAM/64-QAM: %d / %d / %d\n', ...
    sum(modeLog==1), sum(modeLog==2), sum(modeLog==3));
for m = 1:3
    ix = modeLog == m;
    fprintf('Mode %d: frames %d, PER %.2f%%, BER %.4g\n', ...
        m, sum(ix), 100*(1-mean(crcLog(ix))), ...
        mean(berLog(ix & ~isnan(berLog))));
end
if ~isempty(firstRecovered)
    fprintf('First CRC-accepted payload (first 32 bits): %s\n', ...
        char('0' + firstRecovered(1:32).'));
end

figure('Name', 'Question 8C receiver results', 'Color', 'w');
subplot(3,1,1); plot(timeLog, snrLog, 'b.-'); grid on;
ylabel('Estimated SNR (dB)'); title('Pilot-based channel quality');
subplot(3,1,2); stairs(timeLog, modeLog, 'LineWidth', 1.2); grid on;
ylim([0.7 3.3]); set(gca,'YTick',1:3, ...
    'YTickLabel',{'QPSK','16-QAM','64-QAM'}); ylabel('Mode');
subplot(3,1,3); plot(timeLog, throughput, 'g.'); grid on;
xlabel('Time (s)'); ylabel('Useful bit/s'); title('Zero for rejected frames');
end

function s = make_extended_frame(payload, mode, P)
% Extends Part A header with 32 known pilots and a 16-bit CRC after payload.
sync = [1;1;0;1;0;0;1;1; 1;0;0;1;0;0;0;1];
id = mode - 1;
modeBits = [bitget(id,2); bitget(id,1)];
lengthBits = bitget(P.Npay, 16:-1:1).';
header = [sync; modeBits; lengthBits];
pair = reshape(header, 2, []).';
headerSymbols = (1-2*pair(:,1) + 1j*(1-2*pair(:,2)))/sqrt(2);
reg = crc16_remainder(payload);
crcBits = double(bitget(reg, 16:-1:1).');
M = [4 16 64]; M = M(mode);
k = log2(M);
data = double([payload; crcBits]);
data = [data; zeros(mod(-numel(data),k),1)];
sym = [P.pilots; headerSymbols; gray_qam_map(data,M)];
up = zeros(numel(sym)*P.sps,1);
up(1:P.sps:end) = sym;
s = conv(up, P.rrc, 'same'); % same pulse alignment as Part A
end

function mode = choose_mode(q, mode, T1, T2, H)
% Part A's hysteresis rule, with Part B's PER-calibrated thresholds.
if isnan(q), return; end
if mode == 1
    if q >= T2+H, mode=3;
    elseif q >= T1+H, mode=2; end
elseif mode == 2
    if q >= T2+H, mode=3;
    elseif q < T1-H, mode=1; end
else
    if q < T1-H, mode=1;
    elseif q < T2-H, mode=2; end
end
end

function h = rrc_filter(beta, span, sps)
% Identical root-raised-cosine coefficients to Part A and Part B.
t = (-span*sps/2:span*sps/2)/sps;
h = zeros(size(t));
for n = 1:numel(t)
    x = t(n);
    if abs(x) < 1e-10
        h(n) = 1+beta*(4/pi-1);
    elseif abs(abs(x)-1/(4*beta)) < 1e-10
        h(n) = (beta/sqrt(2))*((1+2/pi)*sin(pi/(4*beta)) + ...
            (1-2/pi)*cos(pi/(4*beta)));
    else
        h(n) = (sin(pi*x*(1-beta))+4*beta*x*cos(pi*x*(1+beta))) / ...
            (pi*x*(1-(4*beta*x)^2));
    end
end
h = h(:)/sqrt(sum(h.^2));
end

function reg = crc16_remainder(bits)
reg = uint16(65535); poly = uint16(hex2dec('1021'));
for i=1:numel(bits)
    top=bitget(reg,16); reg=bitshift(reg,1);
    if xor(logical(top),logical(bits(i)))
        reg=bitxor(reg,poly);
    end
end
end
