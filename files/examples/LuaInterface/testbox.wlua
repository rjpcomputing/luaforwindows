require "CLRForm"

text = RichTextBox()
text.Multiline = true
text.Text = [[
here is
a set of lines
for you
]]

LuaForm ({text}):ShowDialog()
