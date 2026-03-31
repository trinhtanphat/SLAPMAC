#!/bin/bash
# SlapMac Linux Installer
set -e

echo "🖐 Installing SlapMac for Linux..."

if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required."
    echo "   Ubuntu/Debian: sudo apt install python3"
    echo "   Fedora: sudo dnf install python3"
    echo "   Arch: sudo pacman -S python"
    exit 1
fi

# Install system dependencies
echo "📦 Installing system dependencies..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq python3-pip python3-venv python3-tk \
        libportaudio2 portaudio19-dev
elif command -v dnf &> /dev/null; then
    sudo dnf install -y python3-pip python3-tkinter portaudio-devel
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm python-pip tk portaudio
else
    echo "⚠️  Unknown package manager. Please install manually:"
    echo "    python3-tk, portaudio19-dev (or equivalent)"
fi

# Setup install directory
INSTALL_DIR="$HOME/.local/share/slapmac"
mkdir -p "$INSTALL_DIR"

# Create virtual environment
echo "🐍 Setting up Python environment..."
python3 -m venv "$INSTALL_DIR/venv"
source "$INSTALL_DIR/venv/bin/activate"

# Install Python dependencies
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
pip install --quiet -r "$SCRIPT_DIR/requirements.txt"

# Copy app files
cp "$SCRIPT_DIR/slapmac.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/slap_detector.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/audio_manager.py" "$INSTALL_DIR/"

# Copy resources
mkdir -p "$INSTALL_DIR/resources"
if [ -d "$SCRIPT_DIR/resources" ]; then
    cp "$SCRIPT_DIR/resources/"* "$INSTALL_DIR/resources/" 2>/dev/null || true
fi

# Create launcher script
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/slapmac" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
./venv/bin/python3 slapmac.py "\$@"
EOF
chmod +x "$HOME/.local/bin/slapmac"

# Install desktop entry
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/slapmac.desktop" << EOF
[Desktop Entry]
Name=SlapMac
Comment=Slap your laptop, hear funny sounds!
Exec=$HOME/.local/bin/slapmac
Type=Application
Categories=Audio;Utility;
Keywords=slap;sound;fun;
Terminal=false
EOF

echo ""
echo "✅ SlapMac installed successfully!"
echo "   Run: slapmac"
echo "   Or find 'SlapMac' in your application menu"
