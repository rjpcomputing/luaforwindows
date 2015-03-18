require 'luanet'
luanet.load_assembly "System.Windows.Forms"
Form = luanet.import_type "System.Windows.Forms.Form"
form = Form()
form.Text = "Hello, World!"
form:ShowDialog()
