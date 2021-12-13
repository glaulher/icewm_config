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
Add or remove items in the personal section of the main menu

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



# --------------------------------------------
# Ensure the required personal location exists
# --------------------------------------------

# When the directory for user created .desktop files in the personal menu does not exist
if [[ ! -d $MENU_FILES_USER_PERSONAL ]]; then
   
   # Create the directory
   mkdir -p $MENU_FILES_USER_PERSONAL
   
   # Assign ownership to the user
   chown $SUDO_USER:$SUDO_USER $MENU_FILES_USER_PERSONAL
fi



# -----------------------------------------------------------------
# Repeat all stages continuously until the user instructs otherwise
# -----------------------------------------------------------------

# Create an infinite loop
while true
do

   # -----------------------
   # Select operational mode
   # -----------------------

   # Question and guidance to display
   MESSAGE=$"\n Which one? \
            \n \
            \n 1. Add items to the $MENU_SECTION menu \
            \n \
            \n 2. Remove items from the $MENU_SECTION menu \
            \n \
            \n \
            \n"


   # Display the choices to obtain operational mode
   yad                                       \
   --center                                  \
   --width=0                                 \
   --height=0                                \
   --buttons-layout=center                   \
   --button=$"Add":0                         \
   --button=$"Remove":3                      \
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
          MODE=add
          ;;
      3)  # Show was selected
          MODE=remove
          ;;
      *)  # Otherwise
          exit 1        
          ;;
   esac


 
   # -----------
   # Add an item
   # -----------

   # When add an item was selected
   if [[ "$MODE" = "add" ]]; then
   
      
      
      # -----------------------------------------------
      # Select a .desktop file to be used as a template
      # -----------------------------------------------

      # Create a list of .desktop candidates
      get-list-of-.desktop-candidates $MENU_FILES_GENERAL $MENU_FILES_ANTIX $MENU_FILES_USER_PERSONAL
         
   
      # Question and guidance to display
      MESSAGE=$"\n Select an item to $MODE \
               \n"


      # Titles to display in the list column headers
      COLUMN_HEADER_1=$"Path"
      COLUMN_HEADER_2=$"Menu Item"
      COLUMN_HEADER_3=$"Current Status"


      # Items to display in the list one item per column in each row
      LIST_ITEMS=( "${FILE_CANDIDATES_SORTED[@]}" )
      
      
      # Ensure variable to be used is empty
      SELECTED_MENU_ENTRY=

      # Re-show the following window until it is cancelled or a selection is made   
      while [[ "$SELECTED_MENU_ENTRY" = "" ]]
      do 
         # Display the list of menu items, with path and status columns hidden from view
         SELECTED_MENU_ENTRY="$(yad                              \
                                --maximized                      \
                                --list                           \
                                --no-click                       \
                                --column "$COLUMN_HEADER_1":HD   \
                                --column "$COLUMN_HEADER_2":TXT  \
                                --column "$COLUMN_HEADER_3":HD   \
                                "${LIST_ITEMS[@]}"               \
                                --print-column=1                 \
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
      

      # Ensure array to be used is empty
      SELECTED_FILE=
      
      # Create an array holding the full file path of the selected menu entry
      SELECTED_FILE=( $SELECTED_MENU_ENTRY )
   
   
   
      # ------------------------------------------------------
      # Create values for the entries of the new .desktop file
      # ------------------------------------------------------
      
      # Assign a value to enable a check to be performed for characters that are problematical for yad to handle
      PROBLEM_CHARACTERS_YAD=found
       
      # Repeat until the characters specified by the user are verified OK, or the user exits
      until [[ "$PROBLEM_CHARACTERS_YAD" = "none-found" ]];
      do
         
         
         
         # ---------------------------------------------------------------
         # Assign fallback values from the selected template .desktop file
         # ---------------------------------------------------------------
         
         # Assign fixed values common to every user created personal .desktop file
         HEADER_VALUE="[Desktop Entry]"
         ENCODING_VALUE="UTF-8"
         NODISPLAY_VALUE="False"
         CATEGORIES_VALUE="X-Personal;"
         
         # Assign user selectable values that differ for each user created personal .desktop file
         NAME_VALUE=$(get-value-of-last-field-in-1st-line-that-contains "^Name=" "=" "$SELECTED_FILE")
         EXEC_VALUE=$(get-value-of-last-field-in-1st-line-that-contains "^Exec=" "=" "$SELECTED_FILE")
         ICON_VALUE=$(get-value-of-last-field-in-1st-line-that-contains "^Icon=" "=" "$SELECTED_FILE")
         TERMINAL_VALUE=$(get-value-of-last-field-in-1st-line-that-contains "^Terminal=" "=" "$SELECTED_FILE")
         
         # Assign a default value for the terminal entry to cater for cases where it is not present in the template .desktop file
         [[ -z $TERMINAL_VALUE ]] && TERMINAL_VALUE=False
         
         
         
         # -------------------------------------------------------
         # Provide an opportunity to customise the fallback values
         # -------------------------------------------------------
         
         # Guidance to display at the top of the window
         MESSAGE=$"\n Optional customisation \
                  \n If desired, you may change the following \
                  \n \
                  \n "
         
         # Guidance to display re the name to display in the menu
         LABEL_1=$"The name to display in the $MENU_SECTION menu"
         
         # Guidance to display re the parameters to use when launching the app
         LABEL_2=$"Append any launch parameters \
                \ne.g. template name, web site address"
             
         # Guidance to display re the automatically selected icon
         LABEL_3=$"The default icon to display"
         
         # Guidance to display re using an alternative to the automatically selected icon
         LABEL_4=$"\nTick to select an alternative icon \
                  \nor to use no icon"         
         
         # Guidance to display re whether to launch the app in a terminal
         LABEL_5=$"\nTick to launch in a terminal"
         
         # Ensure the temporary file does not contain anything from a previous iteration
         printf '%s' /dev/null > $TEMP_FILE
         
         # Re-show the following window if either name or exec fields are empty
         while [[ -z $(get-value-of-field "1" "|" "$(cat $TEMP_FILE)") ]] || \
               [[ -z $(get-value-of-field "2" "|" "$(cat $TEMP_FILE)") ]]
         do         
            yad                                       \
            --title="$WINDOW_TITLE"                   \
            --center                                  \
            --width=600                               \
            --height=300                              \
            --image="$ICONS/info_blue.png"            \
            --text="$MESSAGE"                         \
            --buttons-layout=center                   \
            --button="gtk-ok":0                       \
            --button="gtk-cancel":1                   \
            --form                                    \
            --field="$LABEL_1"     "$NAME_VALUE"      \
            --field="$LABEL_2"     "$EXEC_VALUE"      \
            --field="$LABEL_3":RO  "$ICON_VALUE"      \
            --field="$LABEL_4":CHK ""                 \
            --field="$LABEL_5":CHK "$TERMINAL_VALUE"  \
            > $TEMP_FILE


            # Capture which button was selected
            EXIT_STATUS=$?


           # When cancel button was selected or window closed
            exit-upon-yad-cancel-button-or-window-close-performing-optional-command "quit-honouring-pending-menu-update"
         done
         
         
         
         # ----------------------------------------------------------------------------------------
         # Ensure edited customised values do not contain characters that are problematical for yad
         # ----------------------------------------------------------------------------------------
         
         # Message to display in error window
         MESSAGE=$"\n The name to display in the $MENU_SECTION menu \
                  \n should not include any of these characters \
                  \n \
                  \n &amp; * = | / &lt; &gt; \
                  \n "

         # When the user has specified characters that are not problematical to yad
         # ***** n.b. the | symbol must be handled separately because it is used as the field separator character in the first test *****
         if [[ -z $(get-value-of-field "1" "|" "$(cat $TEMP_FILE)" | grep -e '&' -e '*' -e '=' -e '/' -e '<' -e '>') ]] && \
            [[ $(awk -v FS='|' '$0=NF-1' $TEMP_FILE) -eq 5 ]]; then
            
            # Ensure edited customised values are used instead of the fallback values
            NAME_VALUE=$(get-value-of-field "1" "|" "$(cat $TEMP_FILE)")
            EXEC_VALUE=$(get-value-of-field "2" "|" "$(cat $TEMP_FILE)")
               
            # Assign a value to indicate that no characters were detected that are problematical for yad to handle
            PROBLEM_CHARACTERS_YAD=none-found
                    
            # When the user has specified characters that are problematical to yad
            else
                  
            # Display an error message
            yad                             \
            --title="$WINDOW_TITLE"         \
            --center                        \
            --buttons-layout=center         \
            --button="gtk-ok:0"             \
            --title="$WINDOW_TITLE"         \
            --image="$ICONS/cross_red.png"  \
            --text="$MESSAGE"
         fi 
      done
      
      
      
         # --------------------------------------------------------
         # Handle variations in the formation of the terminal value
         # --------------------------------------------------------
      
         # Ensure the terminal value is correctly formed
         [[ "$(get-value-of-field "5" "|" "$(cat $TEMP_FILE)")" = "FALSE" ]] && TERMINAL_VALUE=False || TERMINAL_VALUE=True
         
         
         
         # ----------------------------------------------------------------------------
         # Optional use no icon or manually select a graphic file to be used as an icon
         # ----------------------------------------------------------------------------
         
         # When the user chose to not accept the fallback icon            
         if [[ "$(get-value-of-field "4" "|" "$(cat $TEMP_FILE)")" = "TRUE" ]]; then
         
            # Question and guidance to display
            MESSAGE=$"\n Which one? \
                     \n \
                     \n 1. Select icon manually \
                     \n \
                     \n 2. No icon \
                     \n \
                     \n \
                     \n"
   
   
            # Display the choices for icon selection
            yad                                       \
            --center                                  \
            --width=0                                 \
            --height=0                                \
            --buttons-layout=center                   \
            --button=$"Select Icon":0                 \
            --button=$"No Icon":3                     \
            --button="gtk-cancel":1                   \
            --title="$WINDOW_TITLE"                   \
            --image="$ICONS/questionmark_yellow.png"  \
            --text="$MESSAGE"      
   
   
            # Capture which button was selected
            EXIT_STATUS=$?
   
   
            # When cancel button was selected or window closed
            exit-upon-yad-cancel-button-or-window-close-performing-optional-command "quit-honouring-pending-menu-update"

            
            # When the user opted to select an icon manually
            if [[ $EXIT_STATUS -eq 0 ]]; then
            
               # Guidance to display
               MESSAGE=$"\n Browse to select an icon to display for the new item \
                        \n"

                              
               # Display the directory containing installed icon themes
               SELECTED_ICON="$(yad                             \
                                --maximized                     \
                                --file                          \
                                --filename="$ICON_THEMES"       \
                                --file-filter="$ICON_TYPES"     \
                                --add-preview                   \
                                --buttons-layout=center         \
                                --button="gtk-ok":0             \
                                --button="gtk-cancel":1         \
                                --image="$ICONS/info_blue.png"  \
                                --text="$MESSAGE"               \
                               )"

   
               # Capture which button was selected
               EXIT_STATUS=$?
   
   
               # When cancel button was selected or window closed
               exit-upon-yad-cancel-button-or-window-close-performing-optional-command "quit-honouring-pending-menu-update"

            # When the user opted for no icon
            else
               
               # Assign an empty value
               SELECTED_ICON=               
            fi
            
            
            # Overwite the fallback icon value with the user selected value
            ICON_VALUE=$SELECTED_ICON            
         fi
  
         
         
      # ------------------------------------------------------------------------
      # Create the new .desktop file containing the required and desired entries 
      # ------------------------------------------------------------------------
      
      # Assign the major part of the file name by replacing each space with _ from name value
      FILE_NAME_MAIN=$(echo $NAME_VALUE | sed --expression 's/ /_/g')
      
      # Assign the minor part of the file name by calculating the number of seconds since 1970-01-01
      SECONDS_SINCE_EPOCH=$(date +%s)
      
      # Construct the file name
      FILE_NAME="$FILE_NAME_MAIN"_"$SECONDS_SINCE_EPOCH".desktop
      
      
      # Write the finished .desktop file      
      printf '%s\n' "$HEADER_VALUE"                \
                    "Encoding=$ENCODING_VALUE"     \
                    "Name=$NAME_VALUE"             \
                    "Exec=$EXEC_VALUE"             \
                    "Icon=$ICON_VALUE"             \
                    "Categories=$CATEGORIES_VALUE" \
                    "NoDisplay=$NODISPLAY_VALUE"   \
                    "Terminal=$TERMINAL_VALUE"     > $MENU_FILES_USER_PERSONAL/"$FILE_NAME"
 
      
      # Assign the ownership of the finished .desktop file to the user
      chown $SUDO_USER:$SUDO_USER $MENU_FILES_USER_PERSONAL/"$FILE_NAME"
      
         
      # Set a marker that a menu update is to be performed
      MENU_REFRESH_PENDING_PERSONAL=Y
   fi



   # --------------
   # Remove an item
   # --------------

   # When remove an item was selected
   if [[ "$MODE" = "remove" ]]; then
   
      
      
      # --------------------------------
      # Select a .desktop file to delete
      # --------------------------------

      # Create a list of .desktop candidates
      get-list-of-.desktop-candidates $MENU_FILES_USER_PERSONAL
      
   
      # Question and guidance to display
      MESSAGE=$"\n Select an item to $MODE \
               \n"

      # Titles to display in the list column headers
      COLUMN_HEADER_1=$"Path"
      COLUMN_HEADER_2=$"Menu Item"
      COLUMN_HEADER_3=$"Current Status"

      # Items to display in the list one item per column in each row
      LIST_ITEMS=( "${FILE_CANDIDATES_SORTED[@]}" )
      
      # Ensure variable to be used is empty
      SELECTED_MENU_ENTRY=

      # Re-show the following window until it is cancelled or a selection is made   
      while [[ "$SELECTED_MENU_ENTRY" = "" ]]
      do 
         # Display the list of menu items, with path and status columns hidden from view
         SELECTED_MENU_ENTRY="$(yad                              \
                                --maximized                      \
                                --list                           \
                                --no-click                       \
                                --column "$COLUMN_HEADER_1":HD   \
                                --column "$COLUMN_HEADER_2":TXT  \
                                --column "$COLUMN_HEADER_3":HD   \
                                "${LIST_ITEMS[@]}"               \
                                --print-column=1                 \
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
      

      # Ensure array to be used is empty
      SELECTED_FILE=
      
      # Create an array holding the full file path of the selected menu entry
      SELECTED_FILE=( "$SELECTED_MENU_ENTRY" )
      
      # Delete the file
      rm $SELECTED_FILE
      
      # Set a marker that a menu update is to be performed
      MENU_REFRESH_PENDING_PERSONAL=Y
   fi
   
   

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
