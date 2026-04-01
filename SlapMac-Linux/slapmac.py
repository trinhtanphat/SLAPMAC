#!/usr/bin/env python3
"""SlapMac for Linux - Slap your laptop, hear funny sounds!"""

import tkinter as tk
from tkinter import filedialog
import os
import sys
import threading
from slap_detector import SlapDetector
from audio_manager import AudioManager

try:
    from PIL import Image, ImageTk
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


class SlapMacApp:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("SlapMac")
        self.root.configure(bg="#161626")
        self.root.geometry("400x700")
        self.root.resizable(False, False)

        self.slap_count = 0
        self.is_enabled = True

        # Resource directory
        if getattr(sys, 'frozen', False):
            base_dir = sys._MEIPASS
        else:
            base_dir = os.path.dirname(os.path.abspath(__file__))
        resource_dir = os.path.join(base_dir, 'resources')

        self.audio = AudioManager(resource_dir)
        self.detector = SlapDetector(on_slap=self._on_slap)

        self._build_ui()
        self.detector.start()

    def _build_ui(self):
        bg = "#161626"
        fg = "#FFFFFF"
        accent = "#E94560"
        gray = "#AAAAAA"
        slider_bg = "#1E1E36"

        # Title
        tk.Label(self.root, text="🖐 SlapMac", font=("Arial", 28, "bold"),
                 fg=accent, bg=bg).pack(pady=(30, 0))
        tk.Label(self.root, text="Slap your laptop, hear funny sounds!",
                 font=("Arial", 11), fg=gray, bg=bg).pack(pady=(4, 0))
        tk.Label(self.root, text="⚠ 18+ warning: adult-oriented sound content",
             font=("Arial", 9, "bold"), fg="#FFB74D", bg=bg).pack(pady=(4, 0))

        # Counter
        self.counter_label = tk.Label(self.root, text="0",
                                      font=("Courier", 72, "bold"),
                                      fg=accent, bg=bg)
        self.counter_label.pack(pady=(30, 0))
        tk.Label(self.root, text="S L A P S", font=("Arial", 14),
                 fg=fg, bg=bg).pack()

        # Buttons frame
        btn_frame = tk.Frame(self.root, bg=bg)
        btn_frame.pack(pady=20)

        self.toggle_btn = tk.Button(btn_frame, text="⏸ Pause", width=14,
                                     font=("Arial", 12, "bold"),
                                     fg=fg, bg=accent, bd=0,
                                     activebackground="#C73650",
                                     activeforeground=fg,
                                     command=self._toggle)
        self.toggle_btn.pack(pady=4)

        tk.Button(btn_frame, text="🔊 Test Sound", width=14,
                  font=("Arial", 10), fg=fg, bg="#333350", bd=0,
                  activebackground="#444466", activeforeground=fg,
                  command=self._test_sound).pack(pady=4)

        self.sounds_label = tk.Label(self.root,
                                      text=f"{self.audio.sound_count} sound(s) loaded",
                                      font=("Arial", 9), fg=gray, bg=bg)
        self.sounds_label.pack()

        # Settings section
        tk.Label(self.root, text="⚙️ Settings", font=("Arial", 16, "bold"),
                 fg=fg, bg=bg).pack(pady=(20, 8))

        settings_frame = tk.Frame(self.root, bg=bg)
        settings_frame.pack(fill="x", padx=30)

        # Sensitivity slider (0.5 - 4.0)
        self.sens_label = tk.Label(settings_frame, text="Sensitivity: 1.5",
                                    font=("Arial", 10), fg="#CCCCCC", bg=bg)
        self.sens_label.pack(anchor="w")
        self.sens_slider = tk.Scale(settings_frame, from_=5, to=40,
                                     orient="horizontal", bg=slider_bg,
                                     fg=fg, troughcolor="#333350",
                                     highlightthickness=0, bd=0,
                                     sliderlength=20, length=340,
                                     showvalue=False,
                                     command=self._on_sensitivity)
        self.sens_slider.set(15)
        self.sens_slider.pack(pady=(0, 8))

        # Volume slider (0 - 100)
        self.vol_label = tk.Label(settings_frame, text="Volume: 100%",
                                   font=("Arial", 10), fg="#CCCCCC", bg=bg)
        self.vol_label.pack(anchor="w")
        self.vol_slider = tk.Scale(settings_frame, from_=0, to=100,
                                    orient="horizontal", bg=slider_bg,
                                    fg=fg, troughcolor="#333350",
                                    highlightthickness=0, bd=0,
                                    sliderlength=20, length=340,
                                    showvalue=False,
                                    command=self._on_volume)
        self.vol_slider.set(100)
        self.vol_slider.pack(pady=(0, 8))

        # Cooldown slider (500 - 5000ms)
        self.cool_label = tk.Label(settings_frame, text="Cooldown: 1500ms",
                                    font=("Arial", 10), fg="#CCCCCC", bg=bg)
        self.cool_label.pack(anchor="w")
        self.cool_slider = tk.Scale(settings_frame, from_=5, to=50,
                                     orient="horizontal", bg=slider_bg,
                                     fg=fg, troughcolor="#333350",
                                     highlightthickness=0, bd=0,
                                     sliderlength=20, length=340,
                                     showvalue=False,
                                     command=self._on_cooldown)
        self.cool_slider.set(15)
        self.cool_slider.pack(pady=(0, 8))

        # Add custom sound
        tk.Button(settings_frame, text="➕ Add Custom Sound", width=20,
                  font=("Arial", 10), fg=fg, bg="#333350", bd=0,
                  activebackground="#444466", activeforeground=fg,
                  command=self._add_sound).pack(pady=8)

        # Donate button
        tk.Button(settings_frame, text="☕ Support / Donate", width=20,
                  font=("Arial", 10), fg="#FFD700", bg="#333350", bd=0,
                  activebackground="#444466", activeforeground="#FFD700",
                  command=self._show_donate).pack(pady=4)

    def _on_slap(self):
        if not self.is_enabled:
            return
        self.audio.play_random_sound()
        self.slap_count += 1
        self.root.after(0, self._update_counter)

    def _update_counter(self):
        self.counter_label.config(text=str(self.slap_count))

    def _toggle(self):
        if self.is_enabled:
            self.is_enabled = False
            self.detector.stop()
            self.toggle_btn.config(text="▶ Resume", bg="#28A745")
        else:
            self.is_enabled = True
            self.detector.start()
            self.toggle_btn.config(text="⏸ Pause", bg="#E94560")

    def _test_sound(self):
        self.audio.play_random_sound()
        self.slap_count += 1
        self._update_counter()

    def _on_sensitivity(self, val):
        s = int(val) / 10.0
        self.sens_label.config(text=f"Sensitivity: {s:.1f}")
        self.detector.sensitivity = s

    def _on_volume(self, val):
        v = int(val)
        self.vol_label.config(text=f"Volume: {v}%")
        self.audio.volume = v / 100.0

    def _on_cooldown(self, val):
        ms = int(val) * 100
        self.cool_label.config(text=f"Cooldown: {ms}ms")
        self.detector.cooldown_ms = ms

    def _add_sound(self):
        path = filedialog.askopenfilename(
            title="Select Sound File",
            filetypes=[("Audio Files", "*.mp3 *.wav *.ogg *.m4a")]
        )
        if path:
            if self.audio.add_custom_sound(path):
                self.sounds_label.config(
                    text=f"{self.audio.sound_count} sound(s) loaded")

    def _show_donate(self):
        win = tk.Toplevel(self.root)
        win.title("Support SlapMac ☕")
        win.configure(bg="#161626")
        win.geometry("420x680")
        win.resizable(False, False)

        bg = "#161626"

        canvas = tk.Canvas(win, bg=bg, highlightthickness=0)
        scrollbar = tk.Scrollbar(win, orient="vertical", command=canvas.yview)
        frame = tk.Frame(canvas, bg=bg)

        frame.bind("<Configure>",
                    lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((210, 0), window=frame, anchor="n")
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        tk.Label(frame, text="☕ Support SlapMac", font=("Arial", 20, "bold"),
                 fg="#FFD700", bg=bg).pack(pady=(20, 4))
        tk.Label(frame, text="SlapMac is free and always will be!\n"
                 "If you enjoy it, consider supporting 😊",
                 font=("Arial", 10), fg="#8899AA", bg=bg,
                 justify="center").pack(pady=(0, 16))

        # Determine resource directory
        if getattr(sys, 'frozen', False):
            base_dir = sys._MEIPASS
        else:
            base_dir = os.path.dirname(os.path.abspath(__file__))
        res_dir = os.path.join(base_dir, 'resources')

        self._donate_images = []  # prevent garbage collection

        for label_text, color, filename in [
            ("MoMo", "#D63384", "momo.jpeg"),
            ("Techcombank", "#0D6EFD", "techcombank.jpeg"),
        ]:
            tk.Label(frame, text=label_text, font=("Arial", 14, "bold"),
                     fg=color, bg=bg).pack(pady=(12, 4))
            img_path = os.path.join(res_dir, filename)
            if HAS_PIL and os.path.isfile(img_path):
                img = Image.open(img_path)
                img = img.resize((200, 200), Image.LANCZOS)
                photo = ImageTk.PhotoImage(img)
                self._donate_images.append(photo)
                lbl = tk.Label(frame, image=photo, bg="#FFFFFF",
                               padx=8, pady=8)
                lbl.pack(pady=4)
            else:
                tk.Label(frame, text="(QR image not available)",
                         font=("Arial", 9), fg="#666666", bg=bg).pack()

        tk.Label(frame, text="Thank you for your support! 🙏",
                 font=("Arial", 12), fg="#FFD700", bg=bg).pack(pady=(16, 4))

        tk.Button(frame, text="← Close", width=14, font=("Arial", 10),
                  fg="#FFFFFF", bg="#333350", bd=0,
                  activebackground="#444466", activeforeground="#FFFFFF",
                  command=win.destroy).pack(pady=(8, 20))

    def run(self):
        try:
            self.root.mainloop()
        finally:
            self.detector.stop()
            self.audio.cleanup()


if __name__ == '__main__':
    app = SlapMacApp()
    app.run()
