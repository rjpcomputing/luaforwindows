-- form3.wlua
require 'CLRPackage'
import "System.Windows.Forms"
import "System.Drawing"

button = Button()
button.Text = "Click!"
button.Dock = DockStyle.Top
edit = RichTextBox()
edit.Dock = DockStyle.Fill

form = Form()
form.Text = "Hello, World!"
form.Controls:Add(edit)
form.Controls:Add(button)
form:ShowDialog()
