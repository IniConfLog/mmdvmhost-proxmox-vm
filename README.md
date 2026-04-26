# Инструкция по установке и настройке MMDVMHost + DMRGateway в виртуальной машине Linux с USB FTDI MMDVM модемом.

⚠️ Требования к виртуальной машине (ВМ):
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
1. Подключаемся к ВМ по SSH от пользователя с правами sudo. В командной строке запускаем скрипт, который:
- обновит систему (apt update)
- установит базовые зависимости (curl, git)
- удалит конфликтующий modemmanager
- установит библиотеки, необходимые для сборки
- создаст пользователя mmdvm
- загрузит исходники MMDVMHost и DMRGateway c GitHub разработчика Jonathan Naylor G4KLX
- сборерет проект из исходников
- подготовит систему для работы с USB MMDVM модемом
- Создаст системные фоновые сервисы для MMDVMHost и DMRGateway, которые будут обеспечивать:
     - автозапуск программ при старте системы;
     - постоянную работу в фоне;
     - автоматический перезапуск при падении;
     - централизованные логи.
``` Bash
sudo apt update && sudo apt install -y curl git && \
curl -fsSL https://raw.githubusercontent.com/IniConfLog/mmdvmhost-proxmox-vm/main/install.sh | sudo bash
```
2. После окончания установки проверяем что система видит USB модем MMDVM
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
3. Настраиваем MMDVMHost:
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
4. Настраиваем DMRGateway:
``` Bash
sudo nano /opt/DMRGateway/DMRGateway.ini
```
5. Запускаем сервисы
``` Bash
sudo systemctl daemon-reload
sudo systemctl enable dmrgateway
sudo systemctl enable mmdvmhost
sudo systemctl start dmrgateway
sudo systemctl start mmdvmhost
```
6. Проверяем статус
``` Bash
sudo systemctl status dmrgateway
sudo systemctl status mmdvmhost
```
7. Проверяем логи
``` Bash
sudo journalctl -u dmrgateway -f
sudo journalctl -u mmdvmhost -f
```
