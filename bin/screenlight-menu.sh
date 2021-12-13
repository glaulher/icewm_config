#!/bin/bash


# ***** Library ********************************************************

# Access the prog library
source /usr/local/lib/screenlight/lib-screenlight



# ***** Settings used solely by this script ****************************

# Capture the name of the script including file extension
PROGNAME=${0##*/}

# Set the version number
PROGVERSION=1.1



# ***** Functions used solely by this script ***************************

main()
{
   : 'Run the main trunk of the script'
   :
   : Parameters
   : ' none'
   :
   : Result
   : ' Enables editing of the configuration files and/or implementing'
   : ' the configured values'
   :
   : Example
   : ' function-name'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' entr lib-screenlight screenlight.sh'
   
   # -----Preliminaries ------------------------------------------------
   
   # Ensure multiple instances of the script cannot run concurrently
   lockfile
   
   # Ensure script detritus is removed when the script closes 
   cleanup

   
   # ----- Menu --------------------------------------------------------
   
   # Create an infinite loop, run the menu and chosen option within it
   while true
   do   
   
      # Select an item from the menu or quit the script
      INDEX=$(menu-1)
   
      # Continue or quit based on the outcome of the menu selection
      case $INDEX in
         A:)  # Apply the currently configured day values was selected
              screenlight.sh day
              ;;
         B:)  # Apply the currently configured night values was selected
              screenlight.sh night
              ;;
         C:)  # Edit day values was selected
              MODE=day
              # Employ the day conf file
		      CONFIG_FILE=$CONFIG_FILE_DAY
              ;;
         D:)  # Edit night values values was selected
              MODE=night
              # Employ the night conf file
		      CONFIG_FILE=$CONFIG_FILE_NIGHT
              ;;
        "")   # No selection made via cancel button, esc key, or window closed
              # Quit the script taking no further action
              exit 1
              ;;
      esac

   
      
      # When one of the edit modes was seleceted
      if [[ $MODE = day ]] || [[ $MODE = night ]]; then
   
         # ----- User configurable settings ----------------------------
   
         # Ensure a user editable file exists in the user home file structure
         lib_provide-file-from-skel $CONFIG_DIR $CONFIG_FILE



         # ----- Text editor selection ---------------------------------
   
         # Appoint the user's preferred editor and a fallback editor
         TEXT_EDITOR=$(assign-text-editor)
   


         # ----- Edit configuration values -----------------------------
      
         # Open the conf file for editing, capture its process id
         $TEXT_EDITOR $CONFIG_DIR/$CONFIG_FILE &
         TEXT_EDITOR_PID=$!
      
         # Open the conf file monitor, capture its process id
         echo $CONFIG_DIR/$CONFIG_FILE | entr -p screenlight.sh $MODE &
         CONF_FILE_MONITOR_PID=$!

         # Pause until the text editor is closed, terminate the conf file monitor 
         wait $TEXT_EDITOR_PID
         kill $CONF_FILE_MONITOR_PID
      fi

   
      # ----- Prepareto repeat the menu loop ---------------------------
      
      # Ensure mode is empty
      MODE=
   done
}



assign-text-editor()
{
   : 'Allocate one of two text editors'
   :
   : Parameters
   : ' none'
   :
   : Result
   : ' selects the user preferred GUI text editor and a fallback editor'
   :
   : Example
   : ' none'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' cut grep nano'
   
   local RETURN_VALUE
   
   # Capture the preferred text editor
   RETURN_VALUE=$(grep 'Exec=' $HOME/.local/share/desktop-defaults/editor.desktop | cut -d'=' -f2 | cut -d' ' -f1)
   
   # When the text editor value is empty
   if [[ $RETURN_VALUE = "" ]]; then
   
      # Nominate a fallback text editor
      RETURN_VALUE='urxvt -e nano'
   fi
   
   echo $RETURN_VALUE  
}



lockfile()
{
   : 'Lock a script to prevent it running more than once concurrently'
   :
   : Parameters
   : ' none'
   :
   : Result
   : ' Creates a lock on a script and unlocks it when the script closes'
   : ' While the lock is in force running a second instance of the script'
   : ' generates an error message and exits the script'
   :
   : Example
   : ' none'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' awk flock mkdir yad'
   
   # Capture the name of the of the script excluding path and file extension
   SCRIPT_NAME_EXC_EXTENSION=$(echo ${0%.*} | awk -F '/' '$0=$NF')
   
   # Create a file that has a file descriptor number of 9
   mkdir -p /tmp/$SCRIPT_NAME_EXC_EXTENSION
   exec 9>/tmp/$SCRIPT_NAME_EXC_EXTENSION/$SCRIPT_NAME_EXC_EXTENSION.lock
   
   # Place a lock on the file that has file descriptor number 9
   # The lock remains in force until the file is automatically closed when the script ends
   # Subsequent attempts to create a lock on the open, locked, file will fail indicating 
   # an instance of the script is already running
   # When locking the file fails
   if ! flock -n 9 ; then
     
      # Message to display in error window
      MESSAGE="\n<b><big> Error </big></b> \
               \n \n \
               \n $LIB_WINDOW_TITLE is already running. \
               \n Only one instance at a time is allowed. \
               \n \
               \n Exiting..."

      # Display error message
      yad --center                                 \
          --title="$LIB_WINDOW_TITLE"              \
          --borders="$LIB_BORDER_SIZE"             \
          --window-icon="$LIB_APP"                 \
          --image-on-top                           \
          --image="$LIB_APP"                       \
          --text-align="$LIB_TEXT_ALIGNMENT"       \
          --text="$MESSAGE"                        \
          --buttons-layout="$LIB_BUTTONS_POSITION" \
          --button="$LIB_CANCEL"                   
                
      # Exit with an error status
      exit 1
   fi
}



cleanup()
{
   : 'Remove script detritus when the script closes'
   :
   : Parameters
   : ' none'
   :
   : Result
   : ' Deletes a temporary directory tree and all contents from /tmp'
   :
   : Example
   : ' none'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' awk rm'
   
   # Capture the name of the of the script excluding path and file extension
   SCRIPT_NAME_EXC_EXTENSION=$(echo ${0%.*} | awk -F '/' '$0=$NF')
   
   # Remove items created by the script
   trap "rm -fr /tmp/$SCRIPT_NAME_EXC_EXTENSION" 0
}


menu-1()
{
   : 'Ask user to select which task to perform'
   :
   : Parameters
   : ' none'
   :
   : Result
   : ' returns the value of column 1 for the item selected in the list'
   :
   : Example
   : ' function-name'
   :
   : Note
   : 'none'
   :
   : Requires
   : ' lib-screenlight yad'
   
   local RETURN_VALUE
   
   # Question to display
   MESSAGE="\n<b><big> Which one?</big></b> \n\n"
   
   # Text to display in the menu for each column in the header row
   HEADER_COL1="Index"
   HEADER_COL2="Action"
   
   # Text to display in menu rows 1-n, columns 1,2
   ROW1_COL1=A
   ROW1_COL2="Apply the currently configured day values"
   ROW2_COL1=B
   ROW2_COL2="Apply the currently configured night values"
   ROW3_COL1=C
   ROW3_COL2="Change and apply the day values"
   ROW4_COL1=D
   ROW4_COL2="Change and apply the night values"
   
   ITEM_SELECTED=$(yad --center                                 \
                       --width=475                              \
                       --height=300                             \
                       --title="$LIB_WINDOW_TITLE"              \
                       --borders="$LIB_BORDER_SIZE"             \
                       --window-icon="$LIB_APP"                 \
                       --image-on-top                           \
                       --image="$LIB_APP"                       \
                       --text-align="$LIB_TEXT_ALIGNMENT"       \
                       --text="$MESSAGE"                        \
                       --buttons-layout="$LIB_BUTTONS_POSITION" \
                       --button="$LIB_CANCEL"                   \
                       --button="$LIB_OK"                       \
                       --list                                   \
                       --no-rules-hint                          \
                       --separator=":"                          \
                       --column $HEADER_COL1                    \
                       --column $HEADER_COL2                    \
                       --print-column="1"                       \
                       --hide-column="1"                        \
                       "$ROW1_COL1" "$ROW1_COL2"                \
                       "$ROW2_COL1" "$ROW2_COL2"                \
                       "$ROW3_COL1" "$ROW3_COL2"                \
                       "$ROW4_COL1" "$ROW4_COL2")
      
      
   # Return the value of column 1 of the selected menu item
   RETURN_VALUE=$ITEM_SELECTED
   echo $RETURN_VALUE
}



usage()
{
   : 'Show a description of the script usage when started from CLI'
   :
   : Parameters
   : ' -h|--help'
   :
   : Result
   : ' Displays help and info'
   :
   : Example
   : ' screenlight-menu.sh --help'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' cat'

   # Display the following block
cat << end-of-messageblock

$PROGNAME version $PROGVERSION
Edit and implement values in the Screenlight configuration files.

Usage: 
   $PROGNAME

Options:
   -h, --help         Show this output

Summary:
   A menu offers a choice of implement or edit Screenlight values.
   
   When the script is run it will create a day or night configuration
   file if one does not exist. Changes will not be made to screen
   brightness, contrast or colour temperature until the user edits the
   file and appends suitable values.
   
   Selecting an edit option from the menu opens the configuration file in
   the user's preferred GUI text editor. If one is not defined a fallback
   text editor is employed.
   
   The values in each configuration file adjust the following:
   Day:   screen brightness and/or contrast,
   Night: screen brightness and/or colour temperature.
   
   When a value is changed and saved it is automatically and immediately
   implemented. In this simple way the effect of a change is seen before
   closing the editor.   
               
Configuration:
   Values for screen brightness, contrast and colour temperature are in:
   $HOME/.config/screenlight-day.conf
   $HOME/.config/screenlight-night.conf
  
Requires:
   awk bash cp cut entr flock grep mkdir nano rm lib-screenlight
   screenlight.sh yad

See also:
   screenlight.sh

end-of-messageblock
   exit
}



# ***** Start the script ***********************************************
case $1 in
   "")            # Begin the main trunk of the script
                  main
                  ;;
   --help|-h)     # Show info and help
                  usage
                  ;;
   *)             # Otherwise
                  exit 1        
                  ;;
esac
