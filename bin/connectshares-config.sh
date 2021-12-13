#!/bin/sh 


PROGNAME=${0##*/}
PROGVERSION="7.0"



# --------------------
# Help and Information
# --------------------

# Test for a help request
if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
cat << end-of-messageblock

$PROGNAME version $PROGVERSION
Display an interactive menu to set up information used by connectshares.sh

Usage: 
   $PROGNAME [options]

Options:
   -h, --help     Show this output

Summary:
   Searches the LAN for remote servers offering NFS exports and Samba shares.
   The discovered information is used to create a configuration file via a 
   built-in text editor.  Options are also available to create additional 
   configuration files and to delete unwanted ones.

Requires:  
   cat, dialog, findshares, mktemp, rm

Documentation:
   http://invisible-island.net/dialog
   http://tinycorelinux.net/3.x/tcz/findshares.tcz.info

See also:
   connectshares
   connectshares.sh
   connectshares-config
   disconnectshares
   disconnectshares.sh

end-of-messageblock
   exit 0
fi



# -------------
# Set Variables
# -------------

# File to hold transient output
TEMPFILE1=$(mktemp -q) || TEMPFILE1=/tmp/tempfile1$$



# ------------------------------
# Main menu and help-button text
# ------------------------------

# Display main menu window until operation cancelled
while [ "$?" != -1 ]
do
   dialog  --title "[Arrows] to move up/down   [Enter] to select" \
           --no-shadow \
           --help-button \
           --menu "\n " \
           25 80 5 \
           "1" "Find shares offered by a remote system" \
           "2" "Nominate shares to connect from remote system" \
           "3" "Create a new configuration file" \
           "4" "Delete a configuration file" \
           2> $TEMPFILE1
   EXITCODE="$?"

   # Check if user selected cancel button or closed the window
   [ "$EXITCODE" = 1 ] || [ "$EXITCODE" = 255 ] && exit

   # Check for a help request and display when asked
   [ "$EXITCODE" = 2 ] &&
   dialog --title "[Arrows] to scroll up/down" \
          --no-shadow \
          --cr-wrap \
          --trim \
          --msgbox "$(cat << end-of-messageblock)" \
          25 80

   Setting up to connect to remote shares is usually done once only.
   It takes two steps.


   Step 1 - Discover which shares are available
   --------------------------------------------

   Select menu option "1. Find shares offered by a remote system"
   This searches the network for file servers and the shares they are serving.

   In the majority of cases servers and shares are found without a problem.
   If none are shown, check:
   * The remote server is allowed to send out information
   * The local system firewall is not blocking the reply being received

   After a successful discovery, a summary is displayed from which you choose 
   the shares to connect to your system.  You enter your choices in step 2.


   Step 2 - Save your choice of shares in a file
   ---------------------------------------------

   Select menu option "2. Nominate shares to connect from remote system"
   This enables you to select the file and open it ready to add the
   server and share details.  

   The default configuration file is named connectshares.conf. Use this when 
   connecting to shares from a single remote system.

   Using the examples provided, enter the information from the discovery step.

   After entering the details, setting up is complete.  Your choices will be 
   automatically used when connecting to the remote system.


   Other Menu Options
   ------------------

   When connecting to shares from multiple remote systems, a configuration 
   file for each system is required.  To set up an additional file
   Select menu option "3. Create a new configuration file"
   This copies the file "template.conf" to a new file.  You may give the
   file any name.  The file is automatically opened ready to add the 
   additional server and share details.

   A redundant configuration file may be removed from your system.
   Select menu option "4. Delete a configuration file"
   This enables you to select the file to be deleted.

end-of-messageblock



   # ---------------------------------------------
   # Configuration actions selected from main menu
   # ---------------------------------------------

   # Menu item 1 display list of shares offered by remote servers
   if [ "$(cat $TEMPFILE1)" = 1 ]; then
      findshares > $TEMPFILE1
      dialog --title "[Arrows] to scroll up/down" \
             --no-shadow \
             --textbox "$TEMPFILE1" \
             25 80
   fi



   # Menu item 2 select and edit an existing configuration file
   if [ "$(cat $TEMPFILE1)" = 2 ]; then 

      # Display file selection window until operation cancelled or file edited
      while [ "$?" != -1 ]
      do
         # Select a configuration file to edit
         dialog --title "[Tab] change panel  [Arrows] move up/down  [Spacebar] use cursor item" \
                --no-shadow \
                --fselect "$HOME/.config/connectshares/" \
                15 80 \
                2> $TEMPFILE1

         # Check whether user cancelled or closed window via escape key
         [ "$?" != 0 ] && break

         # Verify a file was selected
         CONFFILE=$(cat $TEMPFILE1)
         [ -f "$CONFFILE" ] && EDITFILE=y || EDITFILE=

         # Edit the configuration file
         if [ -n "$EDITFILE" ]; then
            dialog --title "[Keys] edit   [Enter] new line" \
                   --no-shadow \
                   --no-cancel \
                   --ok-label "Save & Close" \
                   --editbox "$CONFFILE" \
                  25 80 \
                  2> $TEMPFILE1
            [ "$?" = 0 ] && cat $TEMPFILE1 > $CONFFILE
            break
         fi
 
         # Display a message when the file selected is invalid
         if [ -z "$EDITFILE" ]; then
            dialog --title "Error" \
                   --no-shadow \
                   --msgbox "\nThe selected configuration file is invalid" \
                   25 80
         fi
      done
   fi



   # Menu item 3 create and edit a new configuration file
   if [ "$(cat $TEMPFILE1)" = 3 ]; then 

      # Display file selection window until operation cancelled or file selected
      while [ "$?" != -1 ]
      do
         # Request name of configuration file to create
         dialog --title "Enter a name for the new file" \
                --no-shadow \
                --fselect "$HOME/.config/connectshares/" \
                15 80 \
                2> $TEMPFILE1

         # Check whether user cancelled or closed window via escape key
         [ "$?" != 0 ] && break

         # When the file does not exist create it
         CONFFILE=$(cat $TEMPFILE1)
         [ ! -f "$CONFFILE" ] && cp $HOME/.config/connectshares/template.conf $CONFFILE && NEWFILE=y || NEWFILE=

         # Edit the file
         if [ -n "$NEWFILE" ]; then
            dialog --title "[Keys] edit   [Enter] new line" \
                   --no-shadow \
                   --no-cancel \
                   --ok-label "Save & Close" \
                   --editbox "$CONFFILE" \
                   25 80 \
                   2> $TEMPFILE1
            [ "$?" = 0 ] && cat $TEMPFILE1 > $CONFFILE
         fi

         # When the file already exists display a message
         if [ -z "$NEWFILE" ]; then
            dialog --title "Error" \
                   --no-shadow \
                   --msgbox "\nEither the file already exists or the name is invalid" \
                   25 80
         fi 
      done
   fi



   # Menu item 4 delete a configuration file
   if [ "$(cat $TEMPFILE1)" = 4 ]; then 

      # Display file selection window until operation cancelled
      while [ "$?" != -1 ]
      do
         # Obtain name of configuration file to delete
         dialog --title "[Tab] change panel  [Arrows] move up/down  [Spacebar] use cursor item" \
                --no-shadow \
                --fselect "$HOME/.config/connectshares/" \
                15 80 \
                2> $TEMPFILE1

         # Check whether user cancelled or closed window via escape key
         [ "$?" != 0 ] && break

         # Verify a file was specified
         CONFFILE=$(cat $TEMPFILE1)
         [ -f $CONFFILE ] && DELFILE=y || DELFILE=

         # Obtain confirmation to delete file and remove it when received
         if [ -n "$DELFILE" ]; then
            dialog --title "Confirmation" \
                   --no-shadow \
                   --yesno "\nDelete $CONFFILE?" \
                   25 80
            [ "$?" = 0 ] && rm --force --one-file-system "$CONFFILE"
         fi

         # Display a message when the specified file is invalid
         if [ -z "$DELFILE" ]; then
            dialog --title "Error" \
                   --no-shadow \
                   --msgbox "\nUnable to delete the specified file" \
                   25 80 
         fi
      done
   fi
done



# --------
# Clean up
# --------

# Delete the temporary file
rm $TEMPFILE1



# -----
# Close
# -----

clear 
exit 0
