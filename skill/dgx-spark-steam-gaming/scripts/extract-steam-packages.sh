#!/bin/bash
# extract-steam-packages.sh — extract Steam client zip packages into the correct directories
# Usage: bash extract-steam-packages.sh
# Prerequisite: all zips already downloaded to ~/.local/share/Steam/package/

set -e

STEAM_ROOT="${STEAM_ROOT:-$HOME/.local/share/Steam}"
PKG="$STEAM_ROOT/package"

if [ ! -d "$PKG" ]; then
    echo "ERROR: $PKG not found — run the manifest download first"
    exit 1
fi

cd "$PKG"

# check for unzip
command -v unzip >/dev/null || { echo "Need unzip: sudo apt-get install -y unzip"; exit 1; }

echo "=== Extracting Steam packages ==="

# all *_ubuntu12.zip.* and *_all.zip.* extract to the Steam root
for f in *.zip.*; do
    [ "$f" = "*.zip.*" ] && continue
    echo "Extracting: $f"
    
    if [[ "$f" == bins_ubuntu12* ]] || [[ "$f" == bins_sdk_ubuntu12* ]] || \
       [[ "$f" == webkit_ubuntu12* ]] || [[ "$f" == *ubuntu12* ]] || \
       [[ "$f" == *all.zip.* ]]; then
        unzip -qo "$f" -d "$STEAM_ROOT/" 2>/dev/null || true
    fi
done

# mark as installed so Steam skips its self-check
echo "manual_install_via_manifest" > "$PKG/steam_client_ubuntu12.installed"

# fix execute permissions (Steam binaries + webhelper must be executable)
echo "Fixing permissions..."
find "$STEAM_ROOT/ubuntu12_32" -type f -name "steam*" -exec chmod +x {} \; 2>/dev/null
find "$STEAM_ROOT/linux64" -type f -name "steam*" -exec chmod +x {} \; 2>/dev/null
chmod +x "$STEAM_ROOT/ubuntu12_32/steam" 2>/dev/null || true
chmod +x "$STEAM_ROOT/linux64/steam" 2>/dev/null || true

echo "=== Verify extract ==="
echo "linux64/:"
ls "$STEAM_ROOT/linux64/" 2>/dev/null | head -5 || echo "  MISSING"
echo "ubuntu12_32/steam:"
ls -la "$STEAM_ROOT/ubuntu12_32/steam" 2>/dev/null || echo "  MISSING"
echo "ubuntu12_32/steamwebhelper:"
ls -la "$STEAM_ROOT/ubuntu12_32/steamwebhelper" 2>/dev/null || echo "  MISSING"
echo "linux64/steam:"
ls -la "$STEAM_ROOT/linux64/steam" 2>/dev/null || echo "  MISSING"
echo "linux64/steamclient.so:"
ls -la "$STEAM_ROOT/linux64/steamclient.so" 2>/dev/null || echo "  MISSING"

echo "=== done ==="
echo "Now launch Steam directly (bypass bwrap):"
echo "  FEX_ROOTFS=... DISPLAY=:0 XAUTHORITY=... FEXBash -c 'HOME=/home/[DGX Spark_USER] exec \$STEAM_ROOT/ubuntu12_32/steam'"
