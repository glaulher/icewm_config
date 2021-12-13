#!/bin/bash

# icewm-menu-drives.sh - dynamic menu of drives to open via antiX file manager with folder icon
# antiX file manager command: desktop-defaults-run -fm 

# BobC 08/04/19

# example output
#$ lsblk -o name,label,mountpoint | sed '1d' | sed 's/^[^[:alnum:]]*//g'
#sda                     
#sda1      ESP         /boot/efi
#sda2      OS          
#sda3                  
#sda4      4-antiX19   
#sda5      5-antiX19b3 /
#sdb5      BIGData     /media/BIGData
#sdb8                  [SWAP]
#sr0         EDISON      /media/bobc/EDISON
#mmcblk0                 
#mmcblk0p1             /media/bobc/mmcblk0p1-mmc-SA08G_0x41707a68-2

printf 'prog "  ---Drives Menu---"'

# detail lines of menu need to look like this
#echo 'prog 'sda ' /usr/share/icons/Faenza-Cupertino-mini/apps/48/gparted.png gksu gparted /dev/sda'
#echo 'prog 'sda1  1-antiX19b2     /' /usr/share/icons/papirus-antix/48x48/apps/file-manager.png desktop-defaults-run -r -fm /dev/sda1'

lsblk -o name,label,mountpoint | sed '1d' | sed 's/^[^[:alnum:]]*//g' | \
    awk '{print "prog '\''" $0"'\'' folder desktop-defaults-run -fm " $3}'
