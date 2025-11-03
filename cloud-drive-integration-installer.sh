#!/bin/bash
#
# Cloud Drive Integration for Linux File Managers
# Universal installer supporting multiple distributions and cloud providers
#
# Author: 98J30 & Claude
# License: MIT
# Version: 1.0.0
#
# Supported Distributions:
#   - Debian/Ubuntu/Mint/Pop!_OS
#   - Arch/Manjaro/EndeavourOS
#   - Fedora/RHEL/CentOS
#   - OpenSUSE
#   - Siduction
#
# Supported Cloud Providers:
#   - Google Drive
#   - Dropbox
#   - OneDrive
#   - Box
#   - pCloud
#   - Mega
#
# Supported Desktop Environments:
#   - XFCE (Thunar)
#   - GNOME (Nautilus)
#   - KDE (Dolphin)
#   - MATE (Caja)
#   - Cinnamon (Nemo)
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script info
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="Cloud Drive Integration"

# User directories
SCRIPT_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/cloud-drive-integration"
RCLONE_CONFIG="$HOME/.config/rclone"

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Cloud Drive Integration for Linux File Managers        ║
║                                                           ║
║   Seamlessly mount cloud storage as local folders        ║
║   with full drag-and-drop support                        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo -e "${GREEN}Version: $SCRIPT_VERSION${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}ERROR: Please run this script as a normal user (not root)${NC}"
    echo "The script will ask for sudo password when needed."
    exit 1
fi

# Function to detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_LIKE=$ID_LIKE
    else
        echo -e "${RED}ERROR: Cannot detect Linux distribution${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} Detected distribution: $PRETTY_NAME"
}

# Function to detect desktop environment
detect_desktop() {
    if [ ! -z "$XDG_CURRENT_DESKTOP" ]; then
        DESKTOP=$XDG_CURRENT_DESKTOP
    elif [ ! -z "$DESKTOP_SESSION" ]; then
        DESKTOP=$DESKTOP_SESSION
    else
        DESKTOP="unknown"
    fi
    
    echo -e "${GREEN}✓${NC} Detected desktop: $DESKTOP"
    
    # Determine file manager
    case "${DESKTOP,,}" in
        *xfce*)
            FILE_MANAGER="thunar"
            FM_CONFIG_DIR="$HOME/.config/Thunar"
            ;;
        *gnome*)
            FILE_MANAGER="nautilus"
            FM_CONFIG_DIR="$HOME/.local/share/nautilus"
            ;;
        *kde*|*plasma*)
            FILE_MANAGER="dolphin"
            FM_CONFIG_DIR="$HOME/.local/share/kservices5"
            ;;
        *mate*)
            FILE_MANAGER="caja"
            FM_CONFIG_DIR="$HOME/.local/share/caja"
            ;;
        *cinnamon*)
            FILE_MANAGER="nemo"
            FM_CONFIG_DIR="$HOME/.local/share/nemo"
            ;;
        *)
            echo -e "${YELLOW}⚠${NC}  Unknown desktop environment, defaulting to Thunar"
            FILE_MANAGER="thunar"
            FM_CONFIG_DIR="$HOME/.config/Thunar"
            ;;
    esac
    
    echo -e "${GREEN}✓${NC} File manager: $FILE_MANAGER"
}

# Function to install packages based on distro
install_packages() {
    echo ""
    echo -e "${BLUE}Installing required packages...${NC}"
    
    case "$DISTRO" in
        debian|ubuntu|linuxmint|pop|siduction)
            sudo apt-get update
            sudo apt-get install -y rclone fuse3 zenity libnotify-bin curl wget
            ;;
        arch|manjaro|endeavouros)
            sudo pacman -Sy --noconfirm rclone fuse3 zenity libnotify curl wget
            ;;
        fedora|rhel|centos)
            sudo dnf install -y rclone fuse3 zenity libnotify curl wget
            ;;
        opensuse*)
            sudo zypper install -y rclone fuse3 zenity libnotify-tools curl wget
            ;;
        *)
            echo -e "${RED}ERROR: Unsupported distribution${NC}"
            echo "Please install manually: rclone, fuse3, zenity, libnotify"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✓${NC} Packages installed successfully"
}

# Function to select cloud provider
select_cloud_provider() {
    echo ""
    echo -e "${BLUE}Select your cloud storage provider:${NC}"
    echo ""
    echo "  1) Google Drive (2TB+ storage)"
    echo "  2) Dropbox"
    echo "  3) Microsoft OneDrive"
    echo "  4) Box"
    echo "  5) pCloud"
    echo "  6) Mega"
    echo "  7) Other (manual rclone config)"
    echo ""
    
    while true; do
        read -p "Enter your choice (1-7): " choice
        case $choice in
            1)
                CLOUD_PROVIDER="gdrive"
                CLOUD_NAME="Google Drive"
                RCLONE_TYPE="drive"
                break
                ;;
            2)
                CLOUD_PROVIDER="dropbox"
                CLOUD_NAME="Dropbox"
                RCLONE_TYPE="dropbox"
                break
                ;;
            3)
                CLOUD_PROVIDER="onedrive"
                CLOUD_NAME="OneDrive"
                RCLONE_TYPE="onedrive"
                break
                ;;
            4)
                CLOUD_PROVIDER="box"
                CLOUD_NAME="Box"
                RCLONE_TYPE="box"
                break
                ;;
            5)
                CLOUD_PROVIDER="pcloud"
                CLOUD_NAME="pCloud"
                RCLONE_TYPE="pcloud"
                break
                ;;
            6)
                CLOUD_PROVIDER="mega"
                CLOUD_NAME="Mega"
                RCLONE_TYPE="mega"
                break
                ;;
            7)
                echo "Please run 'rclone config' manually, then re-run this script."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1-7.${NC}"
                ;;
        esac
    done
    
    echo -e "${GREEN}✓${NC} Selected: $CLOUD_NAME"
}

# Function to configure rclone
configure_rclone() {
    echo ""
    echo -e "${BLUE}Configuring rclone for $CLOUD_NAME...${NC}"
    echo ""
    
    mkdir -p "$RCLONE_CONFIG"
    
    # Check if remote already exists
    if rclone listremotes | grep -qi "^$CLOUD_PROVIDER:"; then
        echo -e "${YELLOW}⚠${NC}  Remote '$CLOUD_PROVIDER' already exists."
        read -p "Do you want to reconfigure it? (y/n): " reconfigure
        if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}✓${NC} Using existing configuration"
            return 0
        fi
        rclone config delete "$CLOUD_PROVIDER"
    fi
    
    echo ""
    echo -e "${YELLOW}Follow these steps:${NC}"
    echo ""
    echo "  1. Choose a name: Type '${CLOUD_PROVIDER}' and press Enter"
    echo "  2. Choose storage type: Find and enter the number for '$CLOUD_NAME'"
    echo "  3. Follow the prompts (usually just press Enter for defaults)"
    echo "  4. When asked 'Use auto config?': Type 'y'"
    echo "  5. Sign in when your browser opens"
    echo "  6. Confirm the configuration"
    echo ""
    read -p "Press Enter when ready to continue..."
    
    rclone config
    
    # Verify configuration
    if ! rclone listremotes | grep -qi "^$CLOUD_PROVIDER:"; then
        echo -e "${RED}ERROR: Configuration failed or remote not found${NC}"
        echo "Please run 'rclone config' manually and ensure the remote is named '$CLOUD_PROVIDER'"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} Rclone configured successfully"
}

# Function to create mount point and scripts
create_mount_scripts() {
    echo ""
    echo -e "${BLUE}Creating mount scripts...${NC}"
    
    # Create directories
    mkdir -p "$SCRIPT_DIR"
    mkdir -p "$CONFIG_DIR"
    MOUNT_POINT="$HOME/${CLOUD_NAME// /}"  # Remove spaces from cloud name
    mkdir -p "$MOUNT_POINT"
    
    echo -e "${GREEN}✓${NC} Mount point: $MOUNT_POINT"
    
    # Get the actual remote name (handle case sensitivity)
    REMOTE_NAME=$(rclone listremotes | grep -i "^$CLOUD_PROVIDER:" | head -n 1 | sed 's/://')
    
    # Create mount script
    cat > "$SCRIPT_DIR/mount-${CLOUD_PROVIDER}.sh" << EOF
#!/bin/bash
# Mount $CLOUD_NAME

MOUNT_POINT="$MOUNT_POINT"
REMOTE="$REMOTE_NAME:"

# Check if already mounted
if mountpoint -q "\$MOUNT_POINT"; then
    echo "$CLOUD_NAME is already mounted at \$MOUNT_POINT"
    exit 0
fi

# Mount with optimal settings
rclone mount "\$REMOTE" "\$MOUNT_POINT" \\
    --vfs-cache-mode full \\
    --vfs-cache-max-age 72h \\
    --vfs-cache-max-size 10G \\
    --vfs-read-ahead 256M \\
    --buffer-size 256M \\
    --dir-cache-time 72h \\
    --poll-interval 15s \\
    --allow-other \\
    --daemon

sleep 2

if mountpoint -q "\$MOUNT_POINT"; then
    notify-send "$CLOUD_NAME" "Mounted successfully at \$MOUNT_POINT" -i folder-remote
    echo "$CLOUD_NAME mounted at \$MOUNT_POINT"
else
    notify-send "$CLOUD_NAME" "Failed to mount" -i dialog-error
    echo "Failed to mount $CLOUD_NAME"
    exit 1
fi
EOF

    # Create unmount script
    cat > "$SCRIPT_DIR/unmount-${CLOUD_PROVIDER}.sh" << EOF
#!/bin/bash
# Unmount $CLOUD_NAME

MOUNT_POINT="$MOUNT_POINT"

if ! mountpoint -q "\$MOUNT_POINT"; then
    echo "$CLOUD_NAME is not mounted"
    exit 0
fi

fusermount -u "\$MOUNT_POINT"

if [ \$? -eq 0 ]; then
    notify-send "$CLOUD_NAME" "Unmounted successfully" -i folder
    echo "$CLOUD_NAME unmounted"
else
    notify-send "$CLOUD_NAME" "Failed to unmount" -i dialog-error
    echo "Failed to unmount $CLOUD_NAME"
    exit 1
fi
EOF

    chmod +x "$SCRIPT_DIR/mount-${CLOUD_PROVIDER}.sh"
    chmod +x "$SCRIPT_DIR/unmount-${CLOUD_PROVIDER}.sh"
    
    echo -e "${GREEN}✓${NC} Mount scripts created"
    
    # Save configuration
    cat > "$CONFIG_DIR/config.conf" << EOF
CLOUD_PROVIDER=$CLOUD_PROVIDER
CLOUD_NAME=$CLOUD_NAME
MOUNT_POINT=$MOUNT_POINT
REMOTE_NAME=$REMOTE_NAME
FILE_MANAGER=$FILE_MANAGER
INSTALLED_DATE=$(date)
VERSION=$SCRIPT_VERSION
EOF
}

# Function to create autostart entry
create_autostart() {
    echo ""
    echo -e "${BLUE}Setting up automatic mounting on login...${NC}"
    
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/cloud-drive-mount-${CLOUD_PROVIDER}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=$CLOUD_NAME Mount
Exec=$SCRIPT_DIR/mount-${CLOUD_PROVIDER}.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Automatically mount $CLOUD_NAME on login
EOF

    echo -e "${GREEN}✓${NC} Autostart entry created"
}

# Function to integrate with file manager
integrate_file_manager() {
    echo ""
    echo -e "${BLUE}Integrating with $FILE_MANAGER...${NC}"
    
    case "$FILE_MANAGER" in
        thunar)
            integrate_thunar
            ;;
        nautilus)
            integrate_nautilus
            ;;
        dolphin)
            integrate_dolphin
            ;;
        caja)
            integrate_caja
            ;;
        nemo)
            integrate_nemo
            ;;
    esac
    
    # Add bookmark
    mkdir -p "$HOME/.config/gtk-3.0"
    if ! grep -q "$MOUNT_POINT" "$HOME/.config/gtk-3.0/bookmarks" 2>/dev/null; then
        echo "file://$MOUNT_POINT $CLOUD_NAME" >> "$HOME/.config/gtk-3.0/bookmarks"
        echo -e "${GREEN}✓${NC} Bookmark added to sidebar"
    fi
}

# Thunar integration
integrate_thunar() {
    mkdir -p "$FM_CONFIG_DIR"
    
    # Backup existing config
    if [ -f "$FM_CONFIG_DIR/uca.xml" ]; then
        cp "$FM_CONFIG_DIR/uca.xml" "$FM_CONFIG_DIR/uca.xml.backup.$(date +%s)"
    fi
    
    # Create or update uca.xml
    if [ -f "$FM_CONFIG_DIR/uca.xml" ]; then
        # Add to existing
        sed -i 's|</actions>||' "$FM_CONFIG_DIR/uca.xml"
    else
        # Create new
        cat > "$FM_CONFIG_DIR/uca.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<actions>
EOF
    fi
    
    # Add mount/unmount actions
    cat >> "$FM_CONFIG_DIR/uca.xml" << EOF
<action>
	<icon>folder-remote</icon>
	<name>Mount $CLOUD_NAME</name>
	<unique-id>$(date +%s)-mount-$CLOUD_PROVIDER</unique-id>
	<command>$SCRIPT_DIR/mount-${CLOUD_PROVIDER}.sh</command>
	<description>Mount $CLOUD_NAME to $MOUNT_POINT</description>
	<patterns>*</patterns>
	<startup-notify/>
	<directories/>
</action>
<action>
	<icon>folder</icon>
	<name>Unmount $CLOUD_NAME</name>
	<unique-id>$(date +%s)-unmount-$CLOUD_PROVIDER</unique-id>
	<command>$SCRIPT_DIR/unmount-${CLOUD_PROVIDER}.sh</command>
	<description>Unmount $CLOUD_NAME</description>
	<patterns>*</patterns>
	<startup-notify/>
	<directories/>
</action>
</actions>
EOF

    echo -e "${GREEN}✓${NC} Thunar custom actions added"
}

# Nautilus integration
integrate_nautilus() {
    mkdir -p "$FM_CONFIG_DIR/scripts"
    
    # Create mount script
    cat > "$FM_CONFIG_DIR/scripts/Mount $CLOUD_NAME" << EOF
#!/bin/bash
$SCRIPT_DIR/mount-${CLOUD_PROVIDER}.sh
EOF
    
    # Create unmount script
    cat > "$FM_CONFIG_DIR/scripts/Unmount $CLOUD_NAME" << EOF
#!/bin/bash
$SCRIPT_DIR/unmount-${CLOUD_PROVIDER}.sh
EOF
    
    chmod +x "$FM_CONFIG_DIR/scripts/Mount $CLOUD_NAME"
    chmod +x "$FM_CONFIG_DIR/scripts/Unmount $CLOUD_NAME"
    
    echo -e "${GREEN}✓${NC} Nautilus scripts added"
}

# Dolphin integration
integrate_dolphin() {
    mkdir -p "$FM_CONFIG_DIR/ServiceMenus"
    
    cat > "$FM_CONFIG_DIR/ServiceMenus/cloud-drive-$CLOUD_PROVIDER.desktop" << EOF
[Desktop Entry]
Type=Service
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
MimeType=all/all;
Actions=mount-$CLOUD_PROVIDER;unmount-$CLOUD_PROVIDER;

[Desktop Action mount-$CLOUD_PROVIDER]
Name=Mount $CLOUD_NAME
Icon=folder-remote
Exec=$SCRIPT_DIR/mount-${CLOUD_PROVIDER}.sh

[Desktop Action unmount-$CLOUD_PROVIDER]
Name=Unmount $CLOUD_NAME
Icon=folder
Exec=$SCRIPT_DIR/unmount-${CLOUD_PROVIDER}.sh
EOF

    echo -e "${GREEN}✓${NC} Dolphin service menu added"
}

# Caja integration (same as Nautilus)
integrate_caja() {
    integrate_nautilus
    echo -e "${GREEN}✓${NC} Caja scripts added"
}

# Nemo integration (same as Nautilus)
integrate_nemo() {
    integrate_nautilus
    echo -e "${GREEN}✓${NC} Nemo scripts added"
}

# Function to test mount
test_mount() {
    echo ""
    echo -e "${BLUE}Testing mount...${NC}"
    
    "$SCRIPT_DIR/mount-${CLOUD_PROVIDER}.sh"
    
    sleep 3
    
    if mountpoint -q "$MOUNT_POINT"; then
        echo -e "${GREEN}✓${NC} Mount successful!"
        echo ""
        echo "Testing file listing..."
        if timeout 10 ls "$MOUNT_POINT" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Can access files"
        else
            echo -e "${YELLOW}⚠${NC}  Warning: Timeout accessing files (this is normal on first mount)"
        fi
    else
        echo -e "${YELLOW}⚠${NC}  Mount may have failed, but this could be normal"
        echo "    Try running: mount-${CLOUD_PROVIDER}.sh"
    fi
}

# Function to show completion message
show_completion() {
    echo ""
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║              Installation Complete! ✓                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${GREEN}Your $CLOUD_NAME is now integrated with $FILE_MANAGER!${NC}"
    echo ""
    echo -e "${BLUE}What you can do now:${NC}"
    echo "  • Open $FILE_MANAGER and look for '$CLOUD_NAME' in the sidebar"
    echo "  • Drag and drop files to/from $MOUNT_POINT"
    echo "  • Right-click anywhere to mount/unmount"
    echo "  • Your cloud drive will auto-mount on login"
    echo ""
    echo -e "${BLUE}Manual controls:${NC}"
    echo "  Mount:   ${GREEN}mount-${CLOUD_PROVIDER}.sh${NC}"
    echo "  Unmount: ${GREEN}unmount-${CLOUD_PROVIDER}.sh${NC}"
    echo ""
    echo -e "${BLUE}Mount point:${NC} $MOUNT_POINT"
    echo ""
    echo -e "${YELLOW}Note:${NC} You may need to restart $FILE_MANAGER to see all changes:"
    echo "  ${GREEN}killall $FILE_MANAGER${NC}"
    echo ""
    echo -e "${BLUE}Created by: 98J30 & Claude${NC}"
    echo -e "${BLUE}Version: $SCRIPT_VERSION${NC}"
    echo ""
    echo "Enjoy your seamlessly integrated cloud storage! 🚀"
    echo ""
}

# Main installation flow
main() {
    detect_distro
    detect_desktop
    
    # Check if rclone is already installed
    if ! command -v rclone &> /dev/null; then
        install_packages
    else
        echo -e "${GREEN}✓${NC} rclone is already installed"
        read -p "Install additional dependencies? (y/n): " install_deps
        if [[ $install_deps =~ ^[Yy]$ ]]; then
            install_packages
        fi
    fi
    
    select_cloud_provider
    configure_rclone
    create_mount_scripts
    create_autostart
    integrate_file_manager
    test_mount
    show_completion
}

# Run main installation
main

exit 0
