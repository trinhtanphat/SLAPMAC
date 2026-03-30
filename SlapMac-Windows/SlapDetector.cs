using System;
using System.IO;
using System.Threading;
using NAudio.Wave;

namespace SlapMac
{
    /// <summary>
    /// Detects laptop taps/slaps via microphone input by analyzing audio amplitude spikes.
    /// </summary>
    sealed class SlapDetector : IDisposable
    {
        private WaveInEvent? _waveIn;
        private bool _isRunning;
        private DateTime _lastSlapTime = DateTime.MinValue;
        private float _baselineAmplitude;
        private int _calibrationSamples;
        private const int CalibrationCount = 50;

        public event Action? SlapDetected;

        public double Sensitivity { get; set; } = 1.5;
        public int CooldownMs { get; set; } = 300;

        public void Start()
        {
            if (_isRunning) return;
            _isRunning = true;
            _baselineAmplitude = 0;
            _calibrationSamples = 0;

            try
            {
                _waveIn = new WaveInEvent
                {
                    WaveFormat = new WaveFormat(44100, 16, 1),
                    BufferMilliseconds = 20
                };

                _waveIn.DataAvailable += OnDataAvailable;
                _waveIn.RecordingStopped += (s, e) =>
                {
                    if (e.Exception != null)
                    {
                        System.Diagnostics.Debug.WriteLine(
                            $"[SlapMac] Recording error: {e.Exception.Message}");
                    }
                };

                _waveIn.StartRecording();
                System.Diagnostics.Debug.WriteLine("[SlapMac] Microphone detection started");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SlapMac] Failed to start mic: {ex.Message}");
                _isRunning = false;
            }
        }

        public void Stop()
        {
            _isRunning = false;
            if (_waveIn != null)
            {
                try
                {
                    _waveIn.StopRecording();
                    _waveIn.DataAvailable -= OnDataAvailable;
                    _waveIn.Dispose();
                }
                catch { /* ignore cleanup errors */ }
                _waveIn = null;
            }
        }

        private void OnDataAvailable(object? sender, WaveInEventArgs e)
        {
            if (!_isRunning || e.BytesRecorded == 0) return;

            // Calculate RMS amplitude from 16-bit PCM
            double sumSquares = 0;
            int sampleCount = e.BytesRecorded / 2;

            for (int i = 0; i < e.BytesRecorded; i += 2)
            {
                short sample = BitConverter.ToInt16(e.Buffer, i);
                double normalized = sample / 32768.0;
                sumSquares += normalized * normalized;
            }

            float rms = (float)Math.Sqrt(sumSquares / sampleCount);

            // Calibration phase: establish baseline noise level
            if (_calibrationSamples < CalibrationCount)
            {
                _baselineAmplitude = Math.Max(_baselineAmplitude, rms);
                _calibrationSamples++;
                return;
            }

            // Detection: check if amplitude spike exceeds threshold
            float threshold = _baselineAmplitude * (float)(3.0 / Sensitivity);
            float minAbsolute = 0.05f / (float)Sensitivity;

            if (rms > Math.Max(threshold, minAbsolute))
            {
                var now = DateTime.UtcNow;
                if ((now - _lastSlapTime).TotalMilliseconds >= CooldownMs)
                {
                    _lastSlapTime = now;

                    // Slowly adapt baseline (learning from ambient noise changes)
                    _baselineAmplitude = _baselineAmplitude * 0.95f + rms * 0.002f;

                    SlapDetected?.Invoke();
                }
            }
            else
            {
                // Slowly adapt baseline to ambient noise changes
                _baselineAmplitude = _baselineAmplitude * 0.98f + rms * 0.02f;
            }
        }

        public void Dispose()
        {
            Stop();
        }
    }
}
