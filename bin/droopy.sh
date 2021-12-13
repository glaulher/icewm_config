#!/bin/sh


PROGNAME=${0##*/}
PROGVERSION="1.2"



# --------------------
# Help and Information
# --------------------

# When requested show information about script
if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
cat << end-of-messageblock

$PROGNAME version $PROGVERSION
Launches Droopy web server in a console or GUI.

Usage: 
   $PROGNAME [options]

Options:
   -h, --help     Show this output

Summary:
   Enables an impromptu web server to be created on-demand.

   The default action creates and serves a web page providing access to a
   folder named "Public", in the home area of the current user.  Files may
   be uploaded to, and downloaded from the served folder.   

   Access is available to any other system on the same network as the web
   server, via any web browser on the remote system.  In the browser, 
   provide the IP address and port number of the Droopy server 
   e.g. http://ipaddress:8800

   A connection can also be made across the internet.  In this case you 
   must ensure firewalls and routers are setup to allow such connections. 

   Optional configuration items are available in
   /home/USERNAME/.config/droopy/droopy.conf
   
   To stop Droopy:
   When running in a console, press CTRL+C 
   When running in a GUI, close the terminal window or press CTRL+C

Requires:
   awk, chmod, droopy, echo, grep, ip, openssl, python, x-terminal-emulator, yad

Reference:
   Droopy home web site,   http://stackp.online.fr/?p=28

end-of-messageblock
   exit 0
fi


# ----------------
# Network Settings
# ----------------

# Obtain IP address of the local system
# Maximum number of network adaptors to test
COUNTER=3
while [ "$IPADDRESS" = "" ]
do
   for FILE in /sys/class/net/*
   do

      # Find the first network adaptor with a state of up or unknown, and has an ip address
      if ! [ "$FILE" = "/sys/class/net/lo" ]; then
         NIC=$(echo $FILE | awk -F "/" '{ print $NF }')
         STATE=$(cat $FILE/operstate)
         IPADDRESS=$(ip addr show | grep $NIC$ | awk -F " " '{ print $2 }' | awk -F "/" '{ print $1 }')
         [ "$STATE" = "up" ] || [ "$STATE" = "unknown" ] && [ "$IPADDRESS" != "" ] && break
      fi

      # Decrement the counter and test again until a value of zero is reached
      if [ "$COUNTER" != "0" ]; then
         COUNTER=$(expr $COUNTER - 1)

         else

         # Display an error message and exit
         ERRMSG=" An IP address was not found \n\n Exiting..."
         YADBOX="--title="Droopy" --image="error" --button="OK:1""
         [ "$DISPLAY" = "" ] && echo "$ERRMSG"
         [ "$DISPLAY" != "" ] && yad $YADBOX --text="$ERRMSG"
         exit 1
      fi
   done
done


# --------------------------
# User Configurable Settings
# --------------------------

# Location of the user configurable settings file
CONFIGFILE="$HOME/.config/droopy/droopy.conf"

# Obtain the user specifiable configuration
if [ -f $CONFIGFILE ]; then
   . $CONFIGFILE

   else

   # Display an error message and exit
   ERRMSG=" $CONFIGFILE \n Was not found \n\n Exiting..."
   YADBOX="--title="Droopy" --image="error" --button="OK:1""
   [ "$DISPLAY" = "" ] && echo -e "$ERRMSG"
   [ "$DISPLAY" != "" ] && yad $YADBOX --text="$ERRMSG"
   exit 1
fi


# ---------------
# Server Settings
# ---------------

# Verify essential user specifiable server configuration values are assigned
[ "$FOLDER" = "" ] && MISSING1=FOLDER
[ "$MESSAGE" = "" ] && MISSING2=MESSAGE
[ "$PORT" = "" ] && MISSING3=PORT
if [ "$MISSING1" != "" ] || [ "$MISSING2" != "" ] || [ "$MISSING3" != "" ]; then
   ERRMSG=" $CONFIGFILE \n Essential configuration incomplete for \n $MISSING1 \n $MISSING2 \n $MISSING3 \n\n Exiting..."
   YADBOX="--title="Droopy" --image="error" --button="OK:1""
   [ "$DISPLAY" = "" ] && echo -e "$ERRMSG"
   [ "$DISPLAY" != "" ] && yad $YADBOX --text="$ERRMSG"
   exit 1
fi


# Ensure the folder to be served exists
[ -d $FOLDER ] || mkdir $FOLDER


# Assign server parameters to the corresponding user specified optional configuration values
[ "$DOWNLOAD" = "y" ] && DOWNLOAD="--dl" 
[ "$AUTHORISE" != "" ] && AUTHORISE="--auth $AUTHORISE"
[ "$PICTURE" != "" ] && PICTURE="--picture $PICTURE"
[ "$MODE" != "" ] && MODE="--chmod $MODE"
[ "$PEMFILE" != "" ] && PEMFILE="--ssl $PEMFILE"

# Configure the server start command with optional parameters
STARTSERVER="python /usr/local/bin/droopy $DOWNLOAD $AUTHORISE $PICTURE $MODE $PEMFILE"


# -----------------
# Terminal Settings
# -----------------

# Conduct the following only when in GUI mode
if [ "$DISPLAY" != "" ]; then
   
   # Configure the terminal window title bar
   TITLE="Droopy Serving   $FOLDER   on $(hostname)   $IPADDRESS:$PORT"

   # Prepare in case x-terminal-emulator is to be used
   # Cater for differences in the way the command to run in the terminal is handled 
   XTERMEMU=$(which x-terminal-emulator | awk -F "/" '{ print $NF }')
   [ "$XTERMEMU" = "xfce4-terminal" ] && EXE="-x" || EXE="-e"


   # Check whether a preferred terminal is to be used
   if [ "$PREFTERM" != "" ]; then

      # Check whether the preferred terminal emulator exists in the path
      VALIDTERM=$(which $PREFTERM | awk -F "/" '{ print $NF }')
      if [ "$VALIDTERM" = "" ]; then
         ERRMSG=" $CONFIGFILE \n Specifies an invalid terminal emulator \n\n Will try to start using the system default "
         YADBOX="--title="Droopy" --image="error" --timeout="3" --button="OK:1""
         yad $YADBOX --text="$ERRMSG"
         
         else
         
         # Indicate use of the preferred terminal
         USEPREFTERM=y
         
         # Cater for differences in the way the command to run in the terminal is handled 
         [ "$PREFTERM" = "xfce4-terminal" ] && EXE="-x" || EXE="-e"
      fi
   fi
fi


# ------
# Launch
# ------

# In GUI mode start the server using optional and required parameters
if [ "$DISPLAY" != "" ]; then

   # Start with preferred terminal
   [ "$USEPREFTERM" = "y" ] && $PREFTERM -T "$TITLE" $EXE $STARTSERVER --directory $FOLDER --message "$MESSAGE" $PORT

   # Fallback to using x-terminal-emulator
   [ "$USEPREFTERM" = "" ] && x-terminal-emulator -T "$TITLE" $EXE $STARTSERVER --directory $FOLDER --message "$MESSAGE" $PORT
fi

# In console mode start the server using optional and required parameters
if [ "$DISPLAY" = "" ]; then

   # Start the server using optional and required parameters
   $STARTSERVER --directory $FOLDER --message "$MESSAGE" $PORT
fi


exit

 
