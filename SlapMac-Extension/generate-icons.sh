#!/bin/bash
# Generate PNG icons from SVG for Chrome Extension
# Requires: ImageMagick or rsvg-convert

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ICON_DIR="$SCRIPT_DIR/icons"
SVG_FILE="$ICON_DIR/icon.svg"

if command -v rsvg-convert &> /dev/null; then
    rsvg-convert -w 16 -h 16 "$SVG_FILE" -o "$ICON_DIR/icon16.png"
    rsvg-convert -w 48 -h 48 "$SVG_FILE" -o "$ICON_DIR/icon48.png"
    rsvg-convert -w 128 -h 128 "$SVG_FILE" -o "$ICON_DIR/icon128.png"
    echo "Icons generated with rsvg-convert"
elif command -v magick &> /dev/null; then
    magick "$SVG_FILE" -resize 16x16 "$ICON_DIR/icon16.png"
    magick "$SVG_FILE" -resize 48x48 "$ICON_DIR/icon48.png"
    magick "$SVG_FILE" -resize 128x128 "$ICON_DIR/icon128.png"
    echo "Icons generated with ImageMagick"
elif command -v sips &> /dev/null; then
    # macOS built-in tool - convert SVG isn't supported but we can create simple PNGs
    echo "Please install ImageMagick (brew install imagemagick) or use the SVG directly"
    echo "For now, creating placeholder PNGs..."
    # Create a simple colored square PNG as placeholder
    python3 -c "
import struct, zlib

def create_png(size, filename):
    # Simple red gradient PNG
    width = height = size
    raw = b''
    for y in range(height):
        raw += b'\x00'  # filter byte
        for x in range(width):
            r = int(233 + (255-233) * x/width)
            g = int(69 + (107-69) * x/width)
            b = int(96 + (107-96) * x/width)
            raw += bytes([r, g, b, 255])
    
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    
    header = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    
    with open(filename, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk(b'IHDR', header))
        f.write(chunk(b'IDAT', zlib.compress(raw)))
        f.write(chunk(b'IEND', b''))

create_png(16, '$ICON_DIR/icon16.png')
create_png(48, '$ICON_DIR/icon48.png')
create_png(128, '$ICON_DIR/icon128.png')
print('Placeholder icons created')
"
else
    echo "No image conversion tool found. Please install ImageMagick:"
    echo "  brew install imagemagick"
    echo "  or: apt-get install imagemagick"
fi
