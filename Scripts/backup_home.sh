#!/bin/bash

# ================================
# DDP Home Directory Backup Script
# ================================
# Path: /Scripts/backup_home.sh
# Purpose:
# - Backup all user home directories
# - Create compressed timestamped archive
# - Store backups under /backup/ddp-home
# ================================

# Create timestamp variable
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Backup destination file
BACKUP_FILE="/backup/ddp-home/home_backup_$TIMESTAMP.tar.gz"

# Log file
LOG_FILE="/home/hnodri/DDP-Linux-Infrastructure-Project/Evidence/logs/backup_log.txt"

# Start backup
echo "========== BACKUP START ==========" >> "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"

# Create compressed archive
tar -czf "$BACKUP_FILE" /home

# Log result
if [ $? -eq 0 ]; then
    echo "Backup successful: $BACKUP_FILE" >> "$LOG_FILE"
else
    echo "Backup FAILED" >> "$LOG_FILE"
fi

echo "========== BACKUP END ==========" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"