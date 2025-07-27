#!/bin/bash

# Proxmox Hyper-V to HA Windows VM Conversion Tool
# Author: Cemal Demirci & Muammer Yeşilyağcı
# Description: Converts Hyper-V exported Windows VM to Proxmox-compatible, UEFI-enabled VM with HA, shared storage support, and backup policy.
# License: MIT

set -e

### USER INPUTS ###
echo "=== Proxmox Windows VM Automation Tool ==="
echo "1) Windows 10"
echo "2) Windows 11"
echo "3) Windows Server 2019"
echo "4) Windows Server 2022"
read -p "Select OS type (1-4): " os_choice

case $os_choice in
  1) OS_TYPE="win10"; VMNAME="win10-uefi";;
  2) OS_TYPE="win11"; VMNAME="win11-uefi";;
  3) OS_TYPE="win10"; VMNAME="winserv2019-uefi";;
  4) OS_TYPE="win11"; VMNAME="winserv2022-uefi";;
  *) echo "Invalid option."; exit 1;;
esac

read -p "Enter source VHDX full path: " SOURCE_VHDX
read -p "Enter Proxmox VM ID to use (e.g., 9000): " VMID

# Storage setup
echo "Available storages:"
pvesm status | awk 'NR>1 {print NR-1 ")", $1}'
read -p "Select shared storage (number): " storage_id
STORAGE=$(pvesm status | awk -v id=$storage_id 'NR==(id+1) {print $1}')
DEST_DIR="/var/lib/vz/images/$VMID"

mkdir -p "$DEST_DIR"

# Convert VHDX to QCOW2
echo "[+] Converting VHDX to QCOW2..."
qemu-img convert -f vhdx -O qcow2 "$SOURCE_VHDX" "$DEST_DIR/vm-$VMID-disk-0.qcow2"

# Create VM
qm create $VMID \
  --name "$VMNAME" \
  --memory 8192 \
  --cores 4 \
  --net0 virtio,bridge=vmbr0 \
  --ostype $OS_TYPE \
  --scsihw virtio-scsi-pci \
  --boot order=scsi0 \
  --machine q35 \
  --bios ovmf \
  --efidisk0 $STORAGE:1,efitype=4m,format=qcow2,pre-enrolled-keys=1

# Import disk
echo "[+] Attaching converted disk..."
qm importdisk $VMID "$DEST_DIR/vm-$VMID-disk-0.qcow2" $STORAGE --format qcow2
qm set $VMID --scsi0 $STORAGE:vm-$VMID-disk-0

# VirtIO ISO (optional)
qm set $VMID --ide2 local:iso/virtio-win.iso,media=cdrom
qm set $VMID --vga qxl --boot order=scsi0

# Enable TPM (for Windows 11)
qm set $VMID --tpmstate0 $STORAGE:1,size=4M,version=v2.0

# Enable HA
read -p "Add this VM to HA cluster? (y/n): " add_ha
if [[ "$add_ha" == "y" || "$add_ha" == "Y" ]]; then
  ha-manager add vm:$VMID --group ha-group
  echo "[+] VM added to HA group."
fi

# Backup schedule
echo "[+] Configuring backup schedule..."
echo "1) Include in weekly backup"
echo "2) Skip backup"
read -p "Choose backup policy: " backup_choice

if [[ "$backup_choice" == "1" ]]; then
  echo "[+] Adding VM $VMID to backup job 'weekly-vzdump'..."
  # This assumes you already have a backup job created named 'weekly-vzdump'
  vzdump --quiet 1 --mailto it@domain.com --mode snapshot --compress zstd --storage $STORAGE --vmid $VMID
  echo "[+] One-time backup initiated. Add VM ID to recurring schedule manually if needed."
fi

# Final message
echo "[✔] VM $VMNAME ($VMID) ready with UEFI, TPM, optional HA, and backup policy applied."
echo "Use 'qm start $VMID' to power on."
