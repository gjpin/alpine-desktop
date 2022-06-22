USERNAME=

# Install man pages
apk add mandoc man-pages docs

# Change user password
passwd ${USERNAME}

# Install and configure doas
apk add doas
mkdir -p /etc/doas.d
echo "permit persist :wheel" >> /etc/doas.d/doas.conf

# Create user directories
mkdir -p /home/${USERNAME} && chmod 700 /home/${USERNAME}
mkdir -p /home/${USERNAME}/.local/share/themes
mkdir -p /home/${USERNAME}/.local/bin
mkdir -p /home/${USERNAME}/.ssh && chmod 700 /home/${USERNAME}/.ssh/
apk add xdg-user-dirs

# Enable D-Bus session
apk add dbus dbus-openrc dbus-x11
rc-service dbus start
rc-update add dbus

# Enable realtime scheduling
apk add rtkit
adduser ${USERNAME} rtkit

# Install common applications
apk add htop bind-tools curl tar git upower

# Install fonts
apk add ttf-dejavu font-jetbrains-mono-nerd font-iosevka-nerd

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

# Install mesa drivers
apk add mesa-dri-gallium

# Hardware acceleration support
apk add ffmpeg libva libva-utils

if lspci | grep VGA | grep "Intel" > /dev/null; then
 apk add intel-media-driver
fi

# Install mpv and enable HW acceleration
apk add mpv

mkdir -p /home/${USERNAME}/.config/mpv

tee /home/${USERNAME}/.config/mpv/mpv.conf << EOF
gpu-context=wayland
hwdec=vaapi
vo=gpu
EOF

##### bash
# Install bash and shellcheck
apk add bash bash-completion shellcheck

# Change default bash for user
apk add shadow
chsh --shell /bin/bash ${USERNAME}

# bashrc
tee /home/${USERNAME}/.bash_profile << EOF
# Load sway
[ "$(tty)" = "/dev/tty1" ] && dbus-launch --exit-with-session sway

# Load .bashrc
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF

tee /home/${USERNAME}/.bashrc << 'EOF'
# Environment variables
export SHELL="/bin/bash"
export EDITOR="nvim"
export VISUAL="nvim"
export GOPATH="~/go"
export GOBIN="$GOPATH/bin"

# Aliases
alias sudo="doas"
alias vi="nvim"
alias vim="nvim"

# Paths
export PATH="~/.local/bin:$PATH"
export PATH="~/.npm-global/bin:$PATH"
export PATH="$GOPATH:$PATH"

# Helper functions
EOF

##### Networking
# Avoid overwriting resolv.conf by DHCP
mkdir -p /etc/udhcpc
tee /etc/udhcpc/udhcpc.conf << EOF
RESOLV_CONF="NO"
EOF

# Configure Cloudflare DNS servers
tee /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

##### Alsa
# https://wiki.alpinelinux.org/wiki/ALSA

# Install Alsa packages
apk add alsa-utils alsa-utils-doc alsa-lib alsaconf alsa-ucm-conf

# Add root user to audio group
adduser root audio

# Enable Alsa services
rc-update add alsa
rc-service alsa start

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
rc-service seatd start
adduser ${USERNAME} seat

# Install sway and related packages
apk add sway xwayland xdg-desktop-portal-wlr swaylock swaybg \
  swayidle waybar grimshot foot dmenu wl-clipboard xrandr \
  light playerctl pactl

# Import sway config
mkdir -p /home/${USERNAME}/.config/sway

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/sway \
  -o /home/${USERNAME}/.config/sway/config

# Import foot config
mkdir -p /home/${USERNAME}/.config/foot

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/foot \
  -o /home/${USERNAME}/.config/foot/foot.ini

# Import waybar config
mkdir -p /home/${USERNAME}/.config/waybar

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/waybar.config \
  -o /home/${USERNAME}/.config/waybar/config

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/waybar.style \
  -o /home/${USERNAME}/.config/waybar/style.css

# Import wallpaper
mkdir -p /home/${USERNAME}/Pictures

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/wallpapers/luca-bravo-bTxMLuJOff4-unsplash.jpg \
  -o /home/${USERNAME}/Pictures/luca-bravo-bTxMLuJOff4-unsplash.jpg

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
su ${USERNAME} -c "npm config set prefix '~/.npm-global'"

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

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/spotifyd \
  -o /home/${USERNAME}/.config/spotifyd/spotifyd.conf

# Start spotifyd service when spotify-tui is launched
# TODO

##### neovim
# Install neovim
apk add neovim

# Import configuration
mkdir -p /home/${USERNAME}/.config/nvim

curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/neovim \
  -o /home/${USERNAME}/.config/nvim/init.lua

# Bootstrap neovim
su ${USERNAME} -c "nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'"

# Install language servers
su ${USERNAME} -c "go install golang.org/x/tools/gopls@latest"
su ${USERNAME} -c "go install github.com/lighttiger2505/sqls@latest"
su ${USERNAME} -c "go install github.com/hashicorp/terraform-ls@latest"
su ${USERNAME} -c "npm install -g bash-language-server"
su ${USERNAME} -c "npm install -g typescript-language-server typescript"
su ${USERNAME} -c "npm install -g pyright"

# Add LSP updater helper to bash
tee -a /home/${USERNAME}/.bashrc << EOF

update_lsp(){
  go install golang.org/x/tools/gopls@latest
  go install github.com/lighttiger2505/sqls@latest
  go install github.com/hashicorp/terraform-ls@latest
  npm install -g bash-language-server
  npm install -g typescript-language-server typescript
  npm install -g pyright
}
EOF

##### Flatpak
apk add flatpak

adduser ${USERNAME} flatpak

su ${USERNAME} -c "flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"

su ${USERNAME} -c "flatpak remote-add --user --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo"

# Make sure that all /home/$user actually belongs to $user 
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}