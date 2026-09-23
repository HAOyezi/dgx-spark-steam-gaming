# Steam steamui.so i386 Library Dependency Chain

When Steam's updater finishes extracting packages and the main `steam` binary tries to
`dlmopen steamui.so`, it fails with a cascading dependency chain of missing 32-bit
(i386) libraries. Each failure reveals the NEXT missing library.

## Dependency Order (FIFO)

```
steamui.so
  → libGL.so.1         (libglvnd, 32-bit GL dispatch)
  → libXtst.so.6       (X Test extension)
  → libXi.so.6         (X Input extension)
  → libXfixes.so.3     (X Fixes extension)
  → libXrender.so.1    (X Render extension)
  → libXcursor.so.1    (X Cursor extension)
  → libXinerama.so.1   (X Inerama extension)
  → libXrandr.so.2     (X RandR extension)
  → libXxf86vm.so.1    (X VidMode extension)
  → libXext.so.6       (X Extensions)
  → libX11.so.6        (X11 core)
  → libxcb.so.1        (XCB protocol)
  → libXau.so.6        (X Auth)
  → libXdmcp.so.6      (X DMCP)
  → libEGL.so.1        (EGL - via libglvnd)
  → libGLESv2.so.2     (GLES v2 - via libglvnd)
```

## Download Recipe

All i386 debs come from `http://archive.ubuntu.com/ubuntu/pool/main/`.

### Core GL (libglvnd)

| Package | Subdir | Filename |
|---------|--------|----------|
| libgl1 | libg/libglvnd | libgl1_1.7.0-1build2_i386.deb |
| libegl1 | libg/libglvnd | libegl1_1.7.0-1build2_i386.deb |
| libgles2 | libg/libglvnd | libgles2_1.7.0-1build2_i386.deb |

### X11 Stack (i386)

| Package | Subdir | Filename |
|---------|--------|----------|
| libxtst6 | libx/libxtst | libxtst6_1.2.5-1_i386.deb |
| libxi6 | libx/libxi | libxi6_1.8.2-2_i386.deb |
| libxfixes3 | libx/libxfixes | libxfixes3_6.0.0-1_i386.deb |
| libxrandr2 | libx/libxrandr | libxrandr2_1.5.4-1_i386.deb |
| libxinerama1 | libx/libxinerama | libxinerama1_1.1.4-3_i386.deb |
| libxcursor1 | libx/libxcursor | libxcursor1_1.2.3-1_i386.deb |
| libxrender1 | libx/libxrender | libxrender1_0.9.8-1_i386.deb |
| libxss1 | libx/libxss | libxss1_1.2.3-1_i386.deb |
| libxxf86vm1 | libx/libxxf86vm | libxxf86vm1_1.1.4-1build1_i386.deb |
| libxext6 | libx/libxext | libxext6_1.3.3-1_i386.deb |
| libx11-6 | libx/libx11 | libx11-6_1.8.13-1_i386.deb |
| libxcb1 | libx/libxcb | libxcb1_1.15-1ubuntu2_i386.deb |
| libxau6 | libx/libxau | libxau6_1.0.9-1build1_i386.deb |
| libxdmcp6 | libx/libxdmcp | libxdmcp6_1.1.2-3_i386.deb |

## Extraction Pattern

```bash
ROOTFS="/home/[DGX Spark_USER]/.local/share/fex-emu/RootFS/Ubuntu_24_04"
for deb in *.deb; do
    dpkg-deb -x "$deb" "$ROOTFS/"
done

# Then symlink into /lib/i386-linux-gnu/ where Steam expects them:
mkdir -p "$ROOTFS/lib/i386-linux-gnu"
ln -sf ../usr/lib/i386-linux-gnu/libGL.so.1 "$ROOTFS/lib/i386-linux-gnu/"
```

## Version Discovery Pattern

Versions change. To find current versions:

```bash
curl -sL "http://archive.ubuntu.com/ubuntu/pool/main/libx/$SUBDIR/" \
  | grep -oE "${PKG}_([0-9._~-]+)_i386.deb" \
  | sort -u | tail -1
```

## Notes

- `libglx1` (GLX vendor library) was tried but returned 280 bytes (404) from
  archive. Not needed because the native ARM64 GLX thunk handles it.
- All these libraries are ONLY for loading `steamui.so` (the Steam GUI). Game
  rendering uses Vulkan Thunking directly.
- Adding libxkbcommon0 (libxkbcommon) is often needed for the full CEF
  (Chromium Embedded Framework) used by Steam's web views.
