USERNAME=

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

##### bash
# Install bash
apk add bash

# Change default bash for user
apk add shadow
chsh --shell /bin/bash ${USERNAME}

# bashrc
tee /home/${USERNAME}/.bash_profile << EOF
# Load sway
[ "$(tty)" = "/dev/tty1" ] && exec sway

# Load .bashrc
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF

tee /home/${USERNAME}/.bashrc << 'EOF'
# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Environment variables
export SHELL="/bin/bash"
export EDITOR="nvim"
export VISUAL="nvim"

# Aliases
alias sudo="doas"
alias vi="nvim"
EOF

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

# Install pipewire/wireplumber
apk add pipewire wireplumber

# Install man pages
apk add mandoc man-pages docs

# Install common applications
apk add htop bind-tools curl tar git

### Sway
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

# Install mesa drivers
apk add mesa-dri-gallium

# Install fonts
apk add ttf-dejavu font-jetbrains-mono-nerd font-iosevka-nerd

# Setup seatd daemon
apk add seatd
rc-update add seatd
rc-service seatd start
adduser ${USERNAME} seat

# Install sway and related packages
apk add sway xwayland swaylock swaybg swayidle waybar grimshot foot dmenu wl-clipboard

# Import sway config
mkdir -p /home/${USERNAME}/.config/sway
curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/sway -o /home/${USERNAME}/.config/sway/config

# Import foot config
mkdir -p /home/${USERNAME}/.config/foot
curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/foot -o /home/${USERNAME}/.config/foot/foot.ini

# Install qutebrowser and additional libraries
apk add qutebrowser py3-adblock py3-pygments pdfjs

# Install mpv and enable HW acceleration
apk add mpv

mkdir -p /home/${USERNAME}/.config/mpv

tee /home/${USERNAME}/.config/mpv/mpv.conf << EOF
gpu-context=wayland
hwdec=vaapi
vo=gpu
EOF

##### Development
# Build tools
apk add build-base meson samurai clang

# Install go
apk add go

# Install nodejs and npm
apk add nodejs-current npm

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

# Install packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim \
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim

mkdir -p /home/${USERNAME}/.config/nvim

# tee /home/${USERNAME}/.config/nvim << EOF
# require('packer').startup(function()
#     use 'wbthomason/packer.nvim'
# end)
# EOF

# nvim --headless +PackerCompile +qa

# # Import configuration
# curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/neovim -o /home/${USERNAME}/.config/nvim/init.lua

# nvim --headless +PackerSync +qa

# Make sure that all /home/$user actually belongs to $user 
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}