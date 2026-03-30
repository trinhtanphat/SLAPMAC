using System;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

namespace SlapMac
{
    /// <summary>
    /// Donation form showing QR codes for MoMo and Techcombank.
    /// </summary>
    sealed class DonateForm : Form
    {
        public DonateForm()
        {
            Text = "Support SlapMac ☕";
            Size = new Size(480, 700);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            BackColor = Color.FromArgb(26, 26, 46);
            ForeColor = Color.FromArgb(224, 224, 224);

            var panel = new Panel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true,
                Padding = new Padding(30)
            };
            Controls.Add(panel);

            int y = 20;

            // Title
            var title = new Label
            {
                Text = "☕ Support SlapMac",
                Font = new Font("Segoe UI", 18, FontStyle.Bold),
                ForeColor = Color.FromArgb(255, 215, 0),
                AutoSize = true,
                Location = new Point(100, y),
            };
            panel.Controls.Add(title);
            y += 50;

            // Subtitle
            var subtitle = new Label
            {
                Text = "SlapMac is free and always will be!\nIf you enjoy it, consider supporting 😊",
                Font = new Font("Segoe UI", 10),
                ForeColor = Color.FromArgb(136, 153, 170),
                AutoSize = true,
                Location = new Point(80, y),
                TextAlign = ContentAlignment.MiddleCenter,
            };
            panel.Controls.Add(subtitle);
            y += 60;

            // MoMo
            var momoLabel = new Label
            {
                Text = "MoMo",
                Font = new Font("Segoe UI", 14, FontStyle.Bold),
                ForeColor = Color.FromArgb(214, 51, 132),
                AutoSize = true,
                Location = new Point(185, y),
            };
            panel.Controls.Add(momoLabel);
            y += 35;

            var momoImage = LoadQRImage("momo");
            if (momoImage != null)
            {
                var momoPic = new PictureBox
                {
                    Image = momoImage,
                    SizeMode = PictureBoxSizeMode.Zoom,
                    Size = new Size(200, 200),
                    Location = new Point(115, y),
                    BackColor = Color.White,
                    Padding = new Padding(5),
                };
                panel.Controls.Add(momoPic);
            }
            y += 220;

            // Techcombank
            var techLabel = new Label
            {
                Text = "Techcombank",
                Font = new Font("Segoe UI", 14, FontStyle.Bold),
                ForeColor = Color.FromArgb(13, 110, 253),
                AutoSize = true,
                Location = new Point(150, y),
            };
            panel.Controls.Add(techLabel);
            y += 35;

            var techImage = LoadQRImage("techcombank");
            if (techImage != null)
            {
                var techPic = new PictureBox
                {
                    Image = techImage,
                    SizeMode = PictureBoxSizeMode.Zoom,
                    Size = new Size(200, 200),
                    Location = new Point(115, y),
                    BackColor = Color.White,
                    Padding = new Padding(5),
                };
                panel.Controls.Add(techPic);
            }
            y += 230;

            // Thanks
            var thanks = new Label
            {
                Text = "Thank you for your support! 🙏",
                Font = new Font("Segoe UI", 11),
                ForeColor = Color.FromArgb(255, 215, 0),
                AutoSize = true,
                Location = new Point(110, y),
            };
            panel.Controls.Add(thanks);
        }

        private static Image? LoadQRImage(string name)
        {
            var extensions = new[] { "jpeg", "jpg", "png" };
            foreach (var ext in extensions)
            {
                var path = Path.Combine(AppContext.BaseDirectory, "Resources", $"{name}.{ext}");
                if (File.Exists(path))
                {
                    // Load without locking the file
                    using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
                    return Image.FromStream(stream);
                }
            }
            return null;
        }
    }
}
