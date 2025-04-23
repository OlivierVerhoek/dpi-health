# 🩺 DietPi Deluxe Terminal Health Check

A full-featured, menu-driven system health checker for DietPi-based systems.  
Lightweight, fast, and entirely terminal-based.  

⸻

## 🚀 Features

✅ Categorized health checks with clear output  
✅ Live command output and spinner for longer tasks  
✅ Smart final summary with recommendations  
✅ Advanced system-level checks (crashes, throttling, OOM kills)  
✅ Fully offline-compatible — only installs what you choose  
✅ Clear indicators for slow operations  
✅ Optional full scan (98) and quick summary (99)  
✅ Easy-to-read ASCII-styled banners  
✅ Lightweight, Bash-only — no bloat  

⸻

## 📸 Menu Preview

==== DietPi Health Menu =====
  1.  Top Memory Usage
  2.  Disk Usage
  3.  I/O Stats
  4.  Top CPU Processes
  5.  Failed Services
  6.  Kernel Messages
  7.  Network Check
  8.  Network RX/TX Stats
  9.  Listening Ports Summary
 10.  Users & Sudo
 11.  APT Updates
 12.  Fix Broken Packages
 13.  Largest Directories in /mnt (deep scan) [SLOW]
 14.  Cron Jobs Overview
 15.  Zombie Processes
 16.  Docker Container Status
 17.  Root SSH Login Check
 18.  Unbound DNS Response Time
 19.  Network Speed Test

=== Advanced ===
 20.  Crash/Throttling/OOM Analysis
 21.  Run All Advanced Checks

 98.  Run Full Health Check (all) [INCLUDES SLOW TASKS]
 99.  Quick Summary Overview
100.  Show Final Summary Report
101.  Exit

⸻

## 📦 Installation

git clone https://github.com/YOURUSERNAME/dietpi-health-check.git  
cd dietpi-health-check  
chmod +x health-check.sh  
./health-check.sh  

⸻

## 🔧 Requirements

Most functionality works out-of-the-box, but some commands are optional:  

Tool	Required For  
iftop	Network RX/TX stats  
iostat	I/O performance analysis (sysstat)  
speedtest-cli	Network speed test  
dig	Unbound DNS check  
docker	Docker container overview   
vcgencmd	Undervoltage detection (RPi only)  

The script will ask for permission before installing any missing packages.

⸻

## 📈 Final Summary Report Example

After a full scan, you’ll get a smart overview like:  

✅ General Health: GOOD  
🟡 Notes:  
• 1 failed service (systemd-networkd-wait-online)  
• High number of open ports — consider a firewall  
• Missing sudo users — consider adding your main user  

⸻

## 🤝 Contributing

Suggestions, PRs, and issue reports welcome!  
We’re aiming for a clean, readable, and portable Bash-only design.  

⸻

## 🧠 Author

Created by Olivier Verhoek  
Tested on Raspberry Pi 4 running DietPi  

⸻

## 📜 License

MIT License — do what you want, just credit.
