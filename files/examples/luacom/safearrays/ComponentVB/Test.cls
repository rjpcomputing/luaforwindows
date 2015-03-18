VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Test"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit


Public Function GetArray() As String()
    Dim ar(0 To 1, 0 To 2) As String
    
    ar(0, 0) = "A"
    ar(0, 1) = "B"
    ar(0, 2) = "C"
    ar(1, 0) = "D"
    ar(1, 1) = "E"
    ar(1, 2) = "F"
    
    GetArray = ar
End Function

Public Sub SetArray(ByRef ar() As String)
    Dim i As Long, j As Long
    Dim salida As String
    
    For i = LBound(ar, 1) To UBound(ar, 1)
        For j = LBound(ar, 2) To UBound(ar, 2)
            salida = salida & ar(i, j) & " - "
        Next
        salida = salida & vbCrLf & vbCrLf
    Next
    MsgBox (salida)
    
    ar(1, 2) = "*"
End Sub

Public Function GetArray432() As String()
    Dim ar(1 To 4, 1 To 3, 1 To 2) As String
    
    ar(1, 1, 1) = "(1, 1, 1)": ar(1, 1, 2) = "(1, 1, 2)"
    ar(1, 2, 1) = "(1, 2, 1)": ar(1, 2, 2) = "(1, 2, 2)"
    ar(1, 3, 1) = "(1, 3, 1)": ar(1, 3, 2) = "(1, 3, 2)"
    
    ar(2, 1, 1) = "(2, 1, 1)": ar(2, 1, 2) = "(2, 1, 2)"
    ar(2, 2, 1) = "(2, 2, 1)": ar(2, 2, 2) = "(2, 2, 2)"
    ar(2, 3, 1) = "(2, 3, 1)": ar(2, 3, 2) = "(2, 3, 2)"
    
    ar(3, 1, 1) = "(3, 1, 1)": ar(3, 1, 2) = "(3, 1, 2)"
    ar(3, 2, 1) = "(3, 2, 1)": ar(3, 2, 2) = "(3, 2, 2)"
    ar(3, 3, 1) = "(3, 3, 1)": ar(3, 3, 2) = "(3, 3, 2)"
    
    ar(4, 1, 1) = "(4, 1, 1)": ar(4, 1, 2) = "(4, 1, 2)"
    ar(4, 2, 1) = "(4, 2, 1)": ar(4, 2, 2) = "(4, 2, 2)"
    ar(4, 3, 1) = "(4, 3, 1)": ar(4, 3, 2) = "(4, 3, 2)"
    
    GetArray432 = ar
End Function

