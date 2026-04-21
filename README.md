# 📡 MMDVMHost on Proxmox VM (Clean Install Guide)

This guide provides a clean, reproducible installation of **MMDVMHost** in a Debian/Ubuntu VM running on Proxmox with USB FTDI modem passthrough.

---

# ⚠️ Requirements

- Debian 11/12 or Ubuntu 22.04+
- Proxmox VM with USB passthrough (FTDI 0403:6015)
- Internet access
- sudo privileges

---

# 🔧 1. System preparation

```bash
sudo apt update && sudo apt upgrade -y

Remove modem conflicts:

sudo apt purge -y modemmanager

📦 2. Install dependencies

sudo apt install -y \
  git build-essential cmake \
  libusb-1.0-0-dev libusb-1.0-0 \
  libcurl4-openssl-dev libcurl4 \
  libssl-dev libssl3 \
  libwxgtk3.2-dev libwxgtk3.2-1 \
  libasio-dev \
  libncurses5-dev \
  libudev-dev \
  usbutils lsof htop strace \
  nlohmann-json3-dev \
  libmosquitto-dev mosquitto

👤 3. Create service user

sudo useradd -r -m -s /usr/sbin/nologin mmdvm
sudo usermod -aG dialout mmdvm

🔌 4. Check USB modem

lsusb
ls -l /dev/ttyUSB*
ls -l /dev/serial/by-id/

Expected device:

FTDI 0403:6015
/dev/ttyUSB0

📥 5. Install MMDVMHost

cd /opt
sudo git clone https://github.com/g4klx/MMDVMHost.git
sudo chown -R mmdvm:mmdvm MMDVMHost

⚙️ 6. Build

cd /opt/MMDVMHost
sudo -u mmdvm make clean
sudo -u mmdvm make -j$(nproc)

📁 7. Configuration

sudo mkdir -p /etc/mmdvm
sudo cp /opt/MMDVMHost/MMDVMHost.ini /etc/mmdvm/MMDVMHost.ini
sudo chown -R mmdvm:mmdvm /etc/mmdvm

Edit config:

sudo nano /etc/mmdvm/MMDVMHost.ini

Minimal working config:

[General]
Callsign=N0CALL
Id=1234567
Timeout=180
Duplex=1

[Modem]
Port=/dev/ttyUSB0
BaudRate=115200
TXInvert=0
RXInvert=0
PTTInvert=0
TXDelay=100

🔧 8. systemd service

sudo nano /etc/systemd/system/mmdvmhost.service

[Unit]
Description=MMDVMHost
After=network.target

[Service]
Type=simple
User=mmdvm
Group=mmdvm
ExecStart=/opt/MMDVMHost/MMDVMHost /etc/mmdvm/MMDVMHost.ini
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target

🚀 9. Enable and start service

sudo systemctl daemon-reload
sudo systemctl enable mmdvmhost
sudo systemctl start mmdvmhost

📊 10. Check status

sudo systemctl status mmdvmhost
sudo journalctl -u mmdvmhost -f


