VERSION 5.00
Begin VB.Form frmVarEdit 
   Caption         =   "Edit User Variable"
   ClientHeight    =   1845
   ClientLeft      =   8070
   ClientTop       =   7545
   ClientWidth     =   5250
   Icon            =   "frmVarEdit.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   1845
   ScaleWidth      =   5250
   Visible         =   0   'False
   Begin VB.CommandButton cmdVarCancel 
      Caption         =   "&Cancel"
      Height          =   375
      Left            =   4080
      TabIndex        =   5
      Top             =   1320
      Width           =   1095
   End
   Begin VB.CommandButton cmdVarOk 
      Caption         =   "&Ok"
      Height          =   375
      Left            =   2760
      TabIndex        =   4
      Top             =   1320
      Width           =   1095
   End
   Begin VB.TextBox txtVarValue 
      Height          =   325
      Left            =   1680
      TabIndex        =   3
      Top             =   840
      Width           =   3495
   End
   Begin VB.TextBox txtVarName 
      Height          =   325
      Left            =   1680
      TabIndex        =   2
      Top             =   240
      Width           =   3495
   End
   Begin VB.Label lblVarValue 
      Caption         =   "Variable Value:"
      Height          =   255
      Left            =   120
      TabIndex        =   1
      Top             =   960
      Width           =   1335
   End
   Begin VB.Label lblVarName 
      Caption         =   "Variable Name:"
      Height          =   345
      Left            =   120
      TabIndex        =   0
      Top             =   240
      Width           =   1335
   End
End
Attribute VB_Name = "frmVarEdit"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub cmdVarCancel_Click()
    frmVarEdit.Visible = False
    frmMainui.lvwVariables.SetFocus
    Unload Me
End Sub

Private Sub cmdVarOk_Click()
    
    SetKeyValue "Environment", txtVarName.Text, _
                        txtVarValue.Text, REG_SZ
            
    frmMainui.lvwVariables.SelectedItem.SubItems(1) = _
                    txtVarValue.Text
    frmMainui.lvwVariables.Refresh
    
    frmVarEdit.Visible = False
    frmMainui.lvwVariables.SetFocus
    
    Dim sSTAFCONVDIR As String
    If txtVarName.Text = "STAF_PATH" Then
        sSTAFCONVDIR = txtVarValue.Text & "\bin"
        SetKeyValue "Environment", "STAFCONVDIR", _
                        sSTAFCONVDIR, REG_SZ
    End If
    
    Unload Me
    
End Sub

