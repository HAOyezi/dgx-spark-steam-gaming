# Steam client: full file download & deployment

## Background

Steam's built-in HTTP update library is completely unusable under FEX-Emu (reports `http error 0`). The only workaround is to manually download all client files from the Valve CDN on a machine with internet (the desktop) via a VPN proxy, then `scp` them to the GB10 for deployment.

## The manifest file

The Steam client install manifest lives at `~/.local/share/Steam/package/steam_client_ubuntu12`. It's a text file listing every required component and its hash.

Each component comes in two compression formats (**both are required**):

| Format | Field name | Filename example | Size |
|------|--------|-----------|------|
| Standard zip | `file` | `bins_ubuntu12.zip.ffd18cf93f21d127191f940d87d2c847e10ccee4` | ~68 MB |
| Valve VZ | `zipvz` | `bins_ubuntu12.zip.vz.35915cbfbae1288078e9382eafaefb5c13c067f4_40668729` | ~41 MB |

**Both file sets must be downloaded** into the same directory (`~/.local/share/Steam/package/`), otherwise the Steam updater reports `Package file ... missing or incorrect size`.

## CDN base URL

**Correct URL:** `https://cdn.steamstatic.com/client/`

❌ The `https://client-update.steamstatic.com/steam_client_ubuntu12/` paths all 404.

## Download flow

### Step 1: extract the manifest

```bash
# copy the manifest to the working dir on the GB10
# or fetch it straight from the Valve CDN: curl "https://cdn.steamstatic.com/client/steam_client_ubuntu12"
```

### Step 2: extract the file list from the manifest on the desktop and download

```python
import re, subprocess, os

# read the manifest
with open("steam_client_ubuntu12") as f:
    content = f.read()

# extract every file (zip and zipvz)
files = re.findall(r'"(?:file|zipvz)"\s*"([^"]+)"', content)
base = "https://cdn.steamstatic.com/client"
dest = r"C:\Users\[WINDOWS_USER]\Desktop\steam_pkg"
os.makedirs(dest, exist_ok=True)

for i, f in enumerate(files, 1):
    out = os.path.join(dest, f)
    if os.path.exists(out) and os.path.getsize(out) > 200:
        continue  # skip already downloaded
    subprocess.run(["curl", "-x", "socks5h://127.0.0.1:[PROXY_PORT]",
        "-sL", "--connect-timeout", "10", "--max-time", "600",
        "-o", out, f"{base}/{f}"])
    print(f"[{i}/{len(files)}] {f}: {os.path.getsize(out)} bytes")
```

### Step 3: pack

```bash
# ⚠️ tar globs are unreliable in git-bash — use a file list
cd /c/Users/[WINDOWS_USER]/Desktop/steam_pkg
ls | grep "\.vz\." > /tmp/vz_files.txt
tar -czf /c/Users/[WINDOWS_USER]/Desktop/steam_vz.tar.gz -T /tmp/vz_files.txt

# standard zip files
ls | grep "\.zip\." | grep -v "\.vz\." > /tmp/zip_files.txt
tar -czf /c/Users/[WINDOWS_USER]/Desktop/steam_zips.tar.gz -T /tmp/zip_files.txt
```

### Step 4: SCP to the GB10

```bash
# ⚠️ scp uses /c/Users/... form (MSYS2), not C:\Users\...
scp /c/Users/[WINDOWS_USER]/Desktop/steam_vz.tar.gz [GB10_USER]@[GB10_IP]:/tmp/
scp /c/Users/[WINDOWS_USER]/Desktop/steam_zips.tar.gz [GB10_USER]@[GB10_IP]:/tmp/
```

### Step 5: unpack on the GB10

```bash
cd /home/[GB10_USER]/.local/share/Steam/package
tar xzf /tmp/steam_vz.tar.gz    # VZ files
tar xzf /tmp/steam_zips.tar.gz  # standard zip files
```

### Step 6: extract the zips into the Steam root

```bash
# these zips are not standalone packages — they're Steam client components
# they must be extracted into ~/.local/share/Steam/
cd /home/[GB10_USER]/.local/share/Steam/package
for f in *.zip.*; do
    case $(file -b "$f") in
        "Zip archive"*) unzip -o "$f" -d /home/[GB10_USER]/.local/share/Steam/;;
        *) echo "Skip $f (not a zip archive)";;
    esac
done

# ⚠️ fix execute permissions (files extracted via dpkg-deb/unzip have no x bit)
chmod +x /home/[GB10_USER]/.local/share/Steam/ubuntu12_32/steam
find /home/[GB10_USER]/.local/share/Steam -name 'steamwebhelper' -exec chmod +x {} \;
```

## Verification

```bash
file /home/[GB10_USER]/.local/share/Steam/ubuntu12_32/steam
# → ELF 32-bit LSB pie executable, Intel 80386
ls -la /home/[GB10_USER]/.local/share/Steam/linux64/steamclient.so
du -sh /home/[GB10_USER]/.local/share/Steam/package
# → about 1.1 GB
```

## Key pitfalls

1. **Both file sets required:** only downloading `.zip` without `.zip.vz` → Steam reports "missing or incorrect size" and exits
2. **Correct CDN URL prefix:** `cdn.steamstatic.com/client/` — NOT `client-update.steamstatic.com`
3. **tar globs:** in git-bash, `tar -czf *.vz` produces a 45-byte empty archive → use `ls | grep | tar -T`
4. **Execute permissions:** `chmod +x` after extraction via `dpkg-deb -x` or `unzip`
5. **scp paths:** use `/c/Users/...`, not `C:\Users\...`
