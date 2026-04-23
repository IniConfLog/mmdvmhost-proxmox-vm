<<<<<<< HEAD
# Инструкция по установке и настройке MMDVMHost + DMRGateway в виртуальной машине Proxmox с USB FTDI модемом.

⚠️ Требования к виртуальной машине (ВМ):
=======
# 📡 MMDVMHost on Proxmox VM

Clean and reproducible installation guide for MMDVMHost running in a Proxmox virtual machine with USB FTDI modem passthrough.
>>>>>>> 895bebf (WIP: local changes before sync)

- CPU: 2 vCPU
- RAM: 1–2 GB
- Диск: 16+ GB (SSD)
- Тип машины: q35
- BIOS: OVMF (или SeaBIOS)
- Установлена ОС Debian 12
- Проброшен USB порт MMDVM модема
- Имеется доступ к сети Интернет
- Создан пользователь с правами sudo
---
Порядок установки:

<<<<<<< HEAD
1. Подготавливаем систему к установке (обновляем список пакетов и установленные пакеты)
``` Bash
sudo apt update && sudo apt upgrade -y
```
2. Удаляем потенциально конфликтующий сервис USB-модемов
``` Bash
sudo apt purge -y modemmanager
```
3. Устанавливаем зависимоссти (скачиваем и устанавливаем необходимые для сборки пакеты)
``` Bash
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
```
4. Создаём служебного пользователя mmdvm и добавляем его в группу dialout
``` Bash
sudo useradd -r -m -s /usr/sbin/nologin mmdvm
sudo usermod -aG dialout mmdvm
```
5. Скачиваем ПО MMDVMHost и DMRGateway с гитхаба разработчика (Jonathan Naylor) https://github.com/g4klx и предоставляем права пользователю mmdvm на папки с ПО
``` Bash
cd /opt
sudo git clone https://github.com/g4klx/MMDVMHost.git
sudo git clone https://github.com/g4klx/DMRGateway.git
sudo chown -R mmdvm:mmdvm MMDVMHost DMRGateway
```
6. Компилируем проект из исходников с использованием системных и сторонних библиотек
``` Bash
# MMDVMHost
cd /opt/MMDVMHost
sudo -u mmdvm make clean
sudo -u mmdvm make -j$(nproc)

# DMRGateway
cd /opt/DMRGateway
sudo -u mmdvm make clean
sudo -u mmdvm make -j$(nproc)
```
7. Проверяем что система видит USB модем MMDVM
``` Bash
lsusb
ls -l /dev/ttyUSB*
ls -l /dev/serial/by-id/
```
Ожидается примерный вывод:
``` Bash
...
Bus 003 Device 003: ID 0403:6015 Future Technology Devices International, Ltd Bridge(I2C/SPI/UART/FIFO)
...
crw-rw---- 1 root dialout 188, 0 апр 21 10:01 /dev/ttyUSB0
итого 0
lrwxrwxrwx 1 root root 13 апр 18 06:49 usb-FTDI_FT230X_Basic_UART_DB00PE5A-if00-port0 -> ../../ttyUSB0
```
8. Настраиваем MMDVMHost:
``` Bash
sudo nano /opt/MMDVMHost/MMDVMHost.ini
```
Минимально рабочая конфигурация:
``` Bash
[General]
Callsign=NOCALL
Id=123456
Timeout=180
Duplex=1

[Modem]
Protocol=uart
UARTPort=/dev/ttyUSB0
UARTSpeed=115200
#UARTSpeed=460800
TXInvert=0
RXInvert=0
PTTInvert=0
TXDelay=100
```
Примечание: Значение UARTSpeed= необходимо устанавливать в соответствии с установленным в MMDVM модемеме чипом.
- Если установлен чип STM32F4xx или STM32F7xx - UARTSpeed=115200;
- Если установлен более новый чип STM32F105xx - UARTSpeed=460800;
- Чаще всего на китайских модемах установлены старые чипы, новые установлены на модемах разработанных Алексеем RN6LJT в 2024/2025 годах.
9. Настраиваем DMRGateway:
``` Bash
sudo nano /opt/DMRGateway/DMRGateway.ini
```
10. Создаем системные фоновые сервисы для MMDVMHost и DMRGateway, которые будут обеспечивать:
- автозапуск программ при старте системы;
- постоянную работу в фоне;
- автоматический перезапуск при падении;
- централизованные логи.
DMRGateway
``` Bash
sudo nano /etc/systemd/system/dmrgateway.service
```
``` Bash
[Unit]
Description=DMRGateway
After=network.target

[Service]
User=mmdvm
ExecStart=/opt/DMRGateway/DMRGateway /opt/DMRGateway/DMRGateway.ini
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
MMDVMHost 
``` Bash
sudo nano /etc/systemd/system/mmdvmhost.service
```
``` Bash
[Unit]
Description=MMDVMHost
After=dmrgateway.service
Requires=dmrgateway.service

[Service]
User=mmdvm
ExecStart=/opt/MMDVMHost/MMDVMHost /opt/MMDVMHost/MMDVMHost.ini
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
11. Запускаем сервисы
``` Bash
sudo systemctl daemon-reload
sudo systemctl enable dmrgateway
sudo systemctl enable mmdvmhost
sudo systemctl start dmrgateway
sudo systemctl start mmdvmhost
```
12. Проверяем статус
``` Bash
sudo systemctl status dmrgateway
sudo systemctl status mmdvmhost
```
13. Проверяем логи
``` Bash
sudo journalctl -u dmrgateway -f
sudo journalctl -u mmdvmhost -f
```
Если все прошло удачно вы увидите примерно следующее:
``` Bash
atos@MMDVMHost:~$ sudo systemctl status mmdvmhost
sudo journalctl -u mmdvmhost -f
● mmdvmhost.service - MMDVMHost
     Loaded: loaded (/etc/systemd/system/mmdvmhost.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-04-23 16:41:42 MSK; 1h 48min ago
 Invocation: 8fdbdb36de054633a854c60fcb520dd1
   Main PID: 890 (MMDVMHost)
      Tasks: 3 (limit: 2300)
     Memory: 1.1M (peak: 1.8M)
        CPU: 46.810s
     CGroup: /system.slice/mmdvmhost.service
             └─890 /opt/MMDVMHost/MMDVMHost /opt/MMDVMHost/MMDVMHost.ini

апр 23 18:29:06 MMDVMHost MMDVMHost[890]: D: 2026-04-23 15:29:06.319 0000:  04 00 9A 52 31 5A 41 41 47 >
апр 23 18:29:07 MMDVMHost MMDVMHost[890]: M: 2026-04-23 15:29:07.040 DMR Slot 2, Talker Alias "R1ZAAG R>
апр 23 18:29:07 MMDVMHost MMDVMHost[890]: D: 2026-04-23 15:29:07.040 DMR Slot 2, Talker Alias (Data For>
апр 23 18:29:07 MMDVMHost MMDVMHost[890]: D: 2026-04-23 15:29:07.040 DMR Slot 2, Embedded Talker Alias >
апр 23 18:29:07 MMDVMHost MMDVMHost[890]: D: 2026-04-23 15:29:07.040 0000:  05 00 20 52 31 5A 41 41 47 >
апр 23 18:30:06 MMDVMHost MMDVMHost[890]: M: 2026-04-23 15:30:06.198 DMR Slot 2, received network end o>
апр 23 18:30:22 MMDVMHost MMDVMHost[890]: M: 2026-04-23 15:30:22.477 DMR Slot 2, received network voice>
апр 23 18:30:23 MMDVMHost MMDVMHost[890]: D: 2026-04-23 15:30:23.075 DMR Slot 2, Talker Alias (Data For>
апр 23 18:30:23 MMDVMHost MMDVMHost[890]: D: 2026-04-23 15:30:23.076 DMR Slot 2, Embedded Talker Alias >
апр 23 18:30:23 MMDVMHost MMDVMHost[890]: D: 2026-04-23 15:30:23.076 0000:  04 00 98 52 36 59 42 55 20 >
```
=======
# 📌 1. Overview

This guide installs:
- MMDVMHost digital voice gateway
- systemd service
- FTDI USB modem support
- YSF/DMR-ready base

---

# ⚙️ 2. Requirements

- Debian 11/12 or Ubuntu 22.04+
- Proxmox VM
- USB FTDI modem (0403:6015)
- Internet access

---

# 🔧 3. System preparation

```bash
sudo apt update && sudo apt upgrade -y
sudo apt purge -y modemmanager
>>>>>>> 895bebf (WIP: local changes before sync)
