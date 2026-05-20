#!/bin/bash

# ================================
# create_users.sh - DDP User Creation Script
# ================================
# Path: /Scripts/create_users.sh
# Purpose:
#   Read Linux_Users.CSV and for each row:
#   - Create the department group if it does not already exist
#   - Create the Linux user with a home directory and Bash shell if not already present
#   - Store full name, email, and employee ID in the GECOS comment field
#   - Set a temporary password and force a reset on first login
#   - Add the user to their department group
#
# Usage:
#   sudo bash create_users.sh
#
# Output files written automatically:
#   Scripts/User_Creation_Logs/create_users.log     — full run log (every run)
#   Evidence/users/department_groups.txt            — department group memberships
#   Evidence/users/home_directory_listing.txt       — /home permissions listing
#   Evidence/users/user_list_verification.txt       — passwd entries + space for
#                                                     manual verification notes
#
# Notes:
#   - Script is idempotent: safe to re-run; existing users and groups are skipped
#   - Evidence files are overwritten on each run so they stay current
#   - Add manual verification notes to user_list_verification.txt after running
# ================================

# Exit immediately if any command returns a non-zero status.
set -e

# ---------------------------------------------------------------------------
# Path setup
# ---------------------------------------------------------------------------

# Resolve the directory this script lives in, regardless of where it is called from.
script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project root is one level above the Scripts/ directory.
project_root="$(dirname "$script_directory")"

# CSV file must live in the same directory as this script.
csv_file="$script_directory/Linux_Users.CSV"

# Main run log — captures everything printed during the run.
log_dir="$script_directory/User_Creation_Logs"
log_file="$log_dir/create_users.log"

# Evidence output files — written to the project Evidence/users/ folder.
evidence_dir="$project_root/Evidence/users"
dept_groups_file="$evidence_dir/department_groups.txt"
home_dirs_file="$evidence_dir/home_directory_listing.txt"
user_verify_file="$evidence_dir/user_list_verification.txt"

# Temporary password assigned to every new user.
# Users are forced to change this on first login.
default_password="ChangeMe123!"

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

# This script creates users and groups, which requires root privileges.
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    exit 1
fi

# Abort early if the CSV is missing rather than silently doing nothing.
if [[ ! -f "$csv_file" ]]; then
    echo "ERROR: CSV file not found at $csv_file"
    exit 1
fi

# Create output directories if they do not exist yet.
mkdir -p "$log_dir"
mkdir -p "$evidence_dir"

# Overwrite main log so each run produces a clean, complete record.
: > "$log_file"

echo "DDP user creation started: $(date)" | tee -a "$log_file"
echo "----------------------------------------------" | tee -a "$log_file"

# ---------------------------------------------------------------------------
# Main loop — process each user row from the CSV
# ---------------------------------------------------------------------------

# Skip the header line (line 1) and read the remaining rows.
tail -n +2 "$csv_file" | while IFS=',' read -r full_name first_name last_name username email department employee_id
do
    # Strip leading/trailing whitespace from all fields that will be used as
    # identifiers or stored as metadata. CSV exports sometimes include spaces.
    full_name="$(echo "$full_name"     | xargs)"
    username="$(echo "$username"       | xargs)"
    email="$(echo "$email"             | xargs)"
    department="$(echo "$department"   | xargs)"
    employee_id="$(echo "$employee_id" | xargs)"

    # -- Group creation -------------------------------------------------------
    # Check whether the department group already exists before trying to add it.
    # This makes the script safe to re-run without duplicate-group errors.
    if ! getent group "$department" > /dev/null; then
        groupadd "$department"
        echo "Created group: $department" | tee -a "$log_file"
    fi

    # -- User creation --------------------------------------------------------
    # Only create the user if the username does not already exist on the system.
    if ! id "$username" > /dev/null 2>&1; then

        # Create the user with:
        #   -m  : create a home directory under /home/<username>
        #   -s  : set login shell to Bash
        #   -c  : GECOS comment field — stores full name, email, and employee ID
        #         for easy identification via 'getent passwd' or 'finger'
        useradd -m -s /bin/bash -c "$full_name, $email, EmployeeID $employee_id" "$username"

        # Set the temporary password via chpasswd (reads "user:pass" from stdin).
        echo "$username:$default_password" | chpasswd

        # Force the user to change their password immediately on first login.
        passwd -e "$username" > /dev/null

        echo "Created user: $username ($full_name, $department)" | tee -a "$log_file"
    else
        echo "Skipped (already exists): $username" | tee -a "$log_file"
    fi

    # -- Group membership -----------------------------------------------------
    # Add the user to their department group.
    # -aG appends without removing the user from any existing supplementary groups.
    usermod -aG "$department" "$username"
    echo "  -> Added $username to group: $department" | tee -a "$log_file"

done

# ---------------------------------------------------------------------------
# Evidence file: department_groups.txt
# ---------------------------------------------------------------------------

{
    echo "Department Group Memberships"
    echo "Generated: $(date)"
    echo "=============================="
    getent group | grep -E "Tolvudeild|Rekstrardeild|Framkvaemdadeild|Framleidsludeild"
} > "$dept_groups_file"

echo "" | tee -a "$log_file"
echo "=== Department group memberships ===" | tee -a "$log_file"
cat "$dept_groups_file" | tee -a "$log_file"

# ---------------------------------------------------------------------------
# Evidence file: home_directory_listing.txt
# ---------------------------------------------------------------------------

{
    echo "Home Directory Listing"
    echo "Generated: $(date)"
    echo "=============================="
    ls -ld /home/*
} > "$home_dirs_file"

echo "" | tee -a "$log_file"
echo "=== Home directories ===" | tee -a "$log_file"
cat "$home_dirs_file" | tee -a "$log_file"

# ---------------------------------------------------------------------------
# Evidence file: user_list_verification.txt
# ---------------------------------------------------------------------------
# Writes a header and all /home user passwd entries as a starting point.
# Add manual verification output (e.g. 'id username', 'groups username') below
# the generated section after running the script.

{
    echo "User List Verification"
    echo "Generated: $(date)"
    echo "=============================="
    echo ""
    echo "--- /etc/passwd entries for DDP users ---"
    # Extract only users with a home directory under /home (excludes system accounts).
    getent passwd | awk -F: '$6 ~ /^\/home/ {print}' | sort
    echo ""
    echo "--- Manual verification notes ---"
    echo "# Add manual verification output below (e.g. id, groups, getent passwd)."
} > "$user_verify_file"

echo "" | tee -a "$log_file"
echo "=== User list written to $user_verify_file ===" | tee -a "$log_file"

# ---------------------------------------------------------------------------
# Completion summary
# ---------------------------------------------------------------------------

echo "" | tee -a "$log_file"
echo "DDP user creation completed: $(date)" | tee -a "$log_file"
echo "" | tee -a "$log_file"
echo "Evidence files written:" | tee -a "$log_file"
echo "  $dept_groups_file" | tee -a "$log_file"
echo "  $home_dirs_file" | tee -a "$log_file"
echo "  $user_verify_file" | tee -a "$log_file"