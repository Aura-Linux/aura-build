FROM i386/debian:stretch
WORKDIR /opt/bigbang/build

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install  -y \
  build-essential \
  autoconf \
  git \
  libsdl2-dev \
  debootstrap \
  libguestfs-tools \
  syslinux \
  syslinux-efi \
  util-linux \
  gdisk \
  e2fsprogs \
  linux-image-686-pae

COPY build/ .

CMD [ "bash", "build.sh" ]
