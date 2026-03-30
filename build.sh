#!/bin/bash
# =============================================================================
# SlapMac - Build & Setup Script
# =============================================================================
# This script:
# 1. Copies audio files and QR code images into the correct project locations
# 2. Builds the macOS app (if on macOS)
# 3. Packages the Chrome extension
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

echo "============================================"
echo "  🖐 SlapMac Build Script"
echo "============================================"
echo ""

# ------------------------------------------
# Step 1: Copy resources into macOS app
# ------------------------------------------
echo "📁 Setting up macOS app resources..."

MACOS_RESOURCES="$PROJECT_ROOT/SlapMac/SlapMac/Resources"
mkdir -p "$MACOS_RESOURCES"

# Copy audio files
if [ -d "$PROJECT_ROOT/audio" ]; then
    cp -v "$PROJECT_ROOT/audio/"* "$MACOS_RESOURCES/" 2>/dev/null || true
    echo "  ✅ Audio files copied to macOS app"
else
    echo "  ⚠️  No audio/ directory found"
fi

# Copy QR code images
if [ -d "$PROJECT_ROOT/qrcode" ]; then
    cp -v "$PROJECT_ROOT/qrcode/"* "$MACOS_RESOURCES/" 2>/dev/null || true
    echo "  ✅ QR code images copied to macOS app"
else
    echo "  ⚠️  No qrcode/ directory found"
fi

# ------------------------------------------
# Step 2: Copy resources into Chrome extension
# ------------------------------------------
echo ""
echo "📁 Setting up Chrome extension resources..."

EXT_AUDIO="$PROJECT_ROOT/SlapMac-Extension/audio"
EXT_IMAGES="$PROJECT_ROOT/SlapMac-Extension/images"
mkdir -p "$EXT_AUDIO"
mkdir -p "$EXT_IMAGES"

# Copy audio files
if [ -d "$PROJECT_ROOT/audio" ]; then
    cp -v "$PROJECT_ROOT/audio/"* "$EXT_AUDIO/" 2>/dev/null || true
    echo "  ✅ Audio files copied to extension"
fi

# Copy QR code images
if [ -d "$PROJECT_ROOT/qrcode" ]; then
    cp -v "$PROJECT_ROOT/qrcode/"* "$EXT_IMAGES/" 2>/dev/null || true
    echo "  ✅ QR code images copied to extension"
fi

# Generate extension icons
echo ""
echo "🎨 Generating extension icons..."
if [ -f "$PROJECT_ROOT/SlapMac-Extension/generate-icons.sh" ]; then
    chmod +x "$PROJECT_ROOT/SlapMac-Extension/generate-icons.sh"
    bash "$PROJECT_ROOT/SlapMac-Extension/generate-icons.sh"
fi

# ------------------------------------------
# Step 3: Build macOS app (if on macOS)
# ------------------------------------------
echo ""
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🔨 Building macOS app..."
    
    XCODE_PROJECT="$PROJECT_ROOT/SlapMac/SlapMac.xcodeproj"
    
    if [ -d "$XCODE_PROJECT" ]; then
        xcodebuild -project "$XCODE_PROJECT" \
            -scheme SlapMac \
            -configuration Release \
            -derivedDataPath "$PROJECT_ROOT/build" \
            clean build \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            2>&1 | tail -20
        
        BUILD_APP="$PROJECT_ROOT/build/Build/Products/Release/SlapMac.app"
        if [ -d "$BUILD_APP" ]; then
            echo "  ✅ macOS app built successfully!"
            echo "  📍 Location: $BUILD_APP"
            
            # Copy to dist
            mkdir -p "$PROJECT_ROOT/dist"
            cp -R "$BUILD_APP" "$PROJECT_ROOT/dist/"
            echo "  📦 Copied to dist/SlapMac.app"
        else
            echo "  ❌ Build failed - app not found"
        fi
    else
        echo "  ⚠️  Xcode project not found at $XCODE_PROJECT"
        echo "  💡 Open SlapMac/SlapMac.xcodeproj in Xcode to build manually"
    fi
else
    echo "⚠️  Not on macOS - skipping native app build"
    echo "💡 Transfer this project to a Mac and run:"
    echo "   cd SlapMac && xcodebuild -scheme SlapMac -configuration Release build"
fi

# ------------------------------------------
# Step 4: Package Chrome extension
# ------------------------------------------
echo ""
echo "📦 Packaging Chrome extension..."

DIST_DIR="$PROJECT_ROOT/dist"
mkdir -p "$DIST_DIR"

EXT_DIR="$PROJECT_ROOT/SlapMac-Extension"
EXT_ZIP="$DIST_DIR/SlapMac-Extension.zip"

# Create zip excluding unnecessary files
cd "$EXT_DIR"
zip -r "$EXT_ZIP" . \
    -x "*.sh" \
    -x "*.svg" \
    -x ".DS_Store" \
    -x "__MACOSX/*" \
    2>/dev/null || true

if [ -f "$EXT_ZIP" ]; then
    echo "  ✅ Extension packaged: $EXT_ZIP"
else
    echo "  ⚠️  zip command not available. Package manually."
fi

cd "$PROJECT_ROOT"

# ------------------------------------------
# Done!
# ------------------------------------------
echo ""
echo "============================================"
echo "  ✅ Build Complete!"
echo "============================================"
echo ""
echo "📱 macOS App:"
echo "   Open SlapMac/SlapMac.xcodeproj in Xcode"
echo "   Or find built app in dist/SlapMac.app"
echo ""
echo "🌐 Chrome Extension:"
echo "   1. Open chrome://extensions"
echo "   2. Enable 'Developer mode'"
echo "   3. Click 'Load unpacked'"
echo "   4. Select the SlapMac-Extension folder"
echo ""
echo "   Or install from dist/SlapMac-Extension.zip"
echo ""
