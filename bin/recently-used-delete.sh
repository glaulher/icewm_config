#!/bin/bash

### recently-used-delete.sh - delete history of recently used files

### PPC 09/23/19

yad --center --width=400 --title="Recent files Dynamic menu" --text="  Are you sure you want to delete your Recent files history?  " \
--button=gtk-cancel:1 \
--button="Delete":2 \

foo=$?

[[ $foo -eq 1 ]] && exit 0

if [[ $foo -eq 2 ]]; then
rm ~/.local/share/recently-used.xbel
yad --center --text=" Done!" && exit 0

fi
