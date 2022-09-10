# create directories
mkdir -p /home/${USERNAME}/.local/share/themes
mkdir -p /home/${USERNAME}/Pictures/screenshots

# passwordless commands
tee -a /etc/doas.d/doas.conf << EOF
permit nopass ${USERNAME} cmd zzz
permit nopass ${USERNAME} cmd poweroff
permit nopass ${USERNAME} cmd reboot
EOF

# sway autostart
tee -a /home/${USERNAME}/.zprofile << 'EOF'
# Load sway
[ "$(tty)" = "/dev/tty1" ] && dbus-launch --exit-with-session sway
EOF

# yrfzf alias
tee -a /home/${USERNAME}/.zshrc << 'EOF'
alias yt="ytfzf"
EOF

# Audio
apk add pavucontrol pulseaudio-utils

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

##### GTK apps and settings
apk add nautilus file-roller \
    gnome-text-editor \
    gnome-calculator \
    adw-gtk3 adwaita-icon-theme

mkdir -p /home/${USERNAME}/.config/gtk-3.0
tee -a /home/${USERNAME}/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name = adw-gtk3
gtk-icon-theme-name = Adwaita
EOF

# firefox-gnome-theme
git clone https://github.com/rafaelmardojai/firefox-gnome-theme && cd firefox-gnome-theme
./scripts/install.sh
cd .. && rm -rf firefox-gnome-theme/

###### Power management
# Install zzz
apk add zzz

# Confirm acpi is not overriding power off button
rm -rf /etc/acpi/

# Configure initramfs for hibernation
sed -i 's|lvm|lvm resume|' /etc/mkinitfs/mkinitfs.conf
mkinitfs

# Add kernel parameters required for hibernation
sed -i 's|cryptdm=root|cryptdm=root resume=/dev/vg0/lv_swap|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

##### Outro
# Configure connection with wpa_cli
echo -e "ctrl_interface=DIR=/run/wpa_supplicant GROUP=wheel\nupdate_config=1\n$(/etc/wpa_supplicant/wpa_supplicant.conf)" > /etc/wpa_supplicant/wpa_supplicant.conf

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