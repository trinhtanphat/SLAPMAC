"""Microphone-based slap detection for Linux.

Same algorithm as Windows SlapDetector: RMS amplitude analysis with
adaptive baseline, suppression window, and post-suppression recalibration
to guarantee 1 slap = 1 sound.
"""

import time
import threading

try:
    import numpy as np
    import sounddevice as sd
    HAS_AUDIO_INPUT = True
except ImportError:
    HAS_AUDIO_INPUT = False


class SlapDetector:
    def __init__(self, on_slap=None):
        self.on_slap = on_slap
        self.sensitivity = 1.5
        self.cooldown_ms = 1500
        self.is_running = False

        self._baseline = 0.0
        self._calibration_count = 0
        self._calibration_total = 50
        self._last_slap_time = 0.0
        self._stream = None

        # Suppression window for feedback loop prevention
        self._suppressed = False
        self._suppress_until = 0.0
        self._recalibration_remaining = 0
        self._recalibration_count = 20

    def start(self):
        if self.is_running or not HAS_AUDIO_INPUT:
            return
        self.is_running = True
        self._baseline = 0.0
        self._calibration_count = 0
        self._suppressed = False
        self._recalibration_remaining = 0

        try:
            self._stream = sd.InputStream(
                samplerate=44100,
                channels=1,
                dtype='int16',
                blocksize=882,
                callback=self._audio_callback
            )
            self._stream.start()
        except Exception as e:
            print(f"[SlapMac] Failed to start mic: {e}")
            self.is_running = False

    def stop(self):
        self.is_running = False
        if self._stream:
            try:
                self._stream.stop()
                self._stream.close()
            except Exception:
                pass
            self._stream = None

    def _audio_callback(self, indata, frames, time_info, status):
        if not self.is_running:
            return

        # RMS calculation
        samples = indata[:, 0].astype(np.float64) / 32768.0
        rms = float(np.sqrt(np.mean(samples ** 2)))

        # Calibration phase
        if self._calibration_count < self._calibration_total:
            self._baseline = max(self._baseline, rms)
            self._calibration_count += 1
            return

        threshold = self._baseline * (3.0 / max(0.5, self.sensitivity))
        min_absolute = 0.05 / max(0.5, self.sensitivity)

        now = time.monotonic()

        # Suppression window - skip detection while audio plays back
        if self._suppressed and now < self._suppress_until:
            return

        # Transition out of suppression: force recalibration
        if self._suppressed:
            self._suppressed = False
            self._baseline = 0.0
            self._recalibration_remaining = self._recalibration_count

        # Post-suppression recalibration
        if self._recalibration_remaining > 0:
            self._baseline = max(self._baseline, rms)
            self._recalibration_remaining -= 1
            return

        if rms > max(threshold, min_absolute):
            elapsed_ms = (now - self._last_slap_time) * 1000
            if elapsed_ms >= self.cooldown_ms:
                self._last_slap_time = now
                self._suppressed = True
                self._suppress_until = now + max(self.cooldown_ms * 2, 3000) / 1000.0

                if self.on_slap:
                    threading.Thread(target=self.on_slap, daemon=True).start()
        else:
            # Slowly adapt baseline
            self._baseline = self._baseline * 0.98 + rms * 0.02
