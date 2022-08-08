read -p "Username: " USERNAME

# Install man pages
apk add mandoc man-pages docs

# Change user password
passwd ${USERNAME}

# Install and configure doas
apk add doas

mkdir -p /etc/doas.d

tee /etc/doas.d/doas.conf << EOF
permit persist :wheel
permit nopass ${USERNAME} cmd zzz
permit nopass ${USERNAME} cmd poweroff
permit nopass ${USERNAME} cmd reboot
EOF

# Create user directories
apk add xdg-user-dirs
xdg-user-dirs-update
mkdir -p /home/${USERNAME} && chmod 700 /home/${USERNAME}
mkdir -p /home/${USERNAME}/.local/share/themes
mkdir -p /home/${USERNAME}/.ssh && chmod 700 /home/${USERNAME}/.ssh/
mkdir -p /home/${USERNAME}/Pictures/screenshots

# Enable D-Bus session
apk add dbus dbus-openrc dbus-x11
rc-update add dbus boot

# Enable realtime scheduling
apk add rtkit
adduser ${USERNAME} rtkit

# Install common applications
apk add htop bind-tools curl tar git upower jq openssh \
  lm_sensors gzip p7zip unzip cpupower

# Install syncthing
apk add syncthing syncthing-openrc

rc-update add syncthing

# Install fonts
apk add ttf-dejavu font-cascadia-code-nerd font-jetbrains-mono-nerd font-iosevka-nerd

# Install shell utilities
apk add util-linux pciutils usbutils coreutils binutils findutils grep iproute2

# Install PAM
apk add linux-pam shadow-login

# Install firmware and microcode
# Example of selective firmware packages:
# https://wiki.alpinelinux.org/wiki/Immutable_root_with_atomic_upgrades
apk add linux-firmware

if cat /proc/cpuinfo | grep vendor | grep "AuthenticAMD" > /dev/null; then
 apk add amd-ucode
elif cat /proc/cpuinfo | grep vendor | grep "GenuineIntel" > /dev/null; then
 apk add intel-ucode
fi

# Install thermald
if cat /proc/cpuinfo | grep vendor | grep "GenuineIntel" > /dev/null; then
 apk add thermald
 rc-update add thermald
fi

# Install mesa drivers
apk add mesa-dri-gallium

# Enable vulkan
apk add vulkan-tools

if lspci | grep VGA | grep "Intel" > /dev/null; then
 apk add mesa-vulkan-intel
elif lspci | grep VGA | grep "Radeon" > /dev/null; then
  apk add mesa-vulkan-ati
fi

# Install GPU tools
apk add igt-gpu-tools

# Hardware acceleration support
apk add ffmpeg libva libva-utils

if lspci | grep VGA | grep "Intel" > /dev/null; then
 apk add intel-media-driver
fi

# Install and configure mpv
apk add mpv

mkdir -p /home/${USERNAME}/.config/mpv

tee /home/${USERNAME}/.config/mpv/mpv.conf << EOF
gpu-context=wayland
hwdec=vaapi
vo=gpu
EOF

##### zsh / shell
# Install zsh and shellcheck
apk add zsh zsh-completions shellcheck

# Change default shell for root
chsh --shell /bin/zsh root

# Change default shell for user
apk add shadow
chsh --shell /bin/zsh ${USERNAME}

# zshrc
tee /home/${USERNAME}/.zprofile << 'EOF'
# Load sway
[ "$(tty)" = "/dev/tty1" ] && dbus-launch --exit-with-session sway

# Load .zshrc
if [ -f ~/.zshrc ]; then
    . ~/.zshrc
fi
EOF

tee /home/${USERNAME}/.zshrc << 'EOF'
# Go
export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:$PATH"

# Node / npm
export PATH="$HOME/.npm-global/bin:$PATH"

# Neovim
export EDITOR="nvim"
export VISUAL="nvim"
alias vi="nvim"
alias vim="nvim"

# Other
alias sudo="doas"
alias ll="ls -la"
alias yt="ytfzf"
EOF

##### Networking
# # Avoid overwriting resolv.conf by DHCP
# mkdir -p /etc/udhcpc
# tee /etc/udhcpc/udhcpc.conf << EOF
# RESOLV_CONF="NO"
# EOF

# # Configure Cloudflare DNS servers
# tee /etc/resolv.conf << EOF
# nameserver 1.1.1.1
# nameserver 1.0.0.1
# EOF

##### Firewall
# Install and enable iptables services
apk add iptables ip6tables

rc-update add iptables
rc-update add ip6tables

rc-service iptables start
rc-service ip6tables start

# Load iptables modules
modprobe ip_tables

# Install awall
apk add awall

# Import default policy
NETWORK_INTERFACE_NAME=$(find /sys/class/net ! -type d | xargs realpath | awk -F\/ '/pci/{print $NF}')

tee /etc/awall/private/base.json << EOF
{
    "description": "Base zones and policies",
    "zone": {
        "LAN": {
            "iface": "${NETWORK_INTERFACE_NAME}"
        },
        "VPN": {
            "iface": "tailscale0"
        }
    },
    "policy": [
        {
            "in": "VPN",
            "action": "drop"
        },
        {
            "out": "VPN",
            "action": "accept"
        },
        {
            "in": "LAN",
            "action": "drop"
        },
        {
            "out": "LAN",
            "action": "accept"
        },
        {
            "in": "_fw",
            "action": "accept"
        },
        {
            "in": "_fw",
            "out": "LAN",
            "action": "accept"
        }
    ]
}
EOF

tee /etc/awall/private/custom-services.json << EOF
{
    "service": {
        "tailscale": [
            {
                "proto": "udp",
                "port": 41641
            }
        ],
        "syncthing": [
            {
                "proto": "tcp",
                "port": 22000
            }
        ]
    }
}
EOF

tee /etc/awall/optional/main.json << EOF
{
    "description": "Main firewall",
    "import": [
        "base",
        "custom-services"
    ]
}
EOF

awall enable main

awall activate --force

##### Alsa
# https://wiki.alpinelinux.org/wiki/ALSA

# Install Alsa packages
apk add alsa-utils alsa-utils-doc alsa-lib alsaconf alsa-ucm-conf

# Add root user to audio group
adduser root audio

# Enable Alsa services
rc-update add alsa

##### Pipewire
# https://wiki.alpinelinux.org/wiki/PipeWire

# Install pipewire/wireplumber
apk add pipewire wireplumber pipewire-alsa pipewire-pulse \
  pipewire-spa-bluez pipewire-tools pipewire-spa-vulkan gst-plugin-pipewire \
  pavucontrol pulseaudio-utils

# Enable snd_seq kernel module
modprobe snd_seq
echo snd_seq >> /etc/modules

##### Sway
# Set XDG_RUNTIME_DIR variable
tee /etc/profile.d/xdg_runtime_dir.sh << 'EOF'
if test -z "${XDG_RUNTIME_DIR}"; then
  export XDG_RUNTIME_DIR=/tmp/$(id -u)-runtime-dir
  if ! test -d "${XDG_RUNTIME_DIR}"; then
    mkdir "${XDG_RUNTIME_DIR}"
    chmod 0700 "${XDG_RUNTIME_DIR}"
  fi
fi
EOF

# Setup seatd daemon
apk add seatd
rc-update add seatd
adduser ${USERNAME} seat

# Install sway and related packages
apk add sway xwayland xdg-desktop-portal-wlr swaylock swaybg \
  swayidle waybar grimshot bemenu wl-clipboard xrandr

# Install ctl for backlight / audio
apk add light playerctl

# Install terminal
apk add foot

# Install ranger and libsixel (file manager and sixel implementation)
apk add ranger libsixel

# Import sway config
mkdir -p /home/${USERNAME}/.config/sway

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/configs/sway \
  -o /home/${USERNAME}/.config/sway/config

# Import foot config
mkdir -p /home/${USERNAME}/.config/foot

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/configs/foot \
  -o /home/${USERNAME}/.config/foot/foot.ini

# Import waybar config
mkdir -p /home/${USERNAME}/.config/waybar

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/configs/waybar.config \
  -o /home/${USERNAME}/.config/waybar/config

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/configs/waybar.style \
  -o /home/${USERNAME}/.config/waybar/style.css

# Import wallpaper
mkdir -p /home/${USERNAME}/Pictures/wallpapers

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/wallpapers/snowy-peak-flat-mountains-minimal-4k-it-2560x1440.jpg \
  -o /home/${USERNAME}/Pictures/wallpapers/wallpaper1.jpg

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/wallpapers/wallhaven-96woj1.jpg \
  -o /home/${USERNAME}/Pictures/wallpapers/wallpaper2.jpg

# Install qutebrowser and additional libraries
apk add qutebrowser py3-adblock py3-pygments pdfjs

##### Development
# Build tools
apk add build-base meson samurai clang

# Install go
apk add go

# Install nodejs/npm and change npm's default directory
apk add nodejs-current npm

mkdir /home/${USERNAME}/.npm-global

npm config set prefix "/home/${USERNAME}/.npm-global"

# Install python3 and pip
apk add python3 py3-pip

# Install rust and cargo
apk add rust cargo

# Hashi stack
apk add nomad consul terraform packer

# Tailscale
apk add tailscale

##### Spotify
# Install spotifyd and spotify-tui
apk add spotifyd spotify-tui

# Configure spotifyd
mkdir -p /home/${USERNAME}/.config/spotifyd

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/configs/spotifyd \
  -o /home/${USERNAME}/.config/spotifyd/spotifyd.conf

# Start spotifyd service when spotify-tui is launched
# TODO

##### ytfzf
# Install ytfzf and dependencies
apk add ytfzf fzf swayimg-full yt-dlp ncurses imagemagick

# Configure ytfzf
mkdir -p /home/${USERNAME}/.config/ytfzf

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/configs/ytfzf \
  -o /home/${USERNAME}/.config/ytfzf/conf.sh

##### neovim
# Install neovim
apk add neovim

# Import configuration
mkdir -p /home/${USERNAME}/.config/nvim

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/configs/neovim \
  -o /home/${USERNAME}/.config/nvim/init.lua

# Add LSP updater helper to zshrc
tee -a /home/${USERNAME}/.zshrc << EOF

# Update LSP
update_lsp(){
  go install golang.org/x/tools/gopls@latest
  go install github.com/lighttiger2505/sqls@latest
  go install github.com/hashicorp/terraform-ls@latest
  npm install -g bash-language-server
  npm install -g typescript-language-server typescript
  npm install -g pyright
}
EOF

# Install lua language server
apk add lua-language-server

##### Flatpak
apk add flatpak
adduser ${USERNAME} flatpak

##### VSCode
apk add code-oss code-oss-zsh-completion

code --install-extension golang.Go
code --install-extension dbaeumer.vscode-eslint
code --install-extension ms-python.python
code --install-extension geequlim.godot-tools

##### 2D/3D software
apk add godot blender gimp

##### Common packages
apk add firefox gcompat

# ##### Podman
# # Install podman
# apk add podman

# # Enable cgroups v2
# sed -i 's|#rc_cgroup_mode="hybrid"|rc_cgroup_mode="unified"|' /etc/rc.conf

# # Enable cgroups service
# rc-update add cgroups

# # Enable rootless support
# modprobe tun
# echo tun >>/etc/modules
# echo ${USERNAME}:100000:65536 >/etc/subuid
# echo ${USERNAME}:100000:65536 >/etc/subgid

###### Power management
# Install zzz
apk add zzz

# Confirm acpi is not overriding power off button
rm -rf /etc/acpi/

# If it's a laptop, install and configure TLP
# if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
# apk add tlp

# curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/configs/tlp \
#   -o /etc/tlp.conf

# rc-update add tlp
# fi

# Configure initramfs for hibernation
sed -i 's|lvm|lvm resume|' /etc/mkinitfs/mkinitfs.conf
mkinitfs

# Add kernel parameters required for hibernation
sed -i 's|cryptdm=root|cryptdm=root resume=/dev/vg0/lv_swap|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

##### Outro
# Configure connection with wpa_cli
echo -e "ctrl_interface=DIR=/run/wpa_supplicant GROUP=wheel\nupdate_config=1\n$(/etc/wpa_supplicant/wpa_supplicant.conf)" > /etc/wpa_supplicant/wpa_supplicant.conf

# Set swappiness
echo 'vm.swappiness=10' >/etc/sysctl.d/99-swappiness.conf

# wifi helper
tee -a /home/${USERNAME}/.zshrc << 'EOF'

# Wifi helper
wifi_help(){
  echo "wpa_cli

    scan
    scan_results
    add_network
    set_network 0 ssid "ssid"
    set_network 0 psk "psk"
    enable_network 0
    save config"
}
EOF

# Enable autologin on tty1
sed -i 's|tty1::respawn:/sbin/getty|tty1::respawn:/sbin/agetty --autologin '${USERNAME}' --noclear|' /etc/inittab

# Disable grub menu
sed -i 's|GRUB_TIMEOUT=2|GRUB_TIMEOUT=0|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Make sure that all /home/$user actually belongs to $user 
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}