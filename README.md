# Universal Odoo Installation Script

An automated installation script for Odoo on Ubuntu systems. This script supports multiple Odoo versions (12.0+) and Ubuntu versions (18.04+).

## Features

- ✨ Supports all Odoo versions (12.0 and above)
- 🐧 Works on Ubuntu 18.04 and newer versions
- 🔒 Secure configuration with automatic password generation
- 🚀 Automatic dependency handling
- 📝 Detailed logging
- ⚙️ Systemd service configuration
- 🔄 Easy update mechanism

## Quick Start

```bash
# Download the script
wget https://raw.githubusercontent.com/moaaz1995/odoo-install-script/main/install_odoo.sh

# Make it executable
chmod +x install_odoo.sh

# Run the script (replace XX.0 with your desired Odoo version)
sudo ./install_odoo.sh XX.0
```

## Requirements

- Ubuntu 18.04 or newer
- Sudo privileges
- Internet connection

## Usage Examples

Install Odoo 18:
```bash
sudo ./install_odoo.sh 18.0
```

Install Odoo 16:
```bash
sudo ./install_odoo.sh 16.0
```

## What Gets Installed?

- Odoo of specified version
- PostgreSQL database
- Python dependencies
- System dependencies
- Wkhtmltopdf
- Systemd service
- Virtual environment

## Post-Installation

After installation completes:
1. Access Odoo at: `http://localhost:8069`
2. Check service status: `systemctl status odoo-XX.0`
3. View logs: `tail -f /var/log/odoo/odoo-XX.0.log`

## Updating Odoo

Use the provided update script:
```bash
sudo /opt/odoo/update-odoo-XX.0.sh
```

## Troubleshooting

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any problems, please:
1. Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
2. Search existing [Issues](https://github.com/YOUR_USERNAME/odoo-install-script/issues)
3. Create a new issue if needed

## Star History

If you find this script helpful, please consider giving it a star ⭐️
