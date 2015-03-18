VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   12375
   ClientLeft      =   60
   ClientTop       =   450
   ClientWidth     =   9885
   LinkTopic       =   "Form1"
   ScaleHeight     =   12375
   ScaleWidth      =   9885
   StartUpPosition =   3  'Windows Default
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Dim WithEvents ctlDynamic As VBControlExtender
Attribute ctlDynamic.VB_VarHelpID = -1

Private Sub Form_Load()
'  Dim WithEvents ctlDyn As UserControl
'  Licenses.Add "testlua.Teste"
  Set ctlDynamic = Controls.Add("testcontrol.Teste", "myctl", Form1)
  ctlDynamic.Move 1, 1
  ctlDynamic.Visible = True
End Sub
