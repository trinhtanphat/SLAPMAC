using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace SlapMac
{
    sealed class MainForm : Form
    {
        private readonly AudioManager _audio;
        private readonly SlapDetector _detector;
        private Label _counterLabel = null!;
        private Label _statusLabel = null!;
        private Panel _statusDot = null!;
        private Button _toggleBtn = null!;
        private bool _enabled = true;
        private int _slapCount;

        public event Action<bool>? ToggleStateChanged;
        public event Action<double>? SensitivityChanged;
        public event Action<float>? VolumeChanged;

        public MainForm(AudioManager audio, SlapDetector detector)
        {
            _audio = audio;
            _detector = detector;
            InitializeUI();
        }

        public void OnSlapDetected()
        {
            _slapCount++;
            if (InvokeRequired)
                BeginInvoke(new Action(UpdateCounter));
            else
                UpdateCounter();
        }

        private void UpdateCounter()
        {
            _counterLabel.Text = _slapCount.ToString();
        }

        private void InitializeUI()
        {
            Text = "SlapMac 🖐";
            Size = new Size(420, 560);
            MinimumSize = new Size(400, 500);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            BackColor = Color.FromArgb(22, 22, 38);
            ForeColor = Color.FromArgb(230, 230, 240);
            Font = new Font("Segoe UI", 10);

            var mainPanel = new Panel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(25),
                AutoScroll = true,
            };
            Controls.Add(mainPanel);

            int y = 15;

            // ── Title ──
            var title = new Label
            {
                Text = "🖐 SlapMac",
                Font = new Font("Segoe UI", 24, FontStyle.Bold),
                ForeColor = Color.FromArgb(255, 215, 0),
                AutoSize = true,
                Location = new Point(115, y),
            };
            mainPanel.Controls.Add(title);
            y += 50;

            var subtitle = new Label
            {
                Text = "Slap your laptop, hear funny sounds!",
                Font = new Font("Segoe UI", 10),
                ForeColor = Color.FromArgb(160, 160, 180),
                AutoSize = true,
                Location = new Point(88, y),
            };
            mainPanel.Controls.Add(subtitle);
            y += 35;

            // ── Divider ──
            mainPanel.Controls.Add(CreateDivider(y, 350));
            y += 15;

            // ── Status Row ──
            _statusDot = new Panel
            {
                Size = new Size(12, 12),
                Location = new Point(30, y + 5),
                BackColor = Color.FromArgb(46, 213, 115),
            };
            _statusDot.Paint += (s, e) =>
            {
                e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
                using var brush = new SolidBrush(_statusDot.BackColor);
                e.Graphics.FillEllipse(brush, 0, 0, 11, 11);
            };
            mainPanel.Controls.Add(_statusDot);

            _statusLabel = new Label
            {
                Text = "● Listening for taps...",
                Font = new Font("Segoe UI", 11),
                ForeColor = Color.FromArgb(46, 213, 115),
                AutoSize = true,
                Location = new Point(48, y + 2),
            };
            mainPanel.Controls.Add(_statusLabel);
            y += 35;

            // ── Slap Counter ──
            var counterTitle = new Label
            {
                Text = "SLAP COUNT",
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                ForeColor = Color.FromArgb(120, 120, 150),
                AutoSize = true,
                Location = new Point(155, y),
            };
            mainPanel.Controls.Add(counterTitle);
            y += 22;

            _counterLabel = new Label
            {
                Text = "0",
                Font = new Font("Segoe UI", 48, FontStyle.Bold),
                ForeColor = Color.FromArgb(233, 69, 96),
                AutoSize = true,
                TextAlign = ContentAlignment.MiddleCenter,
                Location = new Point(160, y),
            };
            mainPanel.Controls.Add(_counterLabel);
            y += 70;

            // ── Divider ──
            mainPanel.Controls.Add(CreateDivider(y, 350));
            y += 15;

            // ── Toggle Button ──
            _toggleBtn = new Button
            {
                Text = "⏸ Pause Detection",
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                ForeColor = Color.White,
                BackColor = Color.FromArgb(233, 69, 96),
                FlatStyle = FlatStyle.Flat,
                Size = new Size(200, 42),
                Location = new Point(95, y),
                Cursor = Cursors.Hand,
            };
            _toggleBtn.FlatAppearance.BorderSize = 0;
            _toggleBtn.Click += OnToggleClick;
            mainPanel.Controls.Add(_toggleBtn);
            y += 55;

            // ── Sensitivity ──
            var sensLabel = new Label
            {
                Text = "🎚️ Sensitivity",
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                ForeColor = Color.FromArgb(200, 200, 220),
                AutoSize = true,
                Location = new Point(30, y),
            };
            mainPanel.Controls.Add(sensLabel);

            var sensValue = new Label
            {
                Text = "1.5",
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.FromArgb(255, 215, 0),
                AutoSize = true,
                Location = new Point(320, y + 2),
            };
            mainPanel.Controls.Add(sensValue);
            y += 25;

            var sensSlider = new TrackBar
            {
                Minimum = 5,
                Maximum = 40,
                Value = 15,
                TickFrequency = 5,
                SmallChange = 1,
                LargeChange = 5,
                Size = new Size(330, 30),
                Location = new Point(25, y),
                BackColor = Color.FromArgb(22, 22, 38),
            };
            sensSlider.ValueChanged += (s, e) =>
            {
                var val = sensSlider.Value / 10.0;
                sensValue.Text = val.ToString("F1");
                SensitivityChanged?.Invoke(val);
            };
            mainPanel.Controls.Add(sensSlider);
            y += 40;

            // ── Volume ──
            var volLabel = new Label
            {
                Text = "🔊 Volume",
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                ForeColor = Color.FromArgb(200, 200, 220),
                AutoSize = true,
                Location = new Point(30, y),
            };
            mainPanel.Controls.Add(volLabel);

            var volValue = new Label
            {
                Text = "100%",
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.FromArgb(255, 215, 0),
                AutoSize = true,
                Location = new Point(320, y + 2),
            };
            mainPanel.Controls.Add(volValue);
            y += 25;

            var volSlider = new TrackBar
            {
                Minimum = 0,
                Maximum = 100,
                Value = 100,
                TickFrequency = 10,
                SmallChange = 5,
                LargeChange = 10,
                Size = new Size(330, 30),
                Location = new Point(25, y),
                BackColor = Color.FromArgb(22, 22, 38),
            };
            volSlider.ValueChanged += (s, e) =>
            {
                var val = volSlider.Value / 100f;
                volValue.Text = $"{volSlider.Value}%";
                _audio.Volume = val;
                VolumeChanged?.Invoke(val);
            };
            mainPanel.Controls.Add(volSlider);
            y += 40;

            // ── Sounds Info ──
            var soundsLabel = new Label
            {
                Text = $"🎵 {_audio.SoundCount} sound(s) loaded",
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.FromArgb(140, 140, 170),
                AutoSize = true,
                Location = new Point(30, y),
            };
            mainPanel.Controls.Add(soundsLabel);
            y += 25;

            // ── Test Sound Button ──
            var testBtn = new Button
            {
                Text = "🔊 Test Sound",
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.White,
                BackColor = Color.FromArgb(45, 55, 72),
                FlatStyle = FlatStyle.Flat,
                Size = new Size(120, 30),
                Location = new Point(30, y),
                Cursor = Cursors.Hand,
            };
            testBtn.FlatAppearance.BorderColor = Color.FromArgb(60, 70, 90);
            testBtn.Click += (s, e) => _audio.PlayRandomSound();
            mainPanel.Controls.Add(testBtn);
        }

        private static Panel CreateDivider(int y, int width)
        {
            return new Panel
            {
                Size = new Size(width, 1),
                Location = new Point(15, y),
                BackColor = Color.FromArgb(50, 50, 70),
            };
        }

        private void OnToggleClick(object? sender, EventArgs e)
        {
            _enabled = !_enabled;
            ToggleStateChanged?.Invoke(_enabled);

            if (_enabled)
            {
                _toggleBtn.Text = "⏸ Pause Detection";
                _toggleBtn.BackColor = Color.FromArgb(233, 69, 96);
                _statusLabel.Text = "● Listening for taps...";
                _statusLabel.ForeColor = Color.FromArgb(46, 213, 115);
                _statusDot.BackColor = Color.FromArgb(46, 213, 115);
            }
            else
            {
                _toggleBtn.Text = "▶ Resume Detection";
                _toggleBtn.BackColor = Color.FromArgb(45, 55, 72);
                _statusLabel.Text = "● Detection paused";
                _statusLabel.ForeColor = Color.FromArgb(180, 180, 200);
                _statusDot.BackColor = Color.FromArgb(180, 180, 200);
            }
            _statusDot.Invalidate();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            // Minimize to tray instead of closing
            if (e.CloseReason == CloseReason.UserClosing)
            {
                e.Cancel = true;
                Hide();
            }
            base.OnFormClosing(e);
        }
    }
}
