#!/bin/bash


# ***** Library ********************************************************

# Access the prog library
source /usr/local/lib/screenlight/lib-screenlight



# ***** Settings used solely by this script ****************************

# Capture the name of the script including file extension
PROGNAME=${0##*/}

# Set the version number
PROGVERSION=1.1

# Capture whether to run in day or night mode
MODE=$1



# ***** Functions used solely by this script ***************************

main()
{
   : 'Run the main trunk of the script'
   :
   : Parameters
   : ' none'
   :
   : Result
   : ' Adjusts screen presentation to correspond to user chosen values'
   :
   : Example
   : ' function-name'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' none'

   
   # ----- Mode of operation -------------------------------------------
   
   # Detect which mode was chosen, assign the appropriate conf file
   case $MODE in
      day)    # Employ the day conf file
			  CONFIG_FILE=$CONFIG_FILE_DAY
			  ;;
	  night)  # Employ the night conf file
			  CONFIG_FILE=$CONFIG_FILE_NIGHT
			  ;;
   esac



   # ----- User configurable settings ----------------------------------
   
   # Ensure a user editable file exists in the user home file structure
   lib_provide-file-from-skel $CONFIG_DIR $CONFIG_FILE
   
   # Obtain the config values
   source $CONFIG_DIR/$CONFIG_FILE



   # ----- Day ---------------------------------------------------------
   
   # When day mode is specified
   if [[ $MODE = day ]]; then
   
      # When both brightness and contrast values are empty
      if [[ $BRIGHTNESS_DAY = "" ]] && [[ $CONTRAST_DAY = "" ]]; then
      
         # Issue an error message and exit
         conf_values_empty
      fi
      
      
      # When the brightness value is numeric and within the allowable range
      if [[ $BRIGHTNESS_DAY -lt 100 ]] && [[ $BRIGHTNESS_DAY -gt 0 ]]; then
      
         # Apply the brightness value
         BRIGHTNESS=$BRIGHTNESS_DAY
         implement-brightness 
      fi
      
      
      # When the contrast value is empty
      if [[ $CONTRAST_DAY = "" ]]; then
      
         # Ensure the effect of any residual colour temperature value is nullified
         # Reset screen colour temperature to default
         sct 6500    
      fi
      
      
      # When the contrast value is numeric and within the allowable range
      if [[ $CONTRAST_DAY -lt 100 ]] && [[ $CONTRAST_DAY -gt 0 ]]; then
         
         # Transform the value into the appropriate form
         CONTRAST=$CONTRAST_DAY
         convert-contrast-value
         
         # Apply the contrast value
         implement-contrast
      fi
   fi
   
   
   
   # ----- Night--------------------------------------------------------
   
   # When night mode is specified
   if [[ $MODE = night ]]; then
   
      # When both brightness and colour temperature values are empty
      if [[ $BRIGHTNESS_NIGHT = "" ]] && [[ $COLOUR_TEMPERATURE = "" ]]; then
      
         # Issue an error message and exit
         conf_values_empty
      fi

      # When the brigtness value is numeric and within the allowable range
      if [[ $BRIGHTNESS_NIGHT -lt 101 ]] && [[ $BRIGHTNESS_NIGHT -gt 0 ]]; then
      
         # Apply the brightness value
         BRIGHTNESS=$BRIGHTNESS_NIGHT
         implement-brightness 
      fi
      
      
      # When the screen colour temperature value is numeric and within the allowable range
      if [[ $COLOUR_TEMPERATURE -lt 10001 ]] && [[ $COLOUR_TEMPERATURE -gt 1000 ]]; then
   
         # Apply the contrast value
         implement-colour-temperature
      fi
   fi
   
   
   
   # ---- Quit ---------------------------------------------------------
   
   exit
}



convert-contrast-value()
{
   : 'Reduce the value to 0.01 of its original value'
   :
   : Parameters
   : ' None'
   :
   : Result
   : ' Changes the value so it is suitable for use by xrandr'
   :
   : Example
   : ' function-name'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' bc'
   
   # Convert the value to 1% of its current value
   CONTRAST=$(echo "scale=2; "$CONTRAST" / 100" | bc -l)
}



implement-contrast()
{
   : 'Apply the contrast value'
   :
   : Parameters
   : ' None'
   :
   : Result
   : ' Changes screen contrast to correspond to the user chosen value'
   :
   : Example
   : ' function-name'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' awk xrandr'
   
   # Implement the contrast value
   xrandr --output $(xrandr | awk '/ connected / { print $1 }') --gamma "$CONTRAST":"$CONTRAST":"$CONTRAST"
}



implement-brightness()
{
   : 'Apply the brightness value'
   :
   : Parameters
   : ' None'
   :
   : Result
   : ' Changes screen brightness to correspond to the user chosen value'
   :
   : Example
   : ' function-name'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' backlight-brightness'
   
   # Implement the brightness value
   backlight-brightness --set "$BRIGHTNESS"
}



implement-colour-temperature()
{
   : 'Apply the brightness value'
   :
   : Parameters
   : ' None'
   :
   : Result
   : ' Changes screen colour temperature to correspond to the user chosen value'
   :
   : Example
   : ' function-name'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' sct'
   
   # Implement the brightness value
   sct "$COLOUR_TEMPERATURE"
}



conf_values_empty()
{
   : 'Display an error message when both values in a conf file are empty'
   :
   : Parameters
   : ' none'
   :
   : Result
   : ' Inform tje user to specify one or both values in te conf file'
   :
   : Example
   : ' none'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' yad'
   
   # Message to display in error window
   MESSAGE="\n<b><big> Error </big></b> \
            \n \n \
            \n $MODE values have not been specified. \
            \n Either or both values must be set. \
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
   : ' screenlight.sh --help'
   :
   : Note
   : ' none'
   :
   : Requires
   : ' cat cut cp mkdir'

   # Display the following block
cat << end-of-messageblock

$PROGNAME version $PROGVERSION
Adjust and save screen brightness, contrast and colour temperature values.

Usage: 
   $PROGNAME

Options:
   day                Apply settings suitable for daytime use
   night              Apply settings suitable for nighttime use
   -h, --help         Show this output

Summary:
   When the script is run it will create a day or night configuration
   file if one does not exist. Changes will not be made to screen
   brightness, contrast and colour temperature until the user edits the
   file and appends suitable values.
   
   When the script is run and the corresponding configuration file
   contains appropriate values the screen display is adjusted according
   to the first script parameter, which must be either day or night.
   
   The day parameter adjusts the brightness and/or contrast.
   The night parameter adjusts the brightness and/or colour temperature.
   
   To apply the values each time a user session begins start the script
   via an entry in the session startup file.
            
Configuration:
   Values for screen brightness, contrast and colour temperature are in:
   $HOME/.config/screenlight-day.conf
   $HOME/.config/screenlight-night.conf
  
Requires:
   awk bash bc cat console-grid-gui cp cut mkdir sct xrandr yad
   
See also:
   screenlight-menu.sh

end-of-messageblock
   exit
}



# ***** Start the script ***********************************************
case $1 in
   day|night)     # Begin the main trunk of the script
                  main
                  ;;
   ""|--help|-h)  # Show info and help
                  usage
                  ;;
   *)             # Otherwise
                  exit 1        
                  ;;
esac   

