# EZDDNS
Simple yet versatile IPv6 and IPv4 Cloudflare Dynamic DNS updater for Linux
## Installation
1. Download/Clone the repository and open the directory in Terminal.
```bash
git clone https://github.com/TKtheDEV/EZDDNS
```
2. Edit ezddns.conf to suit your usecase
```bash
vi ezddns.sh
```
4. Make EZDDNS executable
```bash
chmod +x ezddns.sh
```
5. Run ezddns
```bash
./ezddns.sh
```
If you want to start EZDDNS automatically upon reboot do:
```bash
crontab -e
```
and add
```bash
@reboot  /home/user/startup.sh
```
