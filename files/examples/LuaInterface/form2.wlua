require 'CLRPackage'
import "System.Windows.Forms"
import "System.Drawing"

form = Form()
form.Text = "Hello, World!"
button = Button()
button.Text = "Click Me!"
button.Location = Point(20,20)
button.Click:Add(function()
	MessageBox.Show("We wuz clicked!",arg[0],MessageBoxButtons.OK)
end)

form.Controls:Add(button)
form:ShowDialog()
