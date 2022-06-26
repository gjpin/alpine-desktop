# Install
```
# Enable networking
setup-interfaces
rc-service networking start

# Download install script
wget https://raw.githubusercontent.com/gjpin/alpine-desktop/main/install.sh

# Run install script
chmod +x install.sh
./install.sh

# Reboot

# Login as root

# Download setup script
wget https://raw.githubusercontent.com/gjpin/alpine-desktop/main/setup.sh

# Run setup script
chmod +x setup.sh
./setup.sh

# Reboot

# Login as user

# Create all XDG directories
xdg-user-dirs-update

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo

# Bootstrap neovim
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

# Change npm default dir
npm config set prefix '~/.npm-global'

# Install language servers
go install golang.org/x/tools/gopls@latest
go install github.com/lighttiger2505/sqls@latest
go install github.com/hashicorp/terraform-ls@latest
npm install -g bash-language-server
npm install -g typescript-language-server typescript
npm install -g pyright
```

# Steam
apk add steam-devices
flatpak install com.valvesoftware.Steam
flatpak install com.valvesoftware.Steam.CompatibilityTool.Proton-GE
flatpak override --filesystem=/mnt/data/games/steam com.valvesoftware.Steam

xdg-open configuration:
https://unix.stackexchange.com/questions/36380/how-to-properly-and-easily-configure-xdg-open-without-any-environment

qutebrowser flags:
```
qutebrowser --qt-flag ignore-gpu-blocklist --qt-flag enable-zero-copy --qt-flag enable-accelerated-video-decode --qt-flag enable-native-gpu-memory-buffers 
```