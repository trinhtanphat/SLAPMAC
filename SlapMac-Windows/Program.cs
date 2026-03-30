using System;
using System.Windows.Forms;

namespace SlapMac
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // Ensure single instance
            using var mutex = new System.Threading.Mutex(true, "SlapMac-SingleInstance", out bool isNew);
            if (!isNew)
            {
                MessageBox.Show("SlapMac is already running!", "SlapMac",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            Application.Run(new TrayApp());
        }
    }
}
