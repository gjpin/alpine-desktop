HOSTNAME=
USERNAME=
TIMEZONE=

# Get network interface name
NETWORK_INTERFACE_NAME=$(find /sys/class/net ! -type d | xargs realpath | awk -F\/ '/pci/{print $NF}')

tee ./answersfile << EOF
# Use US layout with US variant
KEYMAPOPTS="us us"

# Set hostname
HOSTNAMEOPTS="-n ${HOSTNAME}"

# Set device manager to udev
DEVDOPTS="udev"

# Contents of /etc/network/interfaces
INTERFACESOPTS="auto lo
iface lo inet loopback

auto ${NETWORK_INTERFACE_NAME}
iface ${NETWORK_INTERFACE_NAME} inet dhcp
    hostname ${HOSTNAME}
"	

# DNS
DNSOPTS="-n 1.1.1.1 1.0.0.1"

# Set timezone
TIMEZONEOPTS="-z ${TIMEZONE}"

# Do not set proxy
PROXYOPTS="none"

# Add a main/community/testing edge mirrors
APKREPOSOPTS="https://dl-cdn.alpinelinux.org/alpine/edge/main https://dl-cdn.alpinelinux.org/alpine/edge/community https://dl-cdn.alpinelinux.org/alpine/edge/testing"

# Do not install SSH server
SSHDOPTS="-c none"

# Use chrony
NTPOPTS="-c chrony"

# Use /dev/nvme0n1 as a data disk
DISKOPTS="-e -m sys -k edge -s 0 /dev/nvme0n1"

# Setup user
USEROPTS="-a -g wheel,audio,video,netdev,input -f ${USERNAME} -k none ${USERNAME}"
EOF

# Install Alpine
setup-alpine -f answersfile