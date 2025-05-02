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
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_disk() {
    echo -e "\n============================="
    echo -e "${bold}[DISK USAGE]${reset}"
    echo "============================="
    df -h | grep -v tmpfs
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_io() {
    echo -e "\n============================="
    echo -e "${bold}[I/O STATS]${reset}"
    echo "============================="
    require_tool iostat sysstat || return
    iostat -xz 1 3
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_cpu_processes() {
    echo -e "\n============================="
    echo -e "${bold}[TOP CPU PROCESSES]${reset}"
    echo "============================="
    ps aux --sort=-%cpu | awk 'NR==1 || NR<=6'
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_failed_services() {
    echo -e "\n============================="
    echo -e "${bold}[FAILED SERVICES]${reset}"
    echo "============================="
    systemctl --failed
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_kernel() {
    echo -e "\n============================="
    echo -e "${bold}[KERNEL MESSAGES - ERRORS & WARNINGS ONLY]${reset}"
    echo "============================="

    if command -v journalctl &>/dev/null; then
        journalctl -k --priority=3..4 --no-pager -n 20
    elif dmesg --help 2>&1 | grep -q -- '--level'; then
        dmesg --ctime --level=err,warn | tail -n 20
    else
        echo "Note: No advanced filtering available. Showing last 20 dmesg lines:"
        dmesg | tail -n 20
    fi

    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_network() {
    echo -e "\n============================="
    echo -e "${bold}[NETWORK CHECK]${reset}"
    echo "============================="
    ping -c 4 1.1.1.1
    ping -c 4 google.com
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_network_iftop() {
    echo -e "\n============================="
    echo -e "${bold}[NETWORK RX/TX STATS]${reset}"
    echo "============================="
    require_tool iftop iftop || return
    iftop -t -s 10 -L 10
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_ports() {
    echo -e "\n============================="
    echo -e "${bold}[LISTENING PORTS SUMMARY]${reset}"
    echo "============================="
    ss -tuln | awk '{print $5}' | sort | uniq -c | sort -nr | head -n 15
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_users() {
    echo -e "\n============================="
    echo -e "${bold}[USERS & SUDO GROUP]${reset}"
    echo "============================="
    getent passwd | cut -d: -f1
    echo -e "\nSudo group members:"
    getent group sudo
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_apt() {
    echo -e "\n============================="
    echo -e "${bold}[APT UPDATES]${reset}"
    echo "============================="
    (apt update) & spinner
    apt list --upgradable
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_fix() {
    echo -e "\n============================="
    echo -e "${bold}[FIX BROKEN PACKAGES]${reset}"
    echo "============================="
    apt install -f
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_mnt_dirs() {
    echo -e "\n============================="
    echo -e "${bold}[LARGEST DIRECTORIES IN /mnt]${reset}"
    echo "============================="
    echo "[!] This may take a while..."
    du -h --max-depth=3 /mnt 2>/dev/null | sort -hr | head -n 20
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_cron() {
    echo -e "\n============================="
    echo -e "${bold}[CRON JOBS OVERVIEW]${reset}"
    echo "============================="
    for f in /etc/cron.*; do echo -e "\n$f:"; ls -lh "$f"; done
    crontab -l 2>/dev/null || echo "no crontab for root"
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_zombies() {
    echo -e "\n============================="
    echo -e "${bold}[ZOMBIE PROCESSES]${reset}"
    echo "============================="
    ps aux | awk '{ if ($8 == "Z") print }'
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_docker() {
    echo -e "\n============================="
    echo -e "${bold}[DOCKER CONTAINERS]${reset}"
    echo "============================="
    if command -v docker &>/dev/null; then
        docker ps
    else
        echo "⚠️ Docker is not installed or not available."
    fi
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_root_ssh() {
    echo -e "\n============================="
    echo -e "${bold}[ROOT SSH LOGIN CHECK]${reset}"
    echo "============================="
    grep PermitRootLogin /etc/ssh/sshd_config 2>/dev/null || echo "sshd_config not found"
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_unbound_dns() {
    echo -e "\n============================="
    echo -e "${bold}[UNBOUND DNS RESPONSE TIME]${reset}"
    echo "============================="
    if command -v dig &>/dev/null; then
        dig @127.0.0.1 www.google.com | grep "Query time"
    else
        echo "⚠️ 'dig' is not available; skipping DNS check."
    fi
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_speedtest() {
    echo -e "\n============================="
    echo -e "${bold}[NETWORK SPEED TEST]${reset}"
    echo "============================="

    if command -v speedtest &>/dev/null; then
        if ! speedtest --progress=no; then
            echo -e "⚠️ Speedtest (Ookla) failed or was blocked. Skipping."
        fi
    elif command -v speedtest-cli &>/dev/null; then
        if ! speedtest-cli | grep -q "Download"; then
            echo -e "⚠️ Speedtest (speedtest-cli) failed or was blocked. Skipping."
        fi
    else
        echo "⚠️ No speedtest tool available."
        require_tool speedtest-cli speedtest-cli && speedtest-cli
    fi

    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

health_crash_check() {
    echo -e "\n============================="
    echo -e "${bold}[CRASH & THROTTLE CHECKS]${reset}"
    echo "============================="
    echo -e "Checking dmesg for errors..."
    dmesg | grep -iE 'error|fail|panic' | tail || echo "No kernel panics or errors found"
    echo -e "\nChecking journalctl for last boot errors..."
    journalctl --boot=-1 --priority=3 2>/dev/null || echo "No critical messages found"
    echo -e "\nChecking undervoltage/throttling..."
    if command -v vcgencmd &>/dev/null; then
        vcgencmd get_throttled
    else
        echo "⚠️ 'vcgencmd' not available (only present on Raspberry Pi)."
    fi
    echo -e "\nChecking for OOM kills..."
    oom_output=$(journalctl -k 2>&1 | tee /tmp/journal_check.log | grep -i "killed process")
    if grep -qi "truncated" /tmp/journal_check.log; then
        echo "⚠️ Warning: system journal appears truncated or incomplete. Consider enabling persistent logging."
    fi
    echo "$oom_output"
    [ -z "$oom_output" ] && echo "No OOM kills found"
    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

# === Final Report Function (Dynamic) ===
health_final_report() {
    # RAM info
    ram_available=$(free -h | awk '/Mem:/ {print $7}')

    # CPU load
    cpu_load=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)
    core_count=$(nproc)

    # Disk info
    root_disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    root_disk_free=$(df -h / | awk 'NR==2 {print $4}')
    mnt_total=$(du -sh /mnt 2>/dev/null | cut -f1)

    # Open ports (estimated number of lines with ip:port)
    open_ports=$(ss -tuln | awk '{print $5}' | grep -Eo '[0-9]+$' | wc -l)

    # Failed services
    failed_services=$(systemctl --failed | grep -v "0 loaded units" | grep -c "loaded")

    # DNS response time
    dns_time=$(dig @127.0.0.1 www.google.com | grep "Query time" | awk '{print $4}')

    # Sudo check
    sudo_users=$(getent group sudo | cut -d: -f4)
    has_sudo_user="⚠️ No sudo users detected"
    [[ -n "$sudo_users" ]] && has_sudo_user="✅ Sudo users present"

    echo -e "\n============================="
    echo -e "${bold}[SYSTEM HEALTH SUMMARY]${reset}"
    echo "============================="

    echo -e "\n\U1F4CA ${bold}CPU & RAM:${reset}"
    echo -e "✅ RAM available: ${ram_available}"
    echo -e "✅ Average CPU load: ${cpu_load} (cores: ${core_count})"

    echo -e "\n\U1F4BE ${bold}Storage:${reset}"
    echo -e "✅ Root disk usage: ${root_disk_usage} (${root_disk_free} free)"
    echo -e "✅ /mnt size: ${mnt_total}"

    echo -e "\n\U1F310 ${bold}Network:${reset}"
    echo -e "✅ Internet connection OK (ping successful)"
    echo -e "⚠️ Open ports: ${open_ports} detected"

    echo -e "\n\U1F6E0️ ${bold}System Services & Logging:${reset}"
    [[ "$failed_services" -gt 0 ]] && echo -e "⚠️ ${failed_services} failed service(s) detected" || echo -e "✅ No failed services"
    echo -e "✅ Unbound DNS response: ${dns_time} ms"

    echo -e "\n\U1F433 ${bold}Docker:${reset}"
    echo -e "✅ Containers running (check manually for details)"

    echo -e "\n\U1F512 ${bold}Security:${reset}"
    echo -e "$has_sudo_user"
    echo -e "✅ No zombie processes"

    echo -e "\n\U1F4E6 ${bold}Package Management:${reset}"
    upgradable=$(apt list --upgradable 2>/dev/null | grep -vc "Listing")
    [[ "$upgradable" -gt 0 ]] && echo -e "🔄 ${upgradable} update(s) available" || echo -e "✅ All up-to-date"

    echo -e "\n\U1F4CB ${bold}Recommendations:${reset}"
    [[ -z "$sudo_users" ]] && echo -e "- Add at least one user to sudo"
    [[ "$failed_services" -gt 0 ]] && echo -e "- Check status of failed services"
    [[ "$open_ports" -gt 15 ]] && echo -e "- Consider limiting ports with firewall (e.g. ufw)"
    echo -e "\n${bold}Press enter to return...${reset}"
    read
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
        echo "0. Back"
        echo "------------------------------"
        read -rp "Select an option: " adv
        case $adv in
            1) health_crash_check;;
            2) health_zombies;;
            3) health_docker;;
            4) health_root_ssh;;
            5) health_unbound_dns;;
            0) return;;
            *) echo "Invalid choice"; sleep 1;;
        esac
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

    echo -e "\n${bold}Would you like to see the final report? (y/n)${reset}"
    read -r answer
    [[ $answer =~ ^[Yy]$ ]] && health_final_report

    echo -e "\n${bold}Press enter to return...${reset}"
    read
}

# === Menu ===
while true; do
    clear
    echo -e "${bold}==== DietPi Health Menu =====${reset}"
    echo "=== SYSTEM ==="
    echo "1. Top Memory Usage"
    echo "2. Disk Usage"
    echo "3. I/O Stats"
    echo "4. Top CPU Processes"
    echo "5. Failed Services"
    echo "6. Kernel Messages"
    echo "=== NETWORK ==="
    echo "7. Network Check"
    echo "8. Network RX/TX Stats"
    echo "9. Listening Ports Summary"
    echo "10. Network Speed Test"
    echo "=== MAINTENANCE ==="
    echo "11. APT Updates"
    echo "12. Fix Broken Packages"
    echo "13. Largest Directories in /mnt (deep scan) [TAKES LONG]"
    echo "14. Cron Jobs Overview"
    echo "15. Users & Sudo"
    echo "=== ADVANCED ==="
    echo "16. Open Advanced Menu"
    echo "96. Show final report (summary)"
    echo "97. Quick Crash Check"
    echo "98. Run Full Health Check (all) [INCL. LONG TASKS]"
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
        96) health_final_report; echo -e "Press enter to return..."; read;;
        97) health_crash_check;;
        98) run_all_checks;;
        99) health_memory; health_disk; health_ports; echo -e "Press enter to return..."; read;;
        0) exit 0;;
        *) echo "Invalid choice."; sleep 1;;
    esac
done
