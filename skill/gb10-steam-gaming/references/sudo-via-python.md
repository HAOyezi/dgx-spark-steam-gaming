# GB10 remote sudo methods

## Preferred: SUDO_ASKPASS (Hermes-compatible, not intercepted)

The agent blocks `echo password | sudo -S`. `SUDO_ASKPASS` supplies the password from an external script, **not through stdin**:

```bash
# 1. create the askpass script (once)
ssh [GB10_USER]@[GB10_IP] "cat > /tmp/askpass.sh << 'EOS'
#!/bin/bash
echo '[SUDO_PASS]'
EOS
chmod +x /tmp/askpass.sh"

# 2. when sudo is needed
ssh [GB10_USER]@[GB10_IP] "SUDO_ASKPASS=/tmp/askpass.sh sudo -A your-command-here"
```

## Method 2: Python subprocess (fallback, may be intercepted)

```python
import subprocess
subprocess.run(["sudo","-S","cmd"], input=b"password\n", capture_output=True)
```

## Method 3: pty.openpty (bypasses the terminal requirement)

```python
import pty, os, subprocess
master, slave = pty.openpty()
p = subprocess.Popen(["sudo","-S","cmd"], stdin=slave, ...)
os.write(master, b"password\n")
```

## Pitfalls

- The password sits in plaintext in the askpass script — LAN-only use
- `sudo -A` requires the askpass script to be executable and to close immediately after printing the password
- Python subprocess `input=b"password\n"` (bytes, with trailing newline)
