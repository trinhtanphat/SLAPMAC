"""Audio playback manager for Linux using pygame."""

import os
import random
import shutil

try:
    import pygame
    pygame.mixer.init(frequency=44100, size=-16, channels=2, buffer=2048)
    HAS_PYGAME = True
except (ImportError, pygame.error):
    HAS_PYGAME = False


class AudioManager:
    def __init__(self, resource_dir):
        self.resource_dir = resource_dir
        self.volume = 1.0
        self.is_enabled = True
        self.sound_files = []
        self._load_sounds()

    def _load_sounds(self):
        if not os.path.isdir(self.resource_dir):
            return

        extensions = {'.mp3', '.wav', '.ogg'}
        for f in sorted(os.listdir(self.resource_dir)):
            ext = os.path.splitext(f)[1].lower()
            if ext in extensions:
                full_path = os.path.join(self.resource_dir, f)
                # Path containment check
                if os.path.abspath(full_path).startswith(
                        os.path.abspath(self.resource_dir)):
                    self.sound_files.append(full_path)

    @property
    def sound_count(self):
        return len(self.sound_files)

    def play_random_sound(self):
        if not self.is_enabled or not self.sound_files or not HAS_PYGAME:
            return

        try:
            path = random.choice(self.sound_files)
            pygame.mixer.music.load(path)
            pygame.mixer.music.set_volume(max(0.0, min(1.0, self.volume)))
            pygame.mixer.music.play()
        except Exception as e:
            print(f"[SlapMac] Playback error: {e}")

    def add_custom_sound(self, filepath):
        if not os.path.isfile(filepath):
            return False

        ext = os.path.splitext(filepath)[1].lower()
        if ext not in {'.mp3', '.wav', '.ogg'}:
            return False

        filename = os.path.basename(filepath)
        filename = filename.replace('..', '').replace('/', '_').replace('\\', '_')
        if not filename or filename.startswith('.'):
            return False

        os.makedirs(self.resource_dir, exist_ok=True)
        dest = os.path.join(self.resource_dir, filename)

        # Path containment check
        if not os.path.abspath(dest).startswith(os.path.abspath(self.resource_dir)):
            return False

        shutil.copy2(filepath, dest)
        self.sound_files.append(dest)
        return True

    def cleanup(self):
        if HAS_PYGAME:
            try:
                pygame.mixer.quit()
            except Exception:
                pass
