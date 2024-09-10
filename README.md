# EZDDNS
Simple yet versatile IPv6 and IPv4 Cloudflare Dynamic DNS updater for Linux
## Requirements
Depends on curl and bash

Alpine Linux
```bash
apk add curl bash
```
Debian based Distros
```bash
apt install curl bash
```
Everyone else knows how to use a package manager :)
```bash
curl bash
```

## Installation
1. Download/Clone the repository and open the directory in Terminal.
```bash
git clone https://github.com/TKtheDEV/EZDDNS && cd EZDDNS
```
2. Edit ezddns.conf to suit your usecase
```bash
vi ezddns.conf
```
4. Make EZDDNS executable
```bash
chmod +x ezddns.sh
```
5. Run ezddns
```bash
./ezddns.sh
```
## Start on boot
If you know how to send a PR please
