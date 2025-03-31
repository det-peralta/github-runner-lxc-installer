[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/detperalta)

# GitHub Runner LXC Installer

This script automates the creation and registration of a GitHub self-hosted runner within a Proxmox LXC (Linux Container).

## Prerequisites

- Proxmox server with proper network configuration
- Access to GitHub repository with admin permissions
- Basic knowledge of Proxmox and GitHub Actions

## How to Use

### 1. Get your GitHub owner information

The owner is simply the username or organization name from your GitHub URL.

For example, if your GitHub URL is https://github.com/det-peralta, then:
- Owner: det-peralta

### 2. Get your Runner Token

1. Go to your GitHub repository
2. Navigate to "Settings" → "Actions" → "Runners"
3. Click on "New self-hosted runner"
4. Look for the token in the configuration instructions (it will be shown after `--token`)
5. Copy this token value (looks like a long alphanumeric string)

### 3. Run the installer

```bash
# Run with interactive prompts
./install.sh

# Or provide values as environment variables
OWNER="your-username" RUNNER_TOKEN="your-token" ./install.sh
```

## Configuration Options

The script will prompt you for:
- GitHub owner/username
- GitHub runner token
- Container IP address (defaults to 192.168.0.220/24)
- Container gateway (defaults to 192.168.0.1)

## What the Script Does

1. Downloads Ubuntu 24.10 LXC template
2. Creates and configures a Proxmox LXC container
3. Installs required packages including Docker
4. Sets up the GitHub Actions runner
5. Registers the runner with your GitHub account
6. Configures the runner as a service

## Notes

- The runner is configured with 4 CPU cores and 4GB RAM by default
- Docker is installed for container-based GitHub Actions
- The runner is registered to run as root (using RUNNER_ALLOW_RUNASROOT=1)