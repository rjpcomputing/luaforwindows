-- layout0.wlua
require 'CLRPackage'
import "System.Windows.Forms"

panel = FlowLayoutPanel()

function button(text,callback)
	local b = Button()
	callback = callback or function() print(text) end
	b.Text = text
	b.Click:Add(callback)
	return b
end

function add2panel(c)
	panel.Controls:Add(c)
end

--panel.WrapContents = false
b = button ("Toggle Wrap",function()
	panel.WrapContents = not panel.WrapContents
end)
add2panel(b)
b = button "Two"
add2panel(b)
b = button "Three"
add2panel(b)

form = Form()
form.Text = "Hello, World!"
panel.Dock = DockStyle.Fill

form.Controls:Add(panel)
form:ShowDialog()
