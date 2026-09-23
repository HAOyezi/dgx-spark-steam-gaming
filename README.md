# How to Play Steam Games on a DGX Spark (NVIDIA GB10 / ASUS GX10, ARM64)

> Machine: NVIDIA DGX Spark — the GB10 chip (this unit is an ASUS GX10) — Ubuntu 24.04.4 LTS + GPU driver 580.173.02 + Ubuntu 24.04.4 LTS + GPU driver 580.173.02
> Verified games: Kerbal Space Program, CS2 (Counter-Strike 2)
> Every command in this document was actually run on the machine; measured 2026-09-22.
>
> **💡 Want your AI to set this up for you? See the [`skill/dgx-spark-steam-gaming/`](skill/dgx-spark-steam-gaming/SKILL.md) skill package** — once installed, your AI automatically applies the full measured procedure (including 13 troubleshooting reference docs) whenever "install games on DGX Spark" comes up. Installation instructions: [INSTALL.md](INSTALL.md). This repo is de-personalized — it contains no real IPs, accounts or passwords.

## 1. The principle in one line

The DGX Spark is an ARM machine; Windows/Intel games (x86) can't run on it directly. The official solution uses three translation layers:

```
Windows game (x86 instructions)
    ↓  FEX emulator        —— x86 instructions translated to ARM64 (the game-logic part)
    ↓  Proton + DXVK       —— Windows graphics API translated to Vulkan
    ↓  native GPU driver   —— the DGX Spark GPU renders directly; this part is ARM-native, near zero loss
```

Key point: graphics rendering goes through the native GPU driver, not the emulator — so AAA game frame rates come close to native. Only the game logic (CPU side) has translation loss.

## 2. Installation (one command, official path)

```bash
sudo snap install steam --stable
```

This is Canonical's official ARM64 stable Steam, with all the translation components above built in. **No manual emulator setup, no fiddling.**

First launch downloads a ~1 GB runtime — be patient for a few minutes.

Updates (including newer FEX):

```bash
sudo snap refresh steam
```

## 3. Measured game list (verified 2026-09-22)

| Game | App ID | Size | Experience | Notes |
|------|:--:|:--:|------|------|
| Kerbal Space Program | 220200 | ~7 GB | smooth | Unity engine, best compatibility under emulation |
| CS2 | 730 | 71 GB | smooth | actually installed and played on 2026-09-22 |
| Cyberpunk 2077 | 2077 | — | 45–55 FPS (1080p, ray tracing); 175+ FPS with DLSS4 | reference data |
| DOOM Eternal | — | — | smooth | reference data |

Game data directory (measured):

```
~/snap/steam/common/.local/share/Steam/steamapps/common/
├── Kerbal Space Program/
└── Counter-Strike Global Offensive/   ← CS2's install directory name
```

### KSP Chinese localization

When the Steam GUI is too unstable to switch languages, edit the game config directly:

1. Download `dictionary.cfg` from GitHub `jhihyulin/KSP-Language`
2. Replace `GameData/Squad/Localization/dictionary.cfg`
3. Set `LANGUAGE = zh-tw` in the game's `settings.cfg`
4. Restart KSP

## 4. Remote play (streaming to your desktop)

Turn the DGX Spark into a "game console" — install the client on your desktop and stream the picture with low keyboard/mouse/gamepad latency:

```
DGX Spark GPU → screen capture → Sunshine streaming service → network → Moonlight client (desktop)
```

### 1. Install the streaming service on the DGX Spark

```bash
# find the ubuntu-24.04-arm64 package on the GitHub releases page
sudo dpkg -i sunshine_*.deb
sudo systemctl enable --now sunshine
# set the streaming account password
sunshine --creds [STREAM_USER] [STREAM_PASS]
```

Measured version: Sunshine 2026.516.143833, encoding via the GPU hardware encoder (NVENC), screen capture via X11.

### 2. Install the client on the desktop

Download the Windows version from the Moonlight website or GitHub releases. After install:

- The DGX Spark is auto-discovered on the LAN (or enter its LAN IP manually)
- Enter the account/password set above
- First connection requires submitting the pairing PIN on the streaming web page (`http://[DGX Spark_IP]:47990`)
- Once connected, pick "Desktop" or a specific game

Measured ports: 47984 (video), 47989 (control), 47990 (web config).

## 5. Pitfalls & fixes (all hit in practice)

1. **Steam GUI occasionally crashes** — under emulation, Steam's web-UI component (V8 engine) is incompletely translated; crashes are normal. Just quit and re-launch — **download progress resumes**; game execution is not affected by Steam crashes.
2. **Command-line game downloads (bypass the crashing GUI):**

   ```bash
   # download the CLI tool
   curl -sqL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar zxvf -
   # key point: you MUST launch it with the snap's built-in emulator wrapper;
   # the system-level FEXBash fails with "RootFS path doesn't exist"
   /snap/steam/current/usr/bin/FEXBash ./steamcmd.sh +login <user> +app_update <appid> +quit
   ```

3. **DGX Spark has no independent outbound internet** (international bandwidth restrictions) — foreign download sources are slow or unreachable. Download games/files on the desktop first, then `scp` them to the DGX Spark. Domestic mirrors (Tsinghua/Baidu) work.
4. **Snap updates are slow** — `snap refresh` showing "no updates" is normal; the official release cadence lags standalone FEX releases.
5. **Game selection** — prefer single-player games on the Unity engine without strong anti-cheat; online games with EAC/BattlEye ban emulated environments — don't bother.

## 6. Verification record (reproducible)

```bash
# Steam installed
snap list | grep steam
# expected: steam 1.0.0.85  245  latest/beta  canonical**

# streaming service running, ports listening
systemctl is-active sunshine        # active
ss -tlnp | grep -E '47984|47989|47990'

# game list (app names + install dirs)
grep -H '"name"' ~/snap/steam/common/.local/share/Steam/steamapps/*.acf
```
