#!/bin/bash
# Adds/Removes icons to the IceWM desktop toolbar- antiX Linux (adding icons is done using the info from the app's .desktop file) 
# By PPC, 6/12/2020 adapted from many, many on-line examples
# GPL licence - feel free to improve/adapt this script - but keep the lines about the license and author
# localisation and minor changes added by anticapitalista - 10-12-2020

TEXTDOMAINDIR=/usr/share/locale
TEXTDOMAIN=icewm-toolbar-icon-manager

###Check if the current desktop is IceWM, if not, exit
desktop=$(wmctrl -m)
if [[ $desktop == *"icewm"* ]]; then
  echo $"You are running an IceWM desktop"
    else 
   yad --title=$"Warning" --text=$"This script is meant to be run only in an IceWM desktop" --timeout=10 --no-buttons --center
 exit
fi

###Create list of availables apps, with localized names- this takes a few seconds on low powered devices:

#Get system language (to allow localization):
lang=$(locale | grep LANG | cut -d= -f2 | cut -d. -f1)
#hack to fix languages that are identified in .desktop files by only 2 characters, and not 4 (5 counting the _)
#comparing text that's before the "_" to the text that after that, converted to lower case, if it matches, use only the leters before the "_"
l1=$(echo $lang |cut -d_ -f1)
l2=$(echo $lang |cut -d_ -f2)
l2_converted=$(echo "${l2,,}")
if [ $l1 = $l2_converted ]; then lang=$l1; fi



#To test localization to another language, like french, use: lang=fr

#Loop through all .desktop files in the applications folders and extract name and save that to a .txt file 

cd /usr/share/applications/
find ~+ -type f -name "*.desktop" > ~/.apps-antix-0.txt
cd ~/.local/share/applications/
find ~+ -type f -name "*.desktop" >> ~/.apps-antix-0.txt
###NOTE: repeat the last 2 lines, changing the first, the "cd" one, to change to the folder where your .desktop files are
sort ~/.apps-antix-0.txt > ~/.apps-antix.txt
cd ~

#for file in /usr/share/applications/*.desktop
for file in $(cat ~/.apps-antix.txt)
do
 name1=$(grep -o -m 1 '^Name=.*' $file)

 ### localized menu entries generator (slows the script down, but produces nearly perfectly localized menus):
    name2=$name1
	translated_name1=$(grep -o -m 1 "^Name\[$lang\]=.*" $file)
	[ -z "$translated_name1" ] && note=$"No localized name found, using the original one" || name2=$translated_name1
	#if the desktop file has the string "Desktop Action" simply use the original untranslated name, to avoid risking using a translation that's not the name of the app
	grep -q "Desktop Action" $file && name2=$name1
	name1=$name2
 ### end of localized menu entries generator	 
 name=$(echo $name1|sed 's/.*\=//') 

echo "$name"  --  "$file"
done > /tmp/list.txt
sort /tmp/list.txt > ~/.apps.txt
###


help()
{
		###Function to display help
		yad --center --form --title=$"Toolbar Icon Manager" --field=$"Help::TXT" $"What is this?\nThis utility adds and removes application icons to IceWm's toolbar.\nThe toolbar application icons are created from an application's .desktop file.\nWhat are .desktop files?\nUsually a .desktop file is created during an application's installation process to allow the system easy access to relevant information, such as the app's full name, commands to be executed, icon to be used, where it should be placed in the OS menu, etc.\nA .desktop file name usually refers to the app's name, which makes it very easy to find the intended .desktop file (ex: Firefox ESR's .desktop file is 'firefox-esr.desktop').\nWhen adding a new icon to the toolbar, the user can click the field presented in the main window and a list of all the .desktop files of the installed applications will be shown.\nThat, in fact, is a list of (almost) all installed applications that can be added to the toolbar.\nNote: some of antiX's applications are found in the sub-folder 'antiX'.\n
TIM buttons:\n 'ADD ICON' - select, from the list, the .desktop file of the application you want to add to your toolbar and it instantly shows up on the toolbar.\nIf, for some reason, TIM fails to find the correct icon for your application, it will still create a toolbar icon using the default 'gears' image so that you can still click to access the application.\nYou can click the 'Advanced' button to manually edit the relevant entry and change the application's icon.\n'UNDO LAST STEP' - every time an icon is added or removed from the toolbar, TIM creates a backup file. If you click this button, the toolbar is instantly restored from that backup file, without any confirmation.\n'REMOVE ICON' - this shows a list of all applications that have icons on the toolbar. Double left click any application to remove its icon from the toolbar\n'MOVE ICON' - this shows a list of all applications that have icons on the toolbar. Double left click any application to select it and then move it to the left or to the right\n'ADVANCED' - allows for editing the text configuration file that has all of your desktop's toolbar icon's configurations. Manually editing this file allows the user to rearrange the order of the icons and delete or add any icon. A brief explanation about the inner workings of the text configuration file is displayed before the file is opened for editing.\n Warnings: only manually edit a configuration file if you are sure of what you are doing! Always make a back up copy before editing a configuration file!"  --center --width=600 --height=700 --button=gtk-quit:1
		###END of Function to display help
}

advanced()
{
		###Function to manually manage icons (ADVANCED management)
		cp ~/.icewm/toolbar ~/.icewm/toolbar.bak &&	
		yad --center --form --title=$"Toolbar Icon Manager" --field=$"Warning::TXT" $"If you click 'Yes', the toolbar configuration file will be opened for manual editing.\n
How-to:\nEach toolbar icon is identified by a line starting with 'prog' followed by the application name, icon and the application executable file.\n Move, edit or delete the entire line referring to each toolbar icon entry.\nNote: Lines starting with # are comments only and will be ignored.\nThere can be empty lines.\nSave any changes and then restart IceWM.\nYou can undo the last change from TIMs UNDO LAST STEP button." --width=400 --height=360 --button=gtk-quit:1 --button=gtk-yes:0 && geany ~/.icewm/toolbar
		###END of Function to manually arrange icons
}		

delete_icon()
{
		###Function to delete  icon
		#create backup file before changes
		cp ~/.icewm/toolbar ~/.icewm/toolbar.bak
		### Select any application whose icon you want to remove from the toolbar:
		#display only application names
		sed '/.*\"\(.*\)\".*/ s//\1/g' ~/.icewm/toolbar > /tmp/toolbar-test-edit0.txt
		# do not show commented lines
		egrep -v '^(;|#|//)' /tmp/toolbar-test-edit0.txt > /tmp/toolbar-test-edit.txt
		#choose application to delete
		EXEC=$(yad --title=$"Toolbar Icon Manager" --width=450 --height=480 --center --separator=" " --list  --column=$"Double click any Application to remove its icon:"  < /tmp/toolbar-test-edit.txt --button=$"Remove":4)
		#get line number(s) where the choosen application is
		x=$(echo $EXEC)
		 Line=$(sed -n "/$x/=" ~/.icewm/toolbar)
		 ## NOTE: to be on the safe side, in order to use $Line to delete the line(s) that match the selection, first extract it's first number, to avoid errors in case more than one line matchs the selection (there's more that one icon for the same app on the toolbar), TIM should only delete the first occorrence!!! Also: changed the sed command so it directly deletes line number $Line (solves the bug of not deleting paterns with spaces)...
		 firstx=$(echo $Line | grep -o -E '[0-9]+' | head -1 | sed -e 's/^0\+//')
		# remove the first line that matchs the user selection and save that into a temporary file
		sed ${firstx}d ~/.icewm/toolbar > ~/.tempo
        # copy that temp file to antiX's icewm toolbar file, delete the temp file and restart to see changes BUT only if "toolbar" file is not rendered completly empty after changes (fail safe to avoid deleting the entire toolbar icon's content, in case a icon has a description with \|/*, etc.)
         if [[ -s ~/.tempo ]];
     then echo $"file has something";
     #file is not empty
					cp ~/.tempo ~/.icewm/toolbar ;
					rm ~/.tempo ;
					icewm --restart ;
					exit
      else echo $"file is empty";
      #file is empty
		yad --title=$"Warning" --text=$"No changes were made!\nTIP: you can always try the Advanced buttton." --timeout=3 --no-buttons --center
		 fi
        	exit
		###END of Function to delete last icon
}		

move_icon()
{
	
		#display only application names
		sed '/.*\"\(.*\)\".*/ s//\1/g' ~/.icewm/toolbar > /tmp/toolbar-test-edit0.txt
		# do not show commented lines
		egrep -v '^(;|#|//)' /tmp/toolbar-test-edit0.txt > /tmp/toolbar-test-edit.txt
		#choose icon to be moved:
		EXEC=$(yad --title=$"Toolbar Icon Manager" --width=450 --height=480 --center --separator=" " --list  --column=$"Double click any Application to move its icon:"  < /tmp/toolbar-test-edit.txt --button=$"Move":4)
		#get line number(s) where the choosen application is
		x=$(echo $EXEC)
		 Line=$(sed -n "/$x/=" ~/.icewm/toolbar)
		 #get number of lines in file
		 number_of_lines=$(wc -l < $file)

#only do something if a icon was selected :
if test -z "$x" 
then
      echo $"nothing was selected"
else

file_name=~/.icewm/toolbar
a=$Line

#this performs an infinite loop, so the Move window is ALWAYS open unless the user clicks "Cancel"
	while :
	do

yad --center --undecorated --title=$"Toolbar Icon Manager" --text=$"Choose what do to with $EXEC icon" \
--button=gtk-quit:1 \
--button=$"Move left":2 \
--button=$"Move right":3 

foo=$?
Line_to_the_left=line_number=$((line_number-1))
line_number=$a

if [[ $foo -eq 1 ]]; then exit
fi

#move icon to the left:
if [[ $foo -eq 2 ]]; then
b=$(($a-1))
	if [ $b -gt 0 ]; then
sed -n "$b{h; :a; n; $a{p;x;bb}; H; ba}; :b; p" ${file_name} > test2.txt
#create backup file before changes
cp ~/.icewm/toolbar ~/.icewm/toolbar.bak
 cp test2.txt  ~/.icewm/toolbar
 sleep .3
 rm -f test2.txt
icewm --restart
a=$(($a-1))   # update selected icon's position, just in case the user wants to move it again
	fi
fi

#move icon to the right
if [[ $foo -eq 3 ]]; then
a=$(($a+1))
number_of_lines=$(wc -l < ~/.icewm/toolbar)
b=$(($a-1))
    if [[ $line_number -ge  $number_of_lines ]]; then 
  exit 
  else
  sed -n "$b{h; :a; n; $a{p;x;bb}; H; ba}; :b; p" ${file_name} > test2.txt
#create backup file before changes 
cp ~/.icewm/toolbar ~/.icewm/toolbar.bak
    cp test2.txt  ~/.icewm/toolbar
    sleep .3
    rm -f test2.txt
icewm --restart
# There's no need to update selected icon's position, just in case the user wants to move it again, because moving right just moves the icon to the right of the select icon to the left, so, it updates instantly the selected icon's position
  fi
fi

	done

fi ### ends if cicle that checks if user selected icon to move in the main Move icon window

	}	

restore_icon()
{
		###Function to restore last backup
cp ~/.icewm/toolbar.bak ~/.icewm/toolbar
icewm --restart
		###END Function to restore last backup
}

add_icon()
{

####begin infinite loop
for (( ; ; ))
do


# Use a Yad window to select file to be added to the menu
DADOS=$(yad --button=gtk-quit:1 --button=$"Add selected app's icon":2 --title=$"Choose application to add to the Toolbar"  --height=500 --width=400 --center  --separator=" " --list  --column=  < ~/.apps.txt)

		###Function to add a new icon
COMANDO0=$(echo "$DADOS" | cut -d'|' -f1)
#this strips any existing path from the name:
EXEC0=$(grep Exec= $COMANDO0 | cut -d '=' -f2)
EXEC=$(echo "$EXEC0" | cut -f1 -d" ")
#this strips any existing path from the name:
COMANDO00=$(basename $COMANDO0)
#this strips any existing .desktop from the name:
REMOVE=".desktop"
##strip selection until only the localized application name remains:
#NOME=${DADOS%/usr*}
NOME=${DADOS%--*}

 #try to find app icon:
	ICON0=$(grep Icon= $COMANDO0 | cut -d '=' -f2)
	ICON00=$(echo "$ICON0" | cut -f1 -d" ")
	ICONwithoutpath=$(basename $ICON00)

# By default set the icon as the gears icon, then look if the icon exist in several paths...
ICONE="/usr/share/icons/papirus-antix/24x24/apps/yast-runlevel.png"

# if a icon with a full path exists on the .desktop, use that icon
if [[ -f "$ICON00" ]]; then  ICONE=$ICON00
fi

#...Also check if the icon's name exists in several possible default paths, if a existing icon is found, use that instead!
#We can add as many paths as we want for the system to look for icons, also, we can look for icons with extensions other than .png (ex: svg), adding new "extension" and path's, and repeating the if-fi cicle
extension=".png"

path="/usr/share/pixmaps/"
if [[ -f "$path$ICONwithoutpath$extension" ]]; then  ICONE=$path$ICONwithoutpath$extension
fi

path="/usr/share/icons/papirus-antix/24x24/apps/"
if [[ -f "$path$ICONwithoutpath$extension" ]]; then  ICONE=$path$ICONwithoutpath$extension
fi

path="/usr/share/icons/papirus-antix/24x24/places/"
if [[ -f "$path$ICONwithoutpath$extension" ]]; then  ICONE=$path$ICONwithoutpath$extension
fi

## v.9 - looks in another folder, that has icon's for example, for Brave Browser
path="/usr/share/icons/hicolor/24x24/apps/"
if [[ -f "$path$ICONwithoutpath$extension" ]]; then  ICONE=$path$ICONwithoutpath$extension
fi

## v.9 – if no icon was found after searching the default couple of icon folders, perform active search for icons and use search result only if an icon was found- it takes about 1 second, but almost always finds a icon!
default="/usr/share/icons/papirus-antix/24×24/apps/yast-runlevel.png"
if [ "$ICONE" == "$default" ]; then
  search=$(locate /usr/share/icons/*/$ICONwithoutpath$extension)
  first_result=$(echo $search | head -n1 | awk '{print $1;}')
  if [ -z "$first_result" ]
  then 
  echo $"No icon located, using default Gears icon"
  else 
  echo $"Icon located!" ; ICONE=${first_result::-4}
  fi
fi
###
    
# exit if no application selected- avoids creating empty icon on toolbar:
if [ -z "$EXEC" ]; then exit
fi

#create backup file before changes
cp ~/.icewm/toolbar ~/.icewm/toolbar.bak

#open .desktop file and get EXEC= contents
EXEC0=$(grep Exec= $COMANDO0 | cut -d '=' -f2)
#in case EXEC has more than one line, use only the first
readarray -t lines < <(echo "$EXEC0")
EXECperc="${lines[0]}"

#add line to toolbar - the | cut -f1 -d"%"   part removes any %x option from the exec command.
echo "prog "\"${NOME}"\" "${ICONE}" "${EXECperc}""| cut -f1 -d"%"  >> ~/.icewm/toolbar
#instantly restart IceWm so the new icon appears
icewm --restart

done ###close infite loop
		###END of Function to add a new icon
}

export -f help delete_icon advanced restore_icon add_icon move_icon

DADOS=$(yad --length=200 --width=280 --center --title="Toolbar Icon Manager" \
--form  \
--button=gtk-quit:1 \
--field=$"HELP!help:FBTN" "bash -c help" \
--field=$"ADVANCED!help-hint:FBTN" "bash -c advanced" \
--field=$"ADD ICON!add:FBTN" "bash -c add_icon" \
--field=$"REMOVE ICON!remove:FBTN" "bash -c delete_icon" \
--field=$"MOVE ICON!gtk-go-back-rtl:FBTN" "bash -c move_icon" \
--field=$"UNDO LAST STEP!undo:FBTN" "bash -c restore_icon" \
--wrap --text=$"Please select any option from the buttons below to manage Toolbar icons")

### wait for a button to be pressed then perform the selected function
foo=$?

[[ $foo -eq 1 ]] && exit 0
