#!/bin/bash

# ================================
# test_syslog.sh - DDP Syslog Test Script
# ================================
# Path: /Scripts/Testing/test_syslog.sh
# Purpose:
# - Send a local syslog test message
# - Search centralized remote logs
# - Save syslog test evidence
# ================================

set -euo pipefail

project_root="/home/hnodri/DDP-Linux-Infrastructure-Project"
output_file="$project_root/Evidence/logs/syslog_test_results.txt"
test_message="DDP syslog test from server1 - $(date)"

mkdir -p "$project_root/Evidence/logs"

logger -p user.info "$test_message"

echo "Syslog test timestamp: $(date)" | tee "$output_file"
echo "Test message: $test_message" | tee -a "$output_file"
echo "" | tee -a "$output_file"

sudo grep -R "DDP syslog test" /var/log/remote /var/log/syslog 2>/dev/null | tee -a "$output_file"

echo "" | tee -a "$output_file"
sudo find /var/log/remote -type f | sort | tee -a "$output_file"