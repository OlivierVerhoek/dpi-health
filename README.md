# DietPi Deluxe Health Check

A powerful and interactive terminal-based health check toolkit for DietPi and other Debian-based systems.

## 🧰 Features

- 📊 System stats: CPU, RAM, disk, I/O, top processes
- 🌐 Network diagnostics: ping, speedtest, open ports, DNS response
- 🛠 Maintenance utilities: APT updates, fix broken packages, cron job listing
- 🔐 Security checks: zombie processes, sudo access, root SSH login
- 🐳 Docker: container overview (if installed)
- 📦 Package visibility: upgradable packages
- 📋 Final summary report (with recommendations)
- 🌀 Spinner and step-by-step feedback
- ✅ Smart defaults:
  - Unbound DNS detection on `127.0.0.1#5335`
  - Pi-specific checks (vcgencmd)
  - Tool installation prompts

## 🚀 Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/your-user/dpi-health.git
   cd dpi-health
   ```

2. Make the script executable:
   ```bash
   chmod +x dpi-health.sh
   ```

3. Run the script:
   ```bash
   ./dpi-health.sh
   ```

## 📖 Menu Overview

| Option | Description                                      |
|--------|--------------------------------------------------|
| `1–15` | Individual system/network/maintenance checks     |
| `16`   | Advanced submenu: DNS, Docker, zombie, root SSH  |
| `96`   | 🔍 Summary-only overview                         |
| `97`   | Quick crash/throttle check                       |
| `98`   | Full check — choose between batch or per-check   |
| `99`   | Quick peek: memory, disk, ports                  |
| `0`    | Exit                                             |

## 📦 Dependencies

Minimal set, installed as needed:
- `dig`, `ping`, `ss`, `free`, `df`, `ps`, `journalctl`, `docker`
- Optional: `speedtest`, `iftop`, `iostat`, `vcgencmd` (RPi)

The script will offer to install these interactively via `apt`.

## 🔐 Compatibility

- Optimized for DietPi on Raspberry Pi (also runs fine on other Debian systems)
- Safe to run as user; only escalates when needed
- Resilient to missing tools or non-Pi environments

## 🙏 Credits

Crafted with ❤️ by Olivier.  
Contributions welcome via issues or pull requests!
