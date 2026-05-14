#!/bin/bash

# ================================
# create_users.sh - DDP User Creation Script
# ================================
# Path: /opt/ddp/scripts/create_users.sh
# Purpose:
# - Create DDP Linux users from Linux_Users.CSV
# - Create department groups automatically
# - Add users to their correct department group
# - Create home directories and assign Bash as login shell
# - Generate a clear log for final project evidence
# ================================

set -euo pipefail

csv_file="Linux_Users.CSV"
log_file="create_users.log"
default_password="ChangeMe123!"

# Require root because user and group creation need administrator privileges.
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    exit 1
fi

echo "DDP user creation started: $(date)" | tee "$log_file"

# Read CSV rows after the header line.
tail -n +2 "$csv_file" | while IFS=',' read -r full_name first_name last_name username email department employee_id
do
    # Clean accidental spaces from CSV fields.
    full_name="$(echo "$full_name" | xargs)"
    username="$(echo "$username" | xargs)"
    email="$(echo "$email" | xargs)"
    department="$(echo "$department" | xargs)"
    employee_id="$(echo "$employee_id" | xargs)"

    # Create department group. Ignore error if it already exists.
    groupadd "$department" 2>/dev/null || true

    # Create user with home directory, Bash shell, and comment metadata.
    useradd -m -s /bin/bash -c "$full_name, $email, EmployeeID $employee_id" "$username"

    # Set temporary password and force password change on first login.
    echo "$username:$default_password" | chpasswd
    passwd -e "$username" > /dev/null

    # Add user to department group.
    usermod -aG "$department" "$username"

    echo "Created user $username and added to $department" | tee -a "$log_file"
done

echo "" | tee -a "$log_file"
echo "Department groups:" | tee -a "$log_file"
getent group Tolvudeild Rekstrardeild Framkvaemdadeild Framleidsludeild | tee -a "$log_file"

echo "" | tee -a "$log_file"
echo "Home directories:" | tee -a "$log_file"
ls -ld /home/* | tee -a "$log_file"

echo "DDP user creation completed: $(date)" | tee -a "$log_file"