#! /bin/sh


PROGNAME=${0##*/}
PROGVERSION="7.0"



# --------------------
# Help and Information
# --------------------

# Test for a help request
if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
cat << end-of-messageblock

$PROGNAME version $PROGVERSION 
Unmount remote shares from the local system

Usage:
   $PROGNAME [options]

Options:
   -h, --help     Show this output

Summary:
   Remote CIFS and NFS shares that are mounted on to the local
   file system are presented in an interactive menu.  From the
   menu, one or more shares may be selected and unmounted.

   A report file summarizing the outcome is produced in /tmp.

Requires:  
   awk, cat, cut, grep, dialog, mktemp, sed, sync, umount

Documentation:
   http://invisible-island.net/dialog

See also:
   connectshares
   connectshares.sh
   connectshares-config
   connectshares-config.sh
   disconnectshares

end-of-messageblock
   exit 0
fi



# ----------------------
# Verify user privileges
# ----------------------

#  When not run via sudo display an error message
if [ -z "$SUDO_USER" ];then
   dialog --title "Error"   \
          --no-shadow       \
          --ok-label "Exit" \
          --msgbox "\ndisconnectshares.sh requires root privileges. \nIt should be run via sudo. \n " \
         15 50
   clear
   exit 1
fi



# -------------
# Set Variables
# -------------

# File to hold transient output
TEMPFILE1=$(mktemp -q) || TEMPFILE1=/tmp/tempfile1$$

#  Save the default IFS value then set IFS value to a comma
IFSDEFAULT=$IFS
IFS=,



# ---------
# Main Menu
# ---------

#  Create a comma separated list of remote share names mounted on the local system
{  grep -E 'cifs|nfs' /etc/mtab | \
   awk '/\/mnt\// { print $2 }' | \
   awk -F / '{ print $4 }' |      \
   sed 's/$/,/;s/\\040/ /g' > $TEMPFILE1
}

#  Create vars for dialog checklist parameters tag, item, status, for each share name
COUNTER=1
#  Note: while loop data input at end of do/done
while read SHARENAME
do
   case $COUNTER in
      1)  TAG1=$COUNTER  && ITEM1=$SHARENAME  && STATUS1=off  ;;
      2)  TAG2=$COUNTER  && ITEM2=$SHARENAME  && STATUS2=off  ;;
      3)  TAG3=$COUNTER  && ITEM3=$SHARENAME  && STATUS3=off  ;;
      4)  TAG4=$COUNTER  && ITEM4=$SHARENAME  && STATUS4=off  ;;
      5)  TAG5=$COUNTER  && ITEM5=$SHARENAME  && STATUS5=off  ;;
      6)  TAG6=$COUNTER  && ITEM6=$SHARENAME  && STATUS6=off  ;;
      7)  TAG7=$COUNTER  && ITEM7=$SHARENAME  && STATUS7=off  ;;
      8)  TAG8=$COUNTER  && ITEM8=$SHARENAME  && STATUS8=off  ;;
      9)  TAG9=$COUNTER  && ITEM9=$SHARENAME  && STATUS9=off  ;;
      10) TAG10=$COUNTER && ITEM10=$SHARENAME && STATUS10=off ;;
   esac
   COUNTER=$(expr $COUNTER + 1)
done < $TEMPFILE1 

#  Display the interactive menu of share names available for unmounting
#+ and create a list of shares tagged for unmounting
   dialog --title "[Arrows] move up/down     [Spacebar] mark for disconnection" \
          --no-shadow                    \
          --separate-output              \
          --checklist "" 20 70 20        \
          $TAG1  $ITEM1  $STATUS1        \
          $TAG2  $ITEM2  $STATUS2        \
          $TAG3  $ITEM3  $STATUS3        \
          $TAG4  $ITEM4  $STATUS4        \
          $TAG5  $ITEM5  $STATUS5        \
          $TAG6  $ITEM6  $STATUS6        \
          $TAG7  $ITEM7  $STATUS7        \
          $TAG8  $ITEM8  $STATUS8        \
          $TAG9  $ITEM9  $STATUS9        \
          $TAG10 $ITEM10 $STATUS10       \
          2> $TEMPFILE1

#  Check if user selected cancel button or closed the window
[ "$?" != 0 ] && clear && rm $TEMPFILE1 && exit 1 

#  Transfer values and empty temporary file
TAGGED=$(cat $TEMPFILE1)
cat /dev/null > $TEMPFILE1



# --------------------------------------
# Correlate tagged shares to mountpoints
# --------------------------------------

#  Create a numbered, comma separated list of mountpoints of shares currently mounted
{  MOUNTED=$(grep -E 'cifs|nfs' /etc/mtab | \
   awk '/\/mnt\// { print $2 }' |           \
   sed = | sed 'N;s/\n/ /;s/$/,/;s/\\040/ /g')
}

#  Create a list of mountpoints corresponding to the tagged shares
echo "$TAGGED" | while read TAGGEDLINE
do
   echo "$MOUNTED" | while read MOUNTEDLINE
   do
      if [ "$TAGGEDLINE" = $(echo "$MOUNTEDLINE" | cut -d " " -f 1) ]; then
         echo "$(echo "$MOUNTEDLINE" | cut -d " " -f 2-)" >> $TEMPFILE1
      fi
   done
done

#  Transfer values and empty temporary file
MOUNTPOINTLIST=$(cat $TEMPFILE1)
cat /dev/null > $TEMPFILE1



# ----------
# Disconnect
# ----------

#  Unmount the tagged shares, and set a status indicator
sync
echo "$MOUNTPOINTLIST" | while read MOUNTPOINT
do
   umount -f $MOUNTPOINT
   ERRORCODE="$?"

   #  Store the status of the unmount attempt 
   [ "$ERRORCODE" = 0 ] && echo "Success unmounting $(echo $MOUNTPOINT | cut -d "/" -f 4-)" >> $TEMPFILE1
   [ "$ERRORCODE" != 0 ] && echo "Failure unmounting $(echo $MOUNTPOINT | cut -d "/" -f 4-)" >> $TEMPFILE1
done



# -----------------------------------------
# Summarize the status of unmounting shares
# -----------------------------------------

#  Display the summary
dialog --title "Summary" \
       --no-shadow \
       --sleep 5 \
       --cr-wrap \
       --infobox "\n$(cat $TEMPFILE1) \n " \
       20 70

#  Save the summary report
cat $TEMPFILE1 > /tmp/disconnectshares.rpt



# --------
# Clean up
# --------

#  Delete the temporary file
rm $TEMPFILE1



# -----
# Close
# -----

clear 
exit 0

