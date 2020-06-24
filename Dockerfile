FROM debian:buster
WORKDIR /opt/bigbang/build

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install  -y \
  build-essential \
  autoconf \
  git \
  libsdl2-dev \
  debootstrap \
  libguestfs-tools \
  syslinux

COPY build/ .

CMD [ "bash", "build.sh" ]
