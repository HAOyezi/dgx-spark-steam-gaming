# Install it into your AI (Hermes Agent / any skill-package-capable AI)

The `skill/dgx-spark-steam-gaming/` directory in this repo is a standard skill package: one `SKILL.md` (the main operation manual) + `references/` (13 troubleshooting deep-dives) + `scripts/` (3 helper scripts). Once installed, your AI automatically loads it whenever it sees "install games on DGX Spark / Steam on ARM / remote streaming" requests, and works through the measured procedure.

## How to install

**Option A — copy the directory manually (most universal)**

```bash
# create a folder in your AI's skills directory and copy the repo's skill/ contents into it
cp -r skill/dgx-spark-steam-gaming/ <your-AI-skills-dir>/
```

Hermes Agent's skills directory is `~/.hermes/skills/` (or the skills path in its config); Claude Code uses `.claude/skills/`; for other frameworks, follow their skill-loading convention.

**Option B — Hermes Agent only**

```bash
# after cloning the repo, let Hermes install it itself:
#  tell Hermes: "install the gb10-steam-gaming skill directory into my skills"
```

## Using it after install

Just tell your AI:

> "Set up Steam on this DGX Spark — I want to play Kerbal"

The AI will:
1. Auto-load this skill;
2. First **confirm the machine parameters** with you (the DGX Spark's IP, login user, sudo password, streaming account/password, proxy port — the skill is full of placeholders and will never guess);
3. Take the preferred `sudo snap install steam --stable` path (one command installs the official ARM64 Steam);
4. Configure Sunshine + Moonlight streaming only when remote play is needed.

## What's in the skill

| Part | Content |
|------|------|
| Preferred path | Canonical official Steam Snap (built-in FEX+Proton+DXVK); Kerbal/CS2 measured playable |
| Fallback path | Manual FEX + RootFS + Steam (when the snap is unavailable; 13 reference docs incl. bwrap sandbox bypass, i386 dependency chain, NVIDIA userspace libs) |
| Streaming | Full Sunshine (DGX Spark side) + Moonlight (client) config |
| Pitfall library | 5 major measured pitfall families: Steam GUI crash & resume, steamcmd CLI downloads, no-outbound proxy, snap update lag, etc. |

## Privacy guarantee

This skill package has been scrubbed of sensitive information and contains **no** real IPs, usernames, passwords, proxy ports or pairing codes. The whole document uses bracketed English placeholders (`[DGX Spark_IP]`, `[DGX Spark_USER]`, `[PROXY_PORT]`, `[STREAM_USER]`, …); the AI that installs it will request the real values from the **machine owner** before executing. Safe to distribute publicly.

## Version

- Measured baseline: Ubuntu 24.04.4 / driver 580.173.02 / Steam snap 1.0.0.85 / Sunshine 2026.516
- Updated: 2026-09-22
