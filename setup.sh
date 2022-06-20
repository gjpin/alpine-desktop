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
# Install bash and shellcheck
apk add bash shellcheck

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

# Paths
export PATH="~/.local/bin:$PATH"
export PATH="~/.npm-global/bin:$PATH"
export PATH="$GOPATH:$PATH"

# Helper functions
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

# Enable D-Bus session
apk add dbus dbus-openrc
rc-service dbus start
rc-update add dbus default

# Install man pages
apk add mandoc man-pages docs

# Install common applications
apk add htop bind-tools curl tar git

##### Pipewire
# https://wiki.alpinelinux.org/wiki/PipeWire
# Install pipewire/wireplumber
apk add pipewire wireplumber pipewire-alsa pipewire-pulse \
  pipewire-spa-bluez pipewire-tools pavucontrol

# Configure pipewire
mkdir /etc/pipewire
cp /usr/share/pipewire/pipewire.conf /etc/pipewire/
tee -a /etc/pipewire/pipewire.conf << EOF
{ path = "wireplumber"  args = "" }
{ path = "/usr/bin/pipewire" args = "-c pipewire-pulse.conf" }
EOF

# Enable snd_seq kernel module
modprobe snd_seq
echo snd_seq >> /etc/modules

# Enable realtime scheduling
apk add rtkit
adduser ${USERNAME} rtkit

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
apk add sway xwayland xdg-desktop-portal-wlr swaylock swaybg \
  swayidle waybar grimshot foot dmenu wl-clipboard

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

# Install nodejs/npm and change npm's default directory
apk add nodejs-current npm
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'

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
curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/neovim -o /home/${USERNAME}/.config/nvim/init.lua
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

# Install language servers
go install golang.org/x/tools/gopls@latest
go install github.com/lighttiger2505/sqls@latest
go install github.com/hashicorp/terraform-ls@latest
npm install -g bash-language-server
npm install -g typescript-language-server typescript
npm install -g pyright
npm install -g dockerfile-language-server-nodejs

# Add LSP updater helper to bash
tee -a /home/${USERNAME}/.bashrc << EOF

update_lsp(){
  go install golang.org/x/tools/gopls@latest
  go install github.com/lighttiger2505/sqls@latest
  go install github.com/hashicorp/terraform-ls@latest
  npm install -g bash-language-server
  npm install -g typescript-language-server typescript
  npm install -g pyright
  npm install -g dockerfile-language-server-nodejs
}
EOF

# Install spotifyd and spotify-tui
apk add spotifyd spotify-tui

# Configure spotifyd
mkdir -p /home/${USERNAME}/.config/spotifyd
curl -Ssl https://raw.githubusercontent.com/gjpin/alpine-desktop/main/dotfiles/spotifyd -o /home/${USERNAME}/.config/spotifyd/spotifyd.conf

# Start spotifyd service when spotify-tui is launched
# TODO

# Make sure that all /home/$user actually belongs to $user 
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}