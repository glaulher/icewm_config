#! /bin/bash
#
# Gtkdialog box for the mount command. Part of SliTaz tools.
# adapted for use on antiX by anticapitalista@antiX.operamail.com
VERSION=20161227

TEXTDOMAINDIR=/usr/share/locale
TEXTDOMAIN=mountbox

export BLKID_LIST='
<window title="blkid -o full" icon-name="media-flash">
  <vbox>
    <text use-markup="true">
      <label>"<b>storage devices list</b>"</label>
    </text>
    <frame Partitions table>
      <text wrap="false" width-chars="88">
        <input>sudo blkid -o full</input>
      </text>
    </frame>
    <hbox>
      <button>
        <variable>OK_CLOSE</variable>
        <input file icon="exit"></input>
        <action type="closewindow">OK_CLOSE</action>
      </button>
    </hbox>
  </vbox>
</window>
'

# Mount button to use pmount to auto-open cd, dvd or usb device in Rox
#
export MOUNT_DIALOG='
<window title="antiX-Mountbox" icon-name="media-flash">
  <vbox>
    <text wrap="true" width-chars="72" use-markup="true">
      <label>"Use this utility to mount a storage device in /media.
Device can be flash key, pendrive, cd/dvd, or any USB device.

You can unmount a currently mounted device using the button here,
<b>or</b> perform the unmount operation via rox-filer or spacefm file manager."</label>
    </text>

    <frame Configuration>
      <hbox>
        <text use-markup="true">
          <label>"<b>Device             : </b>"</label>
        </text>
        <entry>
          <default>/dev/sr0</default>
          <variable>DEVICE</variable>
        </entry>
        <button>
          <label>"List"</label>
          <input file icon="drive-harddisk"></input>
      <action type="launch">BLKID_LIST</action>
        </button>
      </hbox>
      <hbox>
        <text use-markup="true">
          <label>"<b>Mount point   : </b>"</label>
        </text>
        <entry>
          <default>/media/cdrom</default>
          <variable>MOUNT_POINT</variable>
        </entry>
      </hbox>
    </frame>

    <hbox>
      <button>
        <label>"Mount"</label>
        <input file icon="forward"></input>
        <action>pmount $DEVICE; rox /media</action>
      </button>
      <button>
        <label>"Umount"</label>
        <input file icon="undo"></input>
        <action>pumount $MOUNT_POINT; sleep 1</action>
        <action type="exit">Exit</action>
      </button>
      <button>
        <input file icon="exit"></input>
        <action type="exit">Exit</action>
      </button>
    </hbox>

  </vbox>
</window>
'

gtkdialog --program=MOUNT_DIALOG

exit 0
