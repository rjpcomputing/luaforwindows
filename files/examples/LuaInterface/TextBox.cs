// build@ csc /debug /nologo /target:library TextBox.cs
using System;
using System.Windows.Forms;
using System.Drawing;

namespace TextBox {

public delegate bool SpecialKeyHandler(Keys key);

class ConsoleTextBox : RichTextBox {
    public SpecialKeyHandler handler;

    protected const int WM_KEYDOWN = 0x0100;

	public void SetHandler(SpecialKeyHandler handler_) {
		handler = handler_;
	}

    public override bool PreProcessMessage(ref Message msg) {
        if (msg.Msg == WM_KEYDOWN) {
            Keys keyData = ((Keys) (int) msg.WParam) | ModifierKeys;
            if (keyData == Keys.Enter || keyData == Keys.Escape || keyData == Keys.Tab ||
                keyData == Keys.Up || keyData == Keys.Down )
            {
                if (handler(keyData)) {
                    return true;
                }
            }
        }
       return base.PreProcessMessage(ref msg);
   }
}

}
