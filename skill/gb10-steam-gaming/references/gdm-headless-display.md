# GDM Headless Display Configuration (GB10 DGX Spark)

The GB10 has no physical display, but ships with GDM3 providing a real NVIDIA Xorg. Key distinction:
- Xvfb: pure software rendering, no DRI3 → Steam 3D GUI cannot render
- GDM + NVIDIA Xorg: real GPU DRI3/GLX/Vulkan support → Steam works

## GDM auto-login

```ini
# /etc/gdm3/custom.conf
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=[GB10_USER]
```

## NVIDIA headless Xorg.conf

```conf
# /etc/X11/xorg.conf
Section "Device"
    Identifier  "Device0"
    Driver      "nvidia"
    VendorName  "NVIDIA Corporation"
    Option      "AllowEmptyInitialConfiguration" "True"
EndSection

Section "Screen"
    Identifier  "Screen0"
    Device      "Device0"
    Monitor     "Monitor0"
    SubSection  "Display"
        Modes   "1920x1080"
        Virtual 1920 1080
    EndSubSection
EndSection

Section "Monitor"
    Identifier  "Monitor0"
EndSection
```

## Enabling the GDM display

```bash
# restart GDM to load the config
sudo systemctl restart gdm3
sleep 5

# verify Xorg is running
pgrep Xorg

# access the display (requires XAUTHORITY)
export XAUTHORITY=/run/user/1000/gdm/Xauthority
export DISPLAY=:0
xdpyinfo | grep -E "vendor|dimensions"
```

## GDM Xorg logs

When Xorg.0.log is empty, GDM's Xorg may live under `/run/user/1000/gdm/`. How to find it:

```bash
# read the Xorg process command line
cat /proc/$(pgrep -n Xorg)/cmdline | tr '\0' ' '

# typical output: /usr/lib/xorg/Xorg vt2 -displayfd 3 -auth /run/user/1000/gdm/Xauthority ...
```

## Display changes after a GDM restart

After a GDM restart the session may switch from vt1 to vt2. Display `:0` usually stays the same, but re-run `xdpyinfo` after startup to verify.
