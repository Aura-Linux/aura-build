#!/bin/bash
FILE=/root/.aura-boot
if [ ! -f "$FILE" ]; then
    echo "Aura is preparing to start for the first time... Please Wait!"
    growpart /dev/sda 1
    resize2fs /dev/sda1
    touch $FILE
fi
echo "Aura is starting the Macintosh environment..."
sudo systemctl stop aura-early-boot
sudo startx /root/.xinitrc -display :0 -- :0 vt8 &
