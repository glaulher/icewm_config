#!/bin/bash

# -----------------------------------------------------------------------------
# antiX gui for mounting/unmount android devices, by PPC and sybok, 21/5/2020, fully GPL...
# -----------------------------------------------------------------------------

TEXTDOMAINDIR=/usr/share/locale
TEXTDOMAIN=android-device-usb-connect

dir="$HOME/android_device"
sleep_time=1
yad_title=$"Android Device USB Connect"
yad_window_icon="phone"
yad_image="/usr/share/icons/papirus-antix/48x48/devices/smartphone.png"

preparation(){
  # Clear some files and prepare directories:
  echo $"Clearing files and preparing directories"
    
  if ! [ -d "${dir}" ]; then
    mkdir -p "$dir"
  fi
} # preparation

check_utilities(){
  # Check that some commands are available
  echo $"Checking availability of required utilities"
  fusermount -V 1>/dev/null || exit 1
## testing -  yad
	if ! [ -x "$(command -v yad)" ]; then
		echo $"Error: yad is not available" >&2 && exit
	fi
## testing -  jmtpfs
	if ! [ -x "$(command -v jmtpfs)" ]; then
		echo $"Error: jmtpfs is not available" >&2 && exit
	fi
  echo $"Checking availability of required utilities finished successfully"
} # check_utilities

check_mounted(){
  # 1- check if a android device seems to be mounted. If so, offer to unmount it and exit OR to access device
	if [ "$(ls -A "$dir")" ]; then
		echo $"An android device seems to be mounted"
		yad --fixed --window-icon=$yad_window_icon --image=$yad_image --title "$yad_title" --center --text=$"An android device seems to be mounted.\n \nChoose 'Unmount' to unplug it safely OR \n Choose 'Access device' to view the device's contents again.   "  --button=$"Access device":1 --button=$"Unmount":2
			foo=$?
			[[ $foo -eq 1 ]] && echo $"User has chosen to access the android device" && desktop-defaults-run -fm "$dir" && exit 1
			[[ $foo -eq 2 ]] && echo $"User has chosen to unmount the android device" && fusermount -u "$dir" && rm -r "$dir" ###&& exit
				#### NEW confirmation dialog, that warns if it's safe to unplug the device
				if [ "$(ls -A "$dir")" ]; then
					echo $"Android device WAS NOT umounted for some reason, do not unplug!"
					yad --fixed --window-icon=$yad_window_icon --image=$yad_image --title "$yad_title" --center --text=$"Android device WAS NOT umounted for some reason, do not unplug!"  --button=$"OK" && exit
				 else
					echo $"Android device is umounted; it is safe to unplug!"
					yad --fixed --window-icon=$yad_window_icon --image=$yad_image --title "$yad_title" --center --text=$"Android device is umounted; it is safe to unplug!"  --button=$"OK" && exit
		
				fi
	fi
 } # check_mounted

check_connected(){
  # 2- Check if an android device is connected to the computer, if not, warn user and exit
 while :
	do
		device_check=$(jmtpfs  2>&1)
			if [[ $device_check == *"No mtp"* ]]; then
				echo $"No device connected"
				else echo $"Device is connected" && sleep 1 && break
			fi
		yad --fixed --window-icon=$yad_window_icon --image=$yad_image --title "$yad_title" --center --text=$"No (MTP enabled) Android device found!\n  \n Connect a single device using its USB cable and \n make sure to select 'MTP' or 'File share' option and retry.   \n" --button=$"EXIT":1 --button=$"Retry":2
		foo=$?
		[[ $foo -eq 1 ]] && echo $"User pressed Exit" && exit 1
		[[ $foo -eq 2 ]] && echo $"User pressed Retry"
	done
} # check_connected

mount_display(){
  # 3- Try to mount android device and show contents
  jmtpfs "$dir" &&
  
   if  [ "$(ls -A "$dir")" ]; then
	desktop-defaults-run -fm "$dir"
	echo $"Device is mounted!"
   else 
	echo $"Device is NOT mounted!" 
  fi
  echo $"Attempted to mount device and display its contents"
} # mount_display

check_while_mount(){
  # 4- When trying to mount device, perform check if device contents are displayed, if not, user may need to allow access on the device. Prompt user to do that and unmount, remount device, and try to display it's contents again
   echo $"Checking if device can be mounted, asking user to grant permission on the device and try to mount again"
 	if [ "$(ls -A "$dir")" ] ; then
			echo $"Device seems properly mounted!"
	     else
			echo $"Please check that you have ALLOWED access to your files on your android device in order to proceed" && yad --fixed --window-icon=$yad_window_icon --image=$yad_image --title "$yad_title" --center --text=$"Please check that you have ALLOWED access to your files on your android device in order to procced\n \n Note: If you did not allow access, simply unplug, allow permission, and plug in your device's USB cable once more" --button Retry && fusermount -u "$dir" && jmtpfs "$dir" && desktop-defaults-run -fm "$dir"
	fi
  #recheck if device contents are displayed, if not, warn user and exit and unmount device to avoid errors
  sleep 1 && echo $"Final check to see if device can be mounted. If not, unmount it to avoid any errors"
[ "$(ls -A "$dir")" ] && echo $"The device seems to be correctly mounted." && exit
 echo $"Please check that you have ALLOWED access to your files on your android device in order to proceed" && yad  --fixed --window-icon=$yad_window_icon --image=$yad_image --title "$yad_title" --center --text=$" Unable to mount device! \n Please check you correctly selected 'MTP...' or 'File transfer...' option.\n Or 'Allowed' file access.\n \n Unplug, allow permission, and plug in your device and try again." --button Exit
	 fusermount -u "$dir" && rm -r "$dir"
} # check_while_mount

main(){
  # The main function
  preparation
  check_utilities
  check_mounted
  check_connected
  mount_display
  check_while_mount
  echo "Done"
} # main

main
