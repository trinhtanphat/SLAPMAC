using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Net.Http;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace SlapMac
{
    sealed class SettingsForm : Form
    {
        private const string GitHubTagsApi = "https://api.github.com/repos/trinhtanphat/SLAPMAC/tags?per_page=20";
        private const string ReleasesUrl = "https://github.com/trinhtanphat/SLAPMAC/releases/latest";

        private readonly SlapDetector _detector;
        private readonly AudioManager _audio;
        private readonly string _currentVersion;
        private string _language = "en";

        private Label _updateStatusLabel = null!;
        private Button _updateNowBtn = null!;
        private Button _checkUpdateBtn = null!;
        private ComboBox _languageCombo = null!;

        private static readonly (string Code, string Label)[] Languages = new[]
        {
            ("en", "🇺🇸 English"), ("vi", "🇻🇳 Tieng Viet"), ("es", "🇪🇸 Espanol"), ("fr", "🇫🇷 Francais"),
            ("de", "🇩🇪 Deutsch"), ("it", "🇮🇹 Italiano"), ("pt", "🇵🇹 Portugues"), ("ru", "🇷🇺 Russkiy"),
            ("ja", "🇯🇵 Nihongo"), ("ko", "🇰🇷 Hangug-eo"), ("zh-CN", "🇨🇳 JianTi ZhongWen"), ("zh-TW", "🇹🇼 FanTi ZhongWen"),
            ("th", "🇹🇭 Thai"), ("id", "🇮🇩 Bahasa Indonesia"), ("ms", "🇲🇾 Bahasa Melayu"), ("hi", "🇮🇳 Hindi"),
            ("ar", "🇸🇦 Arabic"), ("tr", "🇹🇷 Turkce"), ("pl", "🇵🇱 Polski"), ("nl", "🇳🇱 Nederlands")
        };

        public SettingsForm(SlapDetector detector, AudioManager audio)
        {
            _detector = detector;
            _audio = audio;
            _currentVersion = Application.ProductVersion;
            _language = (Application.UserAppDataRegistry.GetValue("Language", "en") as string) ?? "en";
            InitializeUI();
        }

        private void InitializeUI()
        {
            Text = "SlapMac Settings ⚙️";
            Size = new Size(440, 560);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            BackColor = Color.FromArgb(22, 22, 38);
            ForeColor = Color.FromArgb(230, 230, 240);
            Font = new Font("Segoe UI", 10);

            int y = 20;

            // ── Title ──
            var title = new Label
            {
                Text = "⚙️ Settings",
                Font = new Font("Segoe UI", 18, FontStyle.Bold),
                ForeColor = Color.FromArgb(255, 215, 0),
                AutoSize = true,
                Location = new Point(140, y),
            };
            Controls.Add(title);
            y += 50;

            Controls.Add(CreateSectionLabel("Language", 30, y));
            _languageCombo = new ComboBox
            {
                DropDownStyle = ComboBoxStyle.DropDownList,
                Font = new Font("Segoe UI", 9),
                Size = new Size(260, 28),
                Location = new Point(120, y - 2),
                BackColor = Color.FromArgb(45, 55, 72),
                ForeColor = Color.White,
            };
            foreach (var item in Languages)
            {
                _languageCombo.Items.Add(item.Label);
            }
            var index = Array.FindIndex(Languages, x => x.Code == _language);
            _languageCombo.SelectedIndex = index >= 0 ? index : 0;
            _languageCombo.SelectedIndexChanged += (s, e) =>
            {
                _language = Languages[_languageCombo.SelectedIndex].Code;
                Application.UserAppDataRegistry.SetValue("Language", _language);
                ApplyLocalizedLabels();
            };
            Controls.Add(_languageCombo);
            y += 36;

            // ── Sensitivity ──
            Controls.Add(CreateSectionLabel("Detection Sensitivity", 30, y));
            y += 25;

            var sensDesc = new Label
            {
                Text = "Lower = more sensitive (detects light taps)\nHigher = less sensitive (requires harder slaps)",
                Font = new Font("Segoe UI", 8),
                ForeColor = Color.FromArgb(120, 130, 150),
                AutoSize = true,
                Location = new Point(30, y),
            };
            Controls.Add(sensDesc);
            y += 35;

            var sensValue = CreateValueLabel($"{_detector.Sensitivity:F1}", 340, y + 3);
            Controls.Add(sensValue);

            var sensSlider = new TrackBar
            {
                Minimum = 5,
                Maximum = 40,
                Value = (int)(_detector.Sensitivity * 10),
                TickFrequency = 5,
                Size = new Size(300, 30),
                Location = new Point(30, y),
                BackColor = Color.FromArgb(22, 22, 38),
            };
            sensSlider.ValueChanged += (s, e) =>
            {
                _detector.Sensitivity = sensSlider.Value / 10.0;
                sensValue.Text = $"{_detector.Sensitivity:F1}";
            };
            Controls.Add(sensSlider);
            y += 50;

            // ── Volume ──
            Controls.Add(CreateSectionLabel("Playback Volume", 30, y));
            y += 25;

            var volValue = CreateValueLabel($"{(int)(_audio.Volume * 100)}%", 340, y + 3);
            Controls.Add(volValue);

            var volSlider = new TrackBar
            {
                Minimum = 0,
                Maximum = 100,
                Value = (int)(_audio.Volume * 100),
                TickFrequency = 10,
                Size = new Size(300, 30),
                Location = new Point(30, y),
                BackColor = Color.FromArgb(22, 22, 38),
            };
            volSlider.ValueChanged += (s, e) =>
            {
                _audio.Volume = volSlider.Value / 100f;
                volValue.Text = $"{volSlider.Value}%";
            };
            Controls.Add(volSlider);
            y += 50;

            // ── Cooldown ──
            Controls.Add(CreateSectionLabel("Cooldown (ms between sounds)", 30, y));
            y += 25;

            var coolValue = CreateValueLabel($"{_detector.CooldownMs}ms", 340, y + 3);
            Controls.Add(coolValue);

            var coolSlider = new TrackBar
            {
                Minimum = 500,
                Maximum = 5000,
                Value = Math.Clamp(_detector.CooldownMs, 500, 5000),
                TickFrequency = 500,
                SmallChange = 100,
                LargeChange = 500,
                Size = new Size(300, 30),
                Location = new Point(30, y),
                BackColor = Color.FromArgb(22, 22, 38),
            };
            coolSlider.ValueChanged += (s, e) =>
            {
                _detector.CooldownMs = coolSlider.Value;
                coolValue.Text = $"{coolSlider.Value}ms";
            };
            Controls.Add(coolSlider);
            y += 50;

            // ── Divider ──
            Controls.Add(new Panel
            {
                Size = new Size(370, 1),
                Location = new Point(20, y),
                BackColor = Color.FromArgb(50, 50, 70),
            });
            y += 15;

            // ── Add Custom Sound ──
            var addSoundBtn = new Button
            {
                Text = "🎵 Add Custom Sound...",
                Font = new Font("Segoe UI", 10),
                ForeColor = Color.White,
                BackColor = Color.FromArgb(45, 55, 72),
                FlatStyle = FlatStyle.Flat,
                Size = new Size(180, 36),
                Location = new Point(30, y),
                Cursor = Cursors.Hand,
            };
            addSoundBtn.FlatAppearance.BorderColor = Color.FromArgb(60, 70, 90);
            addSoundBtn.Click += OnAddSound;
            Controls.Add(addSoundBtn);

            var soundInfo = new Label
            {
                Text = $"{_audio.SoundCount} sound(s) loaded",
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.FromArgb(120, 130, 150),
                AutoSize = true,
                Location = new Point(220, y + 10),
            };
            Controls.Add(soundInfo);
            y += 55;

            Controls.Add(new Panel
            {
                Size = new Size(370, 1),
                Location = new Point(20, y),
                BackColor = Color.FromArgb(50, 50, 70),
            });
            y += 15;

            Controls.Add(CreateSectionLabel("Version", 30, y));

            var currentVersionLabel = new Label
            {
                Text = $"Current: v{_currentVersion}",
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                ForeColor = Color.FromArgb(255, 215, 0),
                AutoSize = true,
                Location = new Point(260, y + 2),
            };
            Controls.Add(currentVersionLabel);
            y += 28;

            _updateStatusLabel = new Label
            {
                Text = "Checking updates...",
                Font = new Font("Segoe UI", 8),
                ForeColor = Color.FromArgb(120, 130, 150),
                AutoSize = true,
                Location = new Point(30, y),
            };
            Controls.Add(_updateStatusLabel);
            y += 24;

            _checkUpdateBtn = new Button
            {
                Text = "Check Update",
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                ForeColor = Color.White,
                BackColor = Color.FromArgb(45, 55, 72),
                FlatStyle = FlatStyle.Flat,
                Size = new Size(140, 34),
                Location = new Point(30, y),
                Cursor = Cursors.Hand,
            };
            _checkUpdateBtn.FlatAppearance.BorderColor = Color.FromArgb(60, 70, 90);
            _checkUpdateBtn.Click += async (s, e) => await CheckForUpdatesAsync(true);
            Controls.Add(_checkUpdateBtn);

            _updateNowBtn = new Button
            {
                Text = "Update Now",
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                ForeColor = Color.White,
                BackColor = Color.FromArgb(233, 69, 96),
                FlatStyle = FlatStyle.Flat,
                Size = new Size(140, 34),
                Location = new Point(200, y),
                Cursor = Cursors.Hand,
                Enabled = false,
            };
            _updateNowBtn.FlatAppearance.BorderSize = 0;
            _updateNowBtn.Click += (s, e) => Process.Start(new ProcessStartInfo
            {
                FileName = ReleasesUrl,
                UseShellExecute = true,
            });
            Controls.Add(_updateNowBtn);
            y += 50;

            // ── Close Button ──
            var closeBtn = new Button
            {
                Text = "Done",
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                ForeColor = Color.White,
                BackColor = Color.FromArgb(233, 69, 96),
                FlatStyle = FlatStyle.Flat,
                Size = new Size(120, 38),
                Location = new Point(145, y),
                Cursor = Cursors.Hand,
            };
            closeBtn.FlatAppearance.BorderSize = 0;
            closeBtn.Click += (s, e) => Close();
            Controls.Add(closeBtn);
            AcceptButton = closeBtn;

            ApplyLocalizedLabels();
            _ = CheckForUpdatesAsync(false);
        }

        private void ApplyLocalizedLabels()
        {
            Text = L("title");
            _checkUpdateBtn.Text = L("check");
            _updateNowBtn.Text = L("update");
        }

        private string L(string key)
        {
            static Dictionary<string, string> En() => new()
            {
                ["title"] = "SlapMac Settings ⚙️",
                ["check"] = "Check Update",
                ["update"] = "Update Now",
                ["checking"] = "Checking GitHub tags...",
                ["noTags"] = "No release tags found.",
                ["new"] = "New version available: {0}",
                ["upToDate"] = "Up to date ({0}).",
                ["upToDateYou"] = "You're up to date ({0}).",
                ["failed"] = "Update check failed. Try again later.",
            };

            var en = En();
            var vi = new Dictionary<string, string>(en)
            {
                ["title"] = "Cai dat SlapMac ⚙️",
                ["check"] = "Kiem tra cap nhat",
                ["update"] = "Cap nhat ngay",
                ["checking"] = "Dang kiem tra GitHub tags...",
                ["noTags"] = "Khong tim thay release tag.",
                ["new"] = "Co ban moi: {0}",
                ["upToDate"] = "Da moi nhat ({0}).",
                ["upToDateYou"] = "Ban dang o ban moi nhat ({0}).",
                ["failed"] = "Kiem tra cap nhat that bai. Thu lai sau.",
            };

            var shared = new Dictionary<string, Dictionary<string, string>>
            {
                ["es"] = new() { ["check"] = "Buscar actualizacion", ["update"] = "Actualizar ahora" },
                ["fr"] = new() { ["check"] = "Verifier la mise a jour", ["update"] = "Mettre a jour" },
                ["de"] = new() { ["check"] = "Update pruefen", ["update"] = "Jetzt updaten" },
                ["it"] = new() { ["check"] = "Controlla aggiornamento", ["update"] = "Aggiorna ora" },
                ["pt"] = new() { ["check"] = "Verificar atualizacao", ["update"] = "Atualizar agora" },
                ["ru"] = new() { ["check"] = "Proverit obnovlenie", ["update"] = "Obnovit" },
                ["ja"] = new() { ["check"] = "Koshin chekku", ["update"] = "Ima sugu koshin" },
                ["ko"] = new() { ["check"] = "Eobdeiteu hwagin", ["update"] = "Jigeum eobdeiteu" },
                ["zh-CN"] = new() { ["check"] = "Jian cha geng xin", ["update"] = "Li ji geng xin" },
                ["zh-TW"] = new() { ["check"] = "Jian cha geng xin", ["update"] = "Li ji geng xin" },
                ["th"] = new() { ["check"] = "Truat sop update", ["update"] = "Update ton ni" },
                ["id"] = new() { ["check"] = "Cek pembaruan", ["update"] = "Perbarui sekarang" },
                ["ms"] = new() { ["check"] = "Semak kemas kini", ["update"] = "Kemas kini sekarang" },
                ["hi"] = new() { ["check"] = "Update check karo", ["update"] = "Abhi update karo" },
                ["ar"] = new() { ["check"] = "Tahqiq min altahdith", ["update"] = "Haddith alan" },
                ["tr"] = new() { ["check"] = "Guncellemeyi kontrol et", ["update"] = "Simdi guncelle" },
                ["pl"] = new() { ["check"] = "Sprawdz aktualizacje", ["update"] = "Aktualizuj teraz" },
                ["nl"] = new() { ["check"] = "Controleer update", ["update"] = "Nu updaten" },
            };

            if (_language == "vi" && vi.TryGetValue(key, out var viVal)) return viVal;
            if (shared.TryGetValue(_language, out var map) && map.TryGetValue(key, out var mapVal)) return mapVal;
            return en.TryGetValue(key, out var val) ? val : key;
        }

        private async System.Threading.Tasks.Task CheckForUpdatesAsync(bool manual)
        {
            _updateStatusLabel.Text = L("checking");
            _updateNowBtn.Enabled = false;
            _checkUpdateBtn.Enabled = false;

            try
            {
                using var http = new HttpClient();
                http.DefaultRequestHeaders.UserAgent.ParseAdd("SlapMac-Windows");
                var json = await http.GetStringAsync(GitHubTagsApi);
                using var doc = JsonDocument.Parse(json);

                string? latestTag = null;
                foreach (var item in doc.RootElement.EnumerateArray())
                {
                    if (!item.TryGetProperty("name", out var nameProp))
                        continue;
                    var tag = nameProp.GetString();
                    if (!string.IsNullOrWhiteSpace(tag) && Regex.IsMatch(tag, "^v?\\d+\\.\\d+\\.\\d+$"))
                    {
                        latestTag = tag;
                        break;
                    }
                }

                if (string.IsNullOrWhiteSpace(latestTag))
                {
                    _updateStatusLabel.Text = L("noTags");
                    return;
                }

                var latestVersion = latestTag.TrimStart('v');
                var cmp = CompareVersions(latestVersion, _currentVersion);
                if (cmp > 0)
                {
                    _updateStatusLabel.Text = string.Format(L("new"), latestTag);
                    _updateNowBtn.Enabled = true;
                }
                else
                {
                    _updateStatusLabel.Text = manual
                        ? string.Format(L("upToDateYou"), latestTag)
                        : string.Format(L("upToDate"), latestTag);
                }
            }
            catch
            {
                _updateStatusLabel.Text = L("failed");
            }
            finally
            {
                _checkUpdateBtn.Enabled = true;
            }
        }

        private static int CompareVersions(string a, string b)
        {
            var av = ParseVersion(a);
            var bv = ParseVersion(b);
            for (int i = 0; i < 3; i++)
            {
                if (av[i] > bv[i]) return 1;
                if (av[i] < bv[i]) return -1;
            }
            return 0;
        }

        private static int[] ParseVersion(string version)
        {
            var clean = Regex.Match(version, "\\d+\\.\\d+\\.\\d+").Value;
            var parts = clean.Split('.');
            return new[]
            {
                parts.Length > 0 && int.TryParse(parts[0], out var major) ? major : 0,
                parts.Length > 1 && int.TryParse(parts[1], out var minor) ? minor : 0,
                parts.Length > 2 && int.TryParse(parts[2], out var patch) ? patch : 0,
            };
        }

        private static Label CreateSectionLabel(string text, int x, int y)
        {
            return new Label
            {
                Text = text,
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                ForeColor = Color.FromArgb(200, 200, 220),
                AutoSize = true,
                Location = new Point(x, y),
            };
        }

        private static Label CreateValueLabel(string text, int x, int y)
        {
            return new Label
            {
                Text = text,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                ForeColor = Color.FromArgb(255, 215, 0),
                AutoSize = true,
                Location = new Point(x, y),
            };
        }

        private void OnAddSound(object? sender, EventArgs e)
        {
            using var dialog = new OpenFileDialog
            {
                Title = "Choose Audio File",
                Filter = "Audio Files|*.mp3;*.wav;*.aiff;*.m4a;*.wma;*.ogg|All Files|*.*",
                Multiselect = true,
            };

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                int added = 0;
                foreach (var file in dialog.FileNames)
                {
                    if (_audio.AddCustomSound(file))
                        added++;
                }
                if (added > 0)
                {
                    MessageBox.Show(
                        $"Added {added} sound(s)!",
                        "SlapMac",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information);
                }
            }
        }
    }
}
