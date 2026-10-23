# ICT 3128 Question 8C - Receiver

This folder is designed to be copied into the repository containing the `src/`
folder from Part A and the `partB/` folder from Part B. It uses Part A's exact
Gray mapper and Part B's slow-fading + AWGN channel.

## Important interface agreement for the group

The original Part A/B frame has a 16-bit sync, 2-bit mode ID, 16-bit payload
length, and 1200-bit payload. **It has no CRC or pilots.** Part B's existing
`rx_measure` is a benchmark receiver: it is given the actual channel gain and
the actual mode, and calls a frame good only when it matches the known sent bits.
It does not perform CRC checking. A real CRC check cannot be performed on those
original frames without changing the transmitter. We extend the transmitted
frame for this runnable C demonstration:

```
32 known QPSK pilots | original 34-bit QPSK header | 1200-bit payload |
CRC-16/CCITT-FALSE | 0-2 zero padding bits (to complete a QAM symbol)
```

`partC_demo.m` builds that frame with Part A's mapper and RRC pulse, sends it
through `partB_channel.m`, then gives **only received samples and public frame
parameters** to `partC_receiver.m`. This is an integrated A+B+C demonstration
and does not silently claim that the original Part A/B files already send CRC.
If your group wants one unified simulation, agree on this exact extended frame
and call `partC_receiver(r,P)` in the combined loop. Part B's published metrics
are for its original, shorter frame and therefore should not be presented as
measurements from this Part C implementation.

## How to run

Keep `src/`, `partB/`, and `partC/` side by side. In MATLAB set the repository
root as Current Folder, then type:

```matlab
addpath('src', 'partB', 'partC');
partC_demo
```

No Communications Toolbox is used. The script prints overall and per-mode
BER/PER, CRC accepted count, useful throughput and the first 32 recovered bits;
it displays estimated SNR, mode timeline and throughput. Run it and save a
screenshot of your own actual MATLAB output for the handwritten submission.
Random seed is fixed at 8, but MATLAB and Octave may produce different numbers.

## Receiver steps to explain in your handwriting

1. Matched filter the received waveform with the same RRC pulse as transmitter;
   sample every `sps=8` samples. Frame start and timing are assumed known.
2. Estimate complex channel gain from 22 central known pilots:
   `hhat = sum(y_p .* conj(p)) / sum(abs(p).^2)`. Estimate post-filter noise
   power from `mean(abs(y_p-hhat*p).^2)` and calculate
   `SNRhat = 10*log10(abs(hhat)^2 / noisePower)`.
3. Equalize symbols using `z=y/hhat`, restoring amplitude and phase. Decode
   the 34-bit QPSK header; check sync, mode ID and payload length. The header
   tells the receiver to use QPSK, 16-QAM or 64-QAM for the remaining symbols.
4. For each payload symbol, pick the nearest constellation point from the
   actual Part A Gray mapper. Remove pad bits, split payload and 16 CRC bits,
   then calculate the CRC remainder. Accept only if the header and CRC pass.
5. Quantize the measured SNR to a 5-bit CQI (0-31 dB). Send it to the
   transmitter after two frame intervals. The transmitter selects a mode using
   hysteresis and thresholds 19.81/25.89 dB (the calibrated example from B).
6. `BER = erroneous recovered payload bits / compared payload bits` (the demo
   can compare with known simulation bits); `PER = rejected frames / frames`;
   `useful throughput = accepted payload bits / elapsed seconds`. The
   receiver itself does not receive the transmitted payload as an input.

**Block diagram to draw:** bits + CRC + header + pilots -> Gray mapper -> RRC
-> flat Rayleigh channel + AWGN -> matched RRC -> pilot channel/SNR estimate
-> equalizer -> header/mode -> Gray demapper -> CRC -> recovered bits.
Draw CQI feedback from the SNR estimate back to the next transmitter mode.

**Limitations to state:** the simulation knows the frame start and timing;
there is no separate timing recovery. The channel estimate assumes approximately
constant gain during each frame. The pilot-based SNR is noisy and the feedback
is delayed. At low SNR, a corrupted header causes rejection. CRC detects most
errors but is not proof of an error-free frame. For the group's final PDF,
include your name and signature on each handwritten page, the contribution
table, actual screenshots, and have the team lead combine one PDF. The
assignment sheet gives the deadline as 25 October 2026 at 5:00 PM.

## GitHub, without command-line Git

1. Choose the **Part B repository** as the base because it already contains
   the Part A `src/` folder. Do not upload the same Part C folder separately to
   both repositories unless your teammates request that.
2. Sign in to GitHub and open `https://github.com/Athreya20/wcc_project`.
   If you have write access, create a new branch there; otherwise click
   **Fork** to make your own copy. Keep the repository tree intact.
3. In your branch/fork, use **Add file > Upload files** at the repository root.
   Upload `partC/partC_receiver.m`, `partC/partC_demo.m` and this README,
   preserving the `partC` folder. Commit with a message such as
   `Add pilot-aided Q8C receiver and CRC demo`.
4. Open **Contribute > Open pull request**, target `Athreya20/wcc_project:main`,
   and send the PR link to the team lead. Tell them explicitly that Parts A/B
   must transmit the extended pilot+CRC frame to use this receiver and their
   old result table should remain labeled as Part B baseline.

You can also give the three files directly to a teammate who has repository
write access. Do not overwrite their `src/` or `partB/` files.
