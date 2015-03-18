-- layout1.wlua
require 'CLRForm'

panel = Panel()
layout = StreamLayout(panel)
b = Button()
b.Text = "One"
layout:Add(b)
b = Button()
b.Text = "Two"
layout:Add(b)
t = TextBox()
layout:Add(t)
layout:Finish()

form = Form()
form.Text = "Hello, World!"
panel.Dock = DockStyle.Top

form.Controls:Add(panel)
form:ShowDialog()
