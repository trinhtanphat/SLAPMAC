using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using NAudio.Wave;

namespace SlapMac
{
    /// <summary>
    /// Manages audio playback of slap sound effects.
    /// </summary>
    sealed class AudioManager : IDisposable
    {
        private readonly List<string> _soundFiles = new();
        private readonly Random _random = new();
        private IWavePlayer? _currentPlayer;
        private AudioFileReader? _currentReader;

        public float Volume { get; set; } = 1.0f;
        public bool Enabled { get; set; } = true;
        public int SoundCount => _soundFiles.Count;

        public AudioManager()
        {
            LoadSounds();
        }

        private void LoadSounds()
        {
            var resourceDir = Path.Combine(AppContext.BaseDirectory, "Resources");
            if (!Directory.Exists(resourceDir))
            {
                // Try relative to exe
                resourceDir = Path.Combine(
                    AppContext.BaseDirectory,
                    "Resources");
            }

            if (Directory.Exists(resourceDir))
            {
                var extensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                    { ".mp3", ".wav", ".aiff", ".m4a", ".wma", ".ogg" };

                foreach (var file in Directory.EnumerateFiles(resourceDir))
                {
                    if (extensions.Contains(Path.GetExtension(file)))
                    {
                        _soundFiles.Add(file);
                    }
                }
            }

            System.Diagnostics.Debug.WriteLine($"[SlapMac] Loaded {_soundFiles.Count} sound(s)");
        }

        public void PlayRandomSound()
        {
            if (!Enabled || _soundFiles.Count == 0) return;

            try
            {
                // Dispose previous playback
                StopCurrent();

                int index = _random.Next(_soundFiles.Count);
                _currentReader = new AudioFileReader(_soundFiles[index])
                {
                    Volume = Math.Clamp(Volume, 0f, 1f)
                };

                _currentPlayer = new WaveOutEvent();
                _currentPlayer.Init(_currentReader);
                _currentPlayer.Play();

                System.Diagnostics.Debug.WriteLine(
                    $"[SlapMac] Playing: {Path.GetFileName(_soundFiles[index])}");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SlapMac] Playback error: {ex.Message}");
            }
        }

        public bool AddCustomSound(string filePath)
        {
            try
            {
                // Validate extension
                var ext = Path.GetExtension(filePath).ToLowerInvariant();
                var allowed = new HashSet<string> { ".mp3", ".wav", ".aiff", ".m4a", ".wma", ".ogg" };
                if (!allowed.Contains(ext))
                {
                    System.Diagnostics.Debug.WriteLine($"[SlapMac] Unsupported format: {ext}");
                    return false;
                }

                // Sanitize filename
                var fileName = Path.GetFileName(filePath);
                fileName = string.Join("_",
                    fileName.Split(Path.GetInvalidFileNameChars(), StringSplitOptions.RemoveEmptyEntries));

                if (string.IsNullOrWhiteSpace(fileName)) return false;

                var appData = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "SlapMac", "Sounds");
                Directory.CreateDirectory(appData);

                var dest = Path.Combine(appData, fileName);
                File.Copy(filePath, dest, overwrite: true);
                _soundFiles.Add(dest);

                System.Diagnostics.Debug.WriteLine($"[SlapMac] Added: {fileName}");
                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SlapMac] Add sound error: {ex.Message}");
                return false;
            }
        }

        private void StopCurrent()
        {
            try
            {
                _currentPlayer?.Stop();
                _currentPlayer?.Dispose();
                _currentReader?.Dispose();
            }
            catch { /* ignore */ }
            _currentPlayer = null;
            _currentReader = null;
        }

        public void Dispose()
        {
            StopCurrent();
        }
    }
}
