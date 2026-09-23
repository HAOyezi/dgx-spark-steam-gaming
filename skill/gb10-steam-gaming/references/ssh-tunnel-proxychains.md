# GB10 SSH Reverse Tunnel + Proxychains, Detailed Config

## SSH reverse tunnel (desktop VPN → GB10)

The desktop's VPN provides a socks5 proxy at `127.0.0.1:[PROXY_PORT]`.
The GB10 is on the same LAN (at [GB10_IP]), but its direct connection reaches the Steam CDN and some foreign sites very slowly.

Expose the desktop's proxy port to the GB10 via an SSH reverse tunnel:

```bash
# run on the desktop (establishes a persistent tunnel)
ssh -f -N -R [TUNNEL_PORT]:127.0.0.1:[PROXY_PORT] [GB10_USER]@[GB10_IP]

# parameter notes:
#   -f  run in background
#   -N  do not execute a remote command
#   -R [TUNNEL_PORT]:127.0.0.1:[PROXY_PORT]  remote [TUNNEL_PORT] -> local 127.0.0.1:[PROXY_PORT]
```

**Verify the tunnel:**
```bash
# test on the GB10
curl -x socks5h://127.0.0.1:[TUNNEL_PORT] -so /dev/null -w '%{http_code}' https://store.steampowered.com
# expect 200
```

**Tunnel persistence** (auto-reconnect after drops):
```bash
# use autossh on the desktop
autossh -M 0 -f -N -R [TUNNEL_PORT]:127.0.0.1:[PROXY_PORT] [GB10_USER]@[GB10_IP]
```

## Proxychains configuration

Steam's built-in HTTP client ignores system proxy variables (`http_proxy`/`https_proxy`).
Proxychains4 forces all TCP connections through a given proxy via an LD_PRELOAD hook.

### Install
```bash
sudo apt-get install -y proxychains4
```

### Configure `/etc/proxychains4.conf`
```
strict_chain
proxy_dns

[ProxyList]
socks5 127.0.0.1 [TUNNEL_PORT]
```

### Usage
```bash
# any command can be forced through the proxy
proxychains4 FEXBash -c "DISPLAY=:0 exec /path/to/steam_binary"

# verify the proxy works
proxychains4 curl -so /dev/null -w '%{http_code}' https://store.steampowered.com
```

### Pitfalls
- Programs under FEX translation can also be hooked by proxychains — LD_PRELOAD works above the FEX translation layer
- proxychains does not support UDP (TCP only); some games may depend on UDP
- `strict_chain` mode: the proxy chain must be followed in order; when the proxy dies the connection breaks. Use `dynamic_chain` if the tunnel is unstable
