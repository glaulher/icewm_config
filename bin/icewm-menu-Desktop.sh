#!/bin/bash

### icewm-menu-Desktop.sh - dynamic menu of ~/Desktop files & recursive folders to open via dynamic menu
###           set to use antiX execute in terminal command: desktop-defaults-run -t

### BobC 12/27/20 fixes for locales and empty list

### --- example output ---
###prog "alsamixer" gnome-volume-control x-terminal-emulator -e alsamixer
###prog "antiX-docs" help-browser dillo /usr/share/antiX/FAQ/index.html 
###prog "arandr" display arandr
###prog "file-manager" spacefm desktop-defaults-run -fm
###prog "mc-screen.jpg" image-jpeg xdg-open "/home/bobc/Desktop/mc-screen.jpg" 
###prog "mps-youtube terminal desktop-defaults-run -t mpsyt 
###menu "ScreenLayout entries" applications {
###prog "1440x900-Screen" application-x-executable.png xdg-open "/home/bobc/Desktop/ScreenLayout/1440x900-Screen" 
###prog "test a bit more.txt" text-plain xdg-open "/home/bobc/Desktop/ScreenLayout/test a bit more.txt" 
###}
###prog "spacefm-root" spacefm-root gksu spacefm 

walk_dir() {
    if [[ -z $(ls -A "$1") ]]; then
        # Empty dir
        return
    fi
    for pathname in "$1"/*; do
        basename=$( echo ${pathname##*/} | sed 's/\"//g' )
        dispname=$( echo ${basename} | sed 's/%20/ /g' )
        localfile=$( echo ${pathname} | sed 's/file:\/\///g' | sed 's/\"//g' |sed 's/%20/ /g' )
        ###printf '%s\n' "DEBUG Pathname: ${pathname}   Basename: ${basename}   dispname: ${dispname}   localfile: ${localfile} "
        if [ -d "$pathname" ]; then
            if [ $curdirlevel -le 5 ]; then
                basename="${pathname##*/}"
                printf '%s\n' "menu \"${basename} entries\" applications {"
                export curdirlevel=$(( curdirlevel +1 ))
                walk_dir "$pathname"
                printf "}\n"
            fi
        elif [ -e "$pathname" ]; then
            entry_fileext=${basename##*.}
            ###printf '%s\n' "DEBUG entry_fileext: ${entry_fileext} "
            if [ "$entry_fileext" = "desktop" ]; then
                ### this entry is a .desktop, so get execution string, and whether to run in terminal or not
                dispname=$( echo ${dispname} | sed 's/\(.*\)\.desktop/\1/' )
                entry_exec=$( grep '^Exec' $localfile | tail -1 | sed 's/^Exec=//' | sed 's/%.//' )
                ###printf '%s\n' "DEBUG Entry_exec: ${entry_exec} "
                ### use icon from desktop file we hope
                entry_icon=$( grep '^Icon' $localfile | tail -1 | sed 's/^Icon=//' | sed 's/%.//' )
                ###printf '%s\n' "DEBUG: entry_icon: ${entry_icon} "
                if [ -z "$entry_icon" ]; then
                    entry_icon=application-x-executable.png
                    ###printf '%s\n' "DEBUG: entry_icon: ${entry_icon} "
                fi
                if grep -q '^Terminal=true' $localfile; then
                    ### use terminal to execute
                    entry_exec="$TERMCMD $entry_exec"
                    ###printf '%s\n' "DEBUG Terminal based Entry_exec: ${entry_exec} "
                    printf '%s\n' "prog \"${dispname} $entry_icon $entry_exec"
                else
                    printf '%s\n' "prog \"${dispname}\" $entry_icon $entry_exec"
                fi
            else
                # figure out what icon to display, lookup entry_fileext to figure out mimetype, then get icon filename by mangling the text
                if [ -z "$entry_fileext" ]; then
                    mimeicon=application-x-executable.png
                else
                    mimeicon=$( grep -P "[[:blank:]]${entry_fileext}( |$)" /etc/mime.types | sed 's/\//-/g' | sed '/^#/ d' | { read a _; echo "$a"; } )
                    if [ -z "$mimeicon" ]; then
                        mimeicon=application-x-executable.png
                    fi
                fi
                printf '%s\n' "prog \"${dispname}\" $mimeicon xdg-open \"$pathname\" "
            fi
        else
            # not sure why file doesn't exist, but ok to try to open, might be something not on this system
            mimeicon=application-x-executable.png
            printf '%s\n' "prog \"${dispname}\" $mimeicon xdg-open \"$pathname\" "
        fi
    done
}

TOP_DIR="$XDG_DESKTOP_DIR"
export TERMCMD='desktop-defaults-run -t'
export curdirlevel=1
walk_dir "$TOP_DIR"
