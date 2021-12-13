#!/bin/sh


PROGNAME=${0##*/}
PROGVERSION="7.0"



# --------------------
# Help and Information
# --------------------

# When requested show information about script
if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
cat << end-of-messageblock

$PROGNAME version $PROGVERSION 
Mounts Samba and/or NFS shares offered by a remote system(s).
The script must be started with root privileges via sudo.

Usage:
   $PROGNAME [options] [conffile]

Options:
   -h, --help     Show this output

Configuration:
   All user configurable files are placed in the directory
   /home/USERNAME/.config/connectshares/

   The default is to use connectshares.conf.

   An alternative configuration file may be used instead of the default. It can
   have any name.  The file name must appear as the first command line parameter
   when connectshares.sh is started.  This may be used to mount shares from
   multiple remote systems from a local script e.g.
   connectshares.sh  
   connectshares.sh connectshares2.conf
   connectshares.sh conffile3.conf   

Samba Shares:
   Connectshares mounts two types of Samba shares offered by a remote system.

   Shares that allow guest access are mounted without prompting for a password.
   For shares that have password controlled access, Connectshares prompts for 
   the credentials required by the remote server.  Optionally, credentials may
   be added to the configuration file and automatically supplied to the remote
   server without prompting for them. 

   Both share types may be specified in the configuration file, in which case 
   both types will be mounted.  Multiple shares may be specified for either 
   type of share by use of a comma separated list.

   Optionally, mount parameters may be itemized in the configuration file and
   applied when mounting all Samba shares.

   Mounting either type of share may be disabled by not specifying a share of 
   that type in the configuration file.

   Mounting all Samba shares may be disabled in the configuration file.

NFS Shares (Exports):
   Connectshares mounts a single type of NFS share offered by a remote system.

   The shares must be accessible without a user name and password by a local 
   system that has a vaild IP address or DNS name.

   Multiple shares must be specified as a comma separated list.

   Optionally, mount parameters may be itemized in the configuration file and
   applied when mounting all NFS shares.

   Mounting all NFS shares may be disabled in the configuration file.

Mount Points:
   Mount points are created within a subdirectory of /mnt.  A link to the 
   subdirectory is created in the user home directory.

Summary Report:
   For each configuation file used, a report file is produced in /tmp.

Requires: 
   awk, cat, chown, cifs-utils, cut, dialog, echo, grep, id,
   nfs-common|nfs-utils, ping, rm, rmdir, sed, sudo, util-linux,

Documentation:
   http://invisible-island.net/dialog
   http://nfs.sourceforge.net
   http://samba.org

See also:
   connectshares
   connectshares-config
   connectshares-config.sh
   disconnectshares
   disconnectshares.sh

end-of-messageblock
   exit 0
fi



# ----------------------
# Verify user privileges
# ----------------------

# When not run via sudo display an error message
if [ -z "$SUDO_USER" ];then
   dialog --title "Error"   \
          --no-shadow       \
          --ok-label "Exit" \
          --msgbox "\nconnectshares.sh requires root privileges. \nIt should be run via sudo. \n " \
         17 60
   clear
   exit 1
fi



# -------------
# Set variables
# -------------

# File to hold transient output
TEMPFILE1=$(mktemp -q) || TEMPFILE1=/tmp/tempfile1$$

# The location of file holding user specified settings
[ -z "$1" ] && CONFFILE="/home/$SUDO_USER/.config/connectshares/connectshares.conf"
[ -n "$1" ] && CONFFILE="/home/$SUDO_USER/.config/connectshares/$1"

# The name or IP address of the remote system serving the share(s)
REMOTE=$(grep "REMOTE" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2)

# Enable/disable the mounting of Samba shares from the remote system
SAMBA=$(grep -w "SAMBA" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2)

# The name of the domain in which the remote system serves Samba shares(s)
[ -n "$SAMBA" ] && WORKGROUP=$(grep "WORKGROUP" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2)

# Comma separated list of Samba shares on the remote system that require a user name and password
[ -n "$SAMBA" ] && SHARESUSER=$(grep "SHARESUSER" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2)

# Enable/disable automatically supplying user name and password to remote Samba server
[ -n "$SHARESUSER" ] && CREDAUTO=$(grep "CREDAUTO" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2)

# The name and password to be supplied when automatic credentials mode is enabled
[ -n "$CREDAUTO" ] && CREDNAME=$(grep "CREDNAME" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2)
[ -n "$CREDAUTO" ] && CREDPASS=$(grep "CREDPASS" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2)

# Comma separated list of Samba shares on the remote system that do not require a user name and password
[ -n "$SAMBA" ] && SHARESGUEST=$(grep "SHARESGUEST" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2)

# Options to be applied when mounting Samba shares
[ -n "$SAMBA" ] && SAMBAOPT=$(grep "SAMBAOPT" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2-)

# Enable/disable the mounting of NFS shares from the remote system
NFS=$(grep -w "NFS" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2)

# Comma separated list of NFS shares on the remote system that do not require a user name and password
[ -n "$NFS" ] && SHARESIPDNS=$(grep "SHARESIPDNS" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2)

# Options to be applied when mounting NFS shares
[ -n "$NFS" ] && NFSOPT=$(grep "NFSOPT" "$CONFFILE" | grep -v "#" | cut -d "=" -f 2-)

# Name of unprivileged user
USERID=$SUDO_USER

# Primary group of unprivileged user
GROUPID=$(id -ng $SUDO_USER)



# -----------------------
# Check for configuration
# -----------------------

# Verify the settings file is present
[ -f "$CONFFILE" ] || MISSING=y

# When settings file is not present display an error message
if [ -n "$MISSING" ]; then
   dialog --title "Error"   \
          --no-shadow       \
          --ok-label "Exit" \
          --msgbox "\nA configuration file must be present in \n/home/$SUDO_USER/.config/connectshares \n " \
          17 60
   clear
   rm $TEMPFILE1
   exit 1
fi

# Verify a share server has been specified
[ -z "$REMOTE" ] && MISSING=y && echo "Remote system name or address" >> $TEMPFILE1
 
# Check whether Samba shares are to be mounted
if [ -n "$SAMBA" ]; then

   # Verify workgroup and share(s) have been specified
   [ -z "$WORKGROUP" ] && MISSING=y && echo "Samba workgroup" >> $TEMPFILE1
   [ -z "$SHARESUSER" ] && [ -z "$SHARESGUEST" ] && MISSING=y && echo "Samba share(s)" >> $TEMPFILE1

   # When automatic supply of credentials specified verify they have been provided
   if [ -n "$CREDAUTO" ]; then
      [ -z "$CREDNAME" ] || [ -z "$CREDPASS" ] && MISSING=y && echo "Samba credentials" >> $TEMPFILE1
   fi
fi

# Check whether NFS shares are to be mounted
if [ -n "$NFS" ]; then

   # Verify share(s) have been specified
   [ -z "$SHARESIPDNS" ] && MISSING=y && echo "NFS share(s)" >> $TEMPFILE1
fi

# When any configuration item is not present display an error message
   if [ -n "$MISSING" ]; then
      dialog --title "Error"   \
             --no-shadow       \
             --cr-wrap         \
             --ok-label "Exit" \
             --msgbox "\nIncomplete configuration for \n\n$(cat $TEMPFILE1) \n" \
             17 60
      clear
      rm $TEMPFILE1
      exit 1
   fi



# -------------------------------------
# Check for connection to remote system
# -------------------------------------

# Display message throughout attempt to contact share server
dialog --title "Checking"                              \
       --no-shadow                                     \
       --infobox "\nAttempting to contact $REMOTE \n " \
       17 60

# Verify the system serving the shares can be contacted, display an error message on failure
if ! ping -c 3 -W 1 $REMOTE 2>&1 >/dev/null ; then
   dialog --title "Error"                            \
          --no-shadow                                \
          --ok-label "Exit"                          \
          --msgbox "\nUnable to contact $REMOTE \n " \
          17 60
   clear
   rm $TEMPFILE1
   exit 1
fi



# --------------------------------------------------------------------
# Obtain user input of credentials for Samba password protected shares
# --------------------------------------------------------------------

# Verify manually supplying credentials is required
if [ -n "$SHARESUSER" ] && [ -z "$CREDAUTO" ]; then

   # Obtain both parts of credentials
   until [ -n "$CREDNAME" ] && [ -n "$CREDPASS" ]
   do
      # Request the user name and password
      dialog  --title "Credentials"                    \
              --no-shadow                              \
              --insecure                               \
              --mixedform "\nEnter name and password to access protected shares on $REMOTE \n " \
              17 60 0                                  \
              "Username        :" 1 1	"" 1 20 10 0 0 \
              "Password        :" 2 1	"" 2 20 10 0 1 \
              2> $TEMPFILE1

      # Check if user selected cancel button or closed the window
      [ "$?" != 0 ] && clear && exit 1 

      # Assign the separate parts of credentials to variables
      CREDNAME=$(sed -n '1p' $TEMPFILE1)
      CREDPASS=$(sed -n '2p' $TEMPFILE1)

      # Empty the temporary file
      cat /dev/null > $TEMPFILE1
   done
fi



# ------------
# Mount shares
# ------------

# Create a combined list of Samba and NFS shares
SHARESLIST="$SHARESUSER$SHARESGUEST$SHARESIPDNS"

# Save the default IFS value then set IFS value to a comma
IFSDEFAULT=$IFS
IFS=,

# Sequentially get each share name and process it
for SHARE in $SHARESLIST
do
   # Verify share is currently not mounted to avoid multiple mounts
   if [ -z "$(mount | grep "$REMOTE"/"$SHARE")" ] && [ -z "$(mount | grep "$REMOTE":"$SHARE")" ]; then

      # Check whether Samba share and ensure a mountpoint is avaialble
      if [ -n "$(echo $SHARESUSER $SHARESGUEST | grep "$SHARE")" ]; then
         [ -d /mnt/"$REMOTE"/"$SHARE"' on '"$REMOTE" ] || mkdir -p /mnt/"$REMOTE"/"$SHARE"' on '"$REMOTE"
      fi

      # Check whether NFS share and ensure a mountpoint is avaialble
      if [ -n "$(echo $SHARESIPDNS | grep "$SHARE")" ]; then
         NFSDIR="$(echo "$SHARE" | awk -F / '{ print $NF }')"
         [ -d /mnt/"$REMOTE"/"$NFSDIR"' on '"$REMOTE" ] || mkdir -p /mnt/"$REMOTE"/"$NFSDIR"' on '"$REMOTE"
      fi

      # Check share type and set mount options to match
      [ -n "$(echo $SHARESUSER | grep "$SHARE")" ] && MOUNTOPT="dom=$WORKGROUP,user=$CREDNAME,pass=$CREDPASS,uid=$USERID,gid=$GROUPID,$SAMBAOPT"
      [ -n "$(echo $SHARESGUEST | grep "$SHARE")" ] && MOUNTOPT="dom=$WORKGROUP,user=guest,sec=none,uid=$USERID,gid=$GROUPID,$SAMBAOPT"
      [ -n "$(echo $SHARESIPDNS | grep "$SHARE")" ] && MOUNTOPT="$NFSOPT"

      # Mount Samba share, suppress any error message, and set failure indicator if mount fails
      if [ -n "$(echo $SHARESUSER $SHARESGUEST | grep "$SHARE")" ]; then
         mount //"$REMOTE"/"$SHARE" /mnt/"$REMOTE"/"$SHARE"' on '"$REMOTE" -o "$MOUNTOPT" 2>/dev/null
         [ "$?" = 0 ] || MOUNTFAILED="$SHARE"' on '"$REMOTE"
      fi

      # Mount NFS share, suppress any error message, and set failure indicator if mount fails
      if [ -n "$(echo $SHARESIPDNS | grep "$SHARE")" ]; then
         mount "$REMOTE":"$SHARE" /mnt/"$REMOTE"/"$NFSDIR"' on '"$REMOTE" -o "$MOUNTOPT" 2>/dev/null
         ERRORCODE="$?"
         [ "$ERRORCODE" = 0 ] || [ "$ERRORCODE" = 16 ] || MOUNTFAILED="$NFSDIR"' on '"$REMOTE"
      fi

      # Check if share failed to mount
      if [ -n "$MOUNTFAILED" ]; then

         # Create an error message
         MOUNTMSG="Did not mount $MOUNTFAILED"

         # Append error message to temporary file
         echo "$MOUNTMSG" >> $TEMPFILE1

         # Display error message
         dialog --title "Error"                              \
                --no-shadow                                  \
                --sleep 3                                    \
                --infobox "\nDid not mount $MOUNTFAILED \n " \
                17 60 

         # Delete the failed mount point only if empty
         rmdir "/mnt/$REMOTE/$MOUNTFAILED"

         # Set failure indicator to empty
         MOUNTFAILED=
      fi
   fi
done

# Restore the default IFS value
IFS=$IFSDEFAULT




# -------------------------------------------------------
# Make the shares accessible from the user home directory
# -------------------------------------------------------

# Ensure a link to the shares is present in the user home directory
if ! [ -L /home/$SUDO_USER/$REMOTE ]; then
   ln -s /mnt/$REMOTE /home/$SUDO_USER/$REMOTE
   chown --no-dereference $SUDO_USER:$(id -ng $SUDO_USER) /home/$SUDO_USER/$REMOTE
fi



# -----------------------------------------------------
# Summarize the status of shares from the remote system
# -----------------------------------------------------

# Note any failed mount attempts were previously appended to temporary file 1

# Append to the summary file a blank line and a heading
echo " " >> $TEMPFILE1
echo "The following shares are mounted:" >> $TEMPFILE1

# Append to the summary file a list of shares from the remote system that are mounted locally
{  grep "$REMOTE" /etc/mtab |     \
   awk '/\/mnt\// { print $2 }' | \
   awk -F / '{ print $4 }' |      \
   sed 's/\\040/ /g' >> $TEMPFILE1
}

# Append to the summary file blank lines
echo " " >> $TEMPFILE1
echo " " >> $TEMPFILE1

# Display the summary
dialog --title "Summary"                   \
       --no-shadow                         \
       --sleep 5                           \
       --cr-wrap                           \
       --infobox "\n$(cat $TEMPFILE1) \n " \
       17 60

# Save the summary report
cat $TEMPFILE1 > /tmp/connectshares"$1".rpt



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
