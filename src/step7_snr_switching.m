
% Adaptive Wireless Link Project
% Step 7: Configurable SNR switching with hysteresis

clc;
clear;
close all;

%% User-configurable parameters
threshold1 = 10;    % QPSK / 16-QAM threshold in dB
threshold2 = 18;    % 16-QAM / 64-QAM threshold in dB
hysteresis = 1.5;   % Hysteresis margin in dB

% Modulation mode numbers:
% 1 = QPSK, 2 = 16-QAM, 3 = 64-QAM

modeNames = {'QPSK','16-QAM','64-QAM'};

%% Example estimated SNR values
snrValues = [7 10 12 17 20 18 16 9 7];

currentMode = 1;

fprintf('SNR switching demonstration\n\n');

for n = 1:length(snrValues)

    snr = snrValues(n);

    % Switching logic
    if currentMode == 1

        if snr >= threshold2 + hysteresis
            currentMode = 3;
        elseif snr >= threshold1 + hysteresis
            currentMode = 2;
        end

    elseif currentMode == 2

        if snr >= threshold2 + hysteresis
            currentMode = 3;
        elseif snr < threshold1 - hysteresis
            currentMode = 1;
        end

    elseif currentMode == 3

        if snr < threshold1 - hysteresis
            currentMode = 1;
        elseif snr < threshold2 - hysteresis
            currentMode = 2;
        end

    end

    fprintf('Estimated SNR: %5.1f dB | Mode: %s\n', ...
        snr, modeNames{currentMode});
end
