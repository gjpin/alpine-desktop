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
EOF

# Create user directories
apk add xdg-user-dirs
mkdir -p /home/${USERNAME} && chmod 700 /home/${USERNAME}
mkdir -p /home/${USERNAME}/.ssh && chmod 700 /home/${USERNAME}/.ssh/

# Enable D-Bus session
apk add dbus dbus-openrc dbus-x11
rc-update add dbus

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

# Install vulkan packages
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
apk add zsh zsh-completions oh-my-zsh shellcheck

# Change default shell for root
chsh --shell /bin/zsh root

# Change default shell for user
apk add shadow
chsh --shell /bin/zsh ${USERNAME}

# zshrc
tee /home/${USERNAME}/.zprofile << 'EOF'
# Load .zshrc
if [ -f ~/.zshrc ]; then
    . ~/.zshrc
fi
EOF

tee /home/${USERNAME}/.zshrc << 'EOF'
# Oh My Zsh
export ZSH="/usr/share/oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

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

# VSCode
alias code="code-oss"

# Updater helper
update-all() {
  # Update system packages
  doas apk upgrade -U

  # Update Flatpak apps
  flatpak update -y
  
  # Update Node.js global packages
  npm update -g
}

# Other
alias sudo="doas"
alias ll="ls -la"
EOF

# ##### Firewall
# # Install and enable iptables services
# apk add iptables ip6tables

# rc-update add iptables
# rc-update add ip6tables

# rc-service iptables start
# rc-service ip6tables start

# # Load iptables modules
# modprobe ip_tables

# # Install awall
# apk add awall

# # Import default policy
# NETWORK_INTERFACE_NAME=$(find /sys/class/net ! -type d | xargs realpath | awk -F\/ '/pci/{print $NF}')

# tee /etc/awall/private/base.json << EOF
# {
#     "description": "Base zones and policies",
#     "zone": {
#         "LAN": {
#             "iface": "${NETWORK_INTERFACE_NAME}"
#         },
#         "VPN": {
#             "iface": "tailscale0"
#         }
#     },
#     "policy": [
#         {
#             "in": "VPN",
#             "action": "drop"
#         },
#         {
#             "out": "VPN",
#             "action": "accept"
#         },
#         {
#             "in": "LAN",
#             "action": "drop"
#         },
#         {
#             "out": "LAN",
#             "action": "accept"
#         },
#         {
#             "in": "_fw",
#             "action": "accept"
#         },
#         {
#             "in": "_fw",
#             "out": "LAN",
#             "action": "accept"
#         }
#     ]
# }
# EOF

# tee /etc/awall/private/custom-services.json << EOF
# {
#     "service": {
#         "tailscale": [
#             {
#                 "proto": "udp",
#                 "port": 41641
#             }
#         ],
#         "syncthing": [
#             {
#                 "proto": "tcp",
#                 "port": 22000
#             }
#         ]
#     }
# }
# EOF

# tee /etc/awall/optional/main.json << EOF
# {
#     "description": "Main firewall",
#     "import": [
#         "base",
#         "custom-services"
#     ]
# }
# EOF

# awall enable main

# awall activate --force

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
  pipewire-spa-bluez pipewire-tools pipewire-spa-vulkan gst-plugin-pipewire

# Enable snd_seq kernel module
modprobe snd_seq
echo snd_seq >> /etc/modules

##### Development
# Build tools
apk add build-base meson samurai clang

# Install go
apk add go gopls

# Install nodejs/npm and change npm's default directory
apk add nodejs npm

mkdir /home/${USERNAME}/.npm-global

tee /home/${USERNAME}/.npmrc << EOF
prefix=/home/${USERNAME}/.npm-global
EOF

# Install python3 and pip
apk add python3 py3-pip

# Install rust and cargo
apk add rust cargo

# Hashi stack
apk add nomad consul terraform packer

# Tailscale
apk add tailscale

##### neovim
# Install neovim
apk add neovim

# Import configuration
mkdir -p /home/${USERNAME}/.config/nvim

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/configs/neovim \
  -o /home/${USERNAME}/.config/nvim/init.lua

# Install lua language server
apk add lua-language-server

##### Flatpak
apk add flatpak
adduser ${USERNAME} flatpak

##### VSCode
apk add code-oss code-oss-zsh-completion

mkdir -p "/home/${USERNAME}/.config/Code - OSS/User"

tee "/home/${USERNAME}/.config/Code - OSS/User/settings.json" << EOF
{
    "telemetry.telemetryLevel": "off",
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'CaskaydiaCove Nerd Font', 'Noto Sans Mono', 'Droid Sans Mono', 'monospace', 'Droid Sans Fallback'",
    "workbench.enableExperiments": false,
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": null,
    "workbench.tree.indent": 12,
    "window.titleBarStyle": "native",
    "editor.fontWeight": "500",
    "redhat.telemetry.enabled": false,
    "files.associations": {
        "*.j2": "terraform",
        "*.hcl": "terraform",
        "*.bu": "yaml",
        "*.ign": "json",
        "*.service": "ini"
    },
    "extensions.ignoreRecommendations": true,
    "editor.formatOnSave": true,
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true
}
EOF

code-oss --install-extension golang.Go
code-oss --install-extension dbaeumer.vscode-eslint
code-oss --install-extension ms-python.python

##### 2D/3D software
apk add godot blender gimp

##### Common packages
apk add firefox

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
# If it's a laptop, install and configure TLP
# if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
# apk add tlp

# curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/configs/tlp \
#   -o /etc/tlp.conf

# rc-update add tlp
# fi

##### Outro
# Set swappiness
echo 'vm.swappiness=10' >/etc/sysctl.d/99-swappiness.conf

# Disable grub menu
# sed -i 's|GRUB_TIMEOUT=2|GRUB_TIMEOUT=0|' /etc/default/grub
# grub-mkconfig -o /boot/grub/grub.cfg

# Make sure that all /home/$user actually belongs to $user 
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}