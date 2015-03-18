-- Based on a code from Stuart P. Bentley

require"imlua"
require"cdlua"
require"cdluaim"
require"iuplua"
require"iupluacd"
require"iupluaimglib"

anim={}

function print_error(err)
  local msg = {}
  msg[im.ERR_OPEN] = "Error Opening File."
  msg[im.ERR_MEM] = "Insuficient memory."
  msg[im.ERR_ACCESS] = "Error Accessing File."
  msg[im.ERR_DATA] = "Image type not Suported."
  msg[im.ERR_FORMAT] = "Invalid Format."
  msg[im.ERR_COMPRESS] = "Invalid or unsupported compression."
  
  if msg[err] then
    print(msg[err])
  else
    print("Unknown Error.")
  end
end

function load_frames(file_name)

  ifile, err=im.FileOpen(file_name)
  if not ifile then
      print_error(err)
      return
  end

  anim.images={}
  anim.delays={}
  anim.disposal={}
  anim.pos={}
  anim.frame=1
  
  local ScreenWidth = 0 
  local ScreenHeight = 0

  for i=1, select(3,ifile:GetInfo()) do
  
    anim.images[i]=ifile:LoadBitmap(i-1)
    err, anim.images[i] = im.ConvertColorSpaceNew(anim.images[i], im.RGB, true)
    
    local delay=anim.images[i]:GetAttribute("Delay") -- time to wait betweed frames in 1/100 of a second]
    if delay then
      anim.delays[i]=delay[1]*10 -- timer in miliseconds
    else
      if (i == 1) then 
        anim.delays[i]=100 
      else
        anim.delays[i]=anim.delays[i-1]
      end
    end
    
    anim.disposal[i]=anim.images[i]:GetAttribute("Disposal", true) --  [UNDEF, LEAVE, RBACK, RPREV]
    
    local w = anim.images[i]:Width()
    local h = anim.images[i]:Height()
    if (w > ScreenWidth) then ScreenWidth = w end
    if (h > ScreenHeight) then ScreenHeight = h end
    w = anim.images[i]:GetAttribute("ScreenWidth")
    h = anim.images[i]:GetAttribute("ScreenHeight")
    if (w and w[1] > ScreenWidth) then ScreenWidth = w[1] end
    if (h and h[1] > ScreenHeight) then ScreenHeight = h[1] end
    
    local X = anim.images[i]:GetAttribute("XScreen")
    local Y = anim.images[i]:GetAttribute("YScreen")
    anim.pos[i] = {x=0, y=0}
    if (X) then anim.pos[i].x = X[1] end
    if (Y) then anim.pos[i].y = Y[1] end
  end

  ifile:Close()
  
  anim.ScreenHeight = ScreenHeight
  anim.ScreenWidth = ScreenWidth
  
  cnv.rastersize = ScreenWidth.."x"..ScreenHeight
  dlg.size=nil
  iup.Refresh(cnv)
end

t = iup.timer{}

function start_timer()
  dlg.title = "Animated Gif"
  dlg.play_bt.image="IUP_MediaPause" dlg.play_bt.title="Pause"
  t.run = "NO"
  t.time = anim.delays[anim.frame]
  t.run = "YES"
  iup.Update(cnv)
end

function stop_timer()
  dlg.title = "Animated Gif "..anim.frame.."/"..#anim
  dlg.play_bt.image="IUP_MediaPlay" dlg.play_bt.title="Play" 
  t.run="NO"
  iup.Update(cnv)
end

function set_frame(f)
  anim.frame = f
  if anim.frame > #anim.images then
    anim.frame = #anim.images
  end
  if anim.frame < 1 then
    anim.frame = 1
  end
  stop_timer()
end

function t:action_cb()
  anim.frame = anim.frame + 1
  if anim.frame == #anim.images+1 then
    anim.frame = 1
  end
  
  start_timer()
end
    
cnv = iup.canvas{border = "NO"}

function cnv:map_cb()-- the CD canvas can only be created when the IUP canvas is mapped
  canvas = cd.CreateCanvas(cd.IUP, self)
  canvas:Activate()
  
  start_timer()
end

function cnv:action()-- called everytime the IUP canvas needs to be repainted
  canvas:Activate()
  if (anim.disposal[anim.frame] == "RBACK") then
    canvas:Clear()
  end
  local x = anim.pos[anim.frame].x
  local y = anim.ScreenHeight - anim.pos[anim.frame].y - anim.images[anim.frame]:Height()
  anim.images[anim.frame]:cdCanvasPutImageRect(canvas, x, y, 0, 0, 0, 0, 0, 0) -- use default values
end

function cnv:resize_cb()
  canvas:Activate()
  canvas:Clear()
end

function cnv:button_cb(but, pressed)
  if (but == iup.BUTTON1 and pressed==1) then
    local file_name, error = iup.GetFile("*.*")
    if error ~= 0 then
      return
    end
    
    load_frames(file_name)  
    canvas:Activate()
    canvas:Clear()
    start_timer()
  end
end

buts = iup.hbox{
  iup.button{title="First", image="IUP_MediaGotoBegin", action=function(self) set_frame(1) end}, 
  iup.button{title="Previous", image="IUP_MediaRewind", action=function(self) set_frame(anim.frame-1) end}, 
  iup.button{title="Pause", image="IUP_MediaPause", action=function(self) if (t.run=="YES") then stop_timer() else start_timer() end end}, 
  iup.button{title="Next", image="IUP_MediaForward", action=function(self) set_frame(anim.frame+1) end}, 
  iup.button{title="Last", image="IUP_MediaGoToEnd", action=function(self) set_frame(#anim) end}, 
  }
dlg = iup.dialog{iup.vbox{cnv, buts},title="Animated Gif", margin="5x5", gap=10}
dlg.play_bt = dlg[1][2][3]

function dlg:close_cb()
  iup.Destroy(t)
  anim=nil --Destroys will be called by the garbage collector
  canvas:Kill()
  self:destroy()
  return iup.IGNORE -- because we destroy the dialog
end

load_frames(iup.GetFile("*.*"))

dlg:show()
iup.MainLoop()
