VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "COMDLG32.OCX"
Begin VB.Form frmMainui 
   Caption         =   "CRAMP - Scenario"
   ClientHeight    =   8490
   ClientLeft      =   5340
   ClientTop       =   3075
   ClientWidth     =   8670
   LinkTopic       =   "Form1"
   ScaleHeight     =   8490
   ScaleWidth      =   8670
   Begin VB.Frame fraMainUI 
      Height          =   7308
      Index           =   1
      Left            =   600
      TabIndex        =   2
      Top             =   600
      Visible         =   0   'False
      Width           =   7450
      Begin MSComctlLib.ImageList SortIconImageList 
         Left            =   6720
         Top             =   6840
         _ExtentX        =   794
         _ExtentY        =   794
         BackColor       =   -2147483643
         ImageWidth      =   8
         ImageHeight     =   7
         MaskColor       =   12632256
         _Version        =   393216
         BeginProperty Images {2C247F25-8591-11D1-B16A-00C0F0283628} 
            NumListImages   =   2
            BeginProperty ListImage1 {2C247F27-8591-11D1-B16A-00C0F0283628} 
               Picture         =   "frmMainui.frx":0000
               Key             =   ""
            EndProperty
            BeginProperty ListImage2 {2C247F27-8591-11D1-B16A-00C0F0283628} 
               Picture         =   "frmMainui.frx":00D2
               Key             =   ""
            EndProperty
         EndProperty
      End
      Begin VB.Frame Frame4 
         Caption         =   "Profiling"
         Height          =   972
         Left            =   300
         TabIndex        =   32
         Top             =   240
         Width           =   6852
         Begin VB.CommandButton stopCommand 
            Caption         =   "Stop"
            Height          =   288
            Left            =   4440
            TabIndex        =   39
            Top             =   480
            Width           =   972
         End
         Begin VB.CommandButton flushproCommand 
            Caption         =   "Flush"
            Height          =   288
            Left            =   5640
            TabIndex        =   38
            Top             =   480
            Width           =   972
         End
         Begin VB.CommandButton startCommand 
            Caption         =   "Start"
            Height          =   288
            Left            =   3240
            TabIndex        =   37
            Top             =   480
            Width           =   972
         End
         Begin VB.TextBox pidText 
            Height          =   288
            Left            =   2040
            TabIndex        =   35
            Top             =   480
            Width           =   972
         End
         Begin VB.TextBox compnameText 
            Height          =   288
            Left            =   120
            TabIndex        =   33
            Top             =   480
            Width           =   1692
         End
         Begin VB.Label procidLabel 
            Caption         =   "Pid"
            Height          =   252
            Left            =   2040
            TabIndex        =   36
            Top             =   240
            Width           =   972
         End
         Begin VB.Label compnameLabel 
            Caption         =   "Profile Host"
            Height          =   252
            Left            =   120
            TabIndex        =   34
            Top             =   240
            Width           =   1692
         End
      End
      Begin VB.Frame Frame3 
         Caption         =   "Result"
         Height          =   3972
         Left            =   300
         TabIndex        =   29
         Top             =   3120
         Width           =   6852
         Begin VB.CommandButton preCommand 
            Caption         =   "Previous"
            Height          =   288
            Left            =   1200
            TabIndex        =   45
            Top             =   240
            Width           =   972
         End
         Begin VB.CommandButton nextCommand 
            Caption         =   "Next"
            Height          =   288
            Left            =   3751
            TabIndex        =   44
            Top             =   240
            Width           =   972
         End
         Begin VB.TextBox listitemText 
            Height          =   288
            Left            =   5760
            TabIndex        =   43
            Top             =   240
            Width           =   951
         End
         Begin MSComctlLib.ListView queryLV 
            Height          =   3132
            Left            =   120
            TabIndex        =   30
            Top             =   720
            Width           =   6612
            _ExtentX        =   11668
            _ExtentY        =   5530
            LabelEdit       =   1
            LabelWrap       =   -1  'True
            HideSelection   =   -1  'True
            AllowReorder    =   -1  'True
            FullRowSelect   =   -1  'True
            _Version        =   393217
            ForeColor       =   -2147483640
            BackColor       =   -2147483643
            BorderStyle     =   1
            Appearance      =   1
            NumItems        =   0
         End
         Begin VB.Label maxLabel 
            AutoSize        =   -1  'True
            Height          =   192
            Left            =   3050
            TabIndex        =   49
            Top             =   480
            Width           =   36
         End
         Begin VB.Label deshLabel 
            Alignment       =   2  'Center
            AutoSize        =   -1  'True
            Caption         =   "-"
            Height          =   192
            Left            =   2916
            TabIndex        =   48
            Top             =   480
            Width           =   60
         End
         Begin VB.Label miniLabel 
            Alignment       =   1  'Right Justify
            AutoSize        =   -1  'True
            Height          =   192
            Left            =   2800
            TabIndex        =   47
            Top             =   480
            Width           =   51
         End
         Begin VB.Label totalLabel 
            Alignment       =   2  'Center
            Height          =   252
            Left            =   120
            TabIndex        =   46
            Top             =   480
            Width           =   852
         End
         Begin VB.Label itemrangeLabel 
            Caption         =   "Item range : "
            Height          =   252
            Left            =   4920
            TabIndex        =   42
            Top             =   240
            Width           =   852
         End
         Begin VB.Label totLabel 
            Caption         =   "Total items:"
            Height          =   204
            Left            =   120
            TabIndex        =   41
            Top             =   240
            Width           =   852
         End
         Begin VB.Label rngLabel 
            Caption         =   "Visible items:"
            Height          =   204
            Left            =   2520
            TabIndex        =   40
            Top             =   240
            Width           =   972
         End
      End
      Begin VB.Frame Frame2 
         Caption         =   "Query"
         Height          =   700
         Left            =   300
         TabIndex        =   26
         Top             =   2400
         Width           =   6852
         Begin VB.CommandButton runCommand 
            Caption         =   "Init"
            Height          =   288
            Left            =   5640
            TabIndex        =   31
            Top             =   240
            Width           =   972
         End
         Begin VB.CommandButton queryCommand 
            Caption         =   "Query"
            Enabled         =   0   'False
            Height          =   288
            Left            =   4200
            TabIndex        =   28
            Top             =   240
            Width           =   972
         End
         Begin VB.TextBox queryText 
            Enabled         =   0   'False
            Height          =   288
            Left            =   120
            TabIndex        =   27
            Top             =   240
            Width           =   3732
         End
      End
      Begin VB.Frame Frame1 
         Caption         =   "Query Option"
         Height          =   972
         Left            =   300
         TabIndex        =   13
         Top             =   1320
         Width           =   6852
         Begin VB.TextBox addressText 
            Enabled         =   0   'False
            Height          =   288
            Left            =   4680
            TabIndex        =   50
            Top             =   480
            Width           =   1092
         End
         Begin VB.CheckBox appendCheck 
            Caption         =   "Append"
            Height          =   312
            Left            =   5880
            TabIndex        =   20
            Top             =   840
            Width           =   852
         End
         Begin VB.TextBox limitText 
            Height          =   288
            Left            =   5880
            TabIndex        =   18
            Text            =   "10"
            Top             =   480
            Width           =   852
         End
         Begin VB.ComboBox rtCombo 
            Height          =   288
            Left            =   3600
            Style           =   2  'Dropdown List
            TabIndex        =   17
            Top             =   480
            Width           =   972
         End
         Begin VB.ComboBox threadCombo 
            Height          =   288
            Left            =   2520
            Style           =   2  'Dropdown List
            TabIndex        =   16
            Top             =   480
            Width           =   972
         End
         Begin VB.ComboBox staCombo 
            Height          =   288
            Left            =   1200
            Style           =   2  'Dropdown List
            TabIndex        =   15
            Top             =   480
            Width           =   1212
         End
         Begin VB.ComboBox pidCombo 
            Height          =   288
            Left            =   120
            Style           =   2  'Dropdown List
            TabIndex        =   14
            Top             =   480
            Width           =   972
         End
         Begin VB.Label limitLabel 
            Caption         =   "Limit"
            Height          =   252
            Left            =   5880
            TabIndex        =   25
            Top             =   240
            Width           =   852
         End
         Begin VB.Label addLabel 
            Caption         =   "Address"
            Height          =   252
            Left            =   4680
            TabIndex        =   24
            Top             =   240
            Width           =   1092
         End
         Begin VB.Label rtLabel 
            Caption         =   "Type"
            Height          =   252
            Left            =   3600
            TabIndex        =   23
            Top             =   240
            Width           =   972
         End
         Begin VB.Label threadLabel 
            Caption         =   "Thread"
            Height          =   252
            Left            =   2520
            TabIndex        =   22
            Top             =   240
            Width           =   972
         End
         Begin VB.Label selLabel 
            Caption         =   "Selection"
            Height          =   252
            Left            =   1200
            TabIndex        =   21
            Top             =   240
            Width           =   1212
         End
         Begin VB.Label pidLabel 
            Caption         =   "Pid"
            Height          =   252
            Left            =   120
            TabIndex        =   19
            Top             =   240
            Width           =   972
         End
      End
   End
   Begin VB.Frame fraMainUI 
      Height          =   6900
      Index           =   0
      Left            =   600
      TabIndex        =   1
      Top             =   7920
      Width           =   7450
      Begin VB.ComboBox cboIdRef 
         Height          =   315
         Left            =   6000
         TabIndex        =   12
         Top             =   4320
         Width           =   1215
      End
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
         ItemData        =   "frmMainui.frx":01A4
         Left            =   6000
         List            =   "frmMainui.frx":01AE
         TabIndex        =   9
         Text            =   "TRUE"
         Top             =   4920
         Visible         =   0   'False
         Width           =   1215
      End
      Begin VB.CommandButton cmdRun 
         Caption         =   "&Run"
         Height          =   495
         Left            =   6000
         TabIndex        =   8
         Top             =   3240
         Width           =   1215
      End
      Begin VB.CommandButton cmdDelete 
         Caption         =   "&Delete"
         Height          =   495
         Left            =   6000
         TabIndex        =   7
         Top             =   2280
         Width           =   1215
      End
      Begin VB.CommandButton cmdAddTc 
         Caption         =   "Add &Testcase"
         Height          =   495
         Left            =   6000
         TabIndex        =   6
         Top             =   1320
         Width           =   1215
      End
      Begin VB.CommandButton cmdAddGroup 
         Caption         =   "Add &Group"
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
         Height          =   3504
         Left            =   240
         TabIndex        =   3
         Top             =   480
         Width           =   5496
         _ExtentX        =   9710
         _ExtentY        =   6165
         _Version        =   393217
         HideSelection   =   0   'False
         LabelEdit       =   1
         Style           =   7
         Appearance      =   1
      End
   End
   Begin MSComctlLib.TabStrip tspMainUI 
      Height          =   8052
      Left            =   240
      TabIndex        =   0
      Top             =   240
      Width           =   8172
      _ExtentX        =   14420
      _ExtentY        =   14208
      _Version        =   393216
      BeginProperty Tabs {1EFB6598-857C-11D1-B16A-00C0F0283628} 
         NumTabs         =   2
         BeginProperty Tab1 {1EFB659A-857C-11D1-B16A-00C0F0283628} 
            Caption         =   "Engine"
            ImageVarType    =   2
         EndProperty
         BeginProperty Tab2 {1EFB659A-857C-11D1-B16A-00C0F0283628} 
            Caption         =   "Profiler"
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
      Begin VB.Menu mnuSpace 
         Caption         =   "-"
      End
      Begin VB.Menu mnuSave 
         Caption         =   "&Save"
         Shortcut        =   ^S
      End
      Begin VB.Menu mnuSaveAs 
         Caption         =   "Save &As.."
         Shortcut        =   ^A
      End
      Begin VB.Menu mnuSpace2 
         Caption         =   "-"
      End
      Begin VB.Menu mnuMRU 
         Caption         =   ""
         Index           =   0
         Visible         =   0   'False
      End
      Begin VB.Menu mnuMRU 
         Caption         =   ""
         Index           =   1
         Visible         =   0   'False
      End
      Begin VB.Menu mnuMRU 
         Caption         =   ""
         Index           =   2
         Visible         =   0   'False
      End
      Begin VB.Menu mnuMRU 
         Caption         =   ""
         Index           =   3
         Visible         =   0   'False
      End
      Begin VB.Menu mnuSpace3 
         Caption         =   "-"
         Visible         =   0   'False
      End
      Begin VB.Menu mnuExit 
         Caption         =   "E&xit"
         Shortcut        =   ^X
      End
   End
   Begin VB.Menu mnuHelp 
      Caption         =   "&Help"
   End
   Begin VB.Menu mnuLVRigCL 
      Caption         =   "&LVRightCL"
      Visible         =   0   'False
      Begin VB.Menu manuHideShow 
         Caption         =   "HideShowHeaders"
      End
      Begin VB.Menu manuDevider 
         Caption         =   "-"
      End
      Begin VB.Menu manuCurrSetting 
         Caption         =   "Save setting"
      End
      Begin VB.Menu manuStack 
         Caption         =   "Stack"
      End
   End
End
Attribute VB_Name = "frmMainui"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'***********************************************************
'
'***********************************************************

Option Explicit

Const SYNCHRONIZE = 1048576
Const NORMAL_PRIORITY_CLASS = &H20&
Const INFINITE = -1

Private SelectedIndex As Integer
Private imgIconNo As Integer

'***********************************************************
' Sets the IdRef field in attributes
'***********************************************************
Private Sub cboIdRef_Click()
    lvwAttributes.SelectedItem.SubItems(1) = cboIdRef.Text
    lvwAttributes.SetFocus
    cboIdRef.Visible = False
    
End Sub

'***********************************************************
' Sets the True/False in attributes
'***********************************************************
Private Sub cboTrueFalse_Click()
    
    lvwAttributes.SelectedItem.SubItems(1) = cboTrueFalse.Text
    lvwAttributes.SetFocus
    cboTrueFalse.Visible = False
    
End Sub

'***********************************************************
'Adds a group in scenario
'First update the DB with present attributes data in listview
'then adds a new node in treeview
'***********************************************************
Private Sub cmdAddGroup_Click()
    
    WriteIntoDB
    
    AddNodeInTreeView tvwNodes.SelectedItem, otGroup
    
    gSaveFlag = True
    
End Sub

'***********************************************************
'Adds a testcase in scenario
'First update the DB with present attributes data in listview
'then adds a new node in treeview
'***********************************************************
Private Sub cmdAddTc_Click()
    
    WriteIntoDB
    
    AddNodeInTreeView tvwNodes.SelectedItem, otTestcase
    
    gSaveFlag = True
    
End Sub

'***********************************************************
'Sets the EXE path in the testcase attribute
'***********************************************************
Private Sub cmdBrowse_Click()
    Dim ExecPath As String
    Dim strReturnString As String
    Dim retVal As Boolean
    retVal = False
    dlgSelect.Flags = cdlOFNNoChangeDir
    dlgSelect.Filter = "EXE Files (*.exe)|*.exe"
    dlgSelect.CancelError = True
    strReturnString = ""
    
On Local Error GoTo BrowseError
    
    While retVal = False
        dlgSelect.ShowOpen
        ExecPath = dlgSelect.FileName
        
        If ExecPath <> "" Then
            retVal = GetUNCPath(ExecPath, strReturnString)
        End If
        
    Wend
    
    lvwAttributes.SelectedItem.SubItems(1) = strReturnString
    lvwAttributes.SetFocus
    cmdBrowse.Visible = False
    
    Exit Sub
    
BrowseError:
    
    lvwAttributes.SetFocus
    cmdBrowse.Visible = False
    
End Sub

'***********************************************************
'Deletes the selected node from scenario
'***********************************************************
Private Sub cmdDelete_Click()
    Dim selectedNode As Node
    Dim selectedType As ObjectType
    
    Set selectedNode = tvwNodes.SelectedItem
    selectedType = nodetype(selectedNode)
    DeleteNode selectedNode
    DeleteRecord selectedNode
        
    gSaveFlag = True
        
End Sub

'***********************************************************
'Runs the scenario and generates the results.
'First it saves the entire scenario and then runs it.
'***********************************************************
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
    
    Command = gCRAMPPath & "\bin\CRAMPEngine.exe " & gCurFileName
    
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

'***********************************************************
'When CRAMP application starts it does following things.
'***********************************************************
Private Sub Form_Load()
    
    CleanAndRestart
    
    InitialiseMRUFileList
    
    CreateDatabase
        
    AddNodeInTreeView , otScenario
    
    RenameFormWindow
    
    '***********************************************************
    ' My Code Starts Here
    '***********************************************************
    'descending order
    imgIconNo = lvwDescending
    'get all cramp environment variable
    GetEnvironmentVariable
    'add raw/tick
    SetRTCombo
    'set stat/thread/addr combobox
    SetSTACombo
    'move controls
    MoveControls (staCombo.Text)

End Sub

'***********************************************************
'
'***********************************************************
Private Sub Form_Unload(Cancel As Integer)
    WriteIntoDB
    
    SaveIntoMRUFile
    
    If Not CheckSaveStatus Then
        Cancel = -1
        Exit Sub
    Else
        CleanUp 'pie added this code
    End If
    
    Set ADOXcatalog = Nothing
    If FileExists(gDatabaseName) Then
        DeleteFile gDatabaseName
    End If
    
End Sub

'***********************************************************
'Sets the attributs in the listview
'***********************************************************
Private Sub lvwAttributes_Click()
    Dim CellWidth As Double
    Dim Selection As String
    Dim PX As Double
    Dim PY As Double
    Dim ExecPath As String
    
    'Hide the combo boxes and browse button
    cboTrueFalse.Visible = False
    cboIdRef.Visible = False
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
    If UCase(Selection) = UCase("ExecPath") Then
        cmdBrowse.Move PX + CellWidth - 300, PY
        cmdBrowse.Visible = True
        SelectedIndex = lvwAttributes.SelectedItem.index
        
        Exit Sub
    ElseIf UCase(Selection) = UCase("IdRef") Then
        CreateIdRefList
        Dim index As Integer
        cboIdRef.Clear
        cboIdRef.Move PX, PY, CellWidth - 150
        cboIdRef.Visible = True
        cboIdRef.Text = lvwAttributes.SelectedItem.SubItems(1)
        For index = 1 To gIdRef.Count
            cboIdRef.AddItem gIdRef.Item(index)
        Next index
        cboIdRef.SetFocus
        SelectedIndex = lvwAttributes.SelectedItem.index
        
        Exit Sub
    
    End If
    
    Selection = lvwAttributes.SelectedItem.SubItems(1)
    Select Case UCase(Selection)
           
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

'***********************************************************
'When user clicks other than listview, update the DB.
'***********************************************************
Private Sub lvwAttributes_LostFocus()
    
    If cboTrueFalse.Visible Or _
       cboIdRef.Visible Or _
       txtInput.Visible Then
       
       Exit Sub
    End If
    
    WriteIntoDB
    
End Sub

'***********************************************************
'End the CRAMP application
'***********************************************************
Private Sub mnuExit_Click()
    WriteIntoDB
    
    SaveIntoMRUFile
    
    If Not CheckSaveStatus Then
        Exit Sub
    Else
      CleanUp 'pie added this code
    End If
    
    Set ADOXcatalog = Nothing
    If FileExists(gDatabaseName) Then
        DeleteFile gDatabaseName
    End If
    
    End
End Sub

'***********************************************************
'Always update the DB incase the user has modified it
'***********************************************************
Private Sub mnuFile_Click()
    
    WriteIntoDB
    
End Sub

'***********************************************************
'Always update the DB incase the user has modified it
'***********************************************************
Private Sub mnuHelp_Click()
    
    WriteIntoDB
    
    Dim pptPath As String
    pptPath = App.Path & "\..\docs\CRAMP.ppt"
    Dim ppt As Object
    Set ppt = CreateObject("PowerPoint.Application.9")
    ppt.Visible = True
    ppt.Presentations.Open pptPath
    ppt.ActivePresentation.SlideShowSettings.Run
    Set ppt = Nothing
    
End Sub

'***********************************************************
'User has clicked on one of most recent used scenario
'First save the existing scenario if it is modified
'then open the clicked scenario
'***********************************************************
Private Sub mnuMRU_Click(index As Integer)
    Dim RetStatus As Boolean
    RetStatus = CheckSaveStatus
    If Not RetStatus Then
        Exit Sub
    End If
    
    Dim sScenarioName As String
    sScenarioName = gMRUList(0, index)
    
    If Not FileExists(sScenarioName) Then
        Dim Msg, Style, Title, Response, MyString
        Msg = "Scenario file " & Chr(13) & Chr(34) & _
              sScenarioName & Chr(34) & Chr(13) & _
              " does not exist"
        Style = vbExclamation + vbOKOnly
        Title = "CRAMP Error"
        MsgBox Msg, Style, Title
        Exit Sub
    End If
    
    Dim tmpStr As String
    CleanAndRestart
    
    CreateDatabase
    
    gCurScenarioName = GetFileNameWithoutExt(sScenarioName)
    
    gCurFileName = sScenarioName
    mnuSave.Enabled = True
    LoadScenario gCurFileName
    cmdRun.Enabled = True
    RenameFormWindow
    UpdateMRUFileList gCurFileName
    gSaveFlag = False
 
End Sub

'***********************************************************
'User has clicked on New menu in File menu,
'Save the existing scenario if it is modified
'Clean and restart CRAMP application
'***********************************************************
Private Sub mnuNew_Click()
    
    Dim RetStatus As Boolean
    RetStatus = CheckSaveStatus
    If Not RetStatus Then
        Exit Sub
    End If
    
    CleanAndRestart
    
    CreateDatabase
        
    AddNodeInTreeView , otScenario
    
End Sub

'***********************************************************
'Opens the selected scenario file
'***********************************************************
Private Sub mnuOpen_Click()
    Dim strFileName As String
    
    Dim RetStatus As Boolean
    RetStatus = CheckSaveStatus
    If Not RetStatus Then
        Exit Sub
    End If
    
    dlgSelect.Filter = "XML Files (*.xml)|*.xml"
    dlgSelect.FileName = ""
    dlgSelect.ShowOpen
    'Set the global file name
    If dlgSelect.FileName <> "" Then
        CleanAndRestart
    
        CreateDatabase
    
        gCurScenarioName = Left(dlgSelect.FileTitle, _
                                (Len(dlgSelect.FileTitle) - 4))
        strFileName = dlgSelect.FileName
        gCurFileName = strFileName
        mnuSave.Enabled = True
        LoadScenario strFileName
        cmdRun.Enabled = True
        RenameFormWindow
        UpdateMRUFileList strFileName
        gSaveFlag = False
    End If
    
End Sub

'***********************************************************
'Save the current scenario file
'***********************************************************
Private Sub mnuSave_Click()
        
    SaveFunction gCurFileName
    
End Sub

'***********************************************************
'Save the current scenario with new name
'***********************************************************
Private Sub mnuSaveAs_Click()
    dlgSelect.Flags = cdlOFNOverwritePrompt
    dlgSelect.Filter = "XML Files (*.xml)|*.xml"
    If Not gCurFileName = "" Then
        dlgSelect.FileName = gCurFileName
    Else
        dlgSelect.FileName = ""
    End If
    dlgSelect.ShowSave
    
    If dlgSelect.FileTitle <> "" Then
        gCurScenarioName = Left(dlgSelect.FileTitle, _
                                (Len(dlgSelect.FileTitle) - 4))
        gCurFileName = dlgSelect.FileName
        If Not gCurFileName = "" Then
            SaveFunction gCurFileName
            mnuSave.Enabled = True
            cmdRun.Enabled = True
        End If
        RenameFormWindow
    End If
End Sub

'***********************************************************
'User has changed the tab strip option, set the Application
'header accordingly by calling RenameFormWindow
'***********************************************************
Private Sub tspMainUI_Click()
    Dim ii As Integer
    
    For ii = 0 To fraMainUI.Count - 1
        fraMainUI(ii).Visible = False
    Next ii
    
    fraMainUI(tspMainUI.SelectedItem.index - 1).Visible = True
    fraMainUI(tspMainUI.SelectedItem.index - 1).Move 600, 840
    
    RenameFormWindow
End Sub

'***********************************************************
'
'***********************************************************
Private Sub tvwNodes_NodeClick(ByVal Node As MSComctlLib.Node)
    
    'Hide the combo boxes and browse button
    cmdBrowse.Visible = False
    cboTrueFalse.Visible = False
    cboIdRef.Visible = False
    
    WriteIntoDB
    
    RefreshData
    
    SetActionButtons
    
    gSaveFlag = True
    
End Sub

'***********************************************************
'
'***********************************************************
Private Sub txtInput_LostFocus()
        
    If UCase(lvwAttributes.ListItems(SelectedIndex)) = UCase("Name") Then
        If Not IsNumeric(txtInput.Text) Then
            lvwAttributes.ListItems(SelectedIndex).SubItems(1) = txtInput.Text
            'tvwNodes.SelectedItem.Text = txtInput.Text
            UpdateNodeName txtInput.Text
        End If
        
    End If
    
    If UCase(lvwAttributes.ListItems(SelectedIndex)) <> UCase("Release") And _
       UCase(lvwAttributes.ListItems(SelectedIndex)) <> UCase("Argv") Then
        If IsNumeric(txtInput.Text) Then
            lvwAttributes.ListItems(SelectedIndex).SubItems(1) = txtInput.Text
        End If
    Else
        lvwAttributes.ListItems(SelectedIndex).SubItems(1) = txtInput.Text
    End If
    
    lvwAttributes.SetFocus
    txtInput.Visible = False
    
End Sub

'***********************************************************
' My Code Starts Here
'***********************************************************

'***********************************************************
' append check box control
'***********************************************************
Private Sub appendCheck_Click()
  'set query text
  SetQueryText (staCombo.Text)
End Sub

'***********************************************************
' set integer value only
'***********************************************************
Private Sub limitText_KeyPress(KeyAscii As Integer)
  'check for -ve sign
  If KeyAscii = 45 Then
    Exit Sub
  End If
  KeyAscii = ChkForDigit(KeyAscii)
End Sub
'***********************************************************
' limit text box lost focus notification
'***********************************************************
Private Sub limitText_LostFocus()
  If Not IsNumeric(limitText.Text) Then
    limitText.Text = 10
  End If
  'set query text
  SetQueryText (staCombo.Text)
End Sub

'***********************************************************
' set integer value only
'***********************************************************
Private Sub pidText_KeyPress(KeyAscii As Integer)
  KeyAscii = ChkForDigit(KeyAscii)
End Sub
'***********************************************************
' set process id combo box
'***********************************************************
Private Sub pidCombo_Click()
  Dim pidHand As udtPID
  
  If UBound(pidArray) < 0 Then Exit Sub
  If pidCombo.ListIndex > UBound(pidArray) Then Exit Sub
  
  Screen.MousePointer = vbHourglass
  pidHand = pidArray(pidCombo.ListIndex)
  
  'set thread combo box
  SetValueInComboBox pidHand, Me.threadCombo
  'set query text
  SetQueryText (staCombo.Text)
  Screen.MousePointer = vbDefault
End Sub

'***********************************************************
' query command control
'***********************************************************
Private Sub queryCommand_Click()
Screen.MousePointer = vbHourglass
'run perl script
RunPerlScriptWithCP
'store query.psf file into the dictionary
CreateDictionary
gDicCountLower = 0
gDicCountUpper = listitemText.Text
'set query.psf output into the listview
SetValueInListView
HideShowNextPre
'show hide col
ShowHideCol
'add-remove ADDR
AddRemAddrInSTACB
manuCurrSetting.Checked = False
Screen.MousePointer = vbDefault
End Sub

'***********************************************************
' set raw-tick combo box
'***********************************************************
Private Sub rtCombo_Click()
  'set query text
  SetQueryText (frmMainui.staCombo.Text)
End Sub
'***********************************************************
' set stat-threads-addr combo box
'***********************************************************
Private Sub staCombo_Click()
  'set query text
  SetQueryText (staCombo.Text)
  'move controls
  MoveControls (staCombo.Text)
End Sub

'***********************************************************
' set threads combo box
'***********************************************************
Private Sub threadCombo_Click()
  'set query text
  SetQueryText (frmMainui.staCombo.Text)
End Sub

'***********************************************************
' run command control
'***********************************************************
Private Sub runCommand_Click()
  Screen.MousePointer = vbHourglass
  'set process id combobox
  SetProcessIDCombo
  'set query text
  SetQueryText (staCombo.Text)
  'clean up ui
  If queryLV.ColumnHeaders.Count > 0 Then
    queryLV.ColumnHeaders.Clear
  End If
  queryLV.ListItems.Clear
  gDicCountLower = 0
  frmMainui.miniLabel.Caption = gDicCountLower
  gDicCountUpper = 0
  frmMainui.maxLabel.Caption = gDicCountUpper
  If gobjDic.Count > 0 Then
    gobjDic.removeAll
  End If
  'add-remove ADDR
  AddRemAddrInSTACB
  frmMainui.totalLabel.Caption = gobjDic.Count
  Screen.MousePointer = vbDefault
End Sub

'***********************************************************
' start button click
'***********************************************************
Private Sub startCommand_Click()
  
  If compnameText.Text = "" Then
    MsgBox "ERROR :: Null computer name"
    Exit Sub
  End If
  
  If pidText.Text = "" Then
    MsgBox "ERROR :: Null pid value"
    Exit Sub
  End If
  
  'start profiling
  DoProfiling ("START")
End Sub

'***********************************************************
' stop button click
'***********************************************************
Private Sub stopCommand_Click()
  If compnameText.Text = "" Then
    MsgBox "ERROR :: Null computer name"
    Exit Sub
  End If
  
  If pidText.Text = "" Then
    MsgBox "ERROR :: Null pid value"
    Exit Sub
  End If
  
  'stop profiling
  DoProfiling ("STOP")

End Sub

'***********************************************************
' flush button click
'***********************************************************
Private Sub flushproCommand_Click()
  
  If compnameText.Text = "" Then
    MsgBox "ERROR :: Null computer name"
    Exit Sub
  End If
  
  If pidText.Text = "" Then
    MsgBox "ERROR :: Null pid value"
    Exit Sub
  End If
  
  'flush profiling
  DoProfiling ("FLUSH")
End Sub

'***********************************************************
' listview double click
'***********************************************************
Private Sub queryLV_DblClick()
  If queryLV.ColumnHeaders.Count <> 0 Then
    SetValueFromLV (staCombo.Text)
  End If
End Sub
'***********************************************************
' next button click
'***********************************************************
Private Sub nextCommand_Click()
  Screen.MousePointer = vbHourglass
  gDicCountLower = gDicCountUpper
  gDicCountUpper = gDicCountUpper + listitemText.Text
  SetValueInListView
  HideShowNextPre
  'show hide col
  ShowHideCol
  'show icon on header
  ShowSortIconInLVHeader Me.queryLV, imgIconNo
  manuCurrSetting.Checked = False
  Screen.MousePointer = vbDefault
End Sub
'***********************************************************
' previous button click
'***********************************************************
Private Sub preCommand_Click()
  Screen.MousePointer = vbHourglass
  
  If Not (gDicCountLower - listitemText.Text) < 0 Then
    gDicCountLower = gDicCountLower - listitemText.Text
    gDicCountUpper = gDicCountLower + listitemText.Text
  Else
    gDicCountUpper = gDicCountLower
    gDicCountLower = 0
  End If
  
  SetValueInListView
  HideShowNextPre
  'show hide col
  ShowHideCol
  'show icon on header
  ShowSortIconInLVHeader Me.queryLV, imgIconNo
  manuCurrSetting.Checked = False
  Screen.MousePointer = vbDefault
End Sub
'***********************************************************
' set integer value
'***********************************************************
Private Sub listitemText_KeyPress(KeyAscii As Integer)
  KeyAscii = ChkForDigit(KeyAscii)
End Sub
'***********************************************************
' listitem lost focus
'***********************************************************
Private Sub listitemText_LostFocus()
  If Not IsNumeric(listitemText.Text) Then
    listitemText.Text = 100
  End If
  If listitemText.Text > 2000 Then
    listitemText.Text = 2000
  End If
End Sub
'***********************************************************
' pop up menu when right click in the listview
'***********************************************************
Private Sub queryLV_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
  If queryLV.ColumnHeaders.Count > 0 Then
    If Button = vbRightButton Then
      PopupMenu mnuLVRigCL
    End If
  End If
End Sub
'***********************************************************
' click on the manu hide-show
'***********************************************************
Private Sub manuHideShow_Click()
  Screen.MousePointer = vbHourglass
  
  Dim X_Cord As Long
  Dim Y_cord As Long
  
  X_Cord = 0
  Y_cord = 0
  
  InitLVColHSForm
  'set check box sensitivity
  SetCHBSensitivity
  GetCurrCursorPosition X_Cord, Y_cord
  'MsgBox X_Cord & "    " & Y_cord
  frmLVColHS.Top = X_Cord
  frmLVColHS.Left = Y_cord
  
  frmLVColHS.Visible = True
  manuHideShow.Enabled = False
  'frmMainui.Enabled = False
  Screen.MousePointer = vbDefault
End Sub
'***********************************************************
' set current setting
'***********************************************************
Private Sub manuCurrSetting_Click()
  Screen.MousePointer = vbHourglass
  manuCurrSetting.Checked = True
  StoreUserSetting
  Screen.MousePointer = vbDefault
End Sub
'***********************************************************
' set stack
'***********************************************************
Private Sub manuStack_Click()
  Screen.MousePointer = vbHourglass
  GetStackForGivenPosition
  Screen.MousePointer = vbDefault
End Sub
'***********************************************************
' column header click fpr sorting
'***********************************************************
Private Sub queryLV_ColumnClick(ByVal ColumnHeader As MSComctlLib.ColumnHeader)
  
  DoEvents
  
  With Me.queryLV
    
    .MousePointer = ccHourglass
  
    'tie images to listview headers
    .ColumnHeaderIcons = SortIconImageList
    .SortKey = ColumnHeader.index - 1
  
    imgIconNo = GetIconNumber(imgIconNo)
  
    'sort
    RunPerlScriptWithCP ColumnHeader.index - 1, imgIconNo
    CreateDictionary
    SetValueInListView
  
    'show icon on header
    ShowSortIconInLVHeader Me.queryLV, imgIconNo
  
    'show hide col
    ShowHideCol
  
    .Refresh
    .MousePointer = ccDefault
  
  End With
  
End Sub

'***********************************************************
' resizing the window
'***********************************************************
Private Sub Form_Resize()
  fraMainUI(0).Move 600, 840
  fraMainUI(1).Move 600, 840
    
  On Error Resume Next
  
  Dim l, t, w, h
  If Me.WindowState <> vbMinimized Then
    If Me.WindowState <> vbMaximized Then
      If Me.Width < 9000 Then     'prevent form getting too small in width
        Me.Width = 9000
      End If
      If Me.Height < 9000 Then    'prevent from getting too small in height
        Me.Height = 9000
      End If
    End If
        
    tspMainUI.Width = Me.Width - 550
    tspMainUI.Height = Me.Height - 1200
        
    'scenario tab page
    fraMainUI(0).Width = tspMainUI.Width - (2 * (fraMainUI(0).Left - tspMainUI.Left))
    fraMainUI(0).Height = tspMainUI.Height - (1.5 * (fraMainUI(0).Top - tspMainUI.Top))
        
    With Me
      'move the tree listview
      l = .tvwNodes.Left
      t = .tvwNodes.Top
      w = fraMainUI(0).Width - (3 * (tvwNodes.Left - fraMainUI(0).Left)) - cmdAddGroup.Width
      h = fraMainUI(0).Height - (3 * (fraMainUI(0).Top - tvwNodes.Top)) - lvwAttributes.Height
      .tvwNodes.Move l, t, w - 2000, h + 200
      
      'move the scenario listview
      l = .lvwAttributes.Left
      t = tvwNodes.Height - (2 * (tvwNodes.Top - fraMainUI(0).Top))
      w = fraMainUI(0).Width - (2 * (fraMainUI(0).Left - lvwAttributes.Left))
      h = .lvwAttributes.Height
      .lvwAttributes.Move l, t, w + 200, h
      
      'move push button in width
      cmdAddGroup.Left = tvwNodes.Width + 550
      cmdAddTc.Left = tvwNodes.Width + 550
      cmdDelete.Left = tvwNodes.Width + 550
      cmdRun.Left = tvwNodes.Width + 550
      
      'move push button in height
      cmdAddGroup.Top = tvwNodes.Top
      cmdAddTc.Top = cmdAddGroup.Top + (2 * cmdAddGroup.Height)
      cmdDelete.Top = cmdAddTc.Top + (2 * cmdAddTc.Height)
      cmdRun.Top = cmdDelete.Top + (2 * cmdDelete.Height)
      
      'set column header width
      If .lvwAttributes.ColumnHeaders.Count >= 2 Then
        .lvwAttributes.ColumnHeaders(2).Width = .lvwAttributes.Width - .lvwAttributes.ColumnHeaders(1).Width
      End If
      
      'hide controls
      txtInput.Visible = False
      cboTrueFalse.Visible = False
      cboIdRef.Visible = False
      cmdBrowse.Visible = False
    End With
                
    'profiler tab page
    fraMainUI(1).Width = tspMainUI.Width - (2 * (fraMainUI(0).Left - tspMainUI.Left))
    fraMainUI(1).Height = tspMainUI.Height - (1.5 * (fraMainUI(0).Top - tspMainUI.Top))
    
    Frame4.Width = fraMainUI(1).Width - (2 * (fraMainUI(1).Left - Frame4.Left))
    Frame1.Width = fraMainUI(1).Width - (2 * (fraMainUI(1).Left - Frame1.Left))
    Frame2.Width = fraMainUI(1).Width - (2 * (fraMainUI(1).Left - Frame2.Left))
    Frame3.Width = fraMainUI(1).Width - (2 * (fraMainUI(1).Left - Frame3.Left))
    
    'Frame3.Height = fraMainUI(1).Height - 3260
    Frame3.Height = fraMainUI(1).Height - Frame4.Height - Frame1.Height _
                    - Frame2.Height - (fraMainUI(1).Top - Frame4.Top + 100)
    
    'move the profiler listview
    With Me.queryLV
      l = .Left
      t = .Top
      w = Frame3.Width - (2 * (Frame3.Left - .Left))
      h = Frame3.Height - 950
      .Move l, t, w + 150, h
    End With
  End If
  
  Me.Refresh

End Sub


