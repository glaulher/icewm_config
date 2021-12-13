#!/bin/bash

### icewm-menu-recentfiles.sh - dynamic menu of recent files to open via xdg-open

### BobC 09/04/19

### --- example output ---
###prog "startX2.png" image-png xdg-open "file:///home/bobc/startX2.png"
###prog "startXs.jpg" image-jpeg xdg-open "file:///home/bobc/.icewm/themes/Clearview%20Blue%20Large%20w-Rollup/taskbar/startXs.jpg"
###prog "2019-09-17 Catherine Austin Fitts.mp3" audio-mpeg xdg-open "file:///home/bobc/Downloads/2019-09-17%20Catherine%20Austin%20Fitts.mp3"
###prog "antiX.txt" text-plain xdg-open file:///home/bobc/antiX.txt"

# recent files xml path
RECENTUSXML=~/.local/share/recently-used.xbel
RECENTUSDSP=~/.config/recently-used-dsp.conf
# default terminal command to use
TERMCMD='desktop-defaults-run -t'
# default to 10 menus with 10 items per 
maxrowsper=10
# if not configured, default to 10 max displayed
limitlines=10
if [ -f $RECENTUSDSP ]; then
    limitlines=$( cat $RECENTUSDSP )
else
    echo $limitlines > $RECENTUSDSP
fi
limitlines2=$(( limitlines * 2 ))
xmllines=$(( limitlines * 14 ))

colmax=0
rowmax=0
curcol=0
currow=0

while read recentfile mimetype; do
    ###printf '%s\n' "DEBUG recentfile: ${recentfile}  mimetype: ${mimetype} "
    basename=$( echo ${recentfile##*/} | sed 's/\"//g' )
    dispname=$( echo ${basename} | sed 's/%20/ /g' )
    localfile=$( echo ${recentfile} | sed 's/file:\/\///g' | sed 's/\"//g' |sed 's/%20/ /g' )
    mimeicon=$( echo $mimetype | sed 's/\//-/g' | sed 's/\"//g' )
    ###printf '%s\n' "DEBUG basename: ${basename}  dispname: ${dispname}  localfile: ${localfile}  mimeicon: ${mimeicon} "
    # first time calc how many columns of menus are needed based on number of files to be displayed
    if [ $curcol -eq 0 ]; then
        curcol=1
        rowmax=$( wc -l < /tmp/icewm-menu-recentfiles.txt )
        ###printf '%s\n' "DEBUG rowmax: ${rowmax} "
        if [ $rowmax -gt 0 ]; then
            colmax=$((( rowmax + maxrowsper - 1) / ( maxrowsper )))                
        fi
    else
        # if already at max for this menu, end this menu and start a Next menu
        if [ $currow -ge $maxrowsper ]; then
            ###printf "}\n"
            mimeicon=applications
            printf '%s\n' "menu \"Next ${maxrowsper}\" $mimeicon { "
            currow=0
            curcol=$(( curcol +1 ))
        fi
    fi
    currow=$(( currow +1 ))
    if [ -z "$mimeicon" ]; then
        mimeicon=application-x-executable
    fi
    if [ -d "$localfile" ]; then
        mimeicon=inode-directory
        printf '%s\n' "prog \"${dispname}\" $mimeicon xdg-open $recentfile"
    else
        if [ -f "$localfile" ]; then
            entry_fileext=${basename##*.}
            ### if .desktop need to figure out what to run, otherwise use xdg-open
            if [ "$entry_fileext" = "desktop" ]; then
                ### this entry is a .desktop, so get execution string, and whether to run in terminal or not
                dispname=$( echo ${dispname} | sed 's/\(.*\)\.desktop/\1/' )
                entry_exec=$( grep '^Exec' $localfile | tail -1 | sed 's/^Exec=//' | sed 's/%.//' )
                ### use icon from desktop file we hope
                entry_icon=$( grep '^Icon' $localfile | tail -1 | sed 's/^Icon=//' | sed 's/%.//' )
                ###printf '%s\n' "DEBUG: entry_icon: ${entry_icon} "
                if [ -z "$entry_icon" ]; then
                   entry_icon=$mimeicon
                fi
                if grep -q '^Terminal=true' $localfile; then
                    ### use terminal to execute
                    entry_exec="$TERMCMD $entry_exec"
                    printf '%s\n' "prog \"${dispname} $entry_icon $entry_exec"
                else
                    printf '%s\n' "prog \"${dispname}\" $entry_icon $entry_exec"
                fi
            else
                printf '%s\n' "prog \"${dispname}\" $mimeicon xdg-open $recentfile"
            fi
        else
            # not sure why file doesn't exist, but ok to try to open, might be something not on this system
            printf '%s\n' "prog \"${dispname}\" $mimeicon xdg-open $recentfile"
        fi
    fi
done < <(tail -n $xmllines $RECENTUSXML | grep -e "<bookmark href=" -e "<mime:mime-type type=" | tail -n $limitlines2 | sed '1!b ; /<mime:mime-type/d' | sed 's/\<bookmark href\=//g' | sed 's/mime\:mime\-type type\=//g' | sed 's/\" .*/\"/' | sed 's/<//g' | sed 's/\/>//g' | sed 'N;s/\n/ /g' | sed 's/  */ /g' | tac )
