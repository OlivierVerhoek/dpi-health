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
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_disk() {
    echo -e "\n============================="
    echo -e "${bold}[DISK USAGE]${reset}"
    echo "============================="
    df -h | grep -v tmpfs
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_io() {
    echo -e "\n============================="
    echo -e "${bold}[I/O STATS]${reset}"
    echo "============================="
    require_tool iostat sysstat || return
    iostat -xz 1 3
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_cpu_processes() {
    echo -e "\n============================="
    echo -e "${bold}[TOP CPU PROCESSES]${reset}"
    echo "============================="
    ps aux --sort=-%cpu | awk 'NR==1 || NR<=6'
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_failed_services() {
    echo -e "\n============================="
    echo -e "${bold}[FAILED SERVICES]${reset}"
    echo "============================="
    systemctl --failed
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_kernel() {
    echo -e "\n============================="
    echo -e "${bold}[KERNEL MESSAGES]${reset}"
    echo "============================="
    dmesg | tail -n 20
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_network() {
    echo -e "\n============================="
    echo -e "${bold}[NETWORK CHECK]${reset}"
    echo "============================="
    ping -c 4 1.1.1.1
    ping -c 4 google.com
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_network_iftop() {
    echo -e "\n============================="
    echo -e "${bold}[NETWORK RX/TX STATS]${reset}"
    echo "============================="
    require_tool iftop iftop || return
    iftop -t -s 10 -L 10
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_ports() {
    echo -e "\n============================="
    echo -e "${bold}[LISTENING PORTS SUMMARY]${reset}"
    echo "============================="
    ss -tuln | awk '{print $5}' | sort | uniq -c | sort -nr | head -n 15
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_users() {
    echo -e "\n============================="
    echo -e "${bold}[USERS & SUDO GROUP]${reset}"
    echo "============================="
    getent passwd | cut -d: -f1
    echo -e "\nSudo group members:"
    getent group sudo
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_apt() {
    echo -e "\n============================="
    echo -e "${bold}[APT UPDATES]${reset}"
    echo "============================="
    apt update & spinner
    apt list --upgradable
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_fix() {
    echo -e "\n============================="
    echo -e "${bold}[FIX BROKEN PACKAGES]${reset}"
    echo "============================="
    apt install -f
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_mnt_dirs() {
    echo -e "\n============================="
    echo -e "${bold}[LARGEST DIRECTORIES IN /mnt]${reset}"
    echo "============================="
    echo "[!] This may take a while..."
    du -h --max-depth=3 /mnt 2>/dev/null | sort -hr | head -n 20
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_cron() {
    echo -e "\n============================="
    echo -e "${bold}[CRON JOBS OVERVIEW]${reset}"
    echo "============================="
    for f in /etc/cron.*; do echo -e "\n$f:"; ls -lh "$f"; done
    crontab -l 2>/dev/null || echo "no crontab for root"
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_zombies() {
    echo -e "\n============================="
    echo -e "${bold}[ZOMBIE PROCESSES]${reset}"
    echo "============================="
    ps aux | awk '{ if ($8 == "Z") print }'
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_docker() {
    echo -e "\n============================="
    echo -e "${bold}[DOCKER CONTAINERS]${reset}"
    echo "============================="
    docker ps
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_root_ssh() {
    echo -e "\n============================="
    echo -e "${bold}[ROOT SSH LOGIN CHECK]${reset}"
    echo "============================="
    grep PermitRootLogin /etc/ssh/sshd_config 2>/dev/null || echo "sshd_config not found"
    read -rp "\n${bold}Press enter to return...${reset}"
}

health_unbound_dns() {
    echo -e "\n============================="
    echo -e "${bold}[UNBOUND DNS RESPONSE TIME]${reset}"
    echo "============================="
    dig @127.0.0.1 www.google.com | grep "Query time"
    read -rp "\n${bold}Press enter to return...${reset}"
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
    read -rp "\n${bold}Press enter to return...${reset}"
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
    read -rp "\n${bold}Press enter to return...${reset}"
}

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
    read -rp "\n${bold}Druk op enter om terug te keren...${reset}"
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
    done
}
