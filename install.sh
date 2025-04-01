#!/usr/bin/env bash

# This script automates the creation and registration of a GitHub self-hosted runner within a Proxmox LXC container.
# It uses an external script to create the container and focuses on installing and configuring the GitHub runner.

set -e

# Variables
GITHUB_RUNNER_URL="https://github.com/actions/runner/releases/download/v2.323.0/actions-runner-linux-x64-2.323.0.tar.gz"
GITHUB_RUNNER_FILE=$(basename $GITHUB_RUNNER_URL)

# Log function to print messages
log() {
  local text="$1"
  echo -e "\033[33m$text\033[0m"
}

# Create the LXC container using the external script
log "-- Creating LXC container using external script"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/ubuntu.sh)"

# Prompt the user to input the container ID after the external script execution
read -r -p "Enter the container ID of the created LXC: " CTID

# Ensure the container ID was provided
if [ -z "$CTID" ]; then
    log "-- No container ID provided. Exiting."
    exit 1
fi
log "-- Using container ID: $CTID"

# Validate that the provided CTID is a valid integer
if ! [[ "$CTID" =~ ^[0-9]+$ ]]; then
    log "-- Invalid container ID provided. Exiting."
    exit 1
fi
log "-- Valid container ID: $CTID"

# Verify LXC container creation before proceeding
if ! pct config "$CTID" &>/dev/null; then
    log "-- Configuration file for container ID $CTID does not exist. Exiting."
    exit 1
fi

# Retrieve the dynamically assigned IP address
log "-- Retrieving LXC container IP address"
CT_IP=$(pct exec "$CTID" -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
if [ -z "$CT_IP" ]; then
    log "-- Failed to retrieve LXC container IP address for container ID $CTID. Exiting."
    exit 1
fi
log "-- LXC container IP address: $CT_IP"

# Check if container is already running and start it if needed
log "-- Checking LXC container status"
if ! pct status "$CTID" | grep -q "status: running"; then
    log "-- Starting LXC container"
    if ! pct start "$CTID" 2>/dev/null; then
        log "-- Container $CTID already running or cannot be started"
    else
        log "-- Container $CTID started successfully"
    fi
    sleep 5
else
    log "-- LXC container is already running"
fi

# Ask for owner and runner token if they're not set
if [ -z "$OWNER" ]; then
        read -r -p "Enter GitHub username: " OWNER
    echo
fi
if [ -z "$RUNNER_TOKEN" ]; then
    read -r -p "Enter runner token: " RUNNER_TOKEN
    echo
fi

# Check if OWNER contains a slash (repo path) or not (org)
GITHUB_URL="https://github.com/$OWNER"
log "-- Using GitHub URL: $GITHUB_URL"

# Install and start the runner
log "-- Installing runner" 
pct exec "$CTID" -- bash -c "mkdir -p actions-runner && cd actions-runner && \
    curl -fsSL -o $GITHUB_RUNNER_FILE $GITHUB_RUNNER_URL || { echo 'Failed to download runner'; exit 1; } && \
    tar xzf $GITHUB_RUNNER_FILE && \
    RUNNER_ALLOW_RUNASROOT=1 ./config.sh --unattended --url $GITHUB_URL --token $RUNNER_TOKEN && \
    ./svc.sh install root && \
    ./svc.sh start"