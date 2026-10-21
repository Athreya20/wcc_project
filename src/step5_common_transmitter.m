
% Adaptive Wireless Link Project
% Step 5: Common-rate transmitter for three modulation modes

clc;
clear;
close all;
rng(1);

%% Common system parameters
sps = 8;               % Samples per symbol
Rs = 1000;             % Symbol rate (symbols/second)
Fs = Rs*sps;           % Common sample rate
beta = 0.35;           % RRC roll-off factor
span = 10;             % RRC filter span in symbols
NpayloadBits = 1200;   % Payload bits per mode

modes = {'QPSK', '16-QAM', '64-QAM'};
Mvalues = [4, 16, 64];

%% Create a root-raised-cosine filter
t = (-span*sps/2 : span*sps/2)/sps;
h = zeros(size(t));

for n = 1:length(t)
    x = t(n);

    if abs(x) < 1e-10
        h(n) = 1 + beta*(4/pi - 1);
    elseif abs(abs(x)-1/(4*beta)) < 1e-10
        h(n) = (beta/sqrt(2))* ...
            ((1+2/pi)*sin(pi/(4*beta)) + ...
             (1-2/pi)*cos(pi/(4*beta)));
    else
        h(n) = (sin(pi*x*(1-beta)) + ...
            4*beta*x*cos(pi*x*(1+beta))) / ...
            (pi*x*(1-(4*beta*x)^2));
    end
end

h = h/sqrt(sum(h.^2));

%% Build and transmit each modulation mode
for modeIndex = 1:3

    M = Mvalues(modeIndex);
    k = log2(M);

    % Create random payload bits
    payload = randi([0 1], NpayloadBits, 1);

    % Frame header:
    % 16-bit sync word + 2-bit mode ID + 16-bit payload length
    syncBits = [1;1;0;1;0;0;1;1; ...
                1;0;0;1;0;0;0;1];

    modeID = modeIndex - 1;
    modeBits = [bitget(modeID,2); bitget(modeID,1)];

    lengthBits = zeros(16,1);
    for b = 1:16
        lengthBits(b) = bitget(NpayloadBits,17-b);
    end

    header = [syncBits; modeBits; lengthBits];

    % Robustly map the header using QPSK.
    % Pad the header to an even number of bits if needed.
    headerPadded = [header; zeros(mod(length(header),2),1)];
    headerPairs = reshape(headerPadded,2,[]).';

    headerI = 1 - 2*headerPairs(:,1);
    headerQ = 1 - 2*headerPairs(:,2);
    headerSymbols = (headerI + 1j*headerQ)/sqrt(2);

    % Map payload bits using the tested Gray-coded mapper
    payloadSymbols = gray_qam_map(payload, M);


    % Combine header and payload into one framed symbol stream.
    txSymbols = [headerSymbols; payloadSymbols];

    % Upsample and apply the same pulse-shaping filter.
    upsampled = zeros(length(txSymbols)*sps,1);
    upsampled(1:sps:end) = txSymbols;
    txWaveform = conv(upsampled,h,'same');

    % Save results for later plots and analysis.
    symbolStreams{modeIndex} = txSymbols;
    headerLengths(modeIndex) = length(headerSymbols);
    waveforms{modeIndex} = txWaveform;

    fprintf('\nMode: %s\n', modes{modeIndex});
    fprintf('Bits per payload symbol: %d\n', k);
    fprintf('Nominal spectral efficiency: %d bits/s/Hz\n', k);
    fprintf('Common sample rate: %.0f samples/s\n', Fs);
    fprintf('Frame header length: %d bits\n', length(header));
    fprintf('Waveform samples: %d\n', length(txWaveform));
end

disp('All three transmitter waveforms generated.');


%% Step 6: Plot constellations and transmit spectra

figure('Name','Adaptive Transmitter Results', ...
    'Position',[100 100 1200 750]);

for modeIndex = 1:3

    % Retrieve the saved symbols and waveform
    txSymbols = symbolStreams{modeIndex};
    txWaveform = waveforms{modeIndex};

    % Number of bits represented by each payload symbol
    k = log2(Mvalues(modeIndex));

    % Plot constellation
    subplot(3,2,2*modeIndex-1);

% Plot payload symbols only, excluding the QPSK header
payloadStart = length(headerSymbols) + 1;
payloadOnly = txSymbols(headerLengths(modeIndex)+1:end);

plot(real(payloadOnly), imag(payloadOnly), 'b.', ...
     'MarkerSize', 10);


    grid on;
    axis equal;
    xlabel('In-phase (I)');
    ylabel('Quadrature (Q)');
    title([modes{modeIndex}, ' Constellation']);

    % Plot frequency spectrum
    Nfft = 8192;
    X = fftshift(fft(txWaveform, Nfft));
    f = (-Nfft/2:Nfft/2-1)' * Fs/Nfft;

    spectrum_dB = 20*log10(abs(X)/max(abs(X)) + 1e-12);

    subplot(3,2,2*modeIndex);

    plot(f, spectrum_dB);
    grid on;
    xlabel('Frequency (Hz)');
    ylabel('Normalized magnitude (dB)');
    title([modes{modeIndex}, ' Transmit Spectrum']);

    xlim([-2000 2000]);
    ylim([-80 5]);

    % Print modulation information
    fprintf('\n%s\n', modes{modeIndex});
    fprintf('Bits per symbol: %d\n', k);
    fprintf('Nominal spectral efficiency: %d bits/s/Hz\n', k);
end

