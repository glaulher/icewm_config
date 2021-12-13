#!/bin/bash

### recently-used-settings.sh - sets limit of how many recently used files to display

### PPC 09/23/19

# if not configured, default to 10 max displayed
RECENTUSDSP=~/.config/recently-used-dsp.conf
limitlines=$( cat $RECENTUSDSP )
if [ ! $limitlines -ge 0 ]; then
    limitlines=10
    echo $limitlines > $RECENTUSDSP
fi
yad --center --width=400 --title "Recent Files to Display" --text=" Enter the number of recent files  \n you want to be displayed" --entry --entry-text=$limitlines --numeric < $RECENTUSDSP > $RECENTUSDSP
# cat ~/HistoryNumberOfLines.txt  ## use this to test the output...
