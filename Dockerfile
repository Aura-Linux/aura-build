FROM debian:stretch
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
  syslinux-common \
  util-linux \
  gdisk \
  e2fsprogs \
  linux-image-amd64

COPY build/ .

CMD [ "bash", "build.sh" ]
