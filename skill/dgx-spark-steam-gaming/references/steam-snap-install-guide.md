# Canonical Steam Snap for ARM64 — installation & measured results

## Overview

Canonical, together with the NVIDIA DGX team (led by Mitchell Augustin), packaged FEX-Emu + Proton + DXVK into the official Steam Snap; the stable channel has been available since June 2026.

**One command replaces all manual FEX configuration.**

## Install

```bash
sudo snap install steam --stable
```

## Components integrated automatically

| Component | Role |
|------|------|
| FEX-Emu | x86_64 → ARM64 CPU instruction translation |
| Proton (Wine) | Windows API → Linux |
| DXVK | DirectX 9/10/11 → Vulkan |
| VKD3D | DirectX 12 → Vulkan |
| NVIDIA userspace libs | libGLX_nvidia, libnvidia-glcore, Vulkan ICD, DLSS .dll |
| FEX Thunking | Vulkan/GL calls go straight to the native GPU driver |
| bwrap sandbox adaptation | pressure-vessel compatibility |

## Measured performance (DGX Spark, Ubuntu 24.04 ARM64)

Sources: Tom's Hardware, WCCFTech, Reddit r/nvidia, Level1Techs forums

| Game | Settings | FPS | Source |
|------|------|:--:|------|
| Cyberpunk 2077 | 1080p Medium, RT on | 45-55 | Tom's Hardware |
| Cyberpunk 2077 | 1440p, DLSS4 MFG, PT | 175+ | WCCFTech |
| DOOM Eternal | Vulkan | smooth | Level1Techs |
| Dota 2 | default | smooth | Canonical testing |
| CS2 | default | smooth | Canonical testing |
| PS3 emulation (RPCS3) | - | playable | HotHardware |

## Why GPU rendering runs near full speed

```
Game (DirectX) → DXVK/VKD3D → Vulkan API
                                 ↓
                     DGX Spark Blackwell GPU (native ARM64 driver)
                                 ↓
                     Vulkan shader = native ARM64 execution ✅
```

- **DXVK/VKD3D translate the Windows graphics API to Vulkan** — Vulkan is cross-platform; the shader intermediate representation (SPIR-V) runs directly on the ARM64 driver
- **FEX "Thunking"** — Vulkan/GL API calls go straight to the native driver, no CPU translation
- **The only bottleneck is game logic** — x86 CPU code goes through FEX JIT translation; the DGX Spark's Cortex-X925 is strong enough

## Games that don't fit

- Online games with EAC/BattlEye anti-cheat (they detect emulated environments)
- Some domestic Chinese online games
- What works well: single-player 3A, older PC games, emulation

## Post-install GPU streaming validation

You can validate the full pipeline without downloading any game:

```bash
# launch a preinstalled GNOME game
DISPLAY=:0 gnome-mahjongg &

# or the PyOpenGL 3D rotating cube (pygame + PyOpenGL preinstalled)
DISPLAY=:0 python3 3d_test_game.py &
```

Then connect Moonlight to the DGX Spark → Desktop and the picture appears.

## References

- Snap Store: https://snapcraft.io/steam
- GitHub: https://github.com/canonical/steam-snap
- OMG Ubuntu coverage: https://www.omgubuntu.co.uk/2026/06/steam-arm64-snap-stable
- NVIDIA developer forum: https://forums.developer.nvidia.com/t/beta-of-steam-snap-for-arm64/357240
