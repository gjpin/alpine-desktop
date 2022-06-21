# Same as extended profile but with iwd
# https://git.alpinelinux.org/aports/tree/scripts/mkimg.standard.sh

profile_iwd() {
	profile_standard
	profile_abbrev="iwd"
	title="iwd"
	desc="Most common used packages included.
		Suitable for routers and servers.
		Runs from RAM.
		Includes AMD and Intel microcode updates."
	arch="x86 x86_64"
	kernel_addons="xtables-addons zfs"
	boot_addons="amd-ucode intel-ucode"
	initrd_ucode="/boot/amd-ucode.img /boot/intel-ucode.img"
	apks="$apks
		coreutils ethtool hwids doas
		logrotate lsof lm_sensors lxc lxc-templates nano
		pciutils strace tmux
		usbutils v86d vim xtables-addons curl

		acct arpon arpwatch awall bridge-utils bwm-ng
		ca-certificates conntrack-tools cutter cyrus-sasl dhcp
		dhcpcd dhcrelay dnsmasq fping fprobe htop
		igmpproxy ip6tables iproute2 iproute2-qos
		iptables iputils irssi ldns-tools links
		ncurses-terminfo net-snmp net-snmp-tools nrpe nsd
		opennhrp openvpn pingu ppp quagga
		quagga-nhrp rng-tools sntpc socat ssmtp strongswan
		sysklogd tcpdump tinyproxy unbound
		wireguard-tools wireless-tools wpa_supplicant zonenotify

		btrfs-progs cksfv dosfstools cryptsetup
		e2fsprogs e2fsprogs-extra efibootmgr f2fs-tools
		grub-bios grub-efi lvm2 mdadm mkinitfs mtools nfs-utils
		parted rsync sfdisk syslinux util-linux xfsprogs zfs

        iwd
		"

	local _k _a
	for _k in $kernel_flavors; do
		apks="$apks linux-$_k"
		for _a in $kernel_addons; do
			apks="$apks $_a-$_k"
		done
	done
	apks="$apks linux-firmware"
}