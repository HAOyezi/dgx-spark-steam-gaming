# Steam HTTP Error 0 — Full Proxy Debug Log

**Date:** 2026-07-27
**Environment:** GB10 (DGX Spark) Ubuntu 24.04 aarch64, FEX-Emu armv8.4 (PPA)
**Steam binary:** ubuntu12_32/steam (ELF 32-bit x86)

## Error Signature

Every run through `ubuntu12_32/steam` (bypassing steam.sh bwrap) produces:

```
[2026-07-27 15:42:01] Downloading manifest: https://client-update.steamstatic.com/steam_client_ubuntu12
[2026-07-27 15:42:01] Manifest download: finished
[2026-07-27 15:42:01] Download failed: http error 0 (client-update.steamstatic.com/steam_client_ubuntu12)
[2026-07-27 15:42:01] DownloadManifest - exhausted list of download hosts
[2026-07-27 15:42:01] Error: Download failed: http error 0
[2026-07-27 15:42:01] Fatal error: Steam needs to be online to update.
```

"http error 0" is not a real HTTP status code. It means the HTTP library cannot even initialize — the request never leaves the process. This happens consistently, instantly, with zero network activity.

## Proxy Approaches Attempted (All Failed)

### 1. http_proxy env var
```bash
FEXBash -c "export http_proxy=socks5://127.0.0.1:[TUNNEL_PORT] https_proxy=socks5://127.0.0.1:[TUNNEL_PORT]; exec ./steam"
```
**Result:** Same `http error 0`. Steam's internal HTTP library (Valve-custom, not libcurl) ignores proxy env vars.

### 2. privoxy (socks5→HTTP bridge)
```bash
# /etc/privoxy/config:
forward-socks5 / 127.0.0.1:[TUNNEL_PORT] .
listen-address 127.0.0.1:8118

# Test: curl -x http://127.0.0.1:8118 ... → 200 OK
# Run: http_proxy=http://127.0.0.1:8118 FEXBash -c "exec ./steam"
```
**Result:** Same `http error 0`. Steam doesn't use http_proxy for its HTTP calls.

### 3. proxychains4 (LD_PRELOAD connect() interception)
```bash
proxychains4 FEXBash -c "DISPLAY=:0 exec ./steam"
# /etc/proxychains4.conf: strict_chain, socks5 127.0.0.1 [TUNNEL_PORT]
```
**Result:** Same `http error 0`. proxychains intercepts connect() syscalls, but Steam's HTTP stack in FEX can't even reach the connect() stage.

### 4. tsocks (LD_PRELOAD connect() interception)
```bash
tsocks FEXBash -c "DISPLAY=:0 exec ./steam"
```
**Result:** Same `http error 0`. Confirms the problem is inside FEX's x86 HTTP library, not at the syscall level.

## Diagnostic Notes

- `curl` through the same proxy tunnel works (200 OK to steamstatic.com)
- `steamcmd` has exactly the same problem (same HTTP library codebase)
- The bwrap sandbox (`srt-bwrap --bind / / true`) hangs separately in FEX — this is a different issue from the HTTP error
- FEX's Vulkan Thunking (graphics) works perfectly — only the HTTP/network stack is broken

## Root Cause Hypothesis

Steam uses Valve's custom Tier0 HTTP library which likely uses x86-specific CPU features (SSE2, AES-NI) or inline assembly for TLS/SSL that FEX doesn't emulate correctly. The "error 0" suggests the library returns before any actual network I/O occurs — internal initialization failure in the emulated x86 context.

## Known-Good Workaround

The only confirmed workaround is to skip the self-update entirely by pre-populating the Steam client files from a working x86 Linux installation:
1. Install Steam on Dell WSL Ubuntu or another x86 machine
2. Let it fully update
3. `scp -r` the `linux64/`, `package/`, and `clientui/` directories from `~/.local/share/Steam/` to GB10
