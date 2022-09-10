# Setup system to use Xorg
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-xorg-base.in
apk add xorg-server xf86-input-libinput

# Install Plasma and enable services
# https://wiki.alpinelinux.org/wiki/KDE
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-desktop.in
apk add plasma plasma-extras kde-applications-base elogind polkit-elogind \
    xdg-desktop-portal-kde

rc-update add elogind
rc-update add polkit
rc-update add udev
rc-update add sddm

# # Use grub breeze theme (MISSING CORRECT THEME FILENAME)
# tee -a /etc/default/grub << EOF
# GRUB_THEME=/usr/share/grub/themes/breeze
# GRUB_GFXMODE=1920x1080
# GRUB_GFXPAYLOAD_LINUX=keep
# EOF

# grub-mkconfig -o /boot/grub/grub.cfg

# # plymouth (WIP)
# apk add plymouth
# plymouth-set-default-theme breeze
# sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="|& quiet splash|' cenas

# # overview with meta key
# kwriteconfig5 --file kwinrc --group ModifierOnlyShortcuts --key Meta "org.kde.kglobalaccel,/component/kwin,,invokeShortcut,Overview