#!/bin/bash

# ================================
# test_backup.sh - DDP Backup Test Script
# ================================
# Path: /Scripts/Testing/test_backup.sh
# Purpose:
# - Run the DDP home backup script manually
# - Save backup execution output as evidence
# - Verify that backup archive files are created
# ================================

# Run backup script manually as root for testing
sudo /home/hnodri/DDP-Linux-Infrastructure-Project/Scripts/backup_home.sh

# Show latest backup files
sudo ls -lh /backup/ddp-home




# More complex version:

set -euo pipefail

project_root="/home/hnodri/DDP-Linux-Infrastructure-Project"
backup_script="$project_root/Scripts/backup_home.sh"
log_file="$project_root/Evidence/logs/backup_log.txt"

mkdir -p "$project_root/Evidence/logs"

echo "DDP backup test started: $(date)" | tee "$log_file"

sudo bash "$backup_script" 2>&1 | tee -a "$log_file"

echo "" | tee -a "$log_file"
echo "Backup directory listing:" | tee -a "$log_file"
sudo ls -lh /backup/ddp-home 2>&1 | tee -a "$log_file"

echo "" | tee -a "$log_file"
echo "DDP backup test completed: $(date)" | tee -a "$log_file"