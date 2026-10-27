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


*Disclaimer: This repository is for educational and training purposes only.*
