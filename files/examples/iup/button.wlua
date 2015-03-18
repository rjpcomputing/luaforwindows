-- Creates four buttons. The first uses images, the second turns the first
-- on and off, the third exits the application and the last does nothing

require( "iuplua" )

-- defines released button image
img_release = iup.image {
      {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
      {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2},
      {1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
      {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2};
      colors = { "215 215 215", "40 40 40", "30 50 210", "240 0 0" }
}

-- defines pressed button image
img_press = iup.image {
      {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
      {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,4,4,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,4,4,4,4,3,3,3,3,2,2},
      {1,1,3,3,3,3,4,4,4,4,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,4,4,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
      {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2};
      colors = { "40 40 40", "215 215 215", "0 20 180", "210 0 0" }
}

-- defines deactivated button image
img_inactive = iup.image {
      {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
      {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2},
      {1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2},
      {1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
      {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2};
      colors = { "215 215 215", "40 40 40", "100 100 100", "200 200 200" }
}

-- creates a text box
text = iup.text{ readonly = "YES", SIZE = "EIGHTH" }

-- creates a button with image
btn_image = iup.button{ title = "Button with image", image = img_release, impress = img_press, iminactive = img_inactive }

-- creates a button
btn_big = iup.button{ title = "Big useless button", size = "EIGHTHxEIGHTH" }

-- creates a button entitled Exit
btn_exit = iup.button{ title = "Exit" }

-- creates a button entitled Activate
btn_on_off = iup.button{ title = "Activate" }

-- creates a dialog and sets dialog's title and turns off resize, menubox, maximize and minimize
dlg = iup.dialog{ iup.vbox{ iup.hbox{ iup.fill{}, btn_image, btn_on_off, btn_exit, iup.fill{} }, text, btn_big }; title = "IupButton", resize = "NO", menubox = "NO", maxbox = "NO", minbox = "NO" }

-- callback called when activate button is activated
function btn_on_off:action()
  if btn_image.active == "YES" then
    btn_image.active = "NO"
  else
    btn_image.active = "YES"
  end

  return iup.DEFAULT
end

-- callback called when the button is pressed or released
function btn_image:button( b, e )
  if( b == iup.BUTTON1 ) then
    if( e == 1 ) then
      -- button released
      text.value = "Red button pressed"
    else           
      -- button pressed 
      text.value = "Red button released"
    end
  end
  return iup.DEFAULT
end

-- callback called when the exit button is activated
function btn_exit:action()
  dlg:hide()
end

-- shows dialog
dlg:showxy( iup.CENTER, iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
