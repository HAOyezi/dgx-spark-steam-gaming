# Desktop proxy downloads + SCP to the DGX Spark

## Pattern

The DGX Spark's direct connection may be slow or time out on `archive.ubuntu.com`. Standard flow:

```bash
# 1. download on the desktop side via the VPN
curl -x socks5h://127.0.0.1:[PROXY_PORT] -L -o /path/to/file.deb \
  "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6_2.43-2ubuntu2_i386.deb"

# 2. scp to the DGX Spark
scp /path/to/file.deb [DGX Spark_USER]@[DGX Spark_IP]:/tmp/

# 3. extract into the RootFS on the DGX Spark (when using a deb)
ssh [DGX Spark_USER]@[DGX Spark_IP] '
  ROOTFS=$HOME/.local/share/fex-emu/RootFS/Ubuntu_24_04
  dpkg-deb -x /tmp/file.deb $ROOTFS/
'
```

## Finding the correct Ubuntu Archive package name

Version numbers in URLs change frequently. First curl the directory listing to find the actual filename:

```bash
# find the latest libc6 i386 version
curl -sL "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/" | \
  grep -oE "libc6_[^\"]*i386.deb" | tail -5
```

## Sunshine ARM64 deb

```bash
# list all assets of the latest release
curl -x socks5h://127.0.0.1:[PROXY_PORT] -sL \
  "https://api.github.com/repos/LizardByte/Sunshine/releases/latest" | \
  python -c "import sys,json; d=json.load(sys.stdin);
    [print(a['browser_download_url']) for a in d['assets']
     if a['name']=='sunshine-ubuntu-24.04-arm64.deb']"
```

## Moonlight for Windows

```bash
# version numbers change; query the API
curl -x socks5h://127.0.0.1:[PROXY_PORT] -sL \
  "https://api.github.com/repos/moonlight-stream/moonlight-qt/releases/latest" | \
  python -c "import sys,json; d=json.load(sys.stdin);
    [print(a['browser_download_url']) for a in d['assets']
     if a['name'].endswith('.exe') and 'x86' not in a['name']]"
```
