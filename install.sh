#!/usr/bin/env bash
set -euo pipefail

# MMDVMHost + DMRGateway installer
# Author: Ini
# Repo: https://github.com/<your-user>/mmdvm-installer

LOG_FILE="/var/log/mmdvm_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== MMDVM INSTALL START ====="

sudo apt update && sudo apt upgrade -y
sudo apt purge -y modemmanager || true

sudo apt install -y \
  git build-essential cmake \
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

if ! id "mmdvm" &>/dev/null; then
    sudo useradd -r -m -s /usr/sbin/nologin mmdvm
fi

sudo usermod -aG dialout mmdvm

cd /opt

if [ ! -d /opt/MMDVMHost ]; then
    sudo git clone https://github.com/g4klx/MMDVMHost.git
fi

if [ ! -d /opt/DMRGateway ]; then
    sudo git clone https://github.com/g4klx/DMRGateway.git
fi

sudo chown -R mmdvm:mmdvm /opt/MMDVMHost /opt/DMRGateway

cd /opt/MMDVMHost
sudo -u mmdvm make clean || true
sudo -u mmdvm make -j"$(nproc)"

cd /opt/DMRGateway
sudo -u mmdvm make clean || true
sudo -u mmdvm make -j"$(nproc)"

echo "===== INSTALL COMPLETE ====="
