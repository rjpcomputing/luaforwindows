require "luarocks.require"
require "alien"

local gtk,p,i=alien.load("/usr/lib/libgtk-x11-2.0.so.0"),"pointer","int"

gtk.gtk_init:types(nil,p,p)
gtk.gtk_message_dialog_new:types(p,p,i,i,i,p)
gtk.gtk_dialog_run:types(i,p)

gtk.gtk_init(nil,nil)
gtk.gtk_dialog_run(gtk.gtk_message_dialog_new(nil,0,0,1,"Alien Rocks!"))
