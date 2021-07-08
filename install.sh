#!/bin/bash
NEWROOT="/mnt/heavyarms/"
COLOR_PINK="\e[38;5;5m"
COLOR_GREEN="\e[38;5;10m"
COLOR_END="\e[0m"
LINE_START="${COLOR_PINK}:::${COLOR_END} ${COLOR_GREEN}"

cd ${NEWROOT}
tar -xvf /home/gentoo/henrique/Downloads/stage3-amd64-systemd-20210630T214504Z.tar.xz
cd -

echo -e "${LINE_START} Syncing basic config...${COLOR_END}"
rsync -a config_files/basic/ ${NEWROOT}/

echo -e "${LINE_START} Syncing binpkgs...${COLOR_END}"
rsync -a binpkgs/ ${NEWROOT}/var/cache/binpkgs/

echo -e "${LINE_START} Mounting binds...${COLOR_END}"
mount -t proc /proc ${NEWROOT}/proc
mount --rbind /dev ${NEWROOT}/dev
mount --make-rslave ${NEWROOT}/dev
mount --rbind /sys ${NEWROOT}/sys
mount --make-rslave ${NEWROOT}/sys

echo -e "${LINE_START} Entering chroot...${COLOR_END}"
chroot ${NEWROOT} /bin/bash << EOF
emerge-webrsync 
rm /etc/localtime 
ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime 
locale-gen 
eselect locale set 3 
eselect profile set 10 
env-update 
source /etc/profile 
export PS1="(chroot) ${PS1}" 
emerge -kq gentoo-sources 
eselect kernel set 1
wait
EOF
echo -e "${LINE_START} Exiting chroot...${COLOR_END}"

echo -e "${LINE_START} Syncing kernel files...${COLOR_END}"
rsync -av --keep-dirlinks config_files/kernel/* ${NEWROOT}/

echo -e "${LINE_START} Entering chroot...${COLOR_END}"
chroot ${NEWROOT} /bin/bash << EOF
cd /usr/src/linux 
make olddefconfig 
emerge -kq intel-microcode 
make -j4 
make install 
make modules_install 
cd - 
emerge -ukqDN @world 
emerge -kq @heavyarms
wait
EOF

echo -e "${LINE_START} Exiting chroot...${COLOR_END}"
echo -e "${LINE_START} Unmounting binds...${COLOR_END}"
umount --recursive ${NEWROOT}/dev
umount --recursive ${NEWROOT}/proc
umount --recursive ${NEWROOT}/sys

echo -e "${LINE_START} Syncing modules config...${COLOR_END}"
rsync -a config_files/modules/ ${NEWROOT}/
echo -e "${LINE_START} Syncing X config...${COLOR_END}"
rsync -a config_files/X11/ ${NEWROOT}/
wait
