#!/data/data/com.termux/files/usr/bin/bash

# Install Kali Nethunter (official version) on proot-distro

# This script streamlines the integration of Kali NetHunter, a widely-used penetration testing platform, with the proot-distro tool. It simplifies the setup and management of NetHunter distributions within a proot-based environment.

# Providing security professionals with an easy-to-use setup and management solution for NetHunter distributions.

# Key Features:
# - Automated integration of Kali NetHunter into proot-distro, eliminating manual configuration steps.
# - Calculation of the SHA256 checksum of the NetHunter rootfs to ensure data integrity during installation.
# - Facilitation of the installation process, providing a straightforward setup experience.

# Benefits:
# - Easy setup and management of Kali NetHunter distributions within a proot-based environment.
# - Swift installation process, reducing manual effort and saving time.

# Author: Sagar Biswas
# GitHub Repository: https://github.com/sagar040/proot-distro-nethunter

set -e

SCRIPT_VERSION="1.3"

banner() {
    clear
    local B='\e[38;1m'
    local C0='\e[38;5;236m'
    local C1='\e[38;5;18m'
    local C2='\e[38;5;19m'
    local C3='\e[38;5;20m'
    local C4='\e[38;5;21m'
    local C5='\e[38;5;57m'
    local C6='\e[38;5;56m'
    local C7='\e[38;5;93m'
    local C8='\e[38;5;92m'
    local C9='\e[38;5;91m'
    local C10='\e[38;5;128m'
    local C11='\e[38;5;127m'
    local R='\033[0m'
    local S=$(printf '%*s' 12 '')
    echo -e "$B$S$C1......., ,,.."
    echo -e "$S        ...cnx,"
    echo -e "$S$C2 $C5..$R$C2.'''$B$C2 ...:lb;."
    echo -e "$S$C3        $R$C3,;;$B$C3...x,"
    echo -e "$S   $R$C6..$R$C5''$B$C4.       0xc, .."
    echo -e "$S  $R$C7..$B$C4          ,0c,;ckc',"
    echo -e "$S $R$C5'$B$C4          0o        :nn"
    echo -e "$S           On           .:x."
    echo -e "$S           xX"
    echo -e "$S$C5            x0"
    echo -e "$S$C6             ,d$R"$C7"d$B:,."
    echo -e "$S$C9                  .:"$R$C9"c$C9,."
    echo -e "$S$C9                    d,$C9 ''"
    echo -e "$S$C10                      b $C10 '.$C3"
    echo -e "$S$C11                       c"
    echo -e "$S                       '\n"
}

# rootfs path
nh_rootfs="$PREFIX/var/lib/proot-distro/installed-rootfs/BackTrack-linux"

# info
info() {
    banner
    echo -e "\e[38;5;242;1m  -------------- Kali Nethunter Installer --------------\033[0m\n"
    echo -e "\e[38;5;253mInstall Kali NetHunter (Rootless Edition) on PRoot Distro. This is a Bash script that automates the installation of Kali NetHunter, a widely-used penetration testing platform, with the proot-distro tool.\033[0m\n"
    echo -e "\e[38;5;45mVersion:\033[0m \033[1;33m$SCRIPT_VERSION\033[0m\n"
    echo -e "\e[38;5;45mUsage:\033[0m $0 --install\n"
    echo -e "\e[38;5;45mGithub Repo:\033[0m \e[38;5;237mhttps://github.com/sagar040/proot-distro-nethunter\033[0m\n"
    echo -e ""
    exit 0
}

# Check device architecture and set system architecture
get_architecture() {
    supported_arch=("arm64-v8a" "armeabi" "armeabi-v7a")
    device_arch=$(getprop ro.product.cpu.abi)

    printf "\033[34m[*]\033[0m Checking device architecture...\n"

    if [[ " ${supported_arch[@]} " =~ " $device_arch " ]]; then
        case $device_arch in
            "arm64-v8a")
                SYS_ARCH="arm64"
                ;;
            "armeabi" | "armeabi-v7a")
                SYS_ARCH="armhf"
                ;;
        esac
        printf "\033[34m[*]\033[0m Device architecture: $SYS_ARCH\n"
    else
        echo -e "\033[31m[-]\033[0m Unsupported Architecture!"
        exit 1
    fi
}

# Install required packages
install_packages() {
    printf "\n\033[33m[*]\033[0m Installing required packages...\n"
    apt update && apt upgrade -y
    apt install -y proot-distro curl
}

# Get Nethunter image type from user
select_image_type() {
    echo -e "\n\033[33mnethunter images ($SYS_ARCH)\033[0m"
    echo "[1] nethunter (full)"
    echo "[2] nethunter (minimal)"
    echo "[3] nethunter (nano)"

    read -p "Enter the image you want to add [default: 1]: " image_type

    case "$image_type" in
        1) img="full";;
        2) img="minimal";;
        3) img="nano";;
        *) img="full";;
    esac
}

# Retrieve SHA256 checksum for the selected Nethunter image
get_sha256_checksum() {
    base_url="https://kali.download/nethunter-images/current/rootfs"
    sha256_url="$base_url/SHA256SUMS"
    rootfs="kalifs-$SYS_ARCH-$img.tar.xz"

    printf "\n\033[34m[*]\033[0m Retrieving SHA256 checksum...\n"
    SHA256=$(curl -s "$sha256_url" | grep "$rootfs" | awk '{print $1}')

    if [[ -z "$SHA256" ]]; then
        echo -e "\033[31m[-]\033[0m Failed to retrieve SHA256 checksum. Exiting."
        exit 1
    fi

    printf "\033[34m[*]\033[0m Image file: $rootfs\n"
    printf "\033[34m[*]\033[0m SHA256SUM: $SHA256\n"
}

# Generate and save the proot-distro configuration file
generate_config_file() {
    distro_file="# Kali nethunter $SYS_ARCH ($img)
DISTRO_NAME=\"kali Nethunter ($SYS_ARCH)\"
DISTRO_COMMENT=\"Kali nethunter $SYS_ARCH $img (official version)\"
TARBALL_URL['aarch64']=\"$base_url/$rootfs\"
TARBALL_SHA256['aarch64']=\"$SHA256\""

    printf "$distro_file" > "$PREFIX/etc/proot-distro/BackTrack-linux.sh"
}

# Setup Nethunter
setup_nethunter(){
    # hide Kali developers message
    touch $nh_rootfs/root/.hushlogin
    touch $nh_rootfs/home/kali/.hushlogin
    
    proot-distro login BackTrack-linux -- bash -c 'apt update
    apt upgrade -y
    apt autoremove -y
    [ -f "/root/.bash_profile" ] && sed -i "/if/,/fi/d" "/root/.bash_profile";
    echo "kali    ALL=(ALL:ALL) ALL" > /etc/sudoers.d/kali'
}

# Install Nethunter GUI packages
gui_installation() {
    echo -e "\033[33m[*]\033[0m Installing Nethunter GUI packages..."
    proot-distro login BackTrack-linux -- apt install -y xfce4 xfce4-terminal terminator tigervnc-standalone-server xfce4-whiskermenu-plugin dbus-x11 kali-defaults kali-themes kali-menu
    sleep 5
}

# Set up Nethunter GUI
gui_setup() {
    echo -e "\033[34m[*]\033[0m Setting up Nethunter GUI..."
    # Add xstartup file
    cp "./VNC/xstartup" "$nh_rootfs/root/.vnc/"
    # kgui executable
    cp "./VNC/kgui" "$nh_rootfs/usr/bin/"
    # Fix ㉿ symbol encoding issue on terminal
    cp "./fonts/NishikiTeki-font.ttf" "$nh_rootfs/usr/share/fonts/"

    proot-distro login BackTrack-linux -- bash -c 'chmod +x ~/.vnc/xstartup
    chmod +x /usr/bin/kgui'
}


if [[ $1 == "--install" ]]; then
    # Main script
    get_architecture
    install_packages
    select_image_type
    get_sha256_checksum
    generate_config_file
    
    printf "\n\033[32m[+]\033[0m Distribution added as BackTrack-linux\n"
    
    # Install Nethunter
    proot-distro install BackTrack-linux
    
    # Update and setup
    printf "\n\033[33m[*]\033[0m Setting up nethunter...\n"
    setup_nethunter
    
    echo -e "\n\033[33;1mNote:\033[0m  GUI install will require \033[33;1m300 MB\033[0m or more, \033[33;1m1 GB\033[0m or more of disk space will be used after this operation.\n"
    # Nethunter GUI installation
    read -rp $'\033[90;1mDo you want to install Nethunter \033[0m\033[32mGUI\033[90;1m ? (y/n): \033[0m' igui
    if [[ $igui =~ ^[Yy]$ ]]; then
        gui_installation
        gui_setup
        echo -e "\n\033[32m[+]\033[0m Nethunter GUI installed successfully."
    else
        echo -e "\n\033[32m[+]\033[0m Nethunter installed successfully (without GUI)."
    fi
    
    # Shortcut
    echo "alias nethunter='if [ -n \"$1\" ]; then proot-distro login BackTrack-linux --user \"$1\"; else proot-distro login BackTrack-linux; fi'" >> ~/.bashrc
    
    # Print instructions
    echo -e "\nLogin: \033[32mnethunter [user]\033[0m (default=root)"
    echo -e "\n\033[34m[*]\033[0m For GUI access, run \033[32mkgui\033[0m command. (after login into nethunter)"
else
    info
fi
