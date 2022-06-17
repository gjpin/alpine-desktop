USERNAME=

# Change user password
passwd ${USERNAME}

# Install common applications
apk add htop bash bind-tools

# Create user directories
mkdir -p /home/${USERNAME} && chmod 700 /home/${USERNAME}
mkdir -p /home/${USERNAME}/.local/share/themes
mkdir -p /home/${USERNAME}/.local/bin
mkdir -p /home/${USERNAME}/.ssh && chmod 700 /home/${USERNAME}/.ssh/
mkdir -p /home/${USERNAME}/.bashrc.d
apk add xdg-user-dirs

### bash
# Change default bash for user
apk add shadow
chsh --shell /bin/bash ${USERNAME}

# bashrc
tee -a /home/${USERNAME}/.bashrc << 'EOF'
# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc
EOF

# aliases
tee /home/${USERNAME}/.bashrc.d/alias << EOF
alias sudo="doas"
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
apk add ttf-dejavu font-jetbrains-mono-nerd

# Setup seatd daemon
apk add seatd
rc-update add seatd
rc-service seatd start
adduser ${USERNAME} seat

# Install sway and related packages
apk add sway sway-doc xwayland swaylock swaybg swayidle waybar foot

# Autostart sway
tee /home/${USERNAME}/.bashrc.d/sway << EOF
if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  dbus-launch sway
fi
EOF

# Sway config
# exec pipewire-launcher

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

# Make sure that all /home/$user actually belongs to $user 
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}