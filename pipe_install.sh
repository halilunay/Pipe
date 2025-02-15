#!/bin/bash
#
# Pipe Devnet Node Setup Script (systemd) + Automatic Update Option
# Installation with Referral Code
#

echo "-------------------------------------------------"
echo "  Pipe Devnet Node Setup"
echo "  You will be asked if you want to register"
echo "  using a referral code."
echo "  Then, you will have the option to add a cron job"
echo "  for automatic updates."
echo "-------------------------------------------------"
sleep 1

# 1. Get Input Values
echo -n "Your Wallet Address (pubKey): "
read -r PUBKEY

echo -n "How many GB of RAM do you want to allocate? (minimum 4): "
read -r RAM
if [ "$RAM" -lt 4 ]; then
  echo "Error: RAM must be at least 4 GB!"
  exit 1
fi

echo -n "Maximum disk space (in GB, minimum 100): "
read -r DISK
if [ "$DISK" -lt 100 ]; then
  echo "Error: Disk space must be at least 100 GB!"
  exit 1
fi

# Enter your default referral code here
DEFAULT_REF="f8e32ffad3f0dcad"
echo -n "Do you want to use a referral code? (default: $DEFAULT_REF) [Y/n]: "
read -r REF_CHOICE
if [[ "$REF_CHOICE" =~ ^(N|n|No|no)$ ]]; then
  REF_CODE=""
else
  REF_CODE="$DEFAULT_REF"
fi

echo "Please enter the v2 binary (pop) link sent by Pipe via email (must start with https):"
read -r BINARY_URL
if [[ $BINARY_URL != https* ]]; then
    echo "Error: Link must start with 'https'!"
    exit 1
fi

echo "------------------------------------"
echo "Starting installation..."
sleep 1

# 2. System Update and Port Opening
sudo apt update && sudo apt upgrade -y
sudo ufw allow 8003/tcp

# 3. Create Directories
mkdir -p "$HOME/pipe"
mkdir -p "$HOME/pipe/download_cache"

# 4. Stop and Clean Old Services (if any)
echo "Stopping any running popd..."
sudo systemctl stop popd 2>/dev/null
sudo systemctl disable popd 2>/dev/null

echo "Killing processes using port 8003..."
PID=$(lsof -ti :8003)
if [ -n "$PID" ]; then
  kill -9 "$PID"
fi

# 5. Download Binary
cd "$HOME/pipe" || exit
echo "Downloading POP binary..."
wget -q -O pop "$BINARY_URL"
chmod +x pop

# 6. Register with Referral (optional)
#    If the node is already registered, a 403 error may occur.
if [ -n "$REF_CODE" ]; then
  echo "Attempting referral registration... Code: $REF_CODE"
  OUT=$(./pop --signup-by-referral-route "$REF_CODE" 2>&1)
  echo "Output: $OUT"
  if echo "$OUT" | grep -q "403 Forbidden"; then
    echo "Warning: Node is already registered or IP is in use. Referral registration failed."
  else
    echo "Referral registration attempt completed."
  fi
fi

# 7. systemd Service File
SERVICE_FILE="/etc/systemd/system/popd.service"
echo "Creating systemd service file: $SERVICE_FILE"

sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Pipe POP Node Service
After=network.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=$HOME/pipe/pop \\
    --ram=$RAM \\
    --pubKey=$PUBKEY \\
    --max-disk=$DISK \\
    --cache-dir=$HOME/pipe/download_cache
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node
WorkingDirectory=$HOME/pipe

[Install]
WantedBy=multi-user.target
EOF"

# 8. Start the Service
sudo systemctl daemon-reload
sudo systemctl enable popd
sudo systemctl start popd

# 9. Check
echo "------------------------------------"
echo "Installation complete! Service is running."
echo "To see the status:  sudo systemctl status popd"
echo "To watch logs: sudo journalctl -u popd -f"
echo "------------------------------------"
echo "Additional commands (cd \$HOME/pipe):"
echo "  ./pop --status"
echo "  ./pop --points-route"
echo "  ./pop --gen-referral-route"
echo "------------------------------------"

# 10. Automatic Update Option
echo ""
echo "Due to frequent updates, you can add an automatic update."
echo "This will run the script every morning at 06:00 to check for updates."
echo -n "Set up an automatic update cron job? [Y/n]: "
read -r AUTO_UPDATE_CHOICE

if [[ "$AUTO_UPDATE_CHOICE" =~ ^(Y|y|Yes|yes)$ ]]; then
  
  # 10.a) Create auto_update_pipe.sh file
  cat << 'EOF' > "$HOME/pipe/auto_update_pipe.sh"
#!/bin/bash
#
# Pipe Node Auto Update Script
# This script catches the "UPDATE AVAILABLE" statement in 'pop --refresh' output.
# If available, it downloads the new version binary and updates the service.

cd "$HOME/pipe" || exit 1
echo "Running auto-update check..."

REFRESH_OUTPUT=$(./pop --refresh 2>&1)

if echo "$REFRESH_OUTPUT" | grep -q "UPDATE AVAILABLE"; then
    echo "[INFO] New version found. Getting version info..."
    DOWNLOAD_URL=$(echo "$REFRESH_OUTPUT" | grep "Download URL:" | awk '{print $NF}')
    if [ -n "$DOWNLOAD_URL" ]; then
        echo "[INFO] Downloading new version: $DOWNLOAD_URL"
        sudo systemctl stop popd
        wget -q -O "$HOME/pipe/pop" "$DOWNLOAD_URL"
        chmod +x "$HOME/pipe/pop"
        ./pop --refresh || true
        sudo systemctl start popd
        echo "[INFO] Update complete. To watch logs: sudo journalctl -u popd -f"
    else
        echo "[ERROR] 'UPDATE AVAILABLE' but no download URL found!"
    fi
else
    echo "[INFO] No update or already up-to-date."
fi
EOF

  chmod +x "$HOME/pipe/auto_update_pipe.sh"

  # 10.b) Add Cron job (every day at 06:00)
  (
    crontab -l 2>/dev/null
    echo "0 6 * * * /bin/bash $HOME/pipe/auto_update_pipe.sh >> $HOME/pipe/auto_update.log 2>&1"
  ) | crontab -

  echo "[OK] Automatic update cron job set! It will check every morning at 06:00."
  echo "For logs: $HOME/pipe/auto_update.log"
else
  echo "Automatic update not set. You can update manually."
fi

echo ""
echo "Installation (and automatic update if set) complete!"
echo "---------------------------------------------------"
