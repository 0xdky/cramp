VERSION 5.00
Begin VB.Form frmLVColHS 
   BorderStyle     =   4  'Fixed ToolWindow
   Caption         =   "Hide-Show Column"
   ClientHeight    =   3048
   ClientLeft      =   36
   ClientTop       =   276
   ClientWidth     =   3264
   ControlBox      =   0   'False
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3048
   ScaleWidth      =   3264
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Begin VB.Frame tottickColHSCHB 
      Height          =   2952
      Left            =   120
      TabIndex        =   0
      Top             =   0
      Width           =   3012
      Begin VB.CommandButton cancleCommand 
         Caption         =   "Cancle"
         Height          =   288
         Left            =   1680
         TabIndex        =   15
         Top             =   2520
         Width           =   972
      End
      Begin VB.CommandButton okCommand 
         Caption         =   "Ok"
         Height          =   288
         Left            =   360
         TabIndex        =   14
         Top             =   2520
         Width           =   972
      End
      Begin VB.Frame Frame3 
         Height          =   2052
         Left            =   120
         TabIndex        =   1
         Top             =   360
         Width           =   2772
         Begin VB.CheckBox posiColHSCHB 
            Caption         =   "Position"
            Height          =   252
            Left            =   120
            TabIndex        =   16
            Top             =   221
            Width           =   1212
         End
         Begin VB.CheckBox ticksColHSCHB 
            Caption         =   "Ticks"
            Height          =   252
            Left            =   1440
            TabIndex        =   12
            Top             =   1721
            Width           =   1212
         End
         Begin VB.CheckBox timeColHSCHB 
            Caption         =   "Time(ns)"
            Height          =   252
            Left            =   1440
            TabIndex        =   11
            Top             =   1421
            Width           =   1212
         End
         Begin VB.CheckBox excepColHSCHB 
            Caption         =   "Raw Ticks"
            Height          =   270
            Left            =   1440
            TabIndex        =   10
            Top             =   1121
            Width           =   1212
         End
         Begin VB.CheckBox depthColHSCHB 
            Caption         =   "Depth"
            Height          =   252
            Left            =   1440
            TabIndex        =   9
            Top             =   221
            Width           =   1212
         End
         Begin VB.CheckBox modColHSCHB 
            Caption         =   "Module"
            Height          =   252
            Left            =   120
            TabIndex        =   8
            Top             =   821
            Width           =   1212
         End
         Begin VB.CheckBox maxtickColHSCHB 
            Caption         =   "Max ticks"
            Height          =   252
            Left            =   1440
            TabIndex        =   7
            Top             =   521
            Width           =   1212
         End
         Begin VB.CheckBox totticksColHSCHB 
            Caption         =   "Total ticks"
            Height          =   288
            Left            =   1440
            TabIndex        =   6
            Top             =   821
            Width           =   1212
         End
         Begin VB.CheckBox numColHSCHB 
            Caption         =   "Number"
            Height          =   252
            Left            =   120
            TabIndex        =   5
            Top             =   1721
            Width           =   1212
         End
         Begin VB.CheckBox addrColHSCHB 
            Caption         =   "Address"
            Height          =   252
            Left            =   120
            TabIndex        =   4
            Top             =   1421
            Width           =   1212
         End
         Begin VB.CheckBox funcColHSCHB 
            Caption         =   "Function"
            Height          =   252
            Left            =   120
            TabIndex        =   3
            Top             =   1121
            Width           =   1212
         End
         Begin VB.CheckBox threColHSCHB 
            Caption         =   "Thread"
            Height          =   288
            Left            =   120
            TabIndex        =   2
            Top             =   521
            Width           =   1212
         End
      End
      Begin VB.Label Label1 
         Caption         =   "Hide - Show Column"
         Height          =   204
         Left            =   120
         TabIndex        =   13
         Top             =   200
         Width           =   1452
      End
   End
End
Attribute VB_Name = "frmLVColHS"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub okCommand_Click()
  StoreCheckBoxStatus
  frmMainui.manuHideShow.Enabled = True
  Unload Me
End Sub
Private Sub cancleCommand_Click()
  InitLVColHSForm
  frmMainui.manuHideShow.Enabled = True
  Unload Me
End Sub

Private Sub addrColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If addrColHSCHB.Value = 0 Then
    ReorderColumnPosition "Address", False
  Else
    ReorderColumnPosition "Address", True
  End If
End Sub

Private Sub depthColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If depthColHSCHB.Value = 0 Then
    ReorderColumnPosition "Depth", False
  Else
    ReorderColumnPosition "Depth", True
  End If
End Sub

Private Sub excepColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If excepColHSCHB.Value = 0 Then
    ReorderColumnPosition "Raw Ticks", False
  Else
    ReorderColumnPosition "Raw Ticks", True
  End If
End Sub

Private Sub funcColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If funcColHSCHB.Value = 0 Then
    ReorderColumnPosition "Function", False
  Else
    ReorderColumnPosition "Function", True
  End If
End Sub

Private Sub maxtickColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If maxtickColHSCHB.Value = 0 Then
    ReorderColumnPosition "Max ticks", False
  Else
    ReorderColumnPosition "Max ticks", True
  End If
End Sub

Private Sub modColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If modColHSCHB.Value = 0 Then
    ReorderColumnPosition "Module", False
  Else
    ReorderColumnPosition "Module", True
  End If
End Sub

Private Sub numColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If numColHSCHB.Value = 0 Then
    ReorderColumnPosition "Number", False
  Else
    ReorderColumnPosition "Number", True
  End If
End Sub

Private Sub threColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If threColHSCHB.Value = 0 Then
    ReorderColumnPosition "Thread", False
  Else
    ReorderColumnPosition "Thread", True
  End If
End Sub

Private Sub ticksColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If ticksColHSCHB.Value = 0 Then
    ReorderColumnPosition "Ticks", False
  Else
    ReorderColumnPosition "Ticks", True
  End If

End Sub

Private Sub timeColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If timeColHSCHB.Value = 0 Then
    ReorderColumnPosition "Time(ns)", False
  Else
    ReorderColumnPosition "Time(ns)", True
  End If
End Sub

Private Sub totticksColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If totticksColHSCHB.Value = 0 Then
    ReorderColumnPosition "Total ticks", False
  Else
    ReorderColumnPosition "Total ticks", True
  End If
End Sub
Private Sub posiColHSCHB_Click()
  If Me.Visible = False Then Exit Sub
  
  If posiColHSCHB.Value = 0 Then
    ReorderColumnPosition "Position", False
  Else
    ReorderColumnPosition "Position", True
  End If
End Sub

