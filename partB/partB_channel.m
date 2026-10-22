function varargout = partB_channel(varargin)
%PARTB_CHANNEL  Part B channel model: slow Rayleigh flat fading + AWGN.
%
%   F = partB_channel('init', fD, N)
%       New fading realisation: Clarke/Jakes Doppler spectrum with maximum
%       Doppler shift fD (Hz), sum-of-sinusoids model of Zheng & Xiao
%       (IEEE Trans. Commun., 2003) with N sinusoids per branch.
%
%   h = partB_channel('gain', F, t)
%       Complex fading gain h(t) at the times t (s). |h| is Rayleigh,
%       E|h|^2 = 1 and E[h(t+tau) h*(t)] = J0(2*pi*fD*tau).
%
%   [r, c, N0] = partB_channel(s, t0, P, F, EsN0dB)
%       Passes the Part A waveform s (sampled at P.Fs, first sample at
%       time t0) through the channel:  r(t) = c(t) s(t) + w(t)
%         c(t) : fading gain h(t); c = 1 when F = [] (AWGN only)
%         w(t) : complex white Gaussian noise, variance N0 per sample
%       Part A symbols and RRC pulse have unit energy (Es = 1), so
%       N0 = 10^(-EsN0dB/10) gives Es/N0 = EsN0dB at the matched filter.
%       With fading the instantaneous SNR is |c(t)|^2 * 10^(EsN0dB/10).
%
%   Group 08 | ICT 3128 Wireless Communication and Computing | Q8 Part B

if ischar(varargin{1})
    switch lower(varargin{1})
        case 'init'
            varargout{1} = fading_init(varargin{2}, varargin{3});
        case 'gain'
            varargout{1} = fading_gain(varargin{2}, varargin{3});
        otherwise
            error('partB_channel: unknown option ''%s''.', varargin{1});
    end
    return;
end

[s, t0, P, F, EsN0dB] = deal(varargin{1:5});
s  = s(:);
Ns = numel(s);

if isempty(F)
    c = ones(Ns, 1);
else
    % h(t) is evaluated once per symbol and linearly interpolated to the
    % sample instants (it is essentially constant within one symbol).
    tg = t0 + (0:ceil(Ns/P.sps) + 1).'/P.Rs;
    hg = fading_gain(F, tg);
    ts = t0 + (0:Ns - 1).'/P.Fs;
    c  = interp1(tg, hg, ts, 'linear');
end

N0 = 10^(-EsN0dB/10);
w  = sqrt(N0/2)*(randn(Ns, 1) + 1j*randn(Ns, 1));
r  = c.*s + w;

out = {r, c, N0};
varargout = out(1:max(nargout, 1));
end


function F = fading_init(fD, N)
% Random angle of arrival offset and random phases for both branches:
%   hI(t) = sqrt(2/N) sum cos(2 pi fD cos(a_n) t + phiI_n)
%   hQ(t) = sqrt(2/N) sum cos(2 pi fD sin(a_n) t + phiQ_n)
%   a_n = (2 pi n - pi + theta)/(4N),  theta, phi ~ U(-pi, pi)
theta = 2*pi*rand - pi;
n     = (1:N).';
a     = (2*pi*n - pi + theta)/(4*N);

F.fD   = fD;
F.N    = N;
F.wI   = 2*pi*fD*cos(a);
F.wQ   = 2*pi*fD*sin(a);
F.phiI = 2*pi*rand(N, 1) - pi;
F.phiQ = 2*pi*rand(N, 1) - pi;
end


function h = fading_gain(F, t)
% h(t) = (hI(t) + j hQ(t))/sqrt(2), evaluated in chunks to limit memory.
t = t(:).';
h = zeros(numel(t), 1);
chunk = 20000;
for s0 = 1:chunk:numel(t)
    idx = s0:min(s0 + chunk - 1, numel(t));
    hI  = sum(cos(bsxfun(@plus, F.wI*t(idx), F.phiI)), 1);
    hQ  = sum(cos(bsxfun(@plus, F.wQ*t(idx), F.phiQ)), 1);
    h(idx) = (hI + 1j*hQ).'/sqrt(F.N);     % sqrt(2/N)*(1/sqrt(2)) = 1/sqrt(N)
end
end
