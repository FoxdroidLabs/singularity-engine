#!/bin/sh

set -e

APP_NAME="singularity-engine"
BINARY="singularity"
ICON="singularity.png"

echo ""
echo "  SINGULARITY ENGINE"
echo "  ------------------"
echo "  Installer v0.1"
echo ""
echo "  Where do you want to install?"
echo ""
echo "  [1] /opt/singularity-engine  (system, requires sudo)"
echo "  [2] ~/.local/singularity-engine  (user)"
echo "  [3] Custom path"
echo ""
read -rp "  Choice [1-3]: " choice

case "$choice" in
    1) PREFIX="/opt/singularity-engine" ;;
    2) PREFIX="$HOME/.local/singularity-engine" ;;
    3)
        read -rp "  Enter path: " custom
        PREFIX="$(realpath "$custom")"
        ;;
    *)
        echo "Invalid choice."
        exit 1
        ;;
esac

echo ""
echo "  Installing to $PREFIX..."

mkdir -p "$PREFIX/bin"
mkdir -p "$PREFIX/assets"

cp "zig-out/bin/$BINARY" "$PREFIX/bin/$BINARY"
cp "assets/$ICON" "$PREFIX/assets/$ICON"
chmod +x "$PREFIX/bin/$BINARY"

DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"
mkdir -p "$HOME/.local/share/applications"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Singularity Engine
Exec=$PREFIX/bin/$BINARY
Icon=$PREFIX/assets/$ICON
Type=Application
Categories=Development;Game;
Terminal=false
EOF

update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true

echo ""
echo "  Done."
echo "  Installed to : $PREFIX"
echo "  Desktop entry: $DESKTOP_FILE"
echo ""
