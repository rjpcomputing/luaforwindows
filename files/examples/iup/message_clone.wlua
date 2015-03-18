require( "iuplua" )
function myMessage(tit, msg)
  dlg = iup.dialog{iup.vbox{iup.label{title=msg, expand="Yes"}, iup.button{title="OK", padding="5x5"}, margin="10x10", gap="10", alignment="ACENTER"}, title=tit}   
  dlg:popup(10, 10)
  dlg:destroy()
end
tit="New Position"
msg="Antonio's window"
myMessage(tit,msg)
