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
Show or hide items in the application section of the main menu

Usage: 
   $PROGNAME [options]
   Note: must be sourced from menu_manager.sh

Options:
   -h, --help     Show this output

Summary:
   Refer to menu_manager.sh
   
Configuration:
   Refer to menu_manager.sh
      
Environment:
   Refer to menu_manager.sh
      
Requires:
   Refer to menu_manager.sh

end-of-messageblock
   exit 0
fi



# ---------------------
# Inherit configuration
# ---------------------
   
# When this script is not being sourced
if [[ "$0" = "$BASH_SOURCE" ]]; then

   # Title in the titlebar of YAD window
   WINDOW_TITLE=$"Menu Manager"

   # Location of icons used in this script
   ICONS=/usr/share/pixmaps
   
   # Message to display in error window
   ERROR_MSG_1=$"\n This script must be started from \
                \n menu_manager.sh \
                \n \
                \n Exiting..."

   # Display an error message
   yad                             \
   --button=$"OK":1                \
   --title="$WINDOW_TITLE"         \
   --image="$ICONS/cross_red.png"  \
   --text="$ERROR_MSG_1"

   # Exit the script
   clear
   exit 1
fi



# --------------------------------------------------------------------
# Repeat all stages continually, or until the user instructs otherwise
# --------------------------------------------------------------------

# Create an infinite loop
while true
do

   # -----------------------
   # Select operational mode
   # -----------------------

   # Question and guidance to display
   MESSAGE=$"\n Which one? \
            \n \
            \n 1. Hide items from the $MENU_SECTION menu \
            \n \
            \n 2. Show items in the $MENU_SECTION menu \
            \n \
            \n \
            \n"


   # Display the choices to obtain operational mode
   yad                                       \
   --center                                  \
   --width=0                                 \
   --height=0                                \
   --buttons-layout=center                   \
   --button=$"Hide":0                        \
   --button=$"Show":3                        \
   --button="gtk-cancel":1                   \
   --title="$WINDOW_TITLE"                   \
   --image="$ICONS/questionmark_yellow.png"  \
   --text="$MESSAGE"      


   # Capture which button was selected
   EXIT_STATUS=$?


   # When cancel button was selected or window closed
   exit-upon-yad-cancel-button-or-window-close-performing-optional-command "quit-honouring-pending-menu-update"


   # Capture which action was requested
   ACTION=$EXIT_STATUS


   # Assign mode and NoDisplay values corresponding to the selected mode
   case $ACTION in
      0)  # Hide was selected
          MODE=hide
          SELECTED_NODISPLAY_VALUE=True
          ;;
      3)  # Show was selected
          MODE=show
          SELECTED_NODISPLAY_VALUE=False
          ;;
      *)  # Otherwise
          exit 1        
          ;;
   esac


  
   # ----------------------------------------
   # Select the .desktop files to be modified
   # ----------------------------------------

   # Create a list of .desktop candidates
   get-list-of-.desktop-candidates $MENU_FILES_GENERAL $MENU_FILES_ANTIX
   
   
   # Question and guidance to display
   MESSAGE=$"\n Select one or more items to $MODE \
            \n"


   # Titles to display in the list column headers
   COLUMN_HEADER_1=$"Path"
   COLUMN_HEADER_2=$"Menu Item"
   COLUMN_HEADER_3=$"Current Status"


   # Items to display in the list one item per column in each row
   LIST_ITEMS=( "${FILE_CANDIDATES_SORTED[@]}" )


   # Ensure variable to be used is empty
   SELECTED_MENU_ENTRIES=


   # Re-show the following window until it is cancelled or a selection is made   
   while [[ "$SELECTED_MENU_ENTRIES" = "" ]]
   do
      # Display the list of menu items, with path column hidden from view
      SELECTED_MENU_ENTRIES="$(yad                             \
                              --maximized                      \
                              --list                           \
                              --no-click                       \
                              --column "$COLUMN_HEADER_1":HD   \
                              --column "$COLUMN_HEADER_2":TXT  \
                              --column "$COLUMN_HEADER_3":TXT  \
                              "${LIST_ITEMS[@]}"               \
                              --print-column=1                 \
                              --multiple                       \
                              --separator=" "                  \
                              --buttons-layout=center          \
                              --button="gtk-ok":0              \
                              --button="gtk-cancel":1          \
                              --title="$WINDOW_TITLE"          \
                              --image="$ICONS/info_blue.png"   \
                              --text="$MESSAGE"                \
                             )"


      # Capture which button was selected
      EXIT_STATUS=$?


      # When cancel button was selected or window closed
      exit-upon-yad-cancel-button-or-window-close-performing-optional-command "quit-honouring-pending-menu-update"
   done


   # Set a marker that a menu update is to be performed
   MENU_REFRESH_PENDING_APPLICATIONS=Y
      

   # Create an array holding the full file path of each individual selected menu entry
   SELECTED_FILES=( $SELECTED_MENU_ENTRIES )



   # ----------------------------------
   # Modify the selected .desktop files
   # ----------------------------------

   # Step through the list of selected .desktop files, handle each in turn
   for FILE in "${SELECTED_FILES[@]}"
   do
      # Capture the first occurrence of a NoDisplay line
      CURRENT_NODISPLAY_ENTRY=$(get-1st-line-that-contains "NoDisplay=" "$FILE")

      # Capture the current NoDisplay= value
      CURRENT_NODISPLAY_VALUE=$(get-value-of-field "2" "=" "$CURRENT_NODISPLAY_ENTRY")


      # When the the file does not contain a NoDisplay entry line
      if [[ "$CURRENT_NODISPLAY_ENTRY" = "" ]]; then
   
         # Append a NoDisplay entry with the selected NoDisplay value on the line following the first occurrence of Exec=
         sed  --in-place --expression="/Exec=/{a\NoDisplay=$SELECTED_NODISPLAY_VALUE" --expression=':a;$q;n;ba;'} $FILE
     
         # Reset the current NoDisplay value to match the value appended to the file
         CURRENT_NODISPLAY_VALUE=$SELECTED_NODISPLAY_VALUE
      fi

   
      # When the the current NoDisplay value does not match the selected NoDisplay value
      if [[ "$CURRENT_NODISPLAY_VALUE" != "$SELECTED_NODISPLAY_VALUE" ]]; then

         # Replace the current NoDisplay line in the file with one containing the selected value
         sed --in-place --expression="s/$CURRENT_NODISPLAY_ENTRY/NoDisplay=$SELECTED_NODISPLAY_VALUE/" $FILE
      fi
   done
   
   
   
   # ---------------------------------------------------
   # Select refresh the menu or repeat another iteration
   # ---------------------------------------------------
   
   # Question and guidance to display
   MESSAGE=$"\n Which one? \
            \n \
            \n 1. Refresh menu \
            \n \
            \n 2. Make another change before refreshing menu \
            \n \
            \n \
            \n"

   # Display the choices to obtain whether to refresh menu or make another change
   yad                                       \
   --center                                  \
   --width=0                                 \
   --height=0                                \
   --buttons-layout=center                   \
   --button=$"Refresh":0                     \
   --button=$"Another":3                     \
   --title="$WINDOW_TITLE"                   \
   --image="$ICONS/questionmark_yellow.png"  \
   --text="$MESSAGE"      


   # Capture which button was selected
   EXIT_STATUS=$?


   # When the user chose to not make another change
   if [[ $EXIT_STATUS -ne 3 ]]; then
   
      # Refresh the menu
      break 1
   fi
done
