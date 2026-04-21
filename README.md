# Инструкция по установке и настройке MMDVMHost в виртуальной машине Proxmox с USB FTDI модемом.

⚠️ Требования к виртуальной машине (ВМ):

- CPU: 2 vCPU
- RAM: 1–2 GB
- Диск: 16+ GB (SSD)
- Тип машины: q35
- BIOS: OVMF (или SeaBIOS)
- Установлена ОС Debian 11/12 или Ubuntu 22.04+
- Проброшен USB порт MMDVM модема
- Имеется доступ к сети Интернет
- Создан пользователь с правами sudo
---
Порядок установки:

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
```
4. Создаём служебного пользователя mmdvm и добавляем его в группу dialout
``` Bash
sudo useradd -r -m -s /usr/sbin/nologin mmdvm
sudo usermod -aG dialout mmdvm
```
5. Проверяем USB устройства
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
6. Скачиваем MMDVMHost с гитхаба разработчика (Jonathan Naylor) https://github.com/g4klx/MMDVMHost
``` Bash
cd /opt
sudo git clone https://github.com/g4klx/MMDVMHost.git
sudo chown -R mmdvm:mmdvm MMDVMHost
```
7. Компилируем проект из исходников с использованием системных и сторонних библиотек
``` Bash
cd /opt/MMDVMHost
sudo -u mmdvm make clean
sudo -u mmdvm make -j$(nproc)
```
8. Создаем отдельную папку /etc/mmdvm для файла конфигурации и копируем в нее исходный файл конфигурации MMDVMHost.ini
``` Bash
sudo mkdir -p /etc/mmdvm
sudo cp /opt/MMDVMHost/MMDVMHost.ini /etc/mmdvm/MMDVMHost.ini
sudo chown -R mmdvm:mmdvm /etc/mmdvm
```
9. Открыаем файл конфигурации MMDVMHost.ini для редактирования:
``` Bash
sudo nano /etc/mmdvm/MMDVMHost.ini
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
10. Создаем системный фоновый сервис, который будет обеспечивать:
- автозапуск программы при старте системы;
- постоянную работу в фоне;
- автоматический перезапуск при падении;
- централизованные логи.
``` Bash
sudo nano /etc/systemd/system/mmdvmhost.service
```
``` Bash
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
```
11. Запускаем сервис
``` Bash
sudo systemctl daemon-reload
sudo systemctl enable mmdvmhost
sudo systemctl start mmdvmhost
```
12. Проверяем статус
``` Bash
sudo systemctl status mmdvmhost
sudo journalctl -u mmdvmhost -f
```
Если все прошло удачно вы увидите примерно следующее:
``` Bash
sudo journalctl -u mmdvmhost -f
● mmdvmhost.service - MMDVMHost
     Loaded: loaded (/etc/systemd/system/mmdvmhost.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-04-21 07:15:40 MSK; 3h 29min ago
 Invocation: 9616c8c8de41406eb1de74e660d8f07e
   Main PID: 4849 (MMDVMHost)
      Tasks: 2 (limit: 2300)
     Memory: 1.1M (peak: 1.8M)
        CPU: 1min 25.540s
     CGroup: /system.slice/mmdvmhost.service
             └─4849 /opt/MMDVMHost/MMDVMHost /etc/mmdvm/MMDVMHost.ini
```
