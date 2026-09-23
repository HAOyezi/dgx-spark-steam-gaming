# FEX Thunking Configuration, Explained

## Source

From the GitHub reference project [`MitchellAugustin/fex_autoinstall`](https://github.com/MitchellAugustin/fex_autoinstall) — a verified approach for auto-installing Steam + FEX on Ubuntu 24.04 ARM64.

## Config file contents

```json
{
  "Config": {
    "Disassemble": "0",
    "RootFS": "Ubuntu_24_04",
    "SMCChecks": "1",
    "TSOEnabled": "1",
    "Multiblock": "1",
    "ThunkGuestLibs": "/usr/share/fex-emu/GuestThunks",
    "ThunkHostLibs": "/usr/lib/aarch64-linux-gnu/fex-emu/HostThunks",
    "MonoHacks": "1"
  },
  "ThunksDB": {
    "fex_thunk_test": 0,
    "asound": 0,
    "drm": 0,
    "Vulkan": 1,
    "WaylandClient": 0,
    "GL": 1
  }
}
```

## Key field descriptions

| Field | Effect |
|------|------|
| `ThunksDB.Vulkan: 1` | enable Vulkan thunking — x86 app Vulkan calls go straight to the ARM64 native driver |
| `ThunksDB.GL: 1` | enable OpenGL thunking |
| `ThunksDB.drm: 0` | DRM thunk disabled (avoids conflict with pressure-vessel) |
| `ThunksDB.WaylandClient: 0` | Wayland disabled (Steam uses X11) |
| `Config.TSOEnabled: 1` | Total Store Order memory-order emulation (critical for x86→ARM) |
| `Config.Multiblock: 1` | multi-basic-block JIT optimization |

## Getting the config file

```bash
# download directly
curl -L -o ~/.fex-emu/Config.json \
  "https://raw.githubusercontent.com/MitchellAugustin/fex_autoinstall/main/fex_config_with_thunking_enabled.json"

# if using an extracted RootFS (not .sqsh), replace the RootFS field
sed -i 's/Ubuntu_24_04.sqsh/Ubuntu_24_04/g' ~/.fex-emu/Config.json
```

## Thunk file locations

- **Host thunks** (`/usr/lib/aarch64-linux-gnu/fex-emu/HostThunks/`):
  - `libvulkan-host.so` — Vulkan thunk
  - `libGL-host.so` — OpenGL thunk
  - `libEGL-host.so` — EGL thunk
  - `libdrm-host.so` — DRM thunk
  - `libcuda-host.so` — CUDA thunk
  - `libwayland-client-host.so` — Wayland thunk

- **Guest thunks** (`/usr/share/fex-emu/GuestThunks/`):
  - the corresponding x86 guest-side libraries, injected into the FEX emulated process

## Vulkan thunk, verified capabilities

Through FEX thunking, Vulkan supports the following surface extensions (verified):
- `VK_KHR_surface` ✅
- `VK_KHR_xlib_surface` ✅
- `VK_KHR_xcb_surface` ✅
- `VK_KHR_wayland_surface` ✅
- `VK_KHR_swapchain` ✅
- `vkCreateXlibSurfaceKHR` ✅
- `vkCreateXcbSurfaceKHR` ✅

Verification command:
```bash
FEXBash -c "DISPLAY=:0 vulkaninfo --summary" | grep -E "VK_KHR_surface|VK_KHR_xlib"
```

## Steam pressure-vessel isolation problem

Even with correct thunking config, Steam may error with:
```
Vulkan missing requested extension 'VK_KHR_surface'
Vulkan missing requested extension 'VK_KHR_xlib_surface'
BInit - Unable to initialize Vulkan!
```

**Root cause:** Steam's `steamwebhelper` runs inside the `pressure-vessel` (srt-bwrap) container, while FEX's Vulkan thunks live outside the container. The thunks themselves work fine (`vulkaninfo` under FEX enumerates all extensions), but the pressure-vessel container isolation layer blocks the extensions from penetrating through.

**Solution:** see `fex_autoinstall`'s `patch_steam_for_arm64.patch` — insert ARM64 detection into `bin_steam.sh` so the Steam main binary launches directly through `FEXBash $0 "$@"`, keeping the whole Steam chain inside FEX and thereby bypassing pressure-vessel's container isolation.

## Known unknown config options (safe to ignore)

FEX logs `I Unknown ...` messages for the following unknown options (no functional impact):
- `ABILocalFlags`
- `ParanoidTSO`
- `X87StrictReducedPrecision`
