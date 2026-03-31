using System;
using System.Drawing;
using System.Windows.Forms;

namespace SlapMac
{
    sealed class SettingsForm : Form
    {
        private readonly SlapDetector _detector;
        private readonly AudioManager _audio;

        public SettingsForm(SlapDetector detector, AudioManager audio)
        {
            _detector = detector;
            _audio = audio;
            InitializeUI();
        }

        private void InitializeUI()
        {
            Text = "SlapMac Settings ⚙️";
            Size = new Size(440, 480);
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
