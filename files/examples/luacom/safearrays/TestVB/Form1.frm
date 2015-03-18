VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   3090
   ClientLeft      =   60
   ClientTop       =   450
   ClientWidth     =   4680
   LinkTopic       =   "Form1"
   ScaleHeight     =   3090
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton Command4 
      Caption         =   "SetArray [4][3][2]"
      Height          =   495
      Left            =   1920
      TabIndex        =   3
      Top             =   360
      Width           =   1695
   End
   Begin VB.CommandButton Command3 
      Caption         =   "GetArray"
      Height          =   495
      Left            =   360
      TabIndex        =   2
      Top             =   1200
      Width           =   1215
   End
   Begin VB.CommandButton Command2 
      Caption         =   "GetArray [4][3][2]"
      Height          =   495
      Left            =   1920
      TabIndex        =   1
      Top             =   1200
      Width           =   1695
   End
   Begin VB.CommandButton Command1 
      Caption         =   "SetArray"
      Height          =   495
      Left            =   360
      TabIndex        =   0
      Top             =   360
      Width           =   1215
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub Command1_Click()
    Dim p As PRUEBASAFEARRAYLib.Test
    
    Set p = New Test
    
    Dim ar(0 To 1, 0 To 2) As String
    
    ar(0, 0) = "A"
    ar(0, 1) = "B"
    ar(0, 2) = "C"
    ar(1, 0) = "D"
    ar(1, 1) = "E"
    ar(1, 2) = "F"
    Call p.SetArray(ar)
    
    MsgBox (ar(1, 2))
End Sub

Private Sub Command2_Click()
    Dim p As PRUEBASAFEARRAYLib.Test
    
    Set p = New Test
    
    Dim ar() As String
    ar = p.GetArray432
    
    Dim i As Long, j As Long, k As Long
    Dim salida As String
    
    For i = LBound(ar, 1) To UBound(ar, 1)
        For j = LBound(ar, 2) To UBound(ar, 2)
            For k = LBound(ar, 3) To UBound(ar, 3)
                salida = salida & "[" & i & "," & j & "," & k & "]=" & ar(i, j, k) & " - "
            Next
            salida = salida & vbCrLf
        Next
        salida = salida & vbCrLf & vbCrLf
    Next
    MsgBox (salida)
End Sub

Private Sub Command3_Click()
    Dim p As PRUEBASAFEARRAYLib.Test
    
    Set p = New Test
    
    Dim ar() As String
    ar = p.GetArray
    
    Dim i As Long, j As Long
    Dim salida As String
    
    For i = LBound(ar, 1) To UBound(ar, 1)
        For j = LBound(ar, 2) To UBound(ar, 2)
            salida = salida & "[" & i & "," & j & "]=" & ar(i, j) & " - "
        Next
        salida = salida & vbCrLf & vbCrLf
    Next
    MsgBox (salida)
End Sub

Private Sub Command4_Click()
    Dim p As PRUEBASAFEARRAYLib.Test
    
    Set p = New Test
    
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

    
    Call p.SetArray(ar)
    
    'MsgBox (ar(1, 2))
End Sub
