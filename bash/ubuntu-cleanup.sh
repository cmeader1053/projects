#!/bin/bash

# Basic Ubuntu system cleanup script
# Run this script as root or with sudo

echo "Starting system cleanup..."

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., sudo $0)"
  exit 1
fi

echo "Updating package list..."
apt update

echo "Upgrading installed packages..."
apt upgrade -y

echo "Removing unnecessary packages..."
apt autoremove -y

echo "Cleaning up package cache..."
apt autoclean -y
apt clean -y

echo "Removing old snap revisions..."
snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
  snap remove "$snapname" --revision="$revision"
done

echo "Cleaning up thumbnail cache..."
rm -rf ~/.cache/thumbnails/*

echo "Removing journal logs older than 7 days..."
journalctl --vacuum-time=7d

echo "Checking disk usage..."
df -h

echo "System cleanup complete!"
