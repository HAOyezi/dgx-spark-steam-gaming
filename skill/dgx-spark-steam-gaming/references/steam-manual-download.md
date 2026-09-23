# Steam client manifest manual download — bypassing the FEX HTTP library bug

When Steam self-update is completely unusable under FEX (`http error 0`) and the desktop has no WSL Ubuntu installed, **fetching the manifest JSON straight from the Valve CDN and downloading all the zip packages yourself** is the fastest viable path.

## Principle

The Steam bootstrap binary downloads a JSON manifest from `https://cdn.steamstatic.com/client/steam_client_ubuntu12` (the **CDN URL**). Each component in the manifest has **two file sets**:
- `"file"` — standard `.zip.<sha1hash>` archives
- `"zipvz"` — Valve's proprietary VZ compression, `.zip.vz.<sha1hash>_<size>` (smaller; this is what Steam actually uses)

**Both sets must be downloaded** into `~/.local/share/Steam/package/`, otherwise Steam reports `missing or incorrect size` at startup.

Bypass the Steam binary entirely: **download from the desktop via the VPN + scp to the DGX Spark** to achieve the equivalent of the "first update."

## Steps

### ⚡ Recommended: desktop download + SCP (more stable)

The DGX Spark-side SSH tunnel tends to drop under heavy download. **Best approach:** download all files on the desktop through the VPN proxy, pack them, and SCP to the DGX Spark in one shot.

#### 1. Fetch the manifest on the desktop

```bash
curl -x socks5h://127.0.0.1:[PROXY_PORT] -sL -o steam_client_ubuntu12 \
  "https://cdn.steamstatic.com/client/steam_client_ubuntu12"
```

#### 2. Extract and download all file + zipvz entries (two batch downloads)

```bash
# standard zips (.zip.<hash>)
grep -oP '"file"\s*"\K[^"]+' steam_client_ubuntu12 | while read F; do
  curl -x socks5h://127.0.0.1:[PROXY_PORT] -L -o "$F" \
    "https://cdn.steamstatic.com/client/$F"
done

# VZ-compressed (.zip.vz.<hash>_<size>)
grep -oP '"zipvz"\s*"\K[^"]+' steam_client_ubuntu12 | while read F; do
  curl -x socks5h://127.0.0.1:[PROXY_PORT] -L -o "$F" \
    "https://cdn.steamstatic.com/client/$F"
done
```

Total ≈ 710 MB (standard zips ~350MB + VZ ~360MB; 28 file entries + 22 zipvz entries).

#### 3. Pack + SCP to the DGX Spark

```bash
tar -czf steam_pkg.tar.gz *.zip.* steam_client_ubuntu12
scp steam_pkg.tar.gz [DGX Spark_USER]@[DGX Spark_IP]:/tmp/
ssh [DGX Spark_USER]@[DGX Spark_IP] "
  mkdir -p ~/.local/share/Steam/package
  cd ~/.local/share/Steam/package
  tar xzf /tmp/steam_pkg.tar.gz
"
```

#### 4. Extract and set permissions (see `scripts/extract-steam-packages.sh`)

```bash
# extract all zips into the Steam root
cd ~/.local/share/Steam/package
for f in *.zip.*; do unzip -qo "$f" -d ~/.local/share/Steam/; done
# key: fix execute permissions
chmod +x ~/.local/share/Steam/ubuntu12_32/steam
chmod +x ~/.local/share/Steam/linux64/steam 2>/dev/null
```

### 🔧 Fallback: download on the DGX Spark through the SSH tunnel (unstable but less work)

If the tunnel is stable, you can also download directly on the DGX Spark.

### 5. Extract into the correct directories

Different zips extract to different locations. The full extraction script is `scripts/extract-steam-packages.sh`.

Key mappings:
- `bins_ubuntu12.zip.*` → extract into `~/.local/share/Steam/` (contains `ubuntu12_32/steam`, `linux64/steam`)
- `bins_sdk_ubuntu12.zip.*` → same (SDK binaries)
- `webkit_ubuntu12.zip.*` → same (CEF, largest at ~120MB)
- `*_all.zip.*` → same (resources/UI/locales)
- `steam_steamrt_ubuntu12.zip.*` → same

### 6. Write the install manifest marker so Steam skips verification

```bash
echo "manual_install" > $DEST/steam_client_ubuntu12.installed
```

### 7. Launch Steam directly (bypass steam.sh / bwrap)

```bash
export FEX_ROOTFS=$HOME/.local/share/fex-emu/RootFS/Ubuntu_24_04
export DISPLAY=:0
export XAUTHORITY=/run/user/1000/gdm/Xauthority
FEXBash -c "HOME=/home/[DGX Spark_USER] DISPLAY=:0 \
    exec /home/[DGX Spark_USER]/.local/share/Steam/ubuntu12_32/steam"
```

## Key differences vs the WSL-scp approach

| Dimension | manifest manual download | WSL scp |
|------|------------------|---------|
| Desktop-side dependency | curl + VPN only | WSL Ubuntu + Steam |
| Download volume | 710 MB (all components) | only what WSL has downloaded |
| Steam login/cache | user must log in again | can scp `~/.steam/` along with it |
| Debugging effort | zip extract locations need trial and error | copy whole directories directly |

**Recommendation:** when the desktop has WSL, prefer the WSL-scp method (less work, and login state comes along for free). Without WSL, use the manifest manual download.
