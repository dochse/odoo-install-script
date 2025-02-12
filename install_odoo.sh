#!/bin/bash


# Universal Odoo Installation Script
# Author: Moaaz Gafar
# Email: m.gafar2024@gmail.com
# LinkedIn: https://www.linkedin.com/in/%F0%9D%91%B4%F0%9D%92%90%F0%9D%92%82%F0%9D%92%82%F0%9D%92%9B-%F0%9D%91%AE%F0%9D%92%82%F0%9D%92%87%F0%9D%92%82%F0%9D%92%93-0676a3111/
# Created: 2024
# Description: Automated installation script for Odoo (versions 12.0+) on Ubuntu systems
# Repository: https://github.com/moaaz1995/odoo-install-script
#
# This script is provided under MIT License
# Copyright (c) 2024 Moaaz Gafar


# Supports multiple Ubuntu versions (18.04+) and Odoo versions (12.0+)
# Usage: sudo bash install_odoo.sh <version>
# Example: sudo bash install_odoo.sh 16.0

# Exit script on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $1${NC}"
}

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (sudo)"
    exit 1
fi

# Check if version parameter is provided
if [ -z "$1" ]; then
    error "Please provide Odoo version!"
    echo "Usage: sudo bash install_odoo.sh <version>"
    echo "Example: sudo bash install_odoo.sh 16.0"
    exit 1
fi

# Set Odoo version
ODOO_VERSION=$1

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
log "Detected Ubuntu version: ${UBUNTU_VERSION}"

# Function to compare versions
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Function to handle package manager locks
handle_locks() {
    log "Handling package manager locks..."
    killall apt apt-get 2>/dev/null || true
    rm /var/lib/apt/lists/lock 2>/dev/null || true
    rm /var/cache/apt/archives/lock 2>/dev/null || true
    rm /var/lib/dpkg/lock* 2>/dev/null || true
    dpkg --configure -a
}

# Function to check and install package
install_package() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        apt install -y "$1"
    fi
}

# Handle any existing locks
handle_locks

# Update system
log "Updating system packages..."
apt update
apt upgrade -y

# Install common dependencies
log "Installing common dependencies..."
COMMON_PACKAGES="git build-essential wget postgresql node-less"
for package in $COMMON_PACKAGES; do
    install_package $package
done

# Python package installation based on Ubuntu version
log "Installing Python packages..."
if version_gt $UBUNTU_VERSION "22.04"; then
    # For Ubuntu 22.04 and newer
    apt install -y python3-dev python3-pip python3-wheel python3-venv python3-full \
        python3-setuptools
else
    # For Ubuntu 20.04 and older
    apt install -y python3-dev python3-pip python3-wheel python3-venv \
        python3-setuptools
fi

# Install system dependencies
log "Installing system dependencies..."
apt install -y libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev \
    libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev \
    libpq-dev

# Install wkhtmltopdf based on Ubuntu version
log "Installing wkhtmltopdf..."
if version_gt $UBUNTU_VERSION "22.04"; then
    apt install -y wkhtmltopdf
else
    # For older Ubuntu versions, install from website
    wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.focal_amd64.deb
    apt install -y ./wkhtmltox_0.12.5-1.focal_amd64.deb
fi

# Create Odoo user
log "Creating Odoo user..."
id -u odoo &>/dev/null || useradd -m -d /opt/odoo -U -r -s /bin/bash odoo

# Setup PostgreSQL
log "Configuring PostgreSQL..."
su - postgres -c "psql -c \"SELECT 1 FROM pg_user WHERE usename = 'odoo'\" | grep -q 1 || createuser -s odoo"

# Directory structure
log "Creating directory structure..."
mkdir -p /opt/odoo
mkdir -p /var/log/odoo
mkdir -p /etc/odoo
chown -R odoo:odoo /opt/odoo
chown -R odoo:odoo /var/log/odoo
chown -R odoo:odoo /etc/odoo

# Clone Odoo
log "Cloning Odoo ${ODOO_VERSION}..."
if [ -d "/opt/odoo/odoo-${ODOO_VERSION}" ]; then
    log "Updating existing Odoo installation..."
    su - odoo -c "cd /opt/odoo/odoo-${ODOO_VERSION} && git pull"
else
    su - odoo -c "git clone --depth 1 --branch ${ODOO_VERSION} https://github.com/odoo/odoo /opt/odoo/odoo-${ODOO_VERSION}"
fi

# Setup virtual environment
log "Setting up Python virtual environment..."
su - odoo -c "python3 -m venv /opt/odoo/odoo-${ODOO_VERSION}-venv"
VENV_PATH="/opt/odoo/odoo-${ODOO_VERSION}-venv"
VENV_PYTHON="${VENV_PATH}/bin/python3"
VENV_PIP="${VENV_PATH}/bin/pip"

# Install Python dependencies
log "Installing Python packages in virtual environment..."
su - odoo -c "${VENV_PIP} install wheel"
su - odoo -c "cd /opt/odoo/odoo-${ODOO_VERSION} && ${VENV_PIP} install -r requirements.txt"

# Generate random admin password
ADMIN_PASSWORD=$(openssl rand -base64 12)

# Create Odoo config
log "Creating Odoo configuration..."
cat > /etc/odoo/odoo-${ODOO_VERSION}.conf << EOF
[options]
admin_passwd = ${ADMIN_PASSWORD}
db_host = False
db_port = False
db_user = odoo
db_password = False
addons_path = /opt/odoo/odoo-${ODOO_VERSION}/addons
logfile = /var/log/odoo/odoo-${ODOO_VERSION}.log
http_port = 8069
EOF

chown odoo:odoo /etc/odoo/odoo-${ODOO_VERSION}.conf
chmod 640 /etc/odoo/odoo-${ODOO_VERSION}.conf

# Create systemd service
log "Creating systemd service..."
cat > /etc/systemd/system/odoo-${ODOO_VERSION}.service << EOF
[Unit]
Description=Odoo ${ODOO_VERSION}
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo-${ODOO_VERSION}
PermissionsStartOnly=true
User=odoo
Group=odoo
Environment="PATH=${VENV_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=${VENV_PYTHON} /opt/odoo/odoo-${ODOO_VERSION}/odoo-bin -c /etc/odoo/odoo-${ODOO_VERSION}.conf
StandardOutput=journal+console
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

chmod 755 /etc/systemd/system/odoo-${ODOO_VERSION}.service
systemctl daemon-reload

# Start and enable Odoo service
log "Starting Odoo service..."
systemctl start odoo-${ODOO_VERSION}
systemctl enable odoo-${ODOO_VERSION}

# Create an update script
log "Creating update script..."
cat > /opt/odoo/update-odoo-${ODOO_VERSION}.sh << EOF
#!/bin/bash
systemctl stop odoo-${ODOO_VERSION}
su - odoo -c "cd /opt/odoo/odoo-${ODOO_VERSION} && git pull"
su - odoo -c "${VENV_PIP} install -r /opt/odoo/odoo-${ODOO_VERSION}/requirements.txt"
systemctl start odoo-${ODOO_VERSION}
EOF

chmod +x /opt/odoo/update-odoo-${ODOO_VERSION}.sh
chown odoo:odoo /opt/odoo/update-odoo-${ODOO_VERSION}.sh

log "Installation complete!"
echo "========================================"
echo "Odoo ${ODOO_VERSION} Installation Summary"
echo "========================================"
echo "Web interface: http://localhost:8069"
echo "Service name: odoo-${ODOO_VERSION}"
echo "Config file: /etc/odoo/odoo-${ODOO_VERSION}.conf"
echo "Log file: /var/log/odoo/odoo-${ODOO_VERSION}.log"
echo "Virtual environment: ${VENV_PATH}"
echo "Admin password: ${ADMIN_PASSWORD}"
echo ""
echo "To update Odoo in the future, run:"
echo "sudo /opt/odoo/update-odoo-${ODOO_VERSION}.sh"
echo ""
echo "Useful commands:"
echo "- Check status: systemctl status odoo-${ODOO_VERSION}"
echo "- View logs: tail -f /var/log/odoo/odoo-${ODOO_VERSION}.log"
echo "- Restart service: systemctl restart odoo-${ODOO_VERSION}"
