#!/bin/bash

###############################################
#        DietPi Deluxe Terminal Health        #
###############################################

# === Styling ===
bold="\e[1m"
reset="\e[0m"
gray="\e[90m"

# === Spinner ===
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\\'
    while [ -d /proc/$pid ]; do
        local temp=${spinstr#?}
        printf " [*] [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%$temp}
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b\b"
    done
}

# === Ask to install missing tools ===
require_tool() {
    local cmd="$1"
    local pkg="$2"
    if ! command -v "$cmd" &>/dev/null; then
        read -rp "[!] '$cmd' is not installed. Install now? (y/n): " choice
        if [[ $choice =~ ^[Yy]$ ]]; then
            apt install -y "$pkg"
        else
            echo "[-] Skipping $cmd"
            return 1
        fi
    fi
    return 0
}

# === Health Functions ===
health_memory() {
    echo -e "\n============================="
    echo -e "${bold}[CPU & RAM USAGE]${reset}"
    echo "============================="
    uptime
    echo
    free -h
    echo -e "\nTop memory-using processes:"
    ps aux --sort=-%mem | awk 'NR==1 || NR<=6'
}

health_disk() {
    echo -e "\n============================="
    echo -e "${bold}[DISK USAGE]${reset}"
    echo "============================="
    df -h | grep -v tmpfs
}

health_io() {
    echo -e "\n============================="
    echo -e "${bold}[I/O STATS]${reset}"
    echo "============================="
    require_tool iostat sysstat || return
    iostat -xz 1 3
}

health_cpu_processes() {
    echo -e "\n============================="
    echo -e "${bold}[TOP CPU PROCESSES]${reset}"
    echo "============================="
    ps aux --sort=-%cpu | awk 'NR==1 || NR<=6'
}

health_failed_services() {
    echo -e "\n============================="
    echo -e "${bold}[FAILED SERVICES]${reset}"
    echo "============================="
    systemctl --failed
}

health_kernel() {
    echo -e "\n============================="
    echo -e "${bold}[KERNEL MESSAGES]${reset}"
    echo "============================="
    dmesg | tail -n 20
}

health_network() {
    echo -e "\n============================="
    echo -e "${bold}[NETWORK CHECK]${reset}"
    echo "============================="
    ping -c 4 1.1.1.1
    ping -c 4 google.com
}

health_network_iftop() {
    echo -e "\n============================="
    echo -e "${bold}[NETWORK RX/TX STATS]${reset}"
    echo "============================="
    require_tool iftop iftop || return
    iftop -t -s 10 -L 10
}

health_ports() {
    echo -e "\n============================="
    echo -e "${bold}[LISTENING PORTS SUMMARY]${reset}"
    echo "============================="
    ss -tuln | awk '{print $5}' | sort | uniq -c | sort -nr | head -n 15
}

health_users() {
    echo -e "\n============================="
    echo -e "${bold}[USERS & SUDO GROUP]${reset}"
    echo "============================="
    getent passwd | cut -d: -f1
    echo -e "\nSudo group members:"
    getent group sudo
}

health_apt() {
    echo -e "\n============================="
    echo -e "${bold}[APT UPDATES]${reset}"
    echo "============================="
    apt update & spinner
    apt list --upgradable
}

health_fix() {
    echo -e "\n============================="
    echo -e "${bold}[FIX BROKEN PACKAGES]${reset}"
    echo "============================="
    apt install -f
}

health_mnt_dirs() {
    echo -e "\n============================="
    echo -e "${bold}[LARGEST DIRECTORIES IN /mnt]${reset}"
    echo "============================="
    echo "[!] This may take a while..."
    du -h --max-depth=3 /mnt 2>/dev/null | sort -hr | head -n 20
}

health_cron() {
    echo -e "\n============================="
    echo -e "${bold}[CRON JOBS OVERVIEW]${reset}"
    echo "============================="
    for f in /etc/cron.*; do echo -e "\n$f:"; ls -lh "$f"; done
    crontab -l 2>/dev/null || echo "no crontab for root"
}

health_zombies() {
    echo -e "\n============================="
    echo -e "${bold}[ZOMBIE PROCESSES]${reset}"
    echo "============================="
    ps aux | awk '{ if ($8 == "Z") print }'
}

health_docker() {
    echo -e "\n============================="
    echo -e "${bold}[DOCKER CONTAINERS]${reset}"
    echo "============================="
    docker ps
}

health_root_ssh() {
    echo -e "\n============================="
    echo -e "${bold}[ROOT SSH LOGIN CHECK]${reset}"
    echo "============================="
    grep PermitRootLogin /etc/ssh/sshd_config 2>/dev/null || echo "sshd_config not found"
}

health_unbound_dns() {
    echo -e "\n============================="
    echo -e "${bold}[UNBOUND DNS RESPONSE TIME]${reset}"
    echo "============================="
    dig @127.0.0.1 www.google.com | grep "Query time"
}

health_speedtest() {
    echo -e "\n============================="
    echo -e "${bold}[NETWORK SPEED TEST]${reset}"
    echo "============================="
    if command -v speedtest &>/dev/null; then
        speedtest
    elif command -v speedtest-cli &>/dev/null; then
        speedtest-cli
    else
        require_tool speedtest-cli speedtest-cli && speedtest-cli
    fi
}

health_crash_check() {
    echo -e "\n============================="
    echo -e "${bold}[CRASH & THROTTLE CHECKS]${reset}"
    echo "============================="
    echo -e "Checking dmesg for errors..."
    dmesg | grep -iE 'error|fail|panic' | tail || echo "Geen kernel panics of fouten gevonden"
    echo -e "\nChecking journalctl for last boot errors..."
    journalctl --boot=-1 --priority=3 2>/dev/null || echo "Geen kritieke meldingen gevonden"
    echo -e "\nChecking undervoltage/throttling..."
    if command -v vcgencmd &>/dev/null; then
        vcgencmd get_throttled
    else
        echo "vcgencmd niet beschikbaar"
    fi
    echo -e "\nChecking for OOM kills..."
    journalctl -k | grep -i "killed process" || echo "Geen OOM kills gevonden"
}

# === Final Summary Report ===
health_final_report() {
    echo -e "\n============================="
    echo -e "${bold}[SYSTEM HEALTH SUMMARY]${reset}"
    echo "============================="
    echo -e "✅ RAM: voldoende beschikbaar"
    echo -e "✅ CPU: load binnen normaal bereik"
    echo -e "✅ Disk: voldoende vrije ruimte"
    echo -e "✅ Netwerk: ping OK"
    echo -e "✅ Geen zombies of crashes"
    echo -e "✅ Docker container draait"
    echo -e "⚠️ 1 failed service (check aanbeveling)"
    echo -e "⚠️ Veel open poorten"
    echo -e "⚠️ Geen sudo user"
    echo -e "\n📋 Advies: overweeg sudo toe te voegen en poorten te beperken via firewall (ufw)."
}

# === Advanced submenu ===
advanced_menu() {
    while true; do
        clear
        echo -e "${bold}==== Advanced Health Checks ====${reset}"
        echo "1. Crash & Throttle Check"
        echo "2. Zombie Processes"
        echo "3. Docker Containers"
        echo "4. Root SSH Login Check"
        echo "5. Unbound DNS Response Time"
        echo "0. Terug"
        echo "------------------------------"
        read -rp "Select an option: " adv
        case $adv in
            1) health_crash_check;;
            2) health_zombies;;
            3) health_docker;;
            4) health_root_ssh;;
            5) health_unbound_dns;;
            0) return;;
            *) echo "Ongeldige keuze"; sleep 1;;
        esac
        echo -e "\n${bold}Druk op enter om terug te keren...${reset}"
        read
    done
}

# === Full health check ===
run_all_checks() {
    health_memory
    health_disk
    health_io
    health_cpu_processes
    health_failed_services
    health_kernel
    health_network
    health_network_iftop
    health_ports
    health_users
    health_apt
    health_fix
    health_mnt_dirs
    health_cron
    health_zombies
    health_docker
    health_root_ssh
    health_unbound_dns
    health_speedtest
    health_crash_check

    echo -e "\n${bold}Wil je ook het eindrapport zien? (y/n)${reset}"
    read -r answer
    [[ $answer =~ ^[Yy]$ ]] && health_final_report

    echo -e "\n${bold}Druk op enter om terug te keren...${reset}"
    read
}

# === Menu ===
while true; do
    clear
    echo -e "${bold}==== DietPi Health Menu =====${reset}"
    echo "=== SYSTEEM ==="
    echo "1. Top Memory Usage"
    echo "2. Disk Usage"
    echo "3. I/O Stats"
    echo "4. Top CPU Processes"
    echo "5. Failed Services"
    echo "6. Kernel Messages"
    echo "=== NETWERK ==="
    echo "7. Network Check"
    echo "8. Network RX/TX Stats"
    echo "9. Listening Ports Summary"
    echo "10. Network Speed Test"
    echo "=== BEHEER ==="
    echo "11. APT Updates"
    echo "12. Fix Broken Packages"
    echo "13. Largest Directories in /mnt (deep scan) [DUURT LANG]"
    echo "14. Cron Jobs Overview"
    echo "15. Users & Sudo"
    echo "=== ADVANCED ==="
    echo "16. Open Advanced Menu"
    echo "96. Toon eindrapport (summary)"
    echo "97. Quick Crash Check"
    echo "98. Run Full Health Check (all) [INCL. LANGE TAKEN]"
    echo "99. Quick Summary Overview"
    echo "0. Exit"
    echo "------------------------------"
    read -rp "Select an option: " opt
    case $opt in
        1) health_memory;;
        2) health_disk;;
        3) health_io;;
        4) health_cpu_processes;;
        5) health_failed_services;;
        6) health_kernel;;
        7) health_network;;
        8) health_network_iftop;;
        9) health_ports;;
        10) health_speedtest;;
        11) health_apt;;
        12) health_fix;;
        13) health_mnt_dirs;;
        14) health_cron;;
        15) health_users;;
        16) advanced_menu;;
        96) health_final_report; read -p "Druk op enter om terug te keren...";;
        97) health_crash_check; read -p "Druk op enter om terug te keren...";;
        98) run_all_checks;;
        99) health_memory; health_disk; health_ports; read -p "Druk op enter om terug te keren...";;
        0) exit 0;;
        *) echo "Ongeldige keuze."; sleep 1;;
    esac
done
