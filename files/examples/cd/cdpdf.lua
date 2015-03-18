require"cdlua"
require"cdluapdf"

canvas = cd.CreateCanvas(cd.PDF, "test.pdf")
canvas:Foreground (cd.RED)
canvas:Box (10, 55, 10, 55)
canvas:Foreground(cd.EncodeColor(255, 32, 140))
canvas:Line(0, 0, 300, 100)
canvas:Kill()
