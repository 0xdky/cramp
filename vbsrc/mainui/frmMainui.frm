VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "COMDLG32.OCX"
Begin VB.Form frmMainui 
   Caption         =   "CRAMP - Scenario"
   ClientHeight    =   8220
   ClientLeft      =   5340
   ClientTop       =   3075
   ClientWidth     =   8655
   LinkTopic       =   "Form1"
   ScaleHeight     =   8220
   ScaleWidth      =   8655
   Begin VB.Frame fraMainUI 
      Caption         =   "Results"
      Height          =   6900
      Index           =   1
      Left            =   7080
      TabIndex        =   2
      Top             =   -6480
      Visible         =   0   'False
      Width           =   7450
      Begin VB.Label Label1 
         AutoSize        =   -1  'True
         Caption         =   "Under Construction ..."
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   13.5
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   360
         Left            =   2520
         TabIndex        =   12
         Top             =   3240
         Width           =   3075
      End
   End
   Begin VB.Frame fraMainUI 
      Caption         =   "Scenario"
      Height          =   6900
      Index           =   0
      Left            =   600
      TabIndex        =   1
      Top             =   840
      Width           =   7450
      Begin VB.CommandButton cmdBrowse 
         Caption         =   "..."
         Height          =   255
         Left            =   6120
         TabIndex        =   11
         Top             =   6360
         Visible         =   0   'False
         Width           =   255
      End
      Begin VB.TextBox txtInput 
         Appearance      =   0  'Flat
         Height          =   285
         Left            =   6000
         TabIndex        =   10
         Top             =   5520
         Visible         =   0   'False
         Width           =   1215
      End
      Begin VB.ComboBox cboTrueFalse 
         Height          =   315
         ItemData        =   "frmMainui.frx":0000
         Left            =   6000
         List            =   "frmMainui.frx":000A
         TabIndex        =   9
         Text            =   "TRUE"
         Top             =   4920
         Visible         =   0   'False
         Width           =   1215
      End
      Begin VB.CommandButton cmdRun 
         Caption         =   "Run"
         Height          =   495
         Left            =   6000
         TabIndex        =   8
         Top             =   3240
         Width           =   1215
      End
      Begin VB.CommandButton cmdDelete 
         Caption         =   "Delete"
         Height          =   495
         Left            =   6000
         TabIndex        =   7
         Top             =   2280
         Width           =   1215
      End
      Begin VB.CommandButton cmdAddTc 
         Caption         =   "Add Testcase"
         Height          =   495
         Left            =   6000
         TabIndex        =   6
         Top             =   1320
         Width           =   1215
      End
      Begin VB.CommandButton cmdAddGroup 
         Caption         =   "Add Group"
         Height          =   495
         Left            =   6000
         TabIndex        =   5
         Top             =   360
         Width           =   1215
      End
      Begin MSComDlg.CommonDialog dlgSelect 
         Left            =   6720
         Top             =   6240
         _ExtentX        =   847
         _ExtentY        =   847
         _Version        =   393216
      End
      Begin MSComctlLib.ListView lvwAttributes 
         Height          =   2300
         Left            =   240
         TabIndex        =   4
         Top             =   4320
         Width           =   5500
         _ExtentX        =   9710
         _ExtentY        =   4048
         LabelWrap       =   -1  'True
         HideSelection   =   0   'False
         FullRowSelect   =   -1  'True
         GridLines       =   -1  'True
         _Version        =   393217
         ForeColor       =   -2147483640
         BackColor       =   -2147483643
         BorderStyle     =   1
         Appearance      =   1
         NumItems        =   0
      End
      Begin MSComctlLib.TreeView tvwNodes 
         Height          =   3500
         Left            =   240
         TabIndex        =   3
         Top             =   360
         Width           =   5500
         _ExtentX        =   9710
         _ExtentY        =   6165
         _Version        =   393217
         HideSelection   =   0   'False
         Style           =   7
         Appearance      =   1
      End
   End
   Begin MSComctlLib.TabStrip tspMainUI 
      Height          =   7815
      Left            =   240
      TabIndex        =   0
      Top             =   240
      Width           =   8175
      _ExtentX        =   14420
      _ExtentY        =   13785
      _Version        =   393216
      BeginProperty Tabs {1EFB6598-857C-11D1-B16A-00C0F0283628} 
         NumTabs         =   2
         BeginProperty Tab1 {1EFB659A-857C-11D1-B16A-00C0F0283628} 
            Caption         =   "Scenario"
            ImageVarType    =   2
         EndProperty
         BeginProperty Tab2 {1EFB659A-857C-11D1-B16A-00C0F0283628} 
            Caption         =   "Results"
            ImageVarType    =   2
         EndProperty
      EndProperty
   End
   Begin VB.Menu mnuFile 
      Caption         =   "&File"
      Begin VB.Menu mnuNew 
         Caption         =   "&New"
         Shortcut        =   ^N
      End
      Begin VB.Menu mnuOpen 
         Caption         =   "&Open"
         Shortcut        =   ^O
      End
      Begin VB.Menu mnuSave 
         Caption         =   "&Save"
         Shortcut        =   ^S
      End
      Begin VB.Menu mnuSaveAs 
         Caption         =   "&SaveAs.."
         Shortcut        =   ^A
      End
      Begin VB.Menu mnuExit 
         Caption         =   "E&xit"
         Shortcut        =   ^X
      End
   End
   Begin VB.Menu mnuHelp 
      Caption         =   "&Help"
   End
End
Attribute VB_Name = "frmMainui"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Const SYNCHRONIZE = 1048576
Const NORMAL_PRIORITY_CLASS = &H20&
Const INFINITE = -1

Private SelectedIndex As Integer

Private Sub cboTrueFalse_Click()
    
    lvwAttributes.SelectedItem.SubItems(1) = cboTrueFalse.Text
    lvwAttributes.SetFocus
    cboTrueFalse.Visible = False
    
End Sub


Private Sub cmdAddGroup_Click()
    
    AddNodeInTreeView tvwNodes.SelectedItem, otGroup
    
End Sub

Private Sub cmdAddTc_Click()
    
    AddNodeInTreeView tvwNodes.SelectedItem, otTestcase
    
End Sub


Private Sub cmdBrowse_Click()
    Dim ExecPath As String
    
    dlgSelect.Filter = "EXE Files (*.exe)|*.exe"
    dlgSelect.ShowOpen
    ExecPath = dlgSelect.FileName
    If ExecPath <> "" Then
        lvwAttributes.SelectedItem.SubItems(1) = ExecPath
    End If
    lvwAttributes.SetFocus
    cmdBrowse.Visible = False
        
End Sub

Private Sub cmdDelete_Click()
    Dim selectedNode As Node
    Dim selectedType As ObjectType
    
    Set selectedNode = tvwNodes.SelectedItem
    selectedType = nodetype(selectedNode)
    DeleteNode selectedNode
    DeleteRecord selectedNode
        
End Sub

Private Sub cmdRun_Click()
    Dim Command As String
    Dim TaskID As Long
    Dim pInfo As PROCESS_INFORMATION
    Dim sInfo As STARTUPINFO
    Dim sNull As String
    Dim lSuccess As Long
    Dim lRetValue As Long
    Dim retVal As Boolean
    Dim Response
    SaveFunction gCurFileName
    
    MousePointer = 11
    
    Command = App.Path & "\CRAMPEngine.exe " & gCurFileName
    
    sInfo.cb = Len(sInfo)
    lSuccess = CreateProcess(sNull, _
                            Command, _
                            ByVal 0&, _
                            ByVal 0&, _
                            1&, _
                            NORMAL_PRIORITY_CLASS, _
                            ByVal 0&, _
                            sNull, _
                            sInfo, _
                            pInfo)
    
    lRetValue = WaitForSingleObject(pInfo.hProcess, INFINITE)
    retVal = GetExitCodeProcess(pInfo.hProcess, lRetValue&)
    
    If lRetValue = 0 Then
        Response = MsgBox("Scenario Run : Successful!!", , "Status")
    Else
        Response = MsgBox("Scenario Run : Unsuccessful" & Chr(13) & _
                    "Exit code: " & lRetValue, , "Status")
    End If
    
    lRetValue = CloseHandle(pInfo.hThread)
    lRetValue = CloseHandle(pInfo.hProcess)
    
    MousePointer = 99
    
End Sub

Private Sub Form_Load()
    
    CleanAndRestart
    
    CreateDatabase
        
    AddNodeInTreeView , otScenario
    
    'ReadAttributes
    
End Sub



Private Sub lvwAttributes_Click()
    Dim CellWidth As Double
    Dim Selection As String
    Dim PX As Double
    Dim PY As Double
    Dim ExecPath As String
    
    'Hide the combo boxes and browse button
    cboTrueFalse.Visible = False
    cmdBrowse.Visible = False
    txtInput.Visible = False
    txtInput.Text = ""
    
    CellWidth = lvwAttributes.Width _
                - lvwAttributes.ColumnHeaders(1).Width _
                - 300
                
    PX = lvwAttributes.Left _
        + lvwAttributes.SelectedItem.Left _
        + lvwAttributes.ColumnHeaders(1).Width _
        + 75
        
    PY = lvwAttributes.Top _
        + lvwAttributes.SelectedItem.Top _
        + 50
       
    Selection = lvwAttributes.SelectedItem
    If Selection = "ExecPath" Then
        cmdBrowse.Move PX + CellWidth - 300, PY
        cmdBrowse.Visible = True
        SelectedIndex = lvwAttributes.SelectedItem.index
        
        Exit Sub
    End If
    
    Selection = lvwAttributes.SelectedItem.SubItems(1)
    Select Case Selection
           
        Case "TRUE", "FALSE"
            cboTrueFalse.Move PX, PY, CellWidth - 150
            cboTrueFalse.Visible = True
            cboTrueFalse.Text = Selection
            cboTrueFalse.SetFocus
            SelectedIndex = lvwAttributes.SelectedItem.index
            Exit Sub
            
    End Select
      
    txtInput.Text = Selection
    txtInput.Height = lvwAttributes.SelectedItem.Height _
                      - 75
                      
    txtInput.Move PX, PY, CellWidth
    txtInput.Visible = True
    'txtInput.SelText = Selection
    txtInput.SetFocus
    SelectedIndex = lvwAttributes.SelectedItem.index
        
End Sub

Private Sub lvwAttributes_LostFocus()
    'MsgBox "Lost Focus"
    If cboTrueFalse.Visible Or _
       txtInput.Visible Then
       
       Exit Sub
    End If
    
    Dim ii As Integer
    
    WriteIntoDB
    
    
End Sub


Private Sub mnuExit_Click()
    Unload Me
    End
End Sub

Private Sub mnuFile_Click()
    'Update the DB
    WriteIntoDB
    
End Sub

Private Sub mnuHelp_Click()
    WriteIntoDB
End Sub

Private Sub mnuNew_Click()
    
    CleanAndRestart
    
    CreateDatabase
        
    AddNodeInTreeView , otScenario
    
End Sub

Private Sub mnuOpen_Click()
    
    CleanAndRestart
    
    CreateDatabase
    
    Dim strFileName As String
    dlgSelect.Filter = "XML Files (*.xml)|*.xml"
    If Not gCurFileName = "" Then
        dlgSelect.FileName = gCurFileName
    Else
        dlgSelect.FileName = ""
    End If
    dlgSelect.ShowOpen
    'Set the global file name
    strFileName = dlgSelect.FileName
    gCurFileName = strFileName
    mnuSave.Enabled = True
    LoadScenario strFileName
    cmdRun.Enabled = True
    
End Sub

Private Sub mnuSave_Click()
    SaveFunction gCurFileName
End Sub

Private Sub mnuSaveAs_Click()
    
    dlgSelect.Filter = "XML Files (*.xml)|*.xml"
    If Not gCurFileName = "" Then
        dlgSelect.FileName = gCurFileName
    Else
        dlgSelect.FileName = ""
    End If
    dlgSelect.ShowSave
    'Set the global file name
    gCurFileName = dlgSelect.FileName
    If Not gCurFileName = "" Then
        SaveFunction gCurFileName
        mnuSave.Enabled = True
        cmdRun.Enabled = True
    End If
End Sub

Private Sub tspMainUI_Click()
    Dim ii As Integer
    
    For ii = 0 To fraMainUI.Count - 1
        fraMainUI(ii).Visible = False
    Next ii
    
    fraMainUI(tspMainUI.SelectedItem.index - 1).Visible = True
    fraMainUI(tspMainUI.SelectedItem.index - 1).Move 600, 840
    frmMainui.Caption = "CRAMP - " & _
            fraMainUI(tspMainUI.SelectedItem.index - 1).Caption
                
End Sub

Private Sub tvwNodes_NodeClick(ByVal Node As MSComctlLib.Node)
    Dim table_name As String
    table_name = Node.Key
    
    'Hide the combo boxes and browse button
    cmdBrowse.Visible = False
    cboTrueFalse.Visible = False
    
    WriteIntoDB
    
    RefreshData
    
    SetActionButtons
    
End Sub

Private Sub txtInput_LostFocus()
        
    lvwAttributes.ListItems(SelectedIndex).SubItems(1) = txtInput.Text
    lvwAttributes.SetFocus
    txtInput.Visible = False
    
End Sub

