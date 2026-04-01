#!/usr/bin/env python3
"""SlapMac for Linux - Slap your laptop, hear funny sounds!"""

import tkinter as tk
from tkinter import filedialog
import json
import os
import re
import sys
import threading
import urllib.request
import webbrowser
from slap_detector import SlapDetector
from audio_manager import AudioManager

try:
    from PIL import Image, ImageTk
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


class SlapMacApp:
    GITHUB_TAGS_API = "https://api.github.com/repos/trinhtanphat/SLAPMAC/tags?per_page=20"
    RELEASES_URL = "https://github.com/trinhtanphat/SLAPMAC/releases/latest"

    def __init__(self):
        self.root = tk.Tk()
        self.root.title("SlapMac")
        self.root.configure(bg="#161626")
        self.root.geometry("400x700")
        self.root.resizable(False, False)

        self.slap_count = 0
        self.is_enabled = True
        self.current_version = "1.0.0"
        self.latest_tag = None
        self.language_code = "en"
        self.translations = {}
        self.languages = [
            ("en", "🇺🇸 English"), ("vi", "🇻🇳 Tieng Viet"), ("es", "🇪🇸 Espanol"), ("fr", "🇫🇷 Francais"),
            ("de", "🇩🇪 Deutsch"), ("it", "🇮🇹 Italiano"), ("pt", "🇵🇹 Portugues"), ("ru", "🇷🇺 Russkiy"),
            ("ja", "🇯🇵 Nihongo"), ("ko", "🇰🇷 Hangug-eo"), ("zh-CN", "🇨🇳 JianTi ZhongWen"), ("zh-TW", "🇹🇼 FanTi ZhongWen"),
            ("th", "🇹🇭 Thai"), ("id", "🇮🇩 Bahasa Indonesia"), ("ms", "🇲🇾 Bahasa Melayu"), ("hi", "🇮🇳 Hindi"),
            ("ar", "🇸🇦 Arabic"), ("tr", "🇹🇷 Turkce"), ("pl", "🇵🇱 Polski"), ("nl", "🇳🇱 Nederlands")
        ]
        self._load_i18n()

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
        self._check_updates(manual=False)

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

        lang_frame = tk.Frame(self.root, bg=bg)
        lang_frame.pack(pady=(10, 0), padx=26, fill="x")
        tk.Label(lang_frame, text=self._t("language"), font=("Arial", 10, "bold"), fg="#CCCCCC", bg=bg).pack(side="left")
        self.language_var = tk.StringVar(value=self.languages[0][1])
        self.language_menu = tk.OptionMenu(lang_frame, self.language_var, *[x[1] for x in self.languages], command=self._on_language_change)
        self.language_menu.config(bg="#333350", fg="#FFFFFF", activebackground="#444466", activeforeground="#FFFFFF", bd=0, highlightthickness=0)
        self.language_menu["menu"].config(bg="#1E1E36", fg="#FFFFFF")
        self.language_menu.pack(side="right")

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

        self.toggle_btn = tk.Button(btn_frame, text=self._t("pause"), width=14,
                                     font=("Arial", 12, "bold"),
                                     fg=fg, bg=accent, bd=0,
                                     activebackground="#C73650",
                                     activeforeground=fg,
                                     command=self._toggle)
        self.toggle_btn.pack(pady=4)

        self.test_btn = tk.Button(btn_frame, text=self._t("testSound"), width=14,
                  font=("Arial", 10), fg=fg, bg="#333350", bd=0,
                  activebackground="#444466", activeforeground=fg,
              command=self._test_sound)
        self.test_btn.pack(pady=4)

        self.sounds_label = tk.Label(self.root,
                                      text=self._t("soundsLoaded").format(self.audio.sound_count),
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

        # Version update section
        tk.Label(settings_frame, text=f"Version: v{self.current_version}",
                 font=("Arial", 10, "bold"), fg="#FFD700", bg=bg).pack(pady=(18, 4), anchor="w")

        self.update_status_label = tk.Label(
            settings_frame,
            text=self._t("checking"),
            font=("Arial", 9),
            fg=gray,
            bg=bg,
            anchor="w",
            justify="left",
        )
        self.update_status_label.pack(fill="x", pady=(0, 6))

        update_btn_frame = tk.Frame(settings_frame, bg=bg)
        update_btn_frame.pack(fill="x", pady=(0, 8))

        self.check_update_btn = tk.Button(
            update_btn_frame,
            text=self._t("checkUpdate"),
            width=16,
            font=("Arial", 10),
            fg=fg,
            bg="#333350",
            bd=0,
            activebackground="#444466",
            activeforeground=fg,
            command=lambda: self._check_updates(manual=True),
        )
        self.check_update_btn.pack(side="left")

        self.update_now_btn = tk.Button(
            update_btn_frame,
            text=self._t("updateNow"),
            width=16,
            font=("Arial", 10, "bold"),
            fg="#161626",
            bg="#FFD166",
            bd=0,
            state="disabled",
            activebackground="#FFBE3D",
            activeforeground="#161626",
            command=lambda: webbrowser.open(self.RELEASES_URL),
        )
        self.update_now_btn.pack(side="right")

    def _on_language_change(self, selected):
        for code, label in self.languages:
            if label == selected:
                self.language_code = code
                break
        self.toggle_btn.config(text=self._t("pause") if self.is_enabled else self._t("resume"))
        self.test_btn.config(text=self._t("testSound"))
        self.sounds_label.config(text=self._t("soundsLoaded").format(self.audio.sound_count))
        self.check_update_btn.config(text=self._t("checkUpdate"))
        self.update_now_btn.config(text=self._t("updateNow"))
        self._check_updates(manual=False)

    def _load_i18n(self):
        i18n_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "i18n.json")
        if not os.path.isfile(i18n_path):
            return

        try:
            data = json.loads(open(i18n_path, "r", encoding="utf-8").read())
            options = data.get("languageOptions", [])
            loaded = []
            for item in options:
                code = str(item.get("code", "")).strip()
                label = str(item.get("label", "")).strip()
                flag = str(item.get("flag", "")).strip()
                if code and label and flag:
                    loaded.append((code, f"{self._flag_to_emoji(flag)} {label}"))
            if loaded:
                self.languages = loaded

            translations = data.get("translations", {})
            if isinstance(translations, dict):
                self.translations = {
                    code: vals for code, vals in translations.items() if isinstance(vals, dict)
                }
        except Exception:
            self.translations = {}

    @staticmethod
    def _flag_to_emoji(code):
        code = (code or "").upper()
        if len(code) != 2:
            return ""
        return chr(127397 + ord(code[0])) + chr(127397 + ord(code[1]))

    def _t(self, key):
        if self.translations:
            en = self.translations.get("en", {})
            lang = self.translations.get(self.language_code, {})
            if key in lang:
                return lang[key]
            if key in en:
                return en[key]

        vi = {
            "language": "Ngon ngu", "pause": "⏸ Tam dung", "resume": "▶ Tiep tuc", "testSound": "🔊 Thu am thanh",
            "soundsLoaded": "{0} am thanh da tai", "checkUpdate": "Kiem tra cap nhat", "updateNow": "Cap nhat ngay",
            "checking": "Dang kiem tra GitHub tags...", "new": "Co ban moi: {0}", "upToDate": "Da moi nhat ({0}).",
            "upToDateYou": "Ban dang o ban moi nhat ({0}).", "updateFailed": "Kiem tra cap nhat that bai.", "noTags": "Khong tim thay release tag."
        }
        shared = {
            "es": {"language": "Idioma", "checkUpdate": "Buscar actualizacion", "updateNow": "Actualizar ahora"},
            "fr": {"language": "Langue", "checkUpdate": "Verifier la mise a jour", "updateNow": "Mettre a jour"},
            "de": {"language": "Sprache", "checkUpdate": "Update pruefen", "updateNow": "Jetzt updaten"},
            "it": {"language": "Lingua", "checkUpdate": "Controlla aggiornamento", "updateNow": "Aggiorna ora"},
            "pt": {"language": "Idioma", "checkUpdate": "Verificar atualizacao", "updateNow": "Atualizar agora"},
            "ru": {"language": "Yazyk", "checkUpdate": "Proverit obnovlenie", "updateNow": "Obnovit"},
            "ja": {"language": "Gengo", "checkUpdate": "Koshin chekku", "updateNow": "Ima sugu koshin"},
            "ko": {"language": "Eoneo", "checkUpdate": "Eobdeiteu hwagin", "updateNow": "Jigeum eobdeiteu"},
            "zh-CN": {"language": "Yu yan", "checkUpdate": "Jian cha geng xin", "updateNow": "Li ji geng xin"},
            "zh-TW": {"language": "Yu yan", "checkUpdate": "Jian cha geng xin", "updateNow": "Li ji geng xin"},
            "th": {"language": "Phasa", "checkUpdate": "Truat sop update", "updateNow": "Update ton ni"},
            "id": {"language": "Bahasa", "checkUpdate": "Cek pembaruan", "updateNow": "Perbarui sekarang"},
            "ms": {"language": "Bahasa", "checkUpdate": "Semak kemas kini", "updateNow": "Kemas kini sekarang"},
            "hi": {"language": "Bhasha", "checkUpdate": "Update check karo", "updateNow": "Abhi update karo"},
            "ar": {"language": "Lugha", "checkUpdate": "Tahqiq min altahdith", "updateNow": "Haddith alan"},
            "tr": {"language": "Dil", "checkUpdate": "Guncellemeyi kontrol et", "updateNow": "Simdi guncelle"},
            "pl": {"language": "Jezyk", "checkUpdate": "Sprawdz aktualizacje", "updateNow": "Aktualizuj teraz"},
            "nl": {"language": "Taal", "checkUpdate": "Controleer update", "updateNow": "Nu updaten"}
        }
        en = {
            "language": "Language", "pause": "⏸ Pause", "resume": "▶ Resume", "testSound": "🔊 Test Sound",
            "soundsLoaded": "{0} sound(s) loaded", "checkUpdate": "Check Update", "updateNow": "Update Now",
            "checking": "Checking GitHub tags...", "new": "New version available: {0}", "upToDate": "Up to date ({0}).",
            "upToDateYou": "You're up to date ({0}).", "updateFailed": "Update check failed. Try again later.", "noTags": "No release tags found."
        }
        if self.language_code == "vi":
            return vi.get(key, en.get(key, key))
        if self.language_code in shared:
            return shared[self.language_code].get(key, en.get(key, key))
        return en.get(key, key)

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
            self.toggle_btn.config(text=self._t("resume"), bg="#28A745")
        else:
            self.is_enabled = True
            self.detector.start()
            self.toggle_btn.config(text=self._t("pause"), bg="#E94560")

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
                    text=self._t("soundsLoaded").format(self.audio.sound_count))

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
        tk.Label(frame, text="⚠ 18+ warning: adult-oriented sound content",
             font=("Arial", 9, "bold"), fg="#FFB74D", bg=bg,
             justify="center").pack(pady=(0, 8))

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

    @staticmethod
    def _compare_versions(a, b):
        def parse(v):
            parts = [int(x) for x in str(v).split(".")[:3] if x.isdigit()]
            while len(parts) < 3:
                parts.append(0)
            return parts

        av = parse(a)
        bv = parse(b)
        if av > bv:
            return 1
        if av < bv:
            return -1
        return 0

    def _check_updates(self, manual=False):
        self.check_update_btn.config(state="disabled")
        self.update_now_btn.config(state="disabled")
        self.update_status_label.config(text=self._t("checking"))

        def worker():
            try:
                req = urllib.request.Request(
                    self.GITHUB_TAGS_API,
                    headers={
                        "Accept": "application/vnd.github+json",
                        "User-Agent": "SlapMac-Linux"
                    }
                )
                with urllib.request.urlopen(req, timeout=10) as response:
                    data = json.loads(response.read().decode("utf-8"))

                version_tags = []
                for item in data:
                    name = str(item.get("name", "")).strip()
                    if re.match(r"^v?\d+\.\d+\.\d+$", name):
                        version_tags.append(name)

                if not version_tags:
                    self.root.after(0, lambda: self._set_update_result(self._t("noTags"), False))
                    return

                self.latest_tag = version_tags[0]
                latest_version = self.latest_tag.lstrip("v")
                cmp = self._compare_versions(latest_version, self.current_version)

                if cmp > 0:
                    self.root.after(0, lambda: self._set_update_result(
                        self._t("new").format(self.latest_tag), True))
                else:
                    status = self._t("upToDateYou").format(self.latest_tag) if manual else self._t("upToDate").format(self.latest_tag)
                    self.root.after(0, lambda: self._set_update_result(status, False))
            except Exception:
                self.root.after(0, lambda: self._set_update_result(self._t("updateFailed"), False))

        threading.Thread(target=worker, daemon=True).start()

    def _set_update_result(self, message, can_update):
        self.update_status_label.config(text=message)
        self.update_now_btn.config(state="normal" if can_update else "disabled")
        self.check_update_btn.config(state="normal")

    def run(self):
        try:
            self.root.mainloop()
        finally:
            self.detector.stop()
            self.audio.cleanup()


if __name__ == '__main__':
    app = SlapMacApp()
    app.run()
