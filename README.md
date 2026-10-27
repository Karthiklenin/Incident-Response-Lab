# 🐧 Linux Incident Response Lab

Welcome to the **Linux Incident Response Lab**. This repository contains a simulation script and an investigation manual designed to teach and practice hands-on incident response and threat hunting on Linux systems. 

The lab simulates realistic attacker persistence mechanisms, unauthorized accounts, and web shell indicators, allowing security students and professionals to practice detecting and cleaning up compromises.

---

## 🎯 Lab Features & Indicators of Compromise (IOCs)

The simulation script (`linux_compromise_sim.sh`) deploys the following scenarios on a target Linux system:

1. **Backdoor User Creation**: Creates a sudo-enabled user account (`support-agent`) to simulate unauthorized access.
2. **SSH Persistence**: Injects an attacker SSH public key into the default user's `authorized_keys` file.
3. **Cron Job Persistence**: Configures a scheduled cron job (`sysmaintenance`) running a hidden beaconing script from `/dev/shm`.
4. **Systemd Service Backdoor**: Registers and starts a persistence system service (`sysmaintenance.service`).
5. **Active Backdoor Listener**: Spawns an active netcat or Python background listener on port `4444`.
6. **Mock Web Logs**: Generates web access logs at `/var/log/nginx/access.log` simulating a web shell exploitation attempt.

---

## 🚀 Getting Started

### 📋 Prerequisites
* A test Linux environment (e.g., Ubuntu, Debian, CentOS, or Rocky Linux).
* **Do not run the simulation script on a production system.**
* Sudo/Root privileges are required to run both simulation and cleanup actions.

### 🕹️ Running the Simulation
To deploy the mock compromise on your Linux machine:
```bash
sudo chmod +x linux_compromise_sim.sh
sudo ./linux_compromise_sim.sh simulate
```

### 🧹 Cleaning Up
To completely remove all simulation artifacts and restore the system to its original state:
```bash
sudo ./linux_compromise_sim.sh cleanup
```
---

## 👤 About the Author

Created and maintained by **Chaitanya Eshwar Prasad**. Connect with me or follow my work:

[![Website](https://img.shields.io/badge/Website-chaitanyaeshwarprasad.com-005F9E?style=for-the-badge&logo=google-chrome&logoColor=white)](https://chaitanyaeshwarprasad.com)
[![GitHub](https://img.shields.io/badge/GitHub-chaitanyaeshwarprasad-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/chaitanyaeshwarprasad)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Chaitanya%20Eshwar%20Prasad-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/chaitanya-eshwar-prasad)
[![YouTube](https://img.shields.io/badge/YouTube-@chaitanya.eshwar.prasad-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@chaitanya.eshwar.prasad)
[![Instagram](https://img.shields.io/badge/Instagram-@acep.tech.in.telugu-E4405F?style=for-the-badge&logo=instagram&logoColor=white)](https://instagram.com/acep.tech.in.telugu)
[![YesWeHack](https://img.shields.io/badge/YesWeHack-chaitanya--eshwar--prasad-FF5E00?style=for-the-badge&logo=securityscorecard&logoColor=white)](https://yeswehack.com/hunters/chaitanya-eshwar-prasad)

---
*Disclaimer: This repository is for educational and training purposes only.*
