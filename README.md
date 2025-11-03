# Cloud Drive Integration for Linux File Managers

**Seamlessly mount cloud storage as local folders with full drag-and-drop support**

Transform your cloud storage (Google Drive, Dropbox, OneDrive, etc.) into native folders that work just like local drives. Drag, drop, copy, paste - all with the file manager you already use.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

## ✨ Features

- 🚀 **One-command installation** - Set up in minutes
- 📁 **Native file manager integration** - Works with Thunar, Nautilus, Dolphin, Caja, Nemo
- ☁️ **Multiple cloud providers** - Google Drive, Dropbox, OneDrive, Box, pCloud, Mega
- 🔄 **Automatic mounting** - Connects on login
- 💾 **Smart caching** - Fast access with local caching
- 📶 **Offline support** - Cached files work without internet
- 🎯 **Right-click actions** - Mount/unmount from context menu
- 🔖 **Sidebar bookmarks** - Quick access from file manager
- 🐧 **Universal support** - Works on all major Linux distributions

## 📦 Supported Distributions

- **Debian-based:** Ubuntu, Linux Mint, Pop!_OS, Siduction, elementary OS
- **Arch-based:** Arch Linux, Manjaro, EndeavourOS
- **Red Hat-based:** Fedora, RHEL, CentOS
- **SUSE-based:** openSUSE Leap, Tumbleweed
- **And more!**

## 🖥️ Supported Desktop Environments

- XFCE (Thunar)
- GNOME (Nautilus)
- KDE Plasma (Dolphin)
- MATE (Caja)
- Cinnamon (Nemo)

## ☁️ Supported Cloud Providers

- Google Drive
- Dropbox
- Microsoft OneDrive
- Box
- pCloud
- Mega
- Any rclone-supported provider

## 🚀 Quick Start

### Installation
```bash
# Download the installer
wget https://raw.githubusercontent.com/mixebox/cloud-drive-integration/main/cloud-drive-integration-installer.sh

# Make it executable
chmod +x cloud-drive-integration-installer.sh

# Run the installer
./cloud-drive-integration-installer.sh
```

That's it! Follow the prompts to:
1. Select your cloud provider
2. Sign in to authorize access
3. Enjoy seamless cloud integration

### What Gets Installed

The installer will:
- ✅ Install rclone and required dependencies
- ✅ Configure your cloud storage connection
- ✅ Create mount/unmount scripts
- ✅ Set up automatic mounting on login
- ✅ Add context menu actions to your file manager
- ✅ Add a bookmark to your file manager sidebar

## 📖 Usage

### After Installation

1. **Open your file manager** - You'll see your cloud drive in the sidebar
2. **Access your files** - Click the bookmark to open your cloud storage
3. **Drag and drop** - Move files between local and cloud storage
4. **Work offline** - Frequently accessed files are cached locally

### Manual Controls

Mount your cloud drive:
```bash
mount-PROVIDER.sh
```

Unmount:
```bash
unmount-PROVIDER.sh
```

(Replace `PROVIDER` with your cloud provider name, e.g., `gdrive`, `dropbox`)

### Context Menu

Right-click anywhere in your file manager to see:
- **Mount [Cloud Name]** - Connect your cloud storage
- **Unmount [Cloud Name]** - Disconnect safely

## 🎥 Demo

### Before Installation
Accessing cloud files requires:
- Opening a web browser
- Navigating to the cloud provider's website
- Downloading files manually
- Uploading through a web interface

### After Installation
Accessing cloud files is as simple as:
- Opening your file manager
- Clicking your cloud drive folder
- Dragging and dropping files

**It just works.** ✨

## 🔧 Advanced Configuration

### Cache Settings

Edit your mount script to customize caching:
```bash
nano ~/.local/bin/mount-PROVIDER.sh
```

Key settings:
- `--vfs-cache-max-size 10G` - Maximum cache size (default: 10GB)
- `--vfs-cache-max-age 72h` - How long to keep cached files (default: 72 hours)
- `--vfs-read-ahead 256M` - Read-ahead buffer (default: 256MB)

### Multiple Cloud Accounts

Run the installer multiple times to set up multiple cloud drives:
```bash
./cloud-drive-integration-installer.sh
```

Each cloud provider gets its own:
- Mount point
- Scripts
- File manager integration

### Uninstallation

Remove autostart:
```bash
rm ~/.config/autostart/cloud-drive-mount-*.desktop
```

Remove scripts:
```bash
rm ~/.local/bin/mount-*.sh
rm ~/.local/bin/unmount-*.sh
```

Remove rclone config (optional):
```bash
rm -rf ~/.config/rclone
```

## 🤝 Contributing

This project was born from a real need: making Linux cloud storage integration as seamless as it should be.

### Ways to Contribute

- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🔧 Submit pull requests
- ⭐ Star the repository
- 📢 Spread the word

### Development
```bash
# Clone the repository
git clone https://github.com/mixebox/cloud-drive-integration.git

# Test your changes
cd cloud-drive-integration
./cloud-drive-integration-installer.sh
```

## 🏆 Credits

**Created by:**
- **98J30** - Concept, testing, and persistent problem-solving
- **Claude** - Implementation and documentation

**Built with:**
- [rclone](https://rclone.org/) - The backbone of cloud storage mounting
- FUSE - Filesystem in userspace
- Love for open source ❤️

## 📜 License

MIT License - See [LICENSE](LICENSE) file for details

## 🐛 Troubleshooting

### Cloud drive won't mount

Check if rclone is configured:
```bash
rclone listremotes
```

Test the connection:
```bash
rclone ls PROVIDER:
```

### Files don't appear

The first mount can be slow. Wait a few seconds, then:
```bash
ls ~/YourCloudDrive
```

### Permission denied

Ensure your user is in the `fuse` group:
```bash
sudo usermod -a -G fuse $USER
```

Log out and back in for changes to take effect.

### Browser doesn't open during setup

Manually copy the URL from the terminal and paste it into your browser.

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/mixebox/cloud-drive-integration/issues)
- **Discussions:** [GitHub Discussions](https://github.com/mixebox/cloud-drive-integration/discussions)
- **Reddit:** r/linux, r/linuxquestions

## 🗺️ Roadmap

- [ ] GUI configuration tool
- [ ] System tray indicator
- [ ] Bandwidth limiting options
- [ ] Sync status notifications
- [ ] Multi-account management interface
- [ ] Snap/Flatpak packaging (investigating FUSE limitations)
- [ ] AppImage distribution

## 🌟 Why This Exists

Linux has incredible file managers, but cloud storage integration has always been clunky. Web interfaces are slow, third-party apps are limited, and nothing "just works."

This tool changes that. Your cloud storage becomes part of your file system - no compromises, no limitations, no hassle.

**Because cloud storage should be invisible, not in your way.**

---

<div align="center">

**If this saved you time, give it a ⭐**

Made with ☕ and persistence by the Linux community

</div>
