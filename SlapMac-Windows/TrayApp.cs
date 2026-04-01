using System;
using System.Drawing;
using System.Windows.Forms;

namespace SlapMac
{
    /// <summary>
    /// System tray application that manages the SlapMac lifecycle.
    /// </summary>
    sealed class TrayApp : ApplicationContext
    {
        private NotifyIcon _trayIcon = null!;
        private readonly SlapDetector _detector;
        private readonly AudioManager _audio;
        private readonly MainForm _mainForm;
        private int _slapCount;
        private bool _enabled = true;
        private ToolStripMenuItem _toggleItem = null!;
        private ToolStripMenuItem _counterItem = null!;

        public TrayApp()
        {
            _audio = new AudioManager();
            _detector = new SlapDetector();
            _detector.SlapDetected += OnSlapDetected;

            // Create main window
            _mainForm = new MainForm(_audio, _detector);
            _mainForm.ToggleStateChanged += (enabled) =>
            {
                _enabled = enabled;
                _toggleItem.Checked = _enabled;
                _toggleItem.Text = _enabled ? "Enabled" : "Disabled";
                _audio.Enabled = _enabled;
                if (_enabled) _detector.Start(); else _detector.Stop();
                _trayIcon.Text = _enabled ? "SlapMac - Listening..." : "SlapMac - Paused";
            };
            _mainForm.SensitivityChanged += (val) => { _detector.Sensitivity = val; };
            _mainForm.VolumeChanged += (val) => { _audio.Volume = val; };

            // Build context menu
            _toggleItem = new ToolStripMenuItem("Enabled", null, OnToggle)
            { Checked = true };

            _counterItem = new ToolStripMenuItem("Slaps: 0")
            { Enabled = false };

            var sensitivityMenu = new ToolStripMenuItem("Sensitivity");
            AddSensitivity(sensitivityMenu, "Very Low (Light touch)", 0.5);
            AddSensitivity(sensitivityMenu, "Low", 1.0);
            AddSensitivity(sensitivityMenu, "Medium (Default)", 1.5, isDefault: true);
            AddSensitivity(sensitivityMenu, "High", 2.5);
            AddSensitivity(sensitivityMenu, "Very High (Hard slap only)", 4.0);

            var volumeMenu = new ToolStripMenuItem("Volume");
            AddVolume(volumeMenu, "25%", 0.25f);
            AddVolume(volumeMenu, "50%", 0.50f);
            AddVolume(volumeMenu, "75%", 0.75f);
            AddVolume(volumeMenu, "100%", 1.0f, isDefault: true);

            var contextMenu = new ContextMenuStrip();
            contextMenu.Items.Add(new ToolStripMenuItem("🖐 SlapMac") { Enabled = false });
            contextMenu.Items.Add(new ToolStripSeparator());
            contextMenu.Items.Add("Open SlapMac", null, (s, e) => ShowMainForm());
            contextMenu.Items.Add(_toggleItem);
            contextMenu.Items.Add(new ToolStripSeparator());
            contextMenu.Items.Add(_counterItem);
            contextMenu.Items.Add(new ToolStripSeparator());
            contextMenu.Items.Add(sensitivityMenu);
            contextMenu.Items.Add(volumeMenu);
            contextMenu.Items.Add(new ToolStripSeparator());
            contextMenu.Items.Add("⚙️ Settings...", null, OnSettings);
            contextMenu.Items.Add("Add Custom Sound...", null, OnAddSound);
            contextMenu.Items.Add(new ToolStripSeparator());
            contextMenu.Items.Add("☕ Donate / Support", null, OnDonate);
            contextMenu.Items.Add("About SlapMac", null, OnAbout);
            contextMenu.Items.Add(new ToolStripSeparator());
            contextMenu.Items.Add("Quit SlapMac", null, OnQuit);

            _trayIcon = new NotifyIcon
            {
                Icon = LoadIcon(),
                Text = "SlapMac - Tap your laptop!",
                ContextMenuStrip = contextMenu,
                Visible = true
            };

            _trayIcon.DoubleClick += (s, e) => ShowMainForm();

            _detector.Start();

            // Show main window on startup
            ShowMainForm();

            // Show startup notification
            _trayIcon.ShowBalloonTip(
                3000,
                "SlapMac is running! \ud83d\udd90",
                $"Listening for taps/slaps...\n{_audio.SoundCount} sound(s) loaded.\nRight-click tray icon for options.",
                ToolTipIcon.Info);

            // Show welcome window on first launch
            if (!System.IO.File.Exists(GetFirstLaunchFlagPath()))
            {
                ShowWelcomeWindow();
                try { System.IO.File.WriteAllText(GetFirstLaunchFlagPath(), "1"); } catch { }
            }
        }

        private Icon LoadIcon()
        {
            try
            {
                var iconPath = System.IO.Path.Combine(AppContext.BaseDirectory, "Resources", "icon.ico");
                if (System.IO.File.Exists(iconPath))
                    return new Icon(iconPath);
            }
            catch { /* fallback */ }

            return SystemIcons.Application;
        }

        private void AddSensitivity(ToolStripMenuItem parent, string label, double value, bool isDefault = false)
        {
            var item = new ToolStripMenuItem(label)
            {
                Tag = value,
                Checked = isDefault
            };
            item.Click += (s, e) =>
            {
                foreach (ToolStripMenuItem sub in parent.DropDownItems)
                    sub.Checked = false;
                item.Checked = true;
                _detector.Sensitivity = value;
            };
            parent.DropDownItems.Add(item);
        }

        private void AddVolume(ToolStripMenuItem parent, string label, float value, bool isDefault = false)
        {
            var item = new ToolStripMenuItem(label)
            {
                Tag = value,
                Checked = isDefault
            };
            item.Click += (s, e) =>
            {
                foreach (ToolStripMenuItem sub in parent.DropDownItems)
                    sub.Checked = false;
                item.Checked = true;
                _audio.Volume = value;
            };
            parent.DropDownItems.Add(item);
        }

        private void OnSlapDetected()
        {
            if (!_enabled) return;

            _slapCount++;
            _audio.PlayRandomSound();

            // Update tray counter
            if (_counterItem.Owner?.InvokeRequired == true)
            {
                _counterItem.Owner.BeginInvoke(new Action(() =>
                    _counterItem.Text = $"Slaps: {_slapCount}"));
            }
            else
            {
                _counterItem.Text = $"Slaps: {_slapCount}";
            }

            // Update main window counter
            _mainForm.OnSlapDetected();
        }

        private void ShowMainForm()
        {
            _mainForm.Show();
            _mainForm.WindowState = FormWindowState.Normal;
            _mainForm.Activate();
        }

        private void OnSettings(object? sender, EventArgs e)
        {
            var form = new SettingsForm(_detector, _audio);
            form.TopMost = true;
            form.Show();
            form.Activate();
        }

        private void OnToggle(object? sender, EventArgs e)
        {
            _enabled = !_enabled;
            _toggleItem.Checked = _enabled;
            _toggleItem.Text = _enabled ? "Enabled" : "Disabled";
            _audio.Enabled = _enabled;

            if (_enabled)
                _detector.Start();
            else
                _detector.Stop();

            _trayIcon.Text = _enabled
                ? "SlapMac - Listening..."
                : "SlapMac - Paused";
        }

        private void OnAddSound(object? sender, EventArgs e)
        {
            using var dialog = new OpenFileDialog
            {
                Title = "Choose Audio File",
                Filter = "Audio Files|*.mp3;*.wav;*.aiff;*.m4a;*.wma;*.ogg|All Files|*.*",
                Multiselect = true
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
                    _trayIcon.ShowBalloonTip(2000, "SlapMac",
                        $"Added {added} sound(s)!", ToolTipIcon.Info);
            }
        }

        private void OnDonate(object? sender, EventArgs e)
        {
            var form = new DonateForm();
            form.TopMost = true;
            form.Show();
            form.Activate();
        }

        private void OnAbout(object? sender, EventArgs e)
        {
            MessageBox.Show(
                "SlapMac v1.0.0\n\n" +
                "⚠ 18+ warning: adult-oriented sound content\n\n" +
                "Slap your laptop, hear funny sounds! 🖐💻\n\n" +
                "Detects physical taps via microphone and plays\n" +
                "amusing sound effects.\n\n" +
                "Free & Open Source\nMade with ❤️",
                "About SlapMac",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
        }

        private void OnQuit(object? sender, EventArgs e)
        {
            _detector.Dispose();
            _audio.Dispose();
            _mainForm.Dispose();
            _trayIcon.Visible = false;
            _trayIcon.Dispose();
            Application.Exit();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _detector.Dispose();
                _audio.Dispose();
                _mainForm.Dispose();
                _trayIcon.Visible = false;
                _trayIcon.Dispose();
            }
            base.Dispose(disposing);
        }

        private static string GetFirstLaunchFlagPath()
        {
            var dir = System.IO.Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "SlapMac");
            System.IO.Directory.CreateDirectory(dir);
            return System.IO.Path.Combine(dir, ".launched");
        }

        private void ShowWelcomeWindow()
        {
            var form = new Form
            {
                Text = "Welcome to SlapMac! 🖐",
                Size = new Size(460, 380),
                StartPosition = FormStartPosition.CenterScreen,
                FormBorderStyle = FormBorderStyle.FixedDialog,
                MaximizeBox = false,
                MinimizeBox = false,
                BackColor = Color.FromArgb(26, 26, 46),
                ForeColor = Color.FromArgb(224, 224, 224),
                TopMost = true,
            };

            int y = 25;

            var title = new Label
            {
                Text = "🖐 Welcome to SlapMac!",
                Font = new Font("Segoe UI", 20, FontStyle.Bold),
                ForeColor = Color.FromArgb(255, 215, 0),
                AutoSize = true,
                Location = new Point(80, y),
            };
            form.Controls.Add(title);
            y += 55;

            var desc = new Label
            {
                  Text = "⚠ 18+ warning: adult-oriented sound content\n\n" +
                      "Slap your laptop, hear funny sounds!\n\n" +
                       "✅  App is running in the system tray (bottom-right)\n" +
                       "✅  Tap or slap your laptop to trigger sounds\n" +
                       "✅  Right-click the tray icon for settings\n\n" +
                       $"🔊  {_audio.SoundCount} sound(s) loaded\n" +
                       "🎚️  Adjust sensitivity, volume & cooldown from tray menu\n" +
                       "🎵  Add your own sounds via \"Add Custom Sound...\"",
                Font = new Font("Segoe UI", 11),
                ForeColor = Color.FromArgb(200, 200, 220),
                Location = new Point(35, y),
                Size = new Size(390, 200),
            };
            form.Controls.Add(desc);
            y += 210;

            var okBtn = new Button
            {
                Text = "Got It! Let's Slap! 🖐",
                Font = new Font("Segoe UI", 12, FontStyle.Bold),
                ForeColor = Color.White,
                BackColor = Color.FromArgb(233, 69, 96),
                FlatStyle = FlatStyle.Flat,
                Size = new Size(250, 45),
                Location = new Point(95, y),
                Cursor = Cursors.Hand,
            };
            okBtn.FlatAppearance.BorderSize = 0;
            okBtn.Click += (s, e) => form.Close();
            form.Controls.Add(okBtn);
            form.AcceptButton = okBtn;

            form.Show();
            form.Activate();
        }
    }
}
