
Set obj = CreateObject("testlua.Teste")

Wscript.Echo obj.Sum(2,3)

Wscript.Echo obj.I2A(3)

Dim quotient
quotient = 0
Dim remainder
remainder = 0

obj.IntDivide 5,2,quotient,remainder

Wscript.Echo quotient

Wscript.Echo remainder

