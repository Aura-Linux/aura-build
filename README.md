# aura-build
<p align="center">
  <img width="100%" src="https://dolphinbox.net/aura/aura-centre-white.png">
</p>

![Aura Screenshot](https://dolphinbox.net/aura/screenshots/screenshot-2.png)

[https://dolphinbox.net/aura](https://dolphinbox.net/aura)

The main build system for Aura. This is where the OS comes together!

Aura is built using a Docker image, which when run produces the final image for distribution.

## Building
``run.sh`` provides an easy way to build Aura. All you need is Docker installed, and the script will build the container,
and run it (mounting result/ into the container so you can get the resultant disk image).

## Hacking

The ``build/`` folder contains all the files that make up Aura. 
There are a couple of noteworthy files: 
* ``build.sh`` is the file run in the container, which contains all the build steps
* ``system7.hda`` is the System 7 hard disk image.
* ``aura-boot.service`` (and it's related ``.sh`` file) is responsible for starting the X server, but also expanding the 
root partition on first boot.
* ``aura-early-boot.service`` (and it's related ``.sh`` file) is run earlier in the boot process (by basic.target), and 
currently displays an image file on the framebuffer.
* ``basilisk_ii_prefs`` is the Basilisk II configuration file.

## Legal
Aura is provided  **for educational purposes only** as a way to preserve the history of the classic Macintosh software. System 7 can be considered as "abandonware", as it is no longer sold, and the last update was over 23 years ago.
The Macintosh System Software and ROMs are the property of Apple Inc.
