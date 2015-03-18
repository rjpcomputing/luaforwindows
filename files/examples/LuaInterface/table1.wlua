-- table1.wlua
require 'CLRPackage'
import "System.Windows.Forms"

panel = TableLayoutPanel()
panel.RowCount = 2
panel.ColumnCount = 2

function button(text,callback)
	local b = Button()
	b.Text = text
	panel.Controls:Add(b)
	return b
end

b1 = button "One"
b2 = button "Two"
b3 = button "Three"
b4 = button "Four"

panel:SetRow(b1,0); panel:SetColumn(b1,0)
panel:SetRow(b2,0); panel:SetColumn(b2,1)
panel:SetRow(b3,1); panel:SetColumn(b3,0)
panel:SetRow(b4,1); panel:SetColumn(b4,1)

form = Form()
form.Text = "Hello, World!"
panel.Dock = DockStyle.Fill

form.Controls:Add(panel)
form:ShowDialog()
