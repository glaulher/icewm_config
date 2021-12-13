#!/bin/bash


# Capture the name of the script
PROGNAME=${0##*/}

# Set the version number
PROGVERSION=1.1

# Translation
TEXTDOMAINDIR=/usr/share/locale
TEXTDOMAIN=menu_manager.sh

# --------------------
# Help and Information
# --------------------

# When requested show information about script
if [[ "$1" = '-h' ]] || [[ "$1" = '--help' ]]; then

# Display the following block
cat << end-of-messageblock

$PROGNAME version $PROGVERSION
Provides a point-and-click way of controlling items in the applications
and personal sections of the antiX menu.

Usage: 
   $PROGNAME [options]

Options:
   -h  --help        Show this output

Summary:
   Applications Section
   The hide or show feature helps you prevent the menu becoming cluttered
   with unwanted or unused items.  You need no technical skills.  To hide
   an item, just click the button marked hide and select the item(s) from
   a list.
   
   If you decide you want to display any hidden items, just click the
   button marked show and select them from a list.

   Personal Section:
   The add or remove feature helps you place the menu items you use most
   often in the same area of the menu.  In this way you can easily find
   your favourite items rather than having to navigate through cascading
   menu sections to find what you are looking for.
   
   You may customise the item to perform whatever task you desire. 
   Examples:
   * If you regularly browse the antiX forum and Youtube, you can create
     a menu item for each of them to directly open the wanted web site.  
   * If you usually word process the same document template, or edit the
     same spreadsheet template, you can create a menu item for each of 
     them to automatically open the corresponding template.  
    
   If you decide you want to delete any item you created, just click the
   button marked remove and select it from a list.
  
Configuration:
   None required.
      
Environment:
   The script works in a GUI (X) environment. 
   
Requires:
   awk, bash, chown, date, flock, sudo, grep, mkdir, rm, sed, xdg-utils, yad

end-of-messageblock
   exit 0
fi



# ---------------
# Static settings
# ---------------

# Name of the of this script excluding path and file extension
SCRIPT_NAME_EXC_EXTENSION=$(echo ${0%.*} | awk -F '/' '$0=$NF')

# Location of the lock file used to ensure only a single instance of the script is run
LOCK_FILE=/tmp/$SCRIPT_NAME_EXC_EXTENSION.lock

# Temporary file for interim data storage
TEMP_FILE=$LOCK_FILE

# Title in the titlebar of YAD windows
WINDOW_TITLE=$"Menu Manager"

# Location of icons used in this script
ICONS=/usr/share/pixmaps

# Location of icon themes
ICON_THEMES=/usr/share/icons/

# Icon file types to display when browsing icon themes for user selectable icons
ICON_TYPES='*.png *.svg *.xpm'

# Location of each general .desktop file
MENU_FILES_GENERAL=/usr/share/applications

# Location of each antiX specific .desktop file
MENU_FILES_ANTIX=/usr/share/applications/antix

# Location of each user created .desktop file for the personal menu
MENU_FILES_USER_PERSONAL=/home/$SUDO_USER/.local/share/applications/TCM

# Location of each template file used to rebuild the menu for its respective window manager
WINDOW_MANAGER_MENU_TEMPLATES=/usr/share/desktop-menu/templates


# ---------
# Functions
# ---------

# Return the first line that contains 
#   the specified pattern
# Format: function_name  "pattern"  "file_or_var_to_search"
get-1st-line-that-contains()
{
   grep --max-count=1 --ignore-case "$1" "$2"
}


# Return the value of the last field in the first line that contains
#   the specified pattern
#   via the nominated field separator
# Format: function_name  "pattern"  "field_separator"  "file_or_var_to_search"
get-value-of-last-field-in-1st-line-that-contains()
{
   grep --max-count=1 --ignore-case "$1" "$3" | awk -v FS="$2" '$0=$NF'
}


# Return the value of
#   the nominated field 
#   via the specified field separator
# Format: function_name  "field_number"  "field_separator"  "var_to_search"
get-value-of-field()
{
   echo "$3" | awk -v field_number="$1" -v FS="$2" '$0=$field_number'
}


# Create a list of .desktop candidates
#   sorted in aphabetical order of field Name=
#   excluding the .desktop file that launches this script
# Format: function_name "/path/to/dir1" "/path/to/dir2" "/path/to/dirX"
get-list-of-.desktop-candidates()
{
   # Ensure arrays to be used are empty
   MENU_FILES=()
   FILE_CANDIDATES_SORTED=()
   FILE_CANDIDATES_UNSORTED=()   

   
   # Capture a list of all files in each location
   MENU_FILES=( $1/* $2/* $3/* $4/* )
   
   
   # Step through the list of all files by index number of each element, handle each in turn
   for ELEMENT_INDEX in "${!MENU_FILES[@]}"
   do 
      # When the element contains a value that is not a file with a .desktop extension
      if [[ "${MENU_FILES[$ELEMENT_INDEX]}" != *.desktop ]]; then
      
         # Remove the element from the array (i.e. decrement the total element index count by 1)
         unset MENU_FILES[$ELEMENT_INDEX]
      fi
   done


   # Step through the list of .desktop files, handle each in turn
   for FILE in "${MENU_FILES[@]}"
   do
      # Capture the first occurrence of a Name= value displayed in the menu
      NAME=$(get-value-of-last-field-in-1st-line-that-contains "^Name=" "=" "$FILE")
 
      # Capture the first occurrence of a NoDisplay line
      CURRENT_NODISPLAY_ENTRY=$(get-1st-line-that-contains "NoDisplay=" "$FILE")

      # Capture the current NoDisplay= value
      CURRENT_NODISPLAY_VALUE=$(get-value-of-field "2" "=" "$CURRENT_NODISPLAY_ENTRY")

      # ***** n.b. the sequence of tests to assign the following status value is required to be, differs, not contain, hide, show *****

      # When the current NoDisplay value differs from the selected NoDisplay value 
      [[ "$CURRENT_NODISPLAY_VALUE" != "True" ]] && [[ "$CURRENT_NODISPLAY_VALUE" != "False" ]] && STATUS=$"Unknown. Will be set next time it is selected and hidden or shown by Menu Manager"
   
      # When the the file does not contain a NoDisplay entry
      [[ "$CURRENT_NODISPLAY_ENTRY" = "" ]] && STATUS=$"Not Set"
   
      # When the current NoDisplay value is set to hide the menu entry
      [[ "$CURRENT_NODISPLAY_VALUE" = "True" ]] && STATUS=$"Hidden"

      # When the current NoDisplay value is set to show the menu entry
      [[ "$CURRENT_NODISPLAY_VALUE" = "False" ]] && STATUS=$"Shown"

      # ***** n.b. the asterisk is appended as a single * character to be used for line splitting at a later stage *****
      # Append the path to the file name, name to display in the menu, and current status, to an element in an array list 
      FILE_CANDIDATES_UNSORTED+=( "$FILE|$NAME|$STATUS|*" )
   done


   # Sort the list of .desktop files in alphabetical order using the first word of Name= and store the list in a temporary file
   printf '%s\n' "${FILE_CANDIDATES_UNSORTED[@]}" | sort --field-separator='|' --key=2 > $TEMP_FILE


   # Remove from the list of .desktop files the entry that launches this script (i.e. prevent modification of its .desktop file)
   sed --in-place --expression="/$SCRIPT_NAME_EXC_EXTENSION.desktop/d" $TEMP_FILE


   # Step through the list of sorted .desktop files, handle each in turn
   while read -r -d '*'
   do
      # Capture the path to the .desktop file from the line being processed
      FILE_PATH=$(get-value-of-field  "1" "|" "$REPLY")
   
      # Capture the name displayed in the menu from the line being processed
      NAME=$(get-value-of-field  "2" "|" "$REPLY")
   
      # Capture the current NoDisplay= value from the line being processed
      STATUS=$(get-value-of-field  "3" "|" "$REPLY")
   
      # Append the file path, display name, and the current NoDisplay value to separate elements in an array 
      FILE_CANDIDATES_SORTED+=( "$FILE_PATH" "$NAME" "$STATUS" )
   done < <(cat $TEMP_FILE)
}


# Quit the script after refreshing the menu if a refresh is pending from a previous iteration
# Format: function_name ""
quit-honouring-pending-menu-update()
{
   # When a menu update is waiting to be performed from a previous iteration
   if [[ $MENU_REFRESH_PENDING_APPLICATIONS = Y ]] || [[ $MENU_REFRESH_PENDING_PERSONAL = Y ]]; then
      
      # Perform the waiting menu update
      break 2
      
   # When a menu update is not waiting to be performed
   else
      
      # Exit the script
      exit 1
   fi
}


# Exit the script upon yad cancel button or window close, honouring an optional command
# Format: function_name "optional_command"
exit-upon-yad-cancel-button-or-window-close-performing-optional-command()
{
   # When cancel button was selected or window closed
   if [[ $EXIT_STATUS -eq 1 ]] || [[ $EXIT_STATUS -eq 252 ]]; then
   
      # When an optional command is not specified
      if [[ -z $1 ]]; then
         
         # Exit the script
         exit 1
      
         # When an optional command is specified
         else
      
         # Perform the command then exit the script
         $1
         exit 1
      fi
   fi
}

   

# --------------------
# Single instance lock
# --------------------

# Create the lock file and remove it when the script finishes
exec 9> $LOCK_FILE
trap "rm -f $LOCK_FILE" 0 1 2 5 15

# When a subsequent instance of the script is started
if ! flock -n 9 ; then

   # Message to display in error window
   MESSAGE=$"\n $WINDOW_TITLE is already running. \
            \n Only one instance at a time is allowed. \
            \n \
            \n Exiting..."

   # Display error message
   yad                             \
   --center                        \
   --button=$"OK":1                \
   --title="$WINDOW_TITLE"         \
   --image="$ICONS/cross_red.png"  \
   --text="$MESSAGE"
 
   # Exit the script
   clear
   exit 1     
fi



# -------------------
# Select menu section
# -------------------

# Question and guidance to display
MESSAGE=$"\n Which one? \
         \n \
         \n 1. Change the Applications menu \
         \n \
         \n 2. Change the Personal menu \
         \n \
         \n \
         \n"


# Display the choices to obtain which menu to change
yad                                       \
--center                                  \
--width=0                                 \
--height=0                                \
--buttons-layout=center                   \
--button=$"Applications":0                \
--button=$"Personal":3                    \
--button="gtk-cancel":1                   \
--title="$WINDOW_TITLE"                   \
--image="$ICONS/questionmark_yellow.png"  \
--text="$MESSAGE"


# Capture which button was selected
EXIT_STATUS=$?


# When cancel button was selected or window closed
exit-upon-yad-cancel-button-or-window-close-performing-optional-command ""


# Capture which action was requested
ACTION=$EXIT_STATUS



# ------------------------------------------------------
# Hand off control of script to handle the selected menu
# ------------------------------------------------------

# Detect which menu section was chosen, assign appropriate settings, and start the corresponding script 
case "$ACTION" in
   0)   # applications menu was selected
        MENU_SECTION=$"Applications"
        . menu_manager_applications.sh
        ;;
   3)   # personal menu was selected
        MENU_SECTION=$"Personal"
        . menu_manager_personal.sh
        ;;
   *)   # Otherwise
        exit 1        
        ;;
esac



# ***** n.b. below this point control returns to this script only when the hand off script has ended with a menu refresh pending *****



# -----------------------------------------
# Rebuild the system wide applications menu
# -----------------------------------------

# When a refresh of the applications menu is pending
if [[ -n $MENU_REFRESH_PENDING_APPLICATIONS ]];then

   # Rebuild the applications menu
   /usr/local/lib/desktop-menu/desktop-menu-apt-update force
fi   



# --------------------------------
# Rebuild the user's personal menu
# --------------------------------

# When a refresh of the personal menu is pending
if [[ -n $MENU_REFRESH_PENDING_PERSONAL ]]; then
   
   # Ensure arrays to be used are empty
   WINDOW_MANAGER_CANDIDATES=()
   WINDOW_MANAGER_NAMES=()
   
      
   # Capture a list of all files in the location
   WINDOW_MANAGER_CANDIDATES=( $WINDOW_MANAGER_MENU_TEMPLATES/* )
   
   
   # Step through the list of all files by index number of each element, handle each in turn
   for ELEMENT_INDEX in "${!WINDOW_MANAGER_CANDIDATES[@]}"
   do 
      # When the element contains a value that is not a file with a .template extension
      if [[ "${WINDOW_MANAGER_CANDIDATES[$ELEMENT_INDEX]}" != *.template ]]; then
         
         # Remove the element from the array (i.e. decrement the total element index count by 1)
         unset WINDOW_MANAGER_CANDIDATES[$ELEMENT_INDEX]
      fi
   done
   
   
   # Remove the path from each file name
   WINDOW_MANAGER_CANDIDATES=( ${WINDOW_MANAGER_CANDIDATES[@]//"$WINDOW_MANAGER_MENU_TEMPLATES/"} )
   
   
   # Remove the extension from each file name to obtain the name of each window manager
   WINDOW_MANAGER_NAMES=( ${WINDOW_MANAGER_CANDIDATES[@]//.template} )
   
   
   # Step through the list of window manager names, handle each in turn
   for NAME in "${WINDOW_MANAGER_NAMES[@]}"
   do
      # Rebuild the menu for the window manager
      desktop-menu --desktop-code="$NAME"  --menu-file='/etc/xdg/menus/TCM-MENU.menu' --write-out --write-out-file='personal'   
   done
fi


# ----------------------------------------------------------------------------
# Handle the inability of JWM to display changes unless a restart is performed
# ----------------------------------------------------------------------------

# Capture the name of the currently running window manager
CURRENT_WINDOW_MANAGER=$(awk -v FS='-' '$0=$2' /home/$SUDO_USER/.desktop-session/desktop-code.0)


# When the current window manager is JWM, restart it to display the changes in the menu
[[ "$CURRENT_WINDOW_MANAGER" = "jwm" ]] && jwm -restart



# -----
# Close
# -----

# Message to display in the completion window
MESSAGE=$"\n The menu update is finished \
         \n \
         \n Exiting...
         \n"


# Display completion window
yad                              \
--center                         \
--timeout-indicator="bottom"     \
--timeout="3"                    \
--button=$"OK":1                 \
--title="$WINDOW_TITLE"          \
--image="$ICONS/tick_green.png"  \
--text="$MESSAGE"


exit 1
