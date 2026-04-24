#!/usr/bin/env bash
set -euo pipefail

echo "===== MMDVMHost + DMRGateway INSTALL START ====="

# ---------------------------
# Base dependencies
# ---------------------------
echo "[1/6] Installing base dependencies..."
sudo apt update
sudo apt install -y curl git build-essential cmake \
  libusb-1.0-0-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  libwxgtk3.2-dev \
  libasio-dev \
  libudev-dev \
  libncurses-dev \
  nlohmann-json3-dev \
  libmosquitto-dev mosquitto \
  usbutils lsof htop strace

# ---------------------------
# Remove conflicts
# ---------------------------
echo "[2/6] Removing modemmanager (USB conflict)..."
sudo apt purge -y modemmanager || true

# ---------------------------
# User
# ---------------------------
echo "[3/6] Creating user mmdvm..."
if ! id "mmdvm" &>/dev/null; then
    sudo useradd -r -m -s /usr/sbin/nologin mmdvm
fi
sudo usermod -aG dialout mmdvm

# ---------------------------
# Source code
# ---------------------------
echo "[4/6] Cloning repositories..."
cd /opt

if [ ! -d /opt/MMDVMHost ]; then
    sudo git clone https://github.com/g4klx/MMDVMHost.git
fi

if [ ! -d /opt/DMRGateway ]; then
    sudo git clone https://github.com/g4klx/DMRGateway.git
fi

sudo chown -R mmdvm:mmdvm /opt/MMDVMHost /opt/DMRGateway

# ---------------------------
# Build
# ---------------------------
echo "[5/6] Building MMDVMHost..."
cd /opt/MMDVMHost
sudo -u mmdvm make clean || true
sudo -u mmdvm make -j"$(nproc)"

echo "[5/6] Building DMRGateway..."
cd /opt/DMRGateway
sudo -u mmdvm make clean || true
sudo -u mmdvm make -j"$(nproc)"

# ---------------------------
# Systemd services
# ---------------------------
echo "[6/7] Creating systemd services..."

# --- DMRGateway service ---
cat > /etc/systemd/system/dmrgateway.service << 'EOF'
[Unit]
Description=DMRGateway
After=network.target

[Service]
User=mmdvm
Group=mmdvm
ExecStart=/opt/DMRGateway/DMRGateway /opt/DMRGateway/DMRGateway.ini

Restart=on-failure
RestartSec=5

StartLimitIntervalSec=120
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

# --- MMDVMHost service ---
cat > /etc/systemd/system/mmdvmhost.service << 'EOF'
[Unit]
Description=MMDVMHost
After=network.target

[Service]
User=mmdvm
Group=mmdvm
ExecStart=/opt/MMDVMHost/MMDVMHost /opt/MMDVMHost/MMDVMHost.ini

Restart=on-failure
RestartSec=5

StartLimitIntervalSec=120
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------
# Done
# ---------------------------
echo "[6/6] Installation completed successfully!"
echo "Log saved to /var/log/mmdvm_install.log"
