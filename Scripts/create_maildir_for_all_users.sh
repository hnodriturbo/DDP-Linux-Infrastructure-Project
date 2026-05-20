#!/bin/bash

# ================================
# Create Maildir Script - DDP Users
# ================================
# Path: /Scripts/create_maildir_for_all_users.sh
# Purpose:
# - Create Maildir folder structure for all DDP users
# - Set correct ownership and permissions per user
# - Required for Dovecot IMAP mail delivery
# ================================

for user_home in /home/*; do
    username="$(basename "$user_home")"

    sudo mkdir -p "$user_home/Maildir/cur" "$user_home/Maildir/new" "$user_home/Maildir/tmp"
    sudo chown -R "$username:$username" "$user_home/Maildir"
    sudo chmod -R 700 "$user_home/Maildir"
done