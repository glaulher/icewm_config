#!/bin/bash
# Adds a new tool bar icon (from a .desktop file) to the IceWM desktop toolbar- antiX 19
# By PPC, 30/7/2019, adapted from many, many on-line examples
# No licence what so ever- feel free to improve/adapt this script
# To do: 1- allow to list/move/delete icons from the toolbar (huge re-write- the app was meant originaly to add icons only, but I thought it was a nice way to allow some basic icon deletion funtions. -https://pastebin.com/imRHPw9k
# 4-9-2019- EDITED TO SERVE AS FASTER PERSONAL MENU EDITOR

TEXTDOMAINDIR=/usr/share/locale
TEXTDOMAIN=fast_personal_menu_editor

DADOS=$(yad --length=800 --width=800 --center --paned --splitter="200" --title=$"Fast Personal Menu Manager for IceWM" \
--form --field=$"App .desktop file":FL '/usr/share/applications/antix' \
--button=gtk-cancel:1 \
--button=$"REMOVE last entry":2 \
--button=$"ORGANIZE entries":4 \
--button=$"UNDO last change":3 \
--button=$"ADD selected app":0 \
--wrap --text=$"Choose (or drag and drop to the field below) the .desktop file you want to add to the personal menu \n OR select any other option")

### wait for a button to be pressed then do the needed funtion
foo=$?

[[ $foo -eq 1 ]] && exit 0

		###Function to manually arrange icons
		if [[ $foo -eq 4 ]]; then   cp ~/.icewm/personal ~/.icewm/personal.bak &&	yad --center --form --title=$"Fast Personal Menu Manager for IceWM" --field="Warning::TXT" $"FPM has no 'graphical' way to allow users to move icons around or delete arbitrary icons.\nIf you click OK, the personal menu configuration file will be opened for editing.\nEach menu icon is identified by a line starting with 'prog' followed by the application name, icon location and the application executable file.\nMove or delete the entire line refering to each personal menu entry.\nNote: Lines starting with # are comments only and will be ignored.\nThere can be empty lines.\nSave any changes and then restart IceWM.\nYou can undo the last change from FPMs 'Restore' button." --width=400 --height=360  && geany ~/.icewm/personal
		fi 
		###END of Function to manually arrange icons
		
		###Function to delete last icon
	
if [[ $foo -eq 2 ]]; then

			### Does not allow to remove the first $mininumlines "toolbar" file lines  -> meant to not allow delete the show desktop, eject usb and the TIM icons from the toolbar 
			mininumlines=1
			a=($(wc ~/.icewm/personal))
			existinglines=${a[0]}
			if [ "$mininumlines" -gt "$existinglines" ]; then  yad --title=$"Warning" --text=$"FTM is programmed to always keep 1 line in the personal menu file!" --timeout=3 --no-buttons --center; exit
			fi
			###

yad --title=$"Warning" --text=$"This will delete the last entry from your personal menu! Are you sure?" --center --button=gtk-cancel:1 \ --button=gtk-cancel:1 --button=gtk-yes:0 
  confirm=$?
  if [[ $confirm -eq 1 ]]; then exit
  fi

#create backup file before changes
cp ~/.icewm/personal ~/.icewm/personal.bak
#TRY to Remove last icon from the personal menu
BADLINESCOUNT=1
ORIGINALFILE=~/.icewm/personal
truncate -s $(printf "$(stat --format=%s ${ORIGINALFILE}) - $(tail -n${BADLINESCOUNT} ${ORIGINALFILE} | wc -c)\n" | bc ) ${ORIGINALFILE}
#Restart icewm so the change is instantly available
icewm --restart
	exit
fi
		###END of Function to delete last icon

		###Function to restore last backup
if [[ $foo -eq 3 ]]; then
cp ~/.icewm/personal.bak ~/.icewm/personal
icewm --restart
exit 
fi 
		###END Function to restore last backup

if [[ $foo -eq 0 ]]; then

		###Function to add a new icon

COMANDO0=$(echo "$DADOS" | cut -d'|' -f1)
#this strips any existing path from the name:
EXEC0=$(grep Exec= $COMANDO0 | cut -d '=' -f2)
EXEC=$(echo "$EXEC0" | cut -f1 -d" ")
#this strips any existing path from the name:
COMANDO00=$(basename $COMANDO0)
#this strips any existing .desktop from the name:
REMOVE=".desktop"
NOME=${COMANDO00//$REMOVE/}
 #try to find app icon:
	ICON0=$(grep Icon= $COMANDO0 | cut -d '=' -f2)
	ICON00=$(echo "$ICON0" | cut -f1 -d" ")
	ICONwithoutpath=$(basename $ICON00)
	ICON0=$(grep Icon= $COMANDO0 | cut -d '=' -f2)
	ICON00=$(echo "$ICON0" | cut -f1 -d" ")
	ICONwithoutpath=$(basename $ICON00)
	path="/usr/share/icons/papirus-antix/24x24/apps/"
	extension=".png"

if [ "$ICON00" == "$ICONwithoutpath" ]; then
    ICONE=$path$ICONwithoutpath$extension
    ### CHECk IF ICONE exits in default Path
else
    ICONE="/usr/share/icons/papirus-antix/24x24/apps/yast-runlevel.png"
fi
  
  #IF ICON not found on that path, try other path and if still not found, use default  
if [ -f "$ICONE" ]; then OK=OK
else 
   path="/usr/share/pixmaps/"
   ICONE=$path$ICONwithoutpath$extension
        if [ -f "$ICONE" ]; then OK=OK
		else 
		ICONE="/usr/share/icons/papirus-antix/24x24/apps/yast-runlevel.png"
		fi
fi
    
# error if no application selected- avoids creating empty icon on toolbar:
if [ -z "$EXEC" ]; then yad --title=$"Warning" --text=$"No changes were made! Please choose an application." --timeout=3 --no-buttons --center
	exit
fi

#create backup file before changes
cp ~/.icewm/personal ~/.icewm/personal.bak

#open .desktop file and get EXEC= contents
EXEC0=$(grep Exec= $COMANDO0 | cut -d '=' -f2)
#in case EXEC has more than one line, use only the first
readarray -t lines < <(echo "$EXEC0")
EXECperc="${lines[0]}"

#add line to personal menu file - the | cut -f1 -d"%"   part removes any %x option from the exec command.
echo "prog "\"${NOME}"\" "${ICONE}" "${EXECperc}""| cut -f1 -d"%"  >> ~/.icewm/personal
#instantly restart IceWm so the new icon appears
icewm --restart
		###END of Function to add a new icon

exit

fi
