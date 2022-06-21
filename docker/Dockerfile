# Documentation:
# https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage
FROM docker.io/library/alpine:edge

# Enable community repository
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" \
    | tee -a /etc/apk/repositories

# Update the index of available packages
RUN apk update

# Install Alpine Linux toolchain
RUN apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot \
    syslinux xorriso squashfs-tools sudo mtools dosfstools grub-efi

WORKDIR /src

# Clone aports tree
RUN git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git

# Add root user to abuild group
RUN addgroup root abuild

# Create signing keys
RUN abuild-keygen -i -a -n

# Copy custom profile to container
COPY mkimg.iwd.sh aports/scripts/mkimg.iwd.sh

WORKDIR /build

ENTRYPOINT ["/src/aports/scripts/mkimage.sh", "--tag", "edge", "--arch", \
            "x86_64", "--repository", "https://dl-cdn.alpinelinux.org/alpine/edge/main", \
            "--extra-repository", "https://dl-cdn.alpinelinux.org/alpine/edge/community", \
            "--profile", "iwd"]