#!/usr/bin/env python3
#Name: ds-mouse.py
#Version:
#Depends: python, Gtk, xset
#Author: Dave (david@daveserver.info), 2017
#License:GPL v.3
#Purpose: Configure mouse on per user basis for a session. This is the gui frontend

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import os
import re
import gettext
gettext.install("ds-mouse.py", "/usr/share/locale")

class Error:
    def __init__(self, parent, error):
        dlg = Gtk.MessageDialog(parent=parent, flags=0, message_type=Gtk.MessageType.ERROR, buttons=Gtk.ButtonsType.OK, text=_("Error"))
        dlg.format_secondary_text('%s' % error)
        dlg.run()
        dlg.destroy()
       
class Success:
    def __init__(self, parent, success):
        dlg = Gtk.MessageDialog(parent=parent, flags=0, message_type=Gtk.MessageType.INFO, buttons=Gtk.ButtonsType.OK, text=_("Success"))
        dlg.format_secondary_text('%s' % success)
        dlg.run()
        dlg.destroy()
       
class Var: 
    def read(self):        
        var = Var
        var.USER_HOME = os.environ['HOME']
        var.CONF_USER_DIR = var.USER_HOME+"/.desktop-session/"
        var.CONF_USER_FILE = var.CONF_USER_DIR+"mouse.conf"
        var.CONF_USER_STARTUP = var.CONF_USER_DIR+"startup"
        var.CONF_SYSTEM_FILE = "/etc/desktop-session/mouse.conf"
        
        
        if not os.path.exists(var.CONF_USER_DIR):
            os.system("mkdir %s" % (var.CONF_USER_DIR))
            os.system("cp %s %s" % ((var.CONF_SYSTEM_FILE),(var.CONF_USER_DIR)))
        else:
            if not os.path.isfile(var.CONF_USER_FILE):
                os.system("cp %s %s" % ((var.CONF_SYSTEM_FILE),(var.CONF_USER_DIR)))
            
        for line in open(var.CONF_USER_FILE, "r"):
            if "#" not in line:
                if re.search(r'^.*=', line):
                    pieces = line.split('=')
                    var.VARIABLE=(pieces[0])
                    var.VARIABLE = re.sub(r'\n', '', var.VARIABLE)
                    OBJECT=(pieces[1])
                    OBJECT = re.sub(r'\n', '', OBJECT)
                    setattr(var, var.VARIABLE, OBJECT)
        for line in open(var.CONF_USER_STARTUP, "r"):
            if re.search(r'ds-mouse' , line):
                li=line.strip()
                if li.startswith("#"):
                    var.startstatus = False
                else:
                    var.startstatus = True
                    break
            else:
                var.startstatus = False
        
    def write(self, variable, item):
        WRITE_FILE = Var.CONF_USER_FILE+".tmp"
        READ_FILE = Var.CONF_USER_FILE
        
        text = open((WRITE_FILE), "w");text.write("");text.close()
        text = open((WRITE_FILE), "a")
        for line in open(READ_FILE, "r"):
            if "#" not in line:
                if re.search(r'^%s=' % (variable), line):
                    text.write (variable+"="+str(item)+"\n") 
                else:
                    text.write (line) 
            else:
                text.write (line) 
        text.close()        
        os.system("mv %s %s" % ((WRITE_FILE), (READ_FILE)))

class mainWindow(Gtk.Window):
    def apply(self,widget,option):
        if option == 0: #apply button
            acceleration_value = int(self.acceleration.get_value())
            threshold_value = int(self.threshold.get_value())
            size_value = int(self.size.get_value())
            button_order_value = self.order.get_active()
            Var().write('ACCELERATION', acceleration_value)
            Var().write('THRESHOLD', threshold_value)
            Var().write('SIZE', size_value)
            Var().write('BUTTONORDER', button_order_value)
            try:
                os.system("ds-mouse -all")
            except:
                Error(self, _("Could not run ds-mouse -all"))
            else:
                Success(self, _("All Options Set"))
        elif option == 1: #reset motion button
            acceleration_value = '0'
            threshold_value = '0'
            Var().write('ACCELERATION', acceleration_value)
            Var().write('THRESHOLD', threshold_value)
            try:
                os.system("ds-mouse -a")
            except:
                Error(self, _("Could not run ds-mouse -a"))
            else:
                Success(self, _("Mouse Acceleration Reset"))
                adj1 = Gtk.Adjustment(value=float(acceleration_value), lower=0.0, upper=17.0, step_increment=0.1, page_increment=1.0, page_size=1.0 )
                self.acceleration.set_adjustment(adj1)
                adj1 = Gtk.Adjustment(value=float(threshold_value), lower=0.0, upper=101.0, step_increment=1.0, page_increment=1.0, page_size=1.0 )
                self.threshold.set_adjustment(adj1)
                
        elif option == 2: #reset size button
            size_value = '0'
            Var().write('SIZE', size_value)
            try:
                os.system("ds-mouse -s")
            except:
                Error(self, _("Could not run ds-mouse -s"))
            else:
                Success(self, _("Cursor Size Reset"))
                adj1 = Gtk.Adjustment(value=float(size_value), lower=10.0, upper=51.0, step_increment=1.0, page_increment=1.0, page_size=1.0 )
                self.size.set_adjustment(adj1)
        elif option == 3: #change cursor theme button
            try:
                os.system("lxappearance &")
            except:
                os.system("rxvt-unicode -tr -sh 65 -fg white -T 'cursor theme' -e su -c 'update-alternatives --config x-cursor-theme' &")

    def make_frame(self, text, pos1, pos2, pos3, pos4):
        frame = Gtk.Frame(label=_(text))
        frame.set_border_width(10)
        self.grid.attach(frame, pos1, pos2, pos3, pos4)
        frame.show()
        
        self.framebox = Gtk.VBox()
        frame.add(self.framebox)
        self.framebox.show()
        
    def make_label(self, text):
        label = Gtk.Label()
        label.set_text(_(text))
        self.framebox.pack_start(label, True, True, 0)
        label.show()
        
    def scale_set_default_values(self, scale, option):
        scale.set_digits(option)
        scale.set_draw_value(True)
    
    def startup_write(self, FROM, TO):
        TEMP_FILE='/tmp/temp.txt'
        loop=0
        text = open((TEMP_FILE), "a")
        for line in open(Var.CONF_USER_STARTUP, "r"):
            if re.search(r'%s' % (FROM), line):
               text.write (TO+"\n")
               loop=1 
            else:
               text.write (line) 
        
        if loop == 0 :
            text.write ("\n#Enable Mouse Configuration at Startup\nds-mouse -all &\n")
        
        text.close()    
        os.system("mv %s %s && chmod 755 %s" % ((TEMP_FILE), (Var.CONF_USER_STARTUP), (Var.CONF_USER_STARTUP)))
    
    def toggle_startup(self, widget, object):
        if self.loopkill:
            self.loopkill=False
            
        if self.startup.get_active() == True:
            try:
                self.startup_write("ds-mouse", "ds-mouse -all &")
            except:
                Error(self, _("Could not enable. \n Please edit ~/.desktop-session/startup manually"))
                self.startup.set_active(False)
                self.loopkill=True
            else:
                Success(self, _("Mouse configuration will load on startup"))
        else:
            try:
                self.startup_write("ds-mouse", "#ds-mouse -all &")
            except:
                Error(self, _("Could not disable. \n Please edit ~/.desktop-session/startup manually"))
                self.startup.set_active(True)
                self.loopkill=True
            else:
                Success(self, _("Mouse configuration will not load on startup"))

    def __init__(self):
        Gtk.Window.__init__(self)
        self.set_size_request(300,0)
        self.set_border_width(10)
        self.set_title(_("Mouse Options"))
        
        self.grid = Gtk.Grid()
        self.add(self.grid)
        self.grid.show()
        
        self.make_frame(_("Mouse Acceleration"),1,1,1,1)
        self.make_label(_("Acceleration (Multiplier)"))
        
        adj1 = Gtk.Adjustment(value=float(Var.ACCELERATION), lower=0.0, upper=17.0, step_increment=0.1, page_increment=1.0, page_size=1.0 )
        self.acceleration = Gtk.HScale()
        self.acceleration.set_adjustment(adj1)
        self.acceleration.set_size_request(200, 45)
        self.scale_set_default_values(self.acceleration, 1)
        self.framebox.pack_start(self.acceleration, False, False, 0)
        self.acceleration.show()
        
        self.make_label(_("Threshold (Pixels)"))
        
        adj1 = Gtk.Adjustment(value=float(Var.THRESHOLD), lower=0.0, upper=101.0, step_increment=1.0, page_increment=1.0, page_size=1.0 )
        self.threshold = Gtk.HScale()
        self.threshold.set_adjustment(adj1)
        self.threshold.set_size_request(200, 45)
        self.scale_set_default_values(self.threshold, 1)
        self.framebox.pack_start(self.threshold, False, False, 0)
        self.threshold.show()
        
        reset_motion = Gtk.Button.new_from_icon_name(Gtk.STOCK_REVERT_TO_SAVED, 1)
        reset_motion.connect("clicked", self.apply, 1)
        self.framebox.pack_start(reset_motion, False, False, 0)
        reset_motion.show()
        
        self.make_frame(_("Button Order"),1,2,1,1)
       
        store= Gtk.ListStore(int, str)
        store.append([0, _("Right hand layout")])
        store.append([1, _("Left hand layout")])
       
        self.order =  Gtk.ComboBox.new_with_model_and_entry(store)
        self.order.set_entry_text_column(1)
        self.order.set_active(int(Var.BUTTONORDER))
        self.framebox.pack_start(self.order, False, False, 17)
        self.order.show()
        
        self.make_frame(_("Cursor Size"),2,1,1,1)
        self.make_label(_("Size (in pixels)"))
        
        adj1 = Gtk.Adjustment(value=float(Var.SIZE), lower=10.0, upper=51.0, step_increment=1.0, page_increment=1.0, page_size=1.0 )
        self.size = Gtk.HScale()
        self.size.set_adjustment(adj1)
        self.size.set_size_request(200, 45)
        self.scale_set_default_values(self.size, 0)
        self.framebox.pack_start(self.size, False, False, 0)
        self.size.show()
        
        reset_size = Gtk.Button.new_from_icon_name(Gtk.STOCK_REVERT_TO_SAVED, 1)
        reset_size.connect("clicked", self.apply, 2)
        self.framebox.pack_start(reset_size, False, False, 0)
        reset_size.show()
        
        self.make_frame(_("Cursor Theme"), 2,2,1,1)
        self.make_label(_("May require logout/login \nto see the changes."))
        
        theme = Gtk.Button.new_with_mnemonic(_("Change cursor theme"))
        theme.connect("clicked", self.apply, 3)
        self.framebox.pack_start(theme, False, False, 5)
        theme.show()
        
        self.make_frame(_("Startup"),1,3,2,1)
        self.make_label(_("Enable or Disable mouse configuration on startup\n"))
        
        self.startup = Gtk.Switch()
        self.startup.set_size_request(75,30)

        bbox = Gtk.HBox()
        self.framebox.pack_start(bbox, False, False, 10)
        bbox.pack_end(self.startup, False, False, 10)
        bbox.show()

        self.loopkill=False
        if Var.startstatus :
            self.startup.set_active(True)
        else:
            self.startup.set_active(False)

        self.startup.connect("notify::active", self.toggle_startup)
        self.startup.show()
        
        #BUTTON BOX
        
        buttonbox = Gtk.HButtonBox()
        self.grid.attach(buttonbox, 2,4, 1, 1)
        buttonbox.show()
        
        aply = Gtk.Button.new_from_icon_name(Gtk.STOCK_APPLY, 1)
        aply.connect("clicked", self.apply, 0)
        buttonbox.pack_start(aply, False, False, 0)
        aply.show()
        
        close = Gtk.Button.new_from_icon_name(Gtk.STOCK_CLOSE, 1)
        close.connect("clicked", lambda w: Gtk.main_quit())
        buttonbox.pack_start(close, False,False, 0)
        close.show()

Var().read()
win = mainWindow()
win.connect("delete-event", Gtk.main_quit)
win.show_all()
Gtk.main()
