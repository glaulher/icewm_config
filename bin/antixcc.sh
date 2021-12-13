#!/bin/bash
# File Name: controlcenter.sh
# Purpose: all-in-one control centre for antiX
# Authors: OU812 and minor modifications by anticapitalista
# Latest Change:
# 20 August 2008
# 11 January 2009 and renamed antixcc.sh
# 15 August 2009 some apps and labels altered.
# 09 March 2012 by anticapitalista. Added Live section.
# 22 March 2012 by anticapitalista. Added jwm config options and edited admin options.
# 18 April 2012 by anticapitalista. mountbox-antix opens as user not root.
# 06 October 2012 by anticapitalista. Function for ICONS. New icon theme.
# 26 October 2012 by anticapitalista. Includes gksudo and ktsuss.
# 12 May 2013 by anticapitalista. Let user set default apps.
# 05 March 2015 by BitJam: Add alsa-set-card, edit excludes, edit bootloader.  Fix indentation.
#   * Hide live tab on non-live systems.  Use echo instead of gettext.
#   * Remove unneeded doublequotes between tags.  Use $(...) instead of `...`.
# 01 May 2016 by anticapitalista: Use 1 script and use hides if nor present on antiX-base
# 11 July 2017 by BitJam:
#   * use a subroutine to greatly consolidate code
#   * use existence of executable as the key instead of documentation directory
#     perhaps I should switch to "which" or "type"
#   * move set-dpi to desktop tab
#   * enable ati driver button in hardware tab
# 18 Nov by antiX-Dave: fix edit jwm settings button to match icons with icewm and fluxbox
#
# Acknowledgements: Original script by KDulcimer of TinyMe. http://tinyme.mypclinuxos.com
#################################################################################################################################################

TEXTDOMAINDIR=/usr/share/locale
TEXTDOMAIN=antixcc
# Options

#antix-faenza=faenza icons used on antiX-17.4
#antix-moka=moka icons used on earlier releases
#antix-papirus=papirus converted to png icons
#antix-numix-bevel=numix-bevel png icons
#antix-numix-square=numix square png icons

#ICONS=/usr/share/icons/antix-moka
#ICONS=/usr/share/icons/antix-faenza
ICONS=/usr/share/icons/antix-papirus
#ICONS=/usr/share/icons/antix-numix-bevel
#ICONS=/usr/share/icons/antix-numix-square
ICONS2=/usr/share/pixmaps

EXCLUDES_DIR=/usr/local/share/excludes 

EDITOR="geany -i"


its_alive() {
    # return 0
    local root_fstype=$(df -PT / | tail -n1 | awk '{print $2}')
    case $root_fstype in
        aufs|overlay) return 0 ;;
                   *) return 1 ;;
    esac
}

its_alive && ITS_ALIVE=true

Desktop=$"Desktop" Software=$"Software" System=$"System" Network=$"Network" Shares=$"Shares" Session=$"Session"
Live=$"Live" Disks=$"Disks" Hardware=$"Hardware" Drivers=$"Drivers" Maintenance=$"Maintenance"
dpi_label=$(printf "%s DPI" $"Set Font Size")

vbox() {
    local text="$*"
    local len=${#text}
    #printf "vlen: %6s\n" "$len" >&2
    if [ $len -lt 20 ]; then
        echo '<vbox><hseparator></hseparator></vbox>'
    else
    echo "  <vbox>"
    local item
    for item; do
        echo "$item"
    done
    echo "  </vbox>"
    fi
}

hbox() {
    local text="$*"
    local len=${#text}
    #printf "hlen: %6s\n" "$len" >&2
    [ $len -lt 20 ] && return
    echo "<hbox>"
    local item
    for item; do
        echo "$item"
    done
    echo "</hbox>"
}

vbox_frame_hbox() {
    local text="$*"
    local len=${#text}
    #printf "flen: %6s\n" "$len" >&2
    [ $len -lt 20 ] && return
    echo "<vbox><frame><hbox>"
    local item
    for item; do
        echo "$item"
    done
    echo "</hbox></frame></vbox>"
}

entry() {
    local image=$1  action=$2  text=$3
    cat<<Entry
    <hbox>
      <button>
        <input file>$image</input>
        <action>$action</action>
      </button>
      <text use-markup="true" width-chars="32">
        <label>$text</label>
      </text>
    </hbox>
Entry
}

[ -d $HOME/.fluxbox -a -e /usr/share/xsessions/fluxbox.desktop ] && fluxbox_entry=$(entry \
    "$ICONS/gnome-documents.png" \
    "$EDITOR $HOME/.fluxbox/overlay $HOME/.fluxbox/keys $HOME/.fluxbox/init $HOME/.fluxbox/startup $HOME/.fluxbox/apps $HOME/.fluxbox/menu &" \
    $"Edit Fluxbox Settings")

[ -d $HOME/.icewm -a -e /usr/share/xsessions/icewm.desktop ] && icewm_entry=$(entry \
    $ICONS/gnome-documents.png \
    "$EDITOR $HOME/.icewm/winoptions $HOME/.icewm/preferences $HOME/.icewm/keys $HOME/.icewm/startup $HOME/.icewm/toolbar $HOME/.icewm/menu &" \
    $"Edit IceWM Settings")

[ -d $HOME/.jwm -a -e /usr/share/xsessions/jwm.desktop ] && jwm_entry=$(entry \
    $ICONS/gnome-documents.png \
    "$EDITOR $HOME/.jwm/preferences $HOME/.jwm/keys $HOME/.jwm/tray $HOME/.jwm/startup $HOME/.jwmrc $HOME/.jwm/menu &" \
    $"Edit JWM Settings")

# Edit syslinux.cfg if the device it is on is mounted read-write
grep -q " /live/boot-dev .*\<rw\>" /proc/mounts && bootloader_entry=$(entry \
    $ICONS/preferences-desktop.png \
    "gksu '$EDITOR /live/boot-dev/boot/syslinux/syslinux.cfg /live/boot-dev/boot/grub/grub.cfg' &" \
    $"Edit Bootloader Menu")

test -d /usr/local/share/excludes && excludes_entry=$(entry \
    $ICONS/remastersys.png \
    "gksu $EDITOR $EXCLUDES_DIR/*.list &" \
    $"Edit Exclude Files")

if test -x /usr/sbin/synaptic; then synaptic_entry=$(entry \
    $ICONS/synaptic.png \
    "gksu synaptic &" \
    $"Manage Packages")

elif test -x /usr/local/bin/cli-aptiX; then synaptic_entry=$(entry \
    $ICONS/synaptic.png \
    "desktop-defaults-run -t sudo /usr/local/bin/cli-aptiX --pause &" \
    $"Manage Packages")
fi

test -x  /usr/sbin/bootrepair && bootrepair_entry=$(entry \
    $ICONS/bootrepair.png \
    "gksu bootrepair &" \
    $"Boot Repair")

test -x /usr/bin/connman-ui-gtk && connman_entry=$(entry \
    $ICONS/connman.png \
    "connman-ui-gtk &" \
    $"WiFi Connect (Connman)")

test -x /usr/bin/connman-gtk && connman_entry=$(entry \
    $ICONS/connman.png \
    "connman-gtk &" \
    $"WiFi Connect (Connman)")

test -x /usr/bin/cmst && connman_entry=$(entry \
    $ICONS/connman.png \
    "cmst &" \
    $"WiFi Connect (Connman)")

firewall_prog=/usr/bin/gufw
test -x $firewall_prog  && firewall_entry=$(entry \
    $ICONS/gufw.png \
    "gksu gufw &" \
    $"Firewall Configuration")

backup_prog=/usr/bin/luckybackup
test -x $backup_prog  && backup_entry=$(entry \
    $ICONS/luckybackup.png \
    "gksu luckybackup &" \
    $"System Backup")

equalizer_prog=/usr/bin/alsamixer
test -x $equalizer_prog  && equalizer_entry=$(entry \
    $ICONS/alsamixer-equalizer.png \
    "desktop-defaults-run -t alsamixer -D equalizer &" \
    $"Alsamixer Equalizer")

printer_prog=/usr/bin/system-config-printer
test -x $printer_prog  && printer_entry=$(entry \
    $ICONS/printer.png \
    "system-config-printer &" \
    $"Print Settings")

livekernel_prog=/usr/local/bin/live-kernel-updater
test -x $livekernel_prog && livekernel_entry=$(entry \
    $ICONS/live-usb-kernel-updater.png \
    "desktop-defaults-run -t sudo /usr/local/bin/live-kernel-updater --pause &" \
    $"Live-USB Kernel Updater")

systemkeyboard_prog=/usr/bin/system-keyboard-qt
test -x $systemkeyboard_prog && systemkeyboard_entry=$(entry \
    $ICONS/im-chooser.png \
    "gksu system-keyboard-qt &" \
    $"Set System Keyboard Layout")

wallpaper_prog=/usr/local/bin/wallpaper
test -x $wallpaper_prog && wallpaper_entry=$(entry \
    $ICONS/preferences-desktop-wallpaper.png \
    "/usr/local/bin/wallpaper &" \
    $"Choose Wallpaper")

conky_prog=/usr/bin/conky
test -x $conky_prog && test -w $HOME/.conkyrc && conky_entry=$(entry \
    $ICONS/conky.png \
    "desktop-defaults-run -te $HOME/.conkyrc &" \
    $"Edit System Monitor (Conky)")

lxappearance_prog=/usr/bin/lxappearance
test -x $lxappearance_prog && lxappearance_entry=$(entry \
    $ICONS/preferences-desktop-theme.png \
    "lxappearance &" \
    $"Customize Look and Feel")

prefapps_prog=/usr/local/bin/desktop-defaults-set
test -x $prefapps_prog && prefapps_entry=$(entry \
    $ICONS/gnome-settings-default-applications.png \
    "desktop-defaults-set &" \
    $"Preferred Applications")

packageinstaller_prog=/usr/bin/packageinstaller
test -x $packageinstaller_prog && packageinstaller_entry=$(entry \
    $ICONS/packageinstaller.png \
    "gksu packageinstaller &" \
    $"Package Installer")

antixupdater_prog=/usr/local/bin/yad-updater
test -x $antixupdater_prog && antixupdater_entry=$(entry \
    $ICONS/software-sources.png \
    "/usr/local/bin/yad-updater &" \
    $"antiX Updater")

antixautoremove_prog=/usr/local/bin/yad-autoremove
test -x $antixautoremove_prog && antixautoremove_entry=$(entry \
    $ICONS/debian-logo.png \
    "/usr/local/bin/yad-autoremove &" \
    $"antiX autoremove")

sysvconf_prog=/usr/sbin/sysv-rc-conf
test -x $sysvconf_prog && sysvconf_entry=$(entry \
    $ICONS/choose-startup-services.png \
    "rc-conf-wrapper.sh &" \
    $"Choose Startup Services")

runitconf_prog=/usr/local/bin/runit-service-manager.sh
test -x $runitconf_prog && runitconf_entry=$(entry \
    $ICONS/choose-startup-services.png \
    "gksu runit-service-manager.sh &" \
    $"Choose Startup Services")

tzdata_dir=/usr/share/zoneinfo
tzdata_prog=/usr/sbin/dpkg-reconfigure
test -x $tzdata_prog && test -d $tzdata_dir && tzdata_entry=$(entry \
    $ICONS/time-admin.png \
    "set_time-and_date.sh &" \
    $"Set Date and Time")

ceni_prog=/usr/sbin/ceni
test -x $ceni_prog && ceni_entry=$(entry \
    $ICONS/ceni.png \
    "desktop-defaults-run -t sudo ceni &" \
    $"Network Interfaces (Ceni)")

wifi_prog=/usr/local/bin/antix-wifi-switch
test -x $wifi_prog && wifi_entry=$(entry \
    $ICONS/nm-device-wireless.png \
    "antix-wifi-switch &" \
    $"Select wifi Application")

connectshares_prog=/usr/local/bin/connectshares-config
test -x $connectshares_prog && connectshares_entry=$(entry \
    $ICONS/connectshares-config.png \
    "connectshares-config &" \
    $"ConnectShares Configuration")

disconnectshares_prog=/usr/local/bin/disconnectshares
test -x $disconnectshares_prog && disconnectshares_entry=$(entry \
    $ICONS/disconnectshares.png \
    "disconnectshares &" \
    $" DisconnectShares")

droopy_prog=/usr/local/bin/droopy.sh
test -x $droopy_prog && droopy_entry=$(entry \
    $ICONS/droopy.png \
    "droopy.sh &" \
    $"Droopy (File Sharing)")

assistant_prog=/usr/local/bin/1-to-1_assistance.sh
test -x $assistant_prog && assistant_entry=$(entry \
    $ICONS2/1-to-1_assistance.png \
    "1-to-1_assistance.sh &" \
    $"1-to-1 Assistance")

voice_prog=/usr/local/bin/1-to-1_voice.sh
test -x $voice_prog && voice_entry=$(entry \
    $ICONS2/1-to-1_voice.png \
    "1-to-1_voice.sh &" \
    $"1-to-1 Voice")

sshconduit_prog=/usr/local/bin/ssh-conduit.sh
test -x $sshconduit_prog && sshconduit_entry=$(entry \
    $ICONS2/ssh-conduit.png \
    "ssh-conduit.sh &" \
    $"SSH Conduit")

gnomeppp_prog=/usr/bin/gnome-ppp
test -x $gnomeppp_prog && gnomeppp_entry=$(entry \
    $ICONS/gnome-ppp.png \
    "gnome-ppp &" \
    $"Dial-Up Configuaration (GNOME PPP)")

wpasupplicant_prog=/usr/sbin/wpa_gui
test -x $wpasupplicant_prog && wpasupplicant_entry=$(entry \
    $ICONS/wpa_gui.png \
    "/usr/sbin/wpa_gui &" \
    $"WPA Supplicant Configuration")

pppoeconf_prog=/usr/sbin/pppoeconf
test -x $pppoeconf_prog && pppoeconf_entry=$(entry \
    $ICONS/internet-telephony.png \
    "desktop-defaults-run -t /usr/sbin/pppoeconf &" \
    $"ADSL/PPPOE Configuration")

adblock_prog=/usr/local/bin/block-advert.sh
test -x $adblock_prog && adblock_entry=$(entry \
    $ICONS/advert-block.png \
    "gksu block-advert.sh &" \
    $"Adblock")

login_prog=/usr/local/bin/login-config-antix
test -x $login_prog && login_entry=$(entry \
    $ICONS/preferences-system-login.png \
    "gksu login-config-antix &" \
    $"Login Manager")

slim_cc=/usr/local/bin/antixccslim.sh
slim_prog=/usr/bin/slim
test -x $slim_prog && test -x $slim_cc && slim_entry=$(entry \
    $ICONS/preferences-desktop-wallpaper.png \
    "gksu antixccslim.sh &" \
    $"Change Slim Background")

grub_prog=/usr/local/bin/antixccgrub.sh
test -x $grub_prog && grub_entry=$(entry \
    $ICONS/screensaver.png \
    "gksu antixccgrub.sh &" \
    $"Set Grub Boot Image (png only)")

which ${EDITOR%% *} &>/dev/null && confroot_entry=$(entry \
    $ICONS/gnome-documents.png \
    "gksu $EDITOR /etc/fstab /etc/default/keyboard /etc/grub.d/* /etc/slim.conf /etc/apt/sources.list.d/*.list &" \
    $"Edit Config Files")

arandr_prog=/usr/bin/arandr
test -x $arandr_prog && arandr_entry=$(entry \
    $ICONS/video-display.png \
    "arandr &" \
    $"Set Screen Resolution (ARandR)")

gksu_prog=/usr/bin/gksu-properties
test -x $gksu_prog && gksu_entry=$(entry \
    $ICONS/gksu.png \
    "gksu-properties &" \
    $"Password Prompt (su/sudo)")

slimlogin_prog=/usr/local/bin/slim-login
test -x $slimlogin_prog && slimlogin_entry=$(entry \
    $ICONS/preferences-system-login.png \
    "gksu slim-login &" \
    $"Set Auto-Login")

screenblank_prog=/usr/local/bin/set-screen-blank
test -x $screenblank_prog && screenblank_entry=$(entry \
    $ICONS/set-screen-blanking.png \
    "set-screen-blank &" \
    $"Set Screen Blanking")

desktopsession_dir=/usr/share/doc/desktop-session-antix
test -d $desktopsession_dir  && desktopsession_entry=$(entry \
    $ICONS/preferences-system-session.png \
    "$EDITOR $HOME/.desktop-session/*.conf $HOME/.desktop-session/startup &" \
    $"User Desktop-Session")

automount_prog=/usr/local/bin/automount-config
test -x $automount_prog && automount_entry=$(entry \
    $ICONS/mountbox.png \
    "automount-config &" \
    $"Configure Automount")

mountbox_prog=/usr/local/bin/mountbox
test -x $mountbox_prog && mountbox_entry=$(entry \
    $ICONS/mountbox.png \
    "mountbox &" \
    $"Mount Connected Devices")

liveusb_prog_g=/usr/bin/live-usb-maker-gui-antix
liveusb_prog=/usr/local/bin/live-usb-maker
if test -x $liveusb_prog_g; then
liveusb_entry=$(entry \
    $ICONS/live-usb-maker.png \
    "gksu live-usb-maker-gui-antix &" \
    $"Live USB Maker (gui)")

elif test -x $liveusb_prog; then
liveusb_entry=$(entry \
    $ICONS/live-usb-maker.png \
     "desktop-defaults-run sudo &live-usb-maker &" \
     $"Live USB Maker (cli)")
fi

installer_prog=/usr/sbin/minstall
[ -x $installer_prog -a -n "$ITS_ALIVE" ] && installer_entry=$(entry \
    $ICONS2/msystem.png \
    "gksu $installer_prog &" \
    $"Install antiX Linux")

partimage_prog=/usr/sbin/partimage
test -x $partimage_prog && partimage_entry=$(entry \
    $ICONS/drive-harddisk-system.png \
    "desktop-defaults-run -t sudo partimage &" \
    $"Image a Partition")

grsync_prog=/usr/bin/grsync
test -x $grsync_prog && grsync_entry=$(entry \
    $ICONS/grsync.png \
    "grsync &" \
    $"Synchronize Directories")

gparted_prog=/usr/sbin/gparted
test -x $gparted_prog && gparted_entry=$(entry \
    $ICONS/gparted.png \
    "gksu gparted &" \
    $"Partition a Drive")

setdpi_prog=/usr/local/bin/set-dpi
test -x $setdpi_prog && setdpi_entry=$(entry \
    $ICONS/fonts.png \
    "gksu set-dpi &" \
    "$dpi_label")

inxi_prog=/usr/local/bin/inxi-gui
test -x $inxi_prog && inxi_entry=$(entry \
    $ICONS/info_blue.png \
    "inxi-gui &" \
    $"PC Information")

mouse_prog=/usr/local/bin/ds-mouse
test -x $mouse_prog && mouse_entry=$(entry \
    $ICONS/input-mouse.png \
    "ds-mouse &" \
    $"Mouse Configuration")

soundcard_prog=/usr/local/bin/alsa-set-default-card
test -x $soundcard_prog && soundcard_entry=$(entry \
    $ICONS/soundcard.png \
    "alsa-set-default-card &" \
    $"Sound Card Chooser")

mixer_prog=/usr/bin/alsamixer
test -x $mixer_prog && mixer_entry=$(entry \
    $ICONS/audio-volume-high-panel.png \
    "desktop-defaults-run -t alsamixer &" \
    $"Adjust Mixer")

ddm_prog=/usr/bin/ddm-mx
test -x $ddm_prog && nvdriver_entry=$(entry \
    $ICONS/nvidia-settings.png \
    "desktop-defaults-run -t su-to-root -c '/usr/bin/ddm-mx -i nvidia' &" \
    $"Nvidia Driver Installer")

snapshot_prog=/usr/bin/iso-snapshot
test -x $snapshot_prog && snapshot_entry=$(entry \
    $ICONS/gnome-do.png \
    "gksu iso-snapshot &" \
    $"ISO Snapshot")

soundtest_prog=/usr/bin/speaker-test
test -x $soundtest_prog  && soundtest_entry=$(entry \
    $ICONS/preferences-desktop-sound.png \
    "desktop-defaults-run -t speaker-test --channels 2 --test wav --nloops 3 &" \
    $"Test Sound")

menumanager_prog=/usr/local/bin/menu_manager.sh
test -x $menumanager_prog && menumanager_entry=$(entry \
    $ICONS/menu-editor.png \
    "sudo menu_manager.sh &" \
    $"Menu Editor")

usermanager_prog=/usr/sbin/antix-user
test -x $usermanager_prog && usermanager_entry=$(entry \
    $ICONS/user-manager.png \
    "gksu antix-user &" \
    $"User Manager")

galternatives_prog=/usr/bin/galternatives
test -x $galternatives_prog && galternatives_entry=$(entry \
    $ICONS/galternatives.png \
    "gksu galternatives &" \
    $"Alternatives Configurator")

codecs_prog=/usr/bin/codecs
test -x $codecs_prog && codecs_entry=$(entry \
    $ICONS/codecs.png \
    "gksu codecs &" \
    $"Codecs Installer")

netassist_prog=/usr/sbin/network-assistant
test -x $netassist_prog && netassist_entry=$(entry \
    $ICONS/network-assistant.png \
    "gksu network-assistant &" \
    $"Network Assistant")

repomanager_prog=/usr/bin/repo-manager
test -x $repomanager_prog && repomanager_entry=$(entry \
    $ICONS/repo-manager.png \
    "gksu repo-manager &" \
    $"Repo Manager")

which backlight-brightness &>/dev/null && [ -n "$(ls /sys/class/backlight 2>/dev/null)" ] \
    && backlight_entry=$(entry \
    $ICONS/backlight-brightness.png \
    "desktop-defaults-run -t backlight-brightness &" \
    $"Backlight Brightness")

[ -e /etc/live/config/save-persist -o -e /etc/live/config/persist-save.conf ]  && persist_save=$(entry \
    $ICONS/palimpsest.png \
    "gksu persist-save &" \
    $"Save Root Persistence")

[ -e /etc/live/config/remasterable -o -e /etc/live/config/remaster-live.conf ] && live_remaster=$(entry \
    $ICONS/remastersys.png \
    "gksu live-remaster &" \
    $"Remaster-Customize Live")

live_tab=$(cat<<Live_Tab
$(vbox_frame_hbox \
"$(vbox \
"$(entry "$ICONS/pref.png" "gksu persist-config &" $"Configure Live Persistence")" \
"$livekernel_entry" "$bootloader_entry" "$persist_save")" \
"$(vbox \
"$(entry $ICONS/persist-makefs.png "gksu persist-makefs &" $"Set Up Live Persistence")" \
"$excludes_entry" "$live_remaster")")
Live_Tab
)

# If we are on a live system then ...
if grep -q " /live/aufs " /proc/mounts; then
    tab_labels="$Desktop|$Software|$System|$Network|$Shares|$Session|$Live|$Disks|$Hardware|$Drivers|$Maintenance"

else
    tab_labels="$Desktop|$Software|$System|$Network|$Shares|$Session|$Disks|$Hardware|$Drivers|$Maintenance"
    live_tab=
fi

export ControlCenter=$(cat<<Control_Center
<window title="antiX Control Centre" icon="gnome-control-center" window-position="1">
  <vbox>
<notebook tab-pos="0" labels="$tab_labels">
$(vbox_frame_hbox \
"$(vbox "$wallpaper_entry" "$icewm_entry" "$jwm_entry" "$conky_entry")" \
"$(vbox "$setdpi_entry" "$lxappearance_entry" "$fluxbox_entry" "$prefapps_entry")" )

$(vbox_frame_hbox \
"$(vbox "$antixupdater_entry" "$antixautoremove_entry" "$synaptic_entry")" \
"$(vbox "$packageinstaller_entry" "$repomanager_entry")" )

$(vbox_frame_hbox \
"$(vbox "$sysvconf_entry"  "$runitconf_entry" "$galternatives_entry")" \
"$(vbox "$confroot_entry" "$systemkeyboard_entry" "$tzdata_entry")" )

$(vbox_frame_hbox \
"$(vbox "$wifi_entry $connman_entry" "$ceni_entry" "$pppoeconf_entry" )" \
"$(vbox "$gnomeppp_entry" "$wpasupplicant_entry" "$firewall_entry" "$adblock_entry")" )

$(vbox_frame_hbox \
"$(vbox "$connectshares_entry" "$droopy_entry" "$assistant_entry" "$voice_entry")" \
"$(vbox "$disconnectshares_entry" "$sshconduit_entry")" )

$(vbox_frame_hbox \
"$(vbox "$arandr_entry" "$grub_entry")" \
"$(vbox "$login_entry" "$screenblank_entry" "$desktopsession_entry")")

$live_tab

$(vbox_frame_hbox \
"$(vbox "$automount_entry" "$installer_entry" "$mountbox_entry")" \
"$(vbox "$liveusb_entry" "$partimage_entry" "$grsync_entry" "$gparted_entry")")

$(vbox_frame_hbox \
"$(vbox "$printer_entry" "$inxi_entry" "$mouse_entry" "$backlight_entry")" \
"$(vbox "$soundcard_entry" "$soundtest_entry" "$mixer_entry" "$equalizer_entry")")

$(vbox_frame_hbox \
"$(vbox "$nvdriver_entry" "$ndiswrapper_entry")" \
"$(vbox "$codecs_entry")" )

$(vbox_frame_hbox \
"$(vbox "$snapshot_entry" "$backup_entry" "$netassist_entry")" \
"$(vbox "$bootrepair_entry" "$menumanager_entry" "$usermanager_entry")" )

</notebook>
</vbox>
</window>
Control_Center
)

case $1 in
    -d|--debug) echo "$ControlCenter" ; exit ;;
esac

gtkdialog --program=ControlCenter
#unset ControlCenter
