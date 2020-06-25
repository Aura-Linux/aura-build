#!/bin/bash
set -e

export BUILD_DIR=/opt/bigbang/build
export RESULT_DIR=/opt/bigbang/result
export DEBIAN_ROOT=/opt/bigbang/debian_root
export IMAGE_FILE=$RESULT_DIR/aura.img
#export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1

echo "*Aura*  Starting Aura build..."
cd $BUILD_DIR || exit
date
date > $RESULT_DIR/OK

echo "*Aura* Starting Basilisk II build..."
git clone https://github.com/kanjitalk755/macemu.git
cd $BUILD_DIR/macemu/BasiliskII/src/Unix
NO_CONFIGURE=1 ./autogen.sh
./configure --enable-jit-compiler --build i686-pc-linux-gnu --host i686-pc-linux-gnu
make -j
cp BasiliskII $RESULT_DIR
cd $BUILD_DIR

echo "*Aura* Starting OS Build..."
echo "*Aura*   -> Stage 1 (Debootstrap)"
mkdir $DEBIAN_ROOT
debootstrap \
  --include linux-image-686-pae,xorg,sudo,libsdl2-2.0-0,cloud-utils,telnetd,fim \
  --arch i386 \
  stretch \
  "$DEBIAN_ROOT" \
  http://deb.debian.org/debian/
ls -l $DEBIAN_ROOT
#echo "*Aura* Boot Folder Contents:"
#ls -l $DEBIAN_ROOT/boot
#du -h $DEBIAN_ROOT

echo "*Aura*  -> Stage 2 (Settings)"
echo "aura" > $DEBIAN_ROOT/etc/hostname
echo "127.0.0.1 localhost" >> $DEBIAN_ROOT/etc/hosts
echo "127.0.0.1 aura" >> $DEBIAN_ROOT/etc/hosts
sed -i '/root/d' $DEBIAN_ROOT/etc/passwd
echo "root::0:0:root:/root:/bin/bash" >> $DEBIAN_ROOT/etc/passwd

mv $DEBIAN_ROOT/boot/vmlinuz* $DEBIAN_ROOT/boot/vmlinuz
mv $DEBIAN_ROOT/boot/initrd.img* $DEBIAN_ROOT/boot/initrd.img

mkdir $DEBIAN_ROOT/opt/bigbang
mv $BUILD_DIR/macemu/BasiliskII/src/Unix/BasiliskII $DEBIAN_ROOT/opt/bigbang/
mv $BUILD_DIR/system7.hda $DEBIAN_ROOT/opt/bigbang/
mv $BUILD_DIR/Mac\ OS\ ROM $DEBIAN_ROOT/opt/bigbang/

mv $BUILD_DIR/motd $DEBIAN_ROOT/etc/motd
mv $BUILD_DIR/interfaces $DEBIAN_ROOT/etc/network/interfaces
mv $BUILD_DIR/xinitrc $DEBIAN_ROOT/root/.xinitrc
mv $BUILD_DIR/basilisk_ii_prefs $DEBIAN_ROOT/root/.basilisk_ii_prefs
mv $BUILD_DIR/bash_profile $DEBIAN_ROOT/root/.bash_profile

mv $BUILD_DIR/aura-boot.service $DEBIAN_ROOT/etc/systemd/system/aura-boot.service
mv $BUILD_DIR/aura-boot.sh $DEBIAN_ROOT/opt/bigbang/aura-boot.sh
chmod +x $DEBIAN_ROOT/opt/bigbang/aura-boot.sh
ln -s $DEBIAN_ROOT/etc/systemd/system/aura-boot.service $DEBIAN_ROOT/etc/systemd/system/multi-user.target.wants/aura-boot.service

mv $BUILD_DIR/aura-early-boot.service $DEBIAN_ROOT/etc/systemd/system/aura-early-boot.service
mv $BUILD_DIR/aura-early-boot.sh $DEBIAN_ROOT/opt/bigbang/aura-early-boot.sh
mv $BUILD_DIR/welcome.png $DEBIAN_ROOT/opt/bigbang/welcome.png
chmod +x $DEBIAN_ROOT/opt/bigbang/aura-early-boot.sh
mkdir $DEBIAN_ROOT/etc/systemd/system/basic.target.wants/
ln -s $DEBIAN_ROOT/etc/systemd/system/aura-early-boot.service $DEBIAN_ROOT/etc/systemd/system/basic.target.wants/aura-early-boot.service

# Copy EFI boot files
mkdir -p $DEBIAN_ROOT/boot/EFI/BOOT
cp /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi $DEBIAN_ROOT/boot/EFI/BOOT/BOOTX64.EFI
cp /usr/lib/SYSLINUX.EFI/efi32/syslinux.efi $DEBIAN_ROOT/boot/EFI/BOOT/BOOTX32.EFI

# Add a build log
echo "Aura built on: " >> $DEBIAN_ROOT/aura-build-info
date >> $DEBIAN_ROOT/aura-build-info
echo "The build server was: " >> $DEBIAN_ROOT/aura-build-info
uname -a >> $DEBIAN_ROOT/aura-build-info

echo "*Aura*  -> Stage 3 (Image)"
#virt-make-fs \
#  --partition \
#  --format raw \
#  --size +128M \
#  --type ext2 \
#  "$DEBIAN_ROOT" \
#  "$IMAGE_FILE"
mkdir -p /mnt
guestfish -N $IMAGE_FILE=bootroot:fat:ext2:2G:128M:gpt<<_EOF_
exit
_EOF_
sync

LOOP_DEV=$(losetup -f)
echo "Loop Device: $LOOP_DEV"
losetup -f -P $IMAGE_FILE
losetup -l
echo "-"
ls -1 /dev/loop*

echo "Getting partition GUID"
# Get partition GUID
BOOT_GUID=$(blkid -s UUID -o value "$LOOP_DEV"p1)
ROOT_GUID=$(blkid -s UUID -o value "$LOOP_DEV"p2)
echo "    APPEND ro root=UUID=$ROOT_GUID net.ifnames=0 biosdevname=0 quiet" >> $BUILD_DIR/syslinux.cfg
echo "UUID=$ROOT_GUID / ext2 defaults 0 1" > $DEBIAN_ROOT/etc/fstab
echo "UUID=$BOOT_GUID /boot vfat defaults 0 1" >> $DEBIAN_ROOT/etc/fstab

echo "Mounting loopback devices"
mount "$LOOP_DEV"p2 /mnt
mkdir -p /mnt/boot
mount "$LOOP_DEV"p1 /mnt/boot

echo "*Aura*    -> Running rsync"
rsync -avxHAX $DEBIAN_ROOT/ /mnt/

umount /mnt/boot
umount /mnt

# Set BIOS Boot flag and EFI partition
sgdisk --attributes=1:set:2 "$LOOP_DEV"
#sgdisk -t 1:ef00 "$LOOP_DEV"

losetup -d "$LOOP_DEV"

echo "*Aura*  -> Stage 4 (syslinux)"
#"sda" is the disk image in the guestfish environment
guestfish -a $IMAGE_FILE<<_EOF_
run
mount /dev/sda2 /
mount /dev/sda1 /boot
upload /usr/lib/SYSLINUX/gptmbr.bin /boot/mbr.bin
upload ./syslinux.cfg /boot/syslinux.cfg
copy-file-to-device /boot/mbr.bin /dev/sda size:440
extlinux /boot
part-set-bootable /dev/sda 1 true
exit
_EOF_

echo "*Aura* Done!"
sync
