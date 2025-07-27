# 🧠 proxmox-hyperv-converter

Convert Hyper-V exported Windows VMs into Proxmox-compatible, UEFI-enabled, backup-integrated, HA-ready virtual machines — fully automated.  
Hyper-V'den dışa aktarılan Windows sanal makinelerini Proxmox'a dönüştürmek için tam otomatik bir bash scripti.

---

## ✅ Features / Özellikler

- Converts `.vhdx` (Hyper-V export) to `.qcow2`
- Automatically creates UEFI-enabled VM with Proxmox `qm`
- Adds TPM 2.0 support (for Windows 11)
- Includes VirtIO driver ISO mount
- HA Cluster integration (optional)
- Weekly backup policy configuration (optional)
- Türkçe ve İngilizce kullanıcı desteği
- Interactive menu (OS, storage, backup, HA)

---

## Quick Start (on Proxmox Server)

📥 **Download & Run in One Line:**

```bash
curl -o /usr/local/bin/proxmox_winvm_convert.sh https://raw.githubusercontent.com/cemal-demirci/proxmox-hyperv-converter/main/proxmox_winvm_convert.sh && chmod +x /usr/local/bin/proxmox_winvm_convert.sh && proxmox_winvm_convert.sh
