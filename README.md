# WCC Project — Part A

## Overview
This project implements the transmitter-side components for an adaptive modulation system.

## Implemented Features
- QPSK, 16-QAM, and 64-QAM symbol mapping
- Frame creation with header and payload
- Root-raised-cosine (RRC) pulse shaping
- Common transmit sample rate across modulation modes
- Constellation and spectrum plots
- Configurable SNR switching thresholds and hysteresis

## Files
- `step5_common_transmitter.m` — Main transmitter, frame generation, pulse shaping, and plots.
- `gray_qam_map.m` — Gray-coded QPSK, 16-QAM, and 64-QAM mapper.
- `step7_snr_switching.m` — Demonstration of configurable SNR thresholds and hysteresis.

## Requirements
- MATLAB
- Communications Toolbox may be required if the scripts use toolbox-specific functions.

## How to Run
1. Open MATLAB.
2. Add the `src` folder to the MATLAB path.
3. Run `step5_common_transmitter.m` to generate the transmitter waveforms and plots.
4. Run `step7_snr_switching.m` to demonstrate the SNR switching logic.

## Scope and Limitations
This is the transmitter-side Part A implementation. Receiver design, channel simulation, BER evaluation, and full closed-loop adaptation are outside the current scope. The SNR thresholds are illustrative and have not been calibrated against measured BER performance.
