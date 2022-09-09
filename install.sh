read -p "Hostname: " HOSTNAME
read -p "Username: " USERNAME
read -p "Timezone: " TIMEZONE

TOTAL_MEM_GB=$(free -g | grep Mem: | awk '{print $2}')
SWAP_SIZE_MB=$((($TOTAL_MEM_GB + 1) * 1024))
NETWORK_INTERFACE_NAME=$(find /sys/class/net ! -type d | xargs realpath | awk -F\/ '/pci/{print $NF}')

tee ./answersfile << EOF
# Use US layout with US variant
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-keymap.in#L15
KEYMAPOPTS="us us"

# Set hostname
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-hostname.in#L8
HOSTNAMEOPTS="-n ${HOSTNAME}"

# Set device manager to udev
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-devd.in#L10
DEVDOPTS="-C udev"

# Contents of /etc/network/interfaces
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-interfaces.in#L410
INTERFACESOPTS="auto lo
iface lo inet loopback

auto ${NETWORK_INTERFACE_NAME}
iface ${NETWORK_INTERFACE_NAME} inet dhcp
    hostname ${HOSTNAME}
"	

# DNS
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-dns.in#L7
DNSOPTS="-n 1.1.1.1 1.0.0.1"

# Set timezone
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-timezone.in#L9
TIMEZONEOPTS="-z ${TIMEZONE}"

# Do not set proxy
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-proxy.in#L7
PROXYOPTS="none"

# Add a main/community/testing edge mirrors
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-apkrepos.in#L140
APKREPOSOPTS="https://dl-cdn.alpinelinux.org/alpine/edge/main https://dl-cdn.alpinelinux.org/alpine/edge/community https://dl-cdn.alpinelinux.org/alpine/edge/testing"

# Do not install SSH server
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-sshd.in#L7
SSHDOPTS="-c none"

# Use chrony
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-ntp.in#L7
NTPOPTS="-c chrony"

# Use /dev/nvme0n1 as a data disk
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-disk.in#L1394
DISKOPTS="-e -m sys -k edge -s ${SWAP_SIZE_MB} /dev/nvme0n1"

# Setup user
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-user.in#L7
USEROPTS="-a -g wheel,audio,video,netdev,input -f ${USERNAME} -k none ${USERNAME}"
EOF

# Install Alpine
setup-alpine -f answersfile