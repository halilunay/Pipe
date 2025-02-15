# Pipe Devnet Installation Guide

This guide allows you to set up your **Pipe Network** Devnet node with **a single command** (automatic or interactive). It also includes an **optional automatic update** feature.

---

## Features

- **Single Command Installation**: Updates your server, downloads the `pop` binary, writes the systemd service, and starts the node.
- **Referral Code (Optional)**: You can automatically add your referral code during the initial setup.
- **Automatic Update (Optional)**: Checks for updates every day at a specified time (06:00) and upgrades to the new version if necessary.

---

## Steps

### 1. Clone the Repository or Download the Script in RAW Format

The easiest way is to download and run the `pipe_install.sh` script directly:

```bash
# The link below should point to the script in RAW format.
wget https://raw.githubusercontent.com/halilunay/Pipe/refs/heads/main/pipe_install.sh

# Grant execute permission
chmod +x pipe_install.sh

# Run the script
./pipe_install.sh
```

If you encounter a "Permission denied" error, check the `chmod +x pipe_install.sh` command again.

### 2. Answer the Questions Asked by the Script

- **Your Wallet Address (pubKey)**: The public key provided by Pipe or created by you.
- **RAM Amount (GB)**: How much RAM you want to allocate to the node (minimum 4 GB).
- **Disk Amount (GB)**: Maximum disk space the node can use (minimum 100 GB).
- **Referral Code**: Default is set to `f8e32ffad3f0dcad`. You can use this code by answering [Y/n] or skip by saying "No".
- **Pipe Binary (pop) Link**: The pop binary link sent to you by the Pipe team via email (must start with "https"). Example: `https://dl.pipecdn.app/v0.2.5/pop`

### 3. Installation Proceeds Automatically

The script does the following:

- **System Updates**: `sudo apt update && sudo apt upgrade -y`
- **Port Permission**: `sudo ufw allow 8003/tcp`
- **Create Directories**: `$HOME/pipe` and `$HOME/pipe/download_cache`
- **Clean Old Services**: Stops and deletes any running `popd` service.
- **Download and Run Binary**:
  - Saves the downloaded file as `pop`, grants `chmod +x`.
  - If you choose to use a referral code, the script attempts registration with the `--signup-by-referral-route` parameter.
- **Write and Start systemd Service**: Creates a service file under `/etc/systemd/system/` named `popd.service`, reloads the daemon, and activates the service.

### 4. Post-Installation Checks

- **Service Status**:

```bash
sudo systemctl status popd
```

- **Follow Logs**:

```bash
sudo journalctl -u popd -f
```

- **Additional Pop Binary Commands**:

```bash
cd $HOME/pipe
./pop --status
./pop --points-route
./pop --gen-referral-route
```

### 5. Automatic Update Option

After installation, the script asks if you want to set up an "Automatic update cron job":

- **Yes** (Y/y/Yes/yes) sets up a script named `auto_update_pipe.sh` to run every day at 06:00.
  - This script looks for "UPDATE AVAILABLE" in `./pop --refresh`.
  - If a new version is found, it downloads the binary, stops/updates the service, and restarts it.
  - Writes success or error messages to `$HOME/pipe/auto_update.log`.
- **No** (N/n/No/no) does not add automatic updates. You can update manually if desired. For example:

```bash
sudo systemctl stop popd
cd $HOME/pipe
wget -O pop "https://dl.pipecdn.app/v0.2.5/pop"
chmod +x pop
sudo systemctl daemon-reload
sudo systemctl start popd
```

### 6. Frequently Asked Questions (FAQ)

- **Can I Add a Referral Code Later?**
  - Unfortunately, it is not possible to register the same IP/node ID with a referral code again. If no referral was entered during the first registration, you will receive a 403 error later. This is due to Pipe Network backend restrictions.

- **Is Port 8003 Open, How Can I Be Sure?**
  - You can see the rule if ufw is open with the `sudo ufw status` command.
  - You can check your server's IP and 8003 with an external port checker (e.g., portchecker.co).

- **Other VPS Firewall Settings**
  - Some VPS providers (Hetzner, DigitalOcean, etc.) may require additional firewall rules in their panel. You may need to open the 8003 TCP port from the panel.

- **Why Are Updates So Frequent?**
  - Pipe Network Devnet may still be in active development. Therefore, frequent updates are a natural process. Automatic updates alleviate this burden.

---

## Conclusion

By following the steps in this guide, you can set up your Pipe Network Devnet node with a single command, optionally use a referral code, and keep your node continuously updated with automatic updates.

If you have questions or encounter errors:

- Check the logs with `journalctl -u popd -f`,
- Open an Issue on GitHub or check community/forum channels.
