# Steam steamui.so i386 library dependency chain

`steamui.so` is Steam's GUI engine. When loaded under FEX, missing libraries are reported one by one as `dlmopen ... failed: libXXX.so.Y: cannot open shared object file`.

## Dependency order (layer-by-layer push — full verification chain 2026-07-28)

Each time you fix one library, the next one reports missing. **You must knock them down one at a time until steamui.so dlmopen succeeds.**

```
steamui.so
 → libGL.so.1       (GL dispatch — libgl1 i386)
 → libXtst.so.6     (X11 Test extension)
 → libXi.so.6       (X11 Input extension)
 → libXfixes.so.3   (X11 Fixes extension)
 → libXrandr.so.2   (X11 RandR)
 → libXinerama.so.1 (X11 Xinerama)
 → libXcursor.so.1  (X11 Cursor)
 → libXrender.so.1  (X11 Render)
 → libXss.so.1      (X11 Screen Saver)
 → libXext.so.6     (X11 Extensions)
 → libX11.so.6      (X11 core)
 → libxcb.so.1      (X11 protocol)
 → libgobject-2.0.so.0 (GLib object system)
 → libvpx.so.6      (VP8/VP9 video codec — **package name is libvpx9**)
 → libdrm.so.2      (DRI/GPU — **must be a real i386 deb, cannot symlink to x86_64**)
 → GLIBCXX_3.4.29   (libstdc++ version — fixing the symlink suffices)
 → libgbm.so.1      (Mesa GBM)
 → libwayland-client.so.0 (Wayland)
 → libwayland-server.so.0
```

**Confirmed working launcher for Steam CLI:** the official Launcher (`apt install steam-launcher.deb` + `patch_steam_for_arm64.patch`) is the verified take-off method.

## Key pitfalls

### libvpx: package name ≠ so name
- Steam looks for `libvpx.so.6`
- The Ubuntu 24.04 package is `libvpx9` (not libvpx6/libvpx7)
- Correct deb: `libvpx9_1.15.0-2.1ubuntu0.1_i386.deb`
- After download you must: `ln -sf libvpx.so.9 libvpx.so.6`

### libdrm2 i386 download trap
The `libdrm2` deb lives in the Ubuntu archive directory `pool/main/libd/libdrm/` (NOT `d/drm/` or `libd/libdrm2/`).
archive.ubuntu.com returns zero bytes or 404 for some URLs — **prefer the Tsinghua mirror**:

```bash
curl -L -o libdrm2_i386.deb \
  "https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/main/libd/libdrm/libdrm2_2.4.120-2build1_i386.deb"
# verify: file libdrm2_i386.deb → Debian binary package (must NOT be HTML)
# normal size: ~44KB (only 280 bytes means a 404 HTML page)
```

**Do NOT symlink the x86_64 libdrm** — `dlmopen` reports `wrong ELF class: ELFCLASS64`.

### libstdc++ symlink trap
The RootFS ships two versions:
- `.so.6.0.21` — GLIBCXX up to 3.4.21 (libGL needs ≥3.4.29)
- `.so.6.0.33` — GLIBCXX 3.4.29–3.4.33 + Tunables

**The default link points to the old 6.0.21** — it must be fixed:

```bash
unlink libstdc++.so.6
ln -sf libstdc++.so.6.0.33 libstdc++.so.6
# verify: strings libstdc++.so.6.0.33 | grep GLIBCXX | tail -5
```

### Steam runtime's bundled GTK library paths
The Steam runtime's `lib/i386-linux-gnu/` (NOT `usr/lib/`) contains `libglib-2.0.so.0`, `libgobject-2.0.so.0` and other GTK libs. Copy them into the RootFS to cut manual downloads:

```bash
cp -a $RT/lib/i386-linux-gnu/*.so* $ROOTFS/usr/lib/i386-linux-gnu/
cp -a $RT/usr/lib/i386-linux-gnu/*.so* $ROOTFS/usr/lib/i386-linux-gnu/
# 0 → 483+ i386 libs
```

### dlmopen vs LD_LIBRARY_PATH
Steam loads `steamui.so` via `dlmopen` (not standard `dlopen`).
This means the `LD_LIBRARY_PATH` env var is **not inherited** into the dlmopen namespace.
Libraries must live in the RootFS's standard system paths (`/usr/lib/i386-linux-gnu/`).

## Complete download table

| Missing so | Package | Correct Ubuntu 24.04 version | Notes |
|---------|------|----------------------|------|
| libGL.so.1 | libgl1 | 1.7.0-1build2_i386.deb | libglvnd |
| libEGL.so.1 | libegl1 | 1.7.0-1build2_i386.deb | |
| libGLESv2.so.2 | libgles2 | 1.7.0-1build2_i386.deb | |
| libXtst.so.6 | libxtst6 | 1.2.5-1_i386.deb | |
| libXi.so.6 | libxi6 | 1.8.2-2_i386.deb | |
| libXfixes.so.3 | libxfixes3 | 6.0.0-1_i386.deb | |
| libXrandr.so.2 | libxrandr2 | 1.5.4-1_i386.deb | |
| libXinerama.so.1 | libxinerama1 | 1.1.4-3_i386.deb | |
| libXcursor.so.1 | libxcursor1 | 1.2.3-1_i386.deb | |
| libXrender.so.1 | libxrender1 | 0.9.8-1_i386.deb | |
| libXss.so.1 | libxss1 | 1.2.3-1_i386.deb | |
| libXext.so.6 | libxext6 | 1.3.3-1_i386.deb | |
| libX11.so.6 | libx11-6 | 1.8.13-1_i386.deb | |
| libxcb.so.1 | libxcb1 | 1.15-1ubuntu2_i386.deb | |
| libdrm.so.2 | libdrm2 | 2.4.120-2build1_i386.deb | ⚠️ must be real i386, 44KB |
| libgbm.so.1 | libgbm1 | 24.0.5-1ubuntu1_i386.deb | |
| libwayland-client.so.0 | libwayland-client0 | 1.22.0-2.1build1_i386.deb | |
| libwayland-server.so.0 | libwayland-server0 | 1.22.0-2.1build1_i386.deb | |
| libvpx.so.6 | **libvpx9** | 1.15.0-2.1ubuntu0.1_i386.deb | → `ln -sf libvpx.so.9 libvpx.so.6` |
| GLIBCXX_3.4.29 | — | fix symlink: 6.0.33 | `ln -sf libstdc++.so.6.0.33 libstdc++.so.6` |
