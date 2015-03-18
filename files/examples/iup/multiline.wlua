--  IupMultiline Simple Example in IupLua 
--  Shows a multiline that ignores the treatment of the 'g' key, canceling its effect. 

require( "iuplua" )

ml = iup.multiline{expand="YES", value="I ignore the 'g' key!", border="YES"}

ml.action = function(self, c, after)
   if c == iup.K_g then
     return iup.IGNORE
  else
    return iup.DEFAULT;
  end
end

dlg = iup.dialog{ml; title="IupMultiline", size="QUARTERxQUARTER"}
dlg:show()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
