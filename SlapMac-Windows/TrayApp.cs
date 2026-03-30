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
        private readonly NotifyIcon _trayIcon;
        private readonly SlapDetector _detector;
        private readonly AudioManager _audio;
        private int _slapCount;
        private bool _enabled = true;
        private readonly ToolStripMenuItem _toggleItem;
        private readonly ToolStripMenuItem _counterItem;

        public TrayApp()
        {
            _audio = new AudioManager();
            _detector = new SlapDetector();
            _detector.SlapDetected += OnSlapDetected;

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
            contextMenu.Items.Add(_toggleItem);
            contextMenu.Items.Add(new ToolStripSeparator());
            contextMenu.Items.Add(_counterItem);
            contextMenu.Items.Add(new ToolStripSeparator());
            contextMenu.Items.Add(sensitivityMenu);
            contextMenu.Items.Add(volumeMenu);
            contextMenu.Items.Add(new ToolStripSeparator());
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

            _trayIcon.DoubleClick += (s, e) => OnToggle(s!, e);

            _detector.Start();
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

            // UI updates must be on the UI thread
            if (_counterItem.Owner?.InvokeRequired == true)
            {
                _counterItem.Owner.BeginInvoke(new Action(() =>
                    _counterItem.Text = $"Slaps: {_slapCount}"));
            }
            else
            {
                _counterItem.Text = $"Slaps: {_slapCount}";
            }
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
            form.Show();
            form.BringToFront();
        }

        private void OnAbout(object? sender, EventArgs e)
        {
            MessageBox.Show(
                "SlapMac v1.0.0\n\n" +
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
                _trayIcon.Visible = false;
                _trayIcon.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
