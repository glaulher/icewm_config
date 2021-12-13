#!/bin/bash
#Date and Time Setting Tool Copyright 2009,2011 by Tony Brijeski under the GPL V2
# modified by skidoo and ppc - https://pastebin.com/1YmJHb95
###   NOTE: no validation is performed ~~ user can choose "Feb 31"

# Translation
TEXTDOMAINDIR=/usr/share/locale
TEXTDOMAIN=set_time-and_date

DIALOG="`which yad` --width 400 --center --undecorated"
TITLE="--always-print-result --dialog-sep --title="
TEXT="--text="
ENTRY="--entry "
ENTRYTEXT="--entry-text "
MENU="--list --print-column=1 --column=Pick:HD --column=_"
YESNO="--question "
MSGBOX="--info "
SCALE="--scale "
PASSWORD="--entry --hide-text "
TITLETEXT=$"Manage Date and Time Settings"
testroot="`whoami`"   #  howdy       backticks galore
DATE_TEXT=$"Date:"
SETTIME_TEXT=$"Set Current Time"
SETDATE_TEXT=$"Set Current Date"
SETTZ_TEXT=$"Choose Time Zone (using cursor and enter keys)"
SETAUTO_TEXT=$"Use Internet Time server to set automaticaly time/date"
SETHOUR_TEXT=$"Move the slider to the correct Hour"
SETMINUTE_TEXT=$"Move the slider to the correct Minute"
SETTIMEZONE_TEXT=$"Select Time Zone"
EXIT_TEXT=$"Quit"

## TEXT TO BE DESPLAYED ##
 
if [ "$testroot" != "root" ]; then
    gksu $0
    exit 1
fi
 
while [ "$SETCHOICE" != "Exit" ]; do
DAY="`date +%d`"
MONTH="`date +%m`"
YEAR="`date +%Y`"
MINUTE="`date +%M`"
HOUR="`date +%H`"
SETCHOICE=`$DIALOG --no-buttons --center --height 300 $TITLE"$TITLETEXT" $MENU $TEXT" $TITLETEXT\n $DATE_TEXT\n $(date)\n\n" SETTIME " $SETTIME_TEXT" SETDATE " $SETDATE_TEXT"  SETTZ " $SETTZ_TEXT"  SETAUTO " $SETAUTO_TEXT" Exit " $EXIT_TEXT"`
SETCHOICE=`echo $SETCHOICE | cut -d "|" -f 1`
 
if [ "$SETCHOICE" = "SETTIME" ]; then
    HOUR="`date +%H`"
    HOUR=`echo $HOUR | sed -e 's/^0//g'`
    SETHOUR=`$DIALOG --center $TITLE"$TITLETEXT" $SCALE --value=$HOUR --min-value=0 --max-value=23 $TEXT"$SETHOUR_TEXT"`
    if [ "$?" = "0" ]; then
        if [ "${#SETHOUR}" = "1" ]; then
            SETHOUR="0$SETHOUR"
        fi
 
        MINUTE="`date +%M`"
        MINUTE=`echo $MINUTE | sed -e 's/^0//g'`
    fi
 
    SETMINUTE=`$DIALOG --center $TITLE"$TITLETEXT" $SCALE --value=$MINUTE --min-value=0 --max-value=59 $TEXT"$SETMINUTE_TEXT"`
    if [ "$?" = "0" ]; then
        if [ "${#SETMINUTE}" = "1" ]; then
            SETMINUTE="0$SETMINUTE"
        fi
 
        date $MONTH$DAY$SETHOUR$SETMINUTE$YEAR
        hwclock --systohc
    fi
fi
 
if [ "$SETCHOICE" = "SETDATE" ]; then
    var=`$DIALOG --form --separator="" --date-format="%Y%m%d" --field="$DATE_TEXT":DT`
SETYEAR=$(echo ${var:0:4})
SETMONTH=$(echo ${var:4:2})
SETDAY=$(echo ${var:6:2})
MINUTE="`date +%M`"
HOUR="`date +%H`"
sudo date $SETMONTH$SETDAY$HOUR$MINUTE$SETYEAR
                hwclock --systohc
fi
 
if [ "$SETCHOICE" = "SETAUTO" ]; then
sudo date -s "$(wget -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
                hwclock --systohc
fi
 
if [ "$SETCHOICE" = "SETTZ" ]; then
sudo roxterm --hide-menubar -z 0.75 -T " $SETTIMEZONE_TEXT" -e /bin/bash -c "dpkg-reconfigure tzdata"
 
fi
done
 
exit 0
