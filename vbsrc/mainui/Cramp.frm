VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Object = "{00028C01-0000-0000-0000-000000000046}#1.0#0"; "DBGRID32.OCX"
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "COMDLG32.OCX"
Begin VB.Form frmCramp 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "CRAMP - Scenario"
   ClientHeight    =   7890
   ClientLeft      =   150
   ClientTop       =   720
   ClientWidth     =   8130
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   7890
   ScaleWidth      =   8130
   StartUpPosition =   3  'Windows Default
   Begin VB.Frame Frame1 
      Caption         =   "Results"
      Height          =   6500
      Index           =   1
      Left            =   6480
      TabIndex        =   2
      Top             =   -5880
      Width           =   7095
      Begin VB.Label Label2 
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
         Left            =   2040
         TabIndex        =   12
         Top             =   3000
         Width           =   3075
      End
   End
   Begin VB.Frame Frame1 
      Caption         =   "Scenario"
      Height          =   6500
      Index           =   0
      Left            =   480
      TabIndex        =   1
      Top             =   720
      Width           =   7095
      Begin VB.CommandButton cmdRun 
         Caption         =   "Run"
         Height          =   495
         Left            =   5400
         TabIndex        =   11
         Top             =   2880
         Width           =   1215
      End
      Begin VB.ComboBox cboTrueFalse 
         Height          =   315
         ItemData        =   "Cramp.frx":0000
         Left            =   5280
         List            =   "Cramp.frx":000A
         TabIndex        =   10
         Text            =   "True"
         Top             =   5280
         Width           =   1455
      End
      Begin VB.CommandButton cmdBrowse 
         Caption         =   "..."
         Height          =   255
         Left            =   5760
         TabIndex        =   9
         Top             =   4800
         Width           =   255
      End
      Begin VB.ComboBox cboYesNo 
         Height          =   315
         ItemData        =   "Cramp.frx":001B
         Left            =   5280
         List            =   "Cramp.frx":0025
         TabIndex        =   8
         Text            =   "Yes"
         Top             =   4320
         Width           =   1455
      End
      Begin VB.CommandButton cmdDelete 
         Caption         =   "Delete"
         Height          =   495
         Left            =   5400
         TabIndex        =   7
         Top             =   2040
         Width           =   1215
      End
      Begin VB.CommandButton cmdAddTestcase 
         Caption         =   "Add Testcase"
         Height          =   495
         Left            =   5400
         TabIndex        =   6
         Top             =   1200
         Width           =   1215
      End
      Begin VB.CommandButton cmdAddGroup 
         Caption         =   "Add Group"
         Height          =   495
         Left            =   5400
         TabIndex        =   5
         Top             =   360
         Width           =   1215
      End
      Begin MSDBGrid.DBGrid DBGrid1 
         Bindings        =   "Cramp.frx":0032
         Height          =   2295
         Left            =   360
         OleObjectBlob   =   "Cramp.frx":0046
         TabIndex        =   4
         Top             =   3720
         Width           =   4575
      End
      Begin MSComctlLib.TreeView tvwTreeView 
         Height          =   3135
         Left            =   360
         TabIndex        =   3
         Top             =   360
         Width           =   4575
         _ExtentX        =   8070
         _ExtentY        =   5530
         _Version        =   393217
         HideSelection   =   0   'False
         LabelEdit       =   1
         Style           =   7
         Appearance      =   1
      End
   End
   Begin MSComDlg.CommonDialog CommonDialog1 
      Left            =   360
      Top             =   7440
      _ExtentX        =   847
      _ExtentY        =   847
      _Version        =   393216
   End
   Begin VB.Data Data1 
      Caption         =   "Data1"
      Connect         =   "Access 2000;"
      DatabaseName    =   ""
      DefaultCursorType=   0  'DefaultCursor
      DefaultType     =   2  'UseODBC
      Exclusive       =   0   'False
      Height          =   375
      Left            =   1080
      Options         =   0
      ReadOnly        =   0   'False
      RecordsetType   =   1  'Dynaset
      RecordSource    =   ""
      Top             =   7440
      Visible         =   0   'False
      Width           =   2295
   End
   Begin MSComctlLib.TabStrip TabStrip1 
      Height          =   7455
      Left            =   240
      TabIndex        =   0
      Top             =   120
      Width           =   7575
      _ExtentX        =   13361
      _ExtentY        =   13150
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
      Begin VB.Menu mnuNewItem 
         Caption         =   "&New"
      End
      Begin VB.Menu mnuOpenItem 
         Caption         =   "&Open"
      End
      Begin VB.Menu mnuSaveAsItem 
         Caption         =   "Save&As"
      End
      Begin VB.Menu mnuSaveItem 
         Caption         =   "&Save"
      End
      Begin VB.Menu mnuExitItem 
         Caption         =   "E&xit"
      End
   End
   Begin VB.Menu mnuEdit 
      Caption         =   "&Edit"
   End
   Begin VB.Menu mnuHelp 
      Caption         =   "&Help"
   End
End
Attribute VB_Name = "frmCramp"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private gCellValue As String
Private gColumnVal As Integer
Private gRowVal As Integer
Private gCellProperty As String
Private gSetIdRef As Boolean

'************************************************************
'
'************************************************************
Private Sub cboTrueFalse_Click()
    DBGrid1.Col = gColumnVal
    DBGrid1.Row = gRowVal
    DBGrid1.Text = cboTrueFalse.Text
    cboTrueFalse.Visible = False
    
End Sub

'************************************************************
'
'************************************************************
Private Sub cboYesNo_Click()
    
    DBGrid1.Col = gColumnVal
    DBGrid1.Row = gRowVal
    DBGrid1.Text = cboYesNo.Text
    cboYesNo.Visible = False
    
End Sub

'************************************************************
' Adds one new Group node to the selected node of the
' TreeView.
' If the selected node in the TreeView is Testcase node
' this action is invalid
'************************************************************
Private Sub cmdAddGroup_Click()
        
    CreateAndInitialiseTable tvwTreeView.SelectedItem, otGroup
    
End Sub

'************************************************************
' Adds one new Testcase node to the selected node of the
' TreeView
' Invalid for Scenario node
'************************************************************
Private Sub cmdAddTestcase_Click()
    
    CreateAndInitialiseTable tvwTreeView.SelectedItem, otTestcase
    
End Sub

'************************************************************
'
'************************************************************
Private Sub cmdBrowse_Click()
    Dim exePath As String
    CommonDialog1.Filter = "EXE Files (*.exe)|*.exe"
    CommonDialog1.ShowOpen
    exePath = CommonDialog1.FileName
    
    DBGrid1.Col = gColumnVal
    DBGrid1.Row = gRowVal
    DBGrid1.Text = exePath
    cmdBrowse.Visible = False
    
End Sub

'************************************************************
' Deletes the selected node and its children
' Invalid for Scenario element
'************************************************************
Private Sub cmdDelete_Click()
    Dim selectedNode As Node
    Dim selectedType As ObjectType
    
    Set selectedNode = tvwTreeView.SelectedItem
    selectedType = nodetype(selectedNode)
    DeleteNode selectedNode
    DeleteTableInDB selectedNode
           
End Sub

Private Sub cmdRun_Click()
    Dim TaskID As Long
    'TaskID = Shell("calc.exe", vbNormalFocus)
    TaskID = Shell("cmd.exe", vbNormalFocus)
    TaskID = Shell("F:\WRKSPS\cvs\cramp\bin\DPEBaseClassTest.exe", vbNormalFocus)
    
End Sub

Private Sub DBGrid1_AfterColEdit(ByVal ColIndex As Integer)
    If LCase(gCellProperty) = LCase("MaxRunTime") Or _
                    LCase(gCellProperty) = LCase("MonInterval") Or _
                    LCase(gCellProperty) = LCase("NumRuns") Then
        If Not IsNumeric(DBGrid1.Text) Or _
                Val(DBGrid1.Text) <= 0 Then
            DBGrid1.Text = gCellValue
        End If
        Exit Sub
    End If
    
    
End Sub

'************************************************************
' Checks the column the user has clicked
' First column is non editable.
'************************************************************
Private Sub DBGrid1_BeforeColEdit(ByVal ColIndex As Integer, _
                            ByVal KeyAscii As Integer, Cancel As Integer)
    If ColIndex = 0 Then
        Cancel = True
    Else
        Cancel = False
    End If
End Sub

Private Sub DBGrid1_LostFocus()
    
    cboYesNo.Visible = False
    cboTrueFalse.Visible = False
    
End Sub

'************************************************************
'
'************************************************************
Private Sub DBGrid1_MouseDown(Button As Integer, Shift As Integer, _
                                X As Single, Y As Single)
    
    'Declare variables.
    Dim DY, DX, CellLeft, CellTop
    Dim positionX As Double
    Dim positionY As Double
    Dim CellProperty As String
    
    
    ' Hide the combo boxes and browse button
    cmdBrowse.Visible = False
    cboTrueFalse.Visible = False
    cboYesNo.Visible = False
    gSetIdRef = False
    
    'Set the cell particulars
    gColumnVal = DBGrid1.ColContaining(X)
    gRowVal = DBGrid1.RowContaining(Y)
    
    'User has selected Property column, exit sub
    If gColumnVal = 0 Then
        Exit Sub
    End If
    
    DY = DBGrid1.RowHeight
    DX = DBGrid1.Columns(gColumnVal).Width
    
    CellLeft = DBGrid1.Columns(gColumnVal).Left
    CellTop = DBGrid1.RowTop(gRowVal)
    
    'Set the cell value and Property value
    gCellValue = DBGrid1.Columns(gColumnVal). _
         CellValue(DBGrid1.RowBookmark(gRowVal))
    gCellProperty = DBGrid1.Columns(gColumnVal - 1). _
         CellValue(DBGrid1.RowBookmark(gRowVal))
         
    'User intends to change the Exe Path
    'Offer the common dialog box
    If gCellProperty = "ExePath" Then
        positionX = DBGrid1.Left + CellLeft + _
                DBGrid1.Columns(gColumnVal).Width - cmdBrowse.Width
        positionY = DBGrid1.Top + CellTop
        cmdBrowse.Move positionX, positionY
        cmdBrowse.Visible = True
        Exit Sub
    End If
    
    'Offer the Yes/No combo box
    If LCase(gCellValue) = LCase("Yes") Or _
                    LCase(gCellValue) = LCase("No") Then
        positionX = DBGrid1.Left + CellLeft
        positionY = DBGrid1.Top + CellTop
        cboYesNo.Move positionX, positionY, DX
        cboYesNo.Text = gCellValue
        cboYesNo.Visible = True
        Exit Sub
    End If
    
    'Offer the True/False combo box
    If LCase(gCellValue) = LCase("True") Or _
                    LCase(gCellValue) = LCase("False") Then
        positionX = DBGrid1.Left + CellLeft
        positionY = DBGrid1.Top + CellTop
        cboTrueFalse.Width = DBGrid1.Columns(gColumnVal).Width
        cboTrueFalse.Move positionX, positionY, DX
        cboTrueFalse.Text = gCellValue
        cboTrueFalse.Visible = True
        Exit Sub
    End If
    
    If LCase(gCellProperty) = LCase("IdRef") Then
        MsgBox "Please select the Regerence Node"
        gSetIdRef = True
        IdRefSettings
        Exit Sub
    End If
    
    
    SetActionButtons
 
End Sub

'************************************************************
' Loads the form
'************************************************************
Private Sub Form_Load()
    Dim ii As Integer
    For ii = 0 To Frame1.Count - 1
       Frame1(ii).Visible = False
    Next ii
    
    gDatabaseName = "C:\tmp\TestDB.mdb"
    Randomize
    Data1.DatabaseName = gDatabaseName
    
    CurrentTab = 1
    Frame1(CurrentTab - 1).Visible = True
    Frame1(CurrentTab - 1).Move 480, 700
    
    'Enable-Disable menu buttons
    mnuSaveItem.Enabled = False
    
    'Set the global variables
    gstrFileName = ""
    
    'Reinitialise gIdcounter and gIdList
    ReinitialiseIds
    'Create a blank DB
    CreateDatabase
    
       
    'Disable Add and Delete cmd buttons
    cmdAddGroup.Enabled = False
    cmdAddTestcase.Enabled = False
    cmdDelete.Enabled = False
    'cmdRun.Enabled = False
    cboYesNo.Visible = False
    cboTrueFalse.Visible = False
    cmdBrowse.Visible = False
    gSetIdRef = False
    
End Sub

'************************************************************
' Exits the application
'************************************************************
Private Sub mnuExitItem_Click()
   Set ADOXcatalog = Nothing
   'cnn.Close
   
   Unload Me
End Sub

'************************************************************
'
'************************************************************
Private Sub mnuNewItem_Click()
    Dim sql As String
    'Reset all the fields and global variables
    gstrFileName = ""
    
    tvwTreeView.Nodes.Clear
    mnuSaveAsItem.Enabled = True
    mnuSaveItem.Enabled = False
    'Set ADOXcatalog = Nothing
    
    'Set the MSysBlank table as the current datasource for DBGrid
    Data1.DatabaseName = gDatabaseName
    
    sql = "SELECT * FROM MSysBlank"
    Data1.RecordSource = sql
    
    Data1.Refresh
    DBGrid1.Refresh
    
    ' Make the Data and DBGrid controls visible.
    Data1.Visible = False
    'frmCramp.DBGrid1.DataSource = ""
    DBGrid1.Visible = True
    
    'Set the DBGrid's second column width
    DBGrid1.Columns(1).Width = 2600
    
    'Reinitialise gIdcounter and gIdList
    ReinitialiseIds
    'Create a blank DB
    CreateDatabase
       
    'Disable Add and Delete cmd buttons
    cmdAddGroup.Enabled = True
    cmdAddTestcase.Enabled = True
    'cmdDelete.Enabled = False
    
End Sub

'************************************************************
'
'************************************************************
Private Sub mnuOpenItem_Click()
    Dim strFileName As String
    Dim sql As String
    CommonDialog1.Filter = "XML Files (*.xml)|*.xml"
    CommonDialog1.ShowOpen
    gstrFileName = CommonDialog1.FileName
    
    'Set the MSysBlank table as the current datasource for DBGrid
    Data1.DatabaseName = gDatabaseName
    
    sql = "SELECT * FROM MSysBlank"
    Data1.RecordSource = sql
    
    Data1.Refresh
    DBGrid1.Refresh
    
    ' Make the Data and DBGrid controls visible.
    Data1.Visible = False
    'frmCramp.DBGrid1.DataSource = ""
    DBGrid1.Visible = True
    
    'Set the DBGrid's second column width
    DBGrid1.Columns(1).Width = 2600
    
    'Reinitialise gIdcounter and gIdList
    ReinitialiseIds
    
    LoadScenario gstrFileName
    
End Sub

'************************************************************
'
'************************************************************
Private Sub mnuSaveAsItem_Click()
    Dim strFileName As String
    CommonDialog1.Filter = "XML Files (*.xml)|*.xml"
    If Not gstrFileName = "" Then
        CommonDialog1.FileName = gstrFileName
    Else
        CommonDialog1.FileName = ""
    End If
    CommonDialog1.ShowOpen
    'Set the global file name
    gstrFileName = CommonDialog1.FileName
    If Not gstrFileName = "" Then
        SaveFunction gstrFileName
        mnuSaveItem.Enabled = True
    End If
End Sub

'************************************************************
'
'************************************************************
Private Sub mnuSaveItem_Click()
    SaveFunction gstrFileName

End Sub

'************************************************************
'
'************************************************************
Private Sub TabStrip1_Click()
    Dim i As Integer
    CurrentTab = TabStrip1.SelectedItem.index
    
    For i = 0 To Frame1.Count - 1
        Frame1(i).Visible = False
    Next i
    
    Frame1(CurrentTab - 1).Visible = True
    Frame1(CurrentTab - 1).Move 480, 700
    frmCramp.Caption = "CRAMP - " & Frame1(CurrentTab - 1).Caption
            
End Sub


Private Sub tvwTreeView_BeforeLabelEdit(Cancel As Integer)
    Cancel = True
End Sub

'************************************************************
'
'************************************************************
Private Sub tvwTreeView_NodeClick(ByVal Node As MSComctlLib.Node)
        
    Dim table_name As String
    table_name = Node.Key
    
    If gSetIdRef = True Then
        DBGrid1.Col = gColumnVal
        DBGrid1.Row = gRowVal
        DBGrid1.Text = Node.Text
        gSetIdRef = False
        Exit Sub
    End If
    'Hide the combo boxes and browse button
    cmdBrowse.Visible = False
    cboYesNo.Visible = False
    cboTrueFalse.Visible = False
    
    RefreshData Node
    
    SetActionButtons
    
End Sub
