#!/bin/bash
# download-steam-zips.sh — download the standard Steam client .zip files from the desktop via VPN
# Usage: bash download-steam-zips.sh
# Requires: curl + socks5 proxy on the desktop (port [PROXY_PORT])

set -e
PROXY="socks5h://127.0.0.1:[PROXY_PORT]"
BASE="https://cdn.steamstatic.com/client"
MANIFEST="steam_client_ubuntu12"

# Download the manifest
curl -x "$PROXY" -sL --connect-timeout 10 -o "$MANIFEST" "$BASE/$MANIFEST"

# Extract the .zip filenames and download
grep -oP '"file"\s*"\K[^"]+' "$MANIFEST" | while read F; do
    [ -s "$F" ] && [ "$(stat -c%s "$F")" -gt 200 ] && { echo "SKIP: $F"; continue; }
    echo "Downloading: $F"
    curl -x "$PROXY" -sL --connect-timeout 10 --max-time 300 -o "$F" "$BASE/$F"
    [ -s "$F" ] && echo "  OK: $(stat -c%s "$F") bytes" || echo "  FAIL"
done
echo "Done: $(ls *.zip.* 2>/dev/null | wc -l) files, $(du -sh . | cut -f1)"
