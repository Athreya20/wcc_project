# WCC Project — Part B

## Overview
Part B is the channel / propagation model for the adaptive QAM link of Question 8.
It passes the Part A transmit waveform through AWGN and a slow Rayleigh flat-fading
channel whose SNR changes over time, and evaluates the closed loop with ideal,
delayed and noisy SNR feedback.

## Implemented Features
- Slow Rayleigh flat fading with a Jakes Doppler spectrum (fD = 0.1 Hz, coherence time 4.2 s)
- AWGN set by Es/N0 (average 24 dB), giving a time-varying SNR
- Channel checked against theory: Rayleigh PDF, autocorrelation, level-crossing rate, BER
- SNR feedback model: 5-bit CQI, estimation error, feedback delay
- Closed loop with Part A's frames and Part A's threshold + hysteresis rule
- Comparison of ideal, delayed (1 s), noisy (2 dB) and delayed + noisy feedback

## Files
- `partB_main.m` — Runs task B1 (channel, figures B1–B4) and task B2 (feedback, figures B5–B7).
- `partB_channel.m` — The channel model: fading generator and AWGN.

Part B uses Part A's `gray_qam_map.m` from the `src` folder.

## Requirements
- MATLAB (no toolboxes needed) or GNU Octave.

## How to Run
1. Keep the `partB` folder next to the `src` folder.
2. In MATLAB, make `partB` the current folder.
3. Run `partB_main` (about 2 minutes). `partB_main('B1')` or `partB_main('B2')` runs one task.
4. Figures are saved in `partB/figures` and the command-window output in `partB/results`.

## Results
| SNR feedback | Useful throughput | PER | Mode switches/min |
| --- | --- | --- | --- |
| Ideal | 3.30 kbit/s | 3.4 % | 16.1 |
| Delayed 1 s | 2.78 kbit/s | 16.6 % | 15.7 |
| Noisy 2 dB | 3.21 kbit/s | 5.0 % | 25.5 |
| Delayed + noisy | 2.78 kbit/s | 18.0 % | 25.7 |
| Ideal, Part A thresholds (10 / 18 dB) | 2.65 kbit/s | 47.8 % | 13.7 |

Feedback delay hurts most: a 1 s old CQI keeps 16/64-QAM running into fades.
Estimation error mainly makes the mode switch more often.
Part A's 10 / 18 dB thresholds fail even with ideal feedback, so the evaluation uses
thresholds calibrated for PER ≤ 10 % (19.81 / 25.89 dB) with the same rule and hysteresis.

## Scope
Part B covers the channel and the feedback path. The receiver (Part C) and the
threshold and delay optimisation (Part D) are not part of this folder. The figures
and numbers above come from GNU Octave; MATLAB draws different random numbers, so
its values differ slightly.
