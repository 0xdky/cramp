Attribute VB_Name = "modFileHandling"
' This function will return just the file name from a
' string containing a path and file name.

Public Function ParseFileName(sFileIn As String) As String
    Dim I As Integer

   For I = Len(sFileIn) To 1 Step -1
      If InStr("\", Mid$(sFileIn, I, 1)) Then Exit For
   Next
   ParseFileName = Mid$(sFileIn, I + 1, Len(sFileIn) - I)

End Function


' This function will return the file extension from a
' string containing a path and file name.

Public Function GetFileExt(sFileName As String) As String
    Dim P As Integer

    For P = Len(sFileName) To 1 Step -1
        'Find the last ocurrence of "." in the string
        If InStr(".", Mid$(sFileName, P, 1)) Then Exit For
    Next
    
    GetFileExt = Right$(sFileName, Len(sFileName) - P)

End Function

Public Function GetFileNameWithoutExt(sFileName As String) As String
    Dim FileName As String
    Dim FileExt As String
    
    FileName = ParseFileName(sFileName)
    FileExt = GetFileExt(sFileName)
    
    GetFileNameWithoutExt = Left$(FileName, Len(FileName) - (Len(FileExt) + 1))
End Function

'*******************************************************
'Joe Markowski
'jsmarko@eclipse.net
'
'Here's a code snippet to retrieve the old dos filenames
'from the Win95 or Win98 Long filenames.  Occasionally,
'you may need this function.
'For example:
'  C:\MyLongestPath\MyLongerPath\MyFilename.txt
'would return as
'  C:\Mylong~1\MyLong~2\Myfile~1.txt
'*******************************************************
Public Function GetDosPath(LongPath As String) As String

Dim s As String
Dim I As Long
Dim PathLength As Long

        I = Len(LongPath) + 1

        s = String(I, 0)

        PathLength = GetShortPathName(LongPath, s, I)

        GetDosPath = Left$(s, PathLength)

End Function


' This procedure will add a \ to the end of the directory
' name if needed.

Function sFixDirString(sInComming As String) As String
Dim sTemp As String

    sTemp = sInComming

    If Right$(sTemp, 1) <> "\" Then
    sFixDirString = sTemp & "\"
    Else
    sFixDirString = sTemp
    End If

End Function

' The MakeDir routine will create a directory even if the
' underlying directories do not exist.

Sub MakeDir(sDirName As String)
Dim iMouseState As Integer
Dim iNewLen As Integer
Dim iDirLen As Integer

    'Get Mouse State
    iMouseState = Screen.MousePointer

    'Change Mouse To Hour Glass
    Screen.MousePointer = 11

    'Set Start Length To Search For [\]
    iNewLen = 4

    'Add [\] To Directory Name If Not There
    sDirName = sFixDirString(sDirName)

On Local Error GoTo MakeDirError
    MkDir (sDirName)

    'Leave The Mouse The Way You Found It
    Screen.MousePointer = iMouseState
    Exit Sub

MakeDirError:
    'If Err.Number = 75 Then
        'Exit Sub
    'End If
    
    Resume Next
End Sub

Public Sub FolderTestRoutines()
    CopyFolder
    DeleteFolder
    'FileExists
    'CopyFile
End Sub

Public Function FileExists(file As String) As Boolean
    Dim fso
    'Dim file As String
    'file = "D:\CRAMP\TesXML.xml" ' change to match the file w/Path
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(file) Then
        FileExists = True
    Else
        FileExists = False
    End If
End Function


Public Sub CopyFile()
    Dim fso
    Dim file As String, sfol As String, dfol As String
    file = "TestXML.xml" ' change to match the file name
    sfol = "D:\CRAMP\" ' change to match the source folder path
    dfol = "F:\" ' change to match the destination folder path
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FileExists(sfol & file) Then
        MsgBox sfol & file & " does not exist!", vbExclamation, "Source File Missing"
    ElseIf Not fso.FileExists(dfol & file) Then
        fso.CopyFile (sfol & file), dfol, True
    Else
        MsgBox dfol & file & " already exists!", vbExclamation, "Destination File Exists"
    End If
End Sub

Public Sub MoveFile()
    Dim fso
    Dim file As String, sfol As String, dfol As String
    file = "test.xls" ' change to match the file name
    sfol = "C:\" ' change to match the source folder path
    dfol = "E:\" ' change to match the destination folder path
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FileExists(sfol & file) Then
        MsgBox sfol & file & " does not exist!", vbExclamation, "Source File Missing"
    ElseIf Not fso.FileExists(dfol & file) Then
        fso.MoveFile (sfol & file), dfol
    Else
        MsgBox dfol & file & " already exists!", vbExclamation, "Destination File Exists"
    End If
End Sub

Public Sub DeleteFile()
    Dim fso
    Dim file As String
    file = "C:\test.xls" ' change to match the file w/Path
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(file) Then
        fso.DeleteFile file, True
    Else
        MsgBox file & " does not exist or has already been deleted!" _
                , vbExclamation, "File not Found"
    End If
End Sub

Public Sub FolderExists()
    Dim fso
    Dim folder As String
    folder = "C:\My Documents" ' change to match the folder path
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FolderExists(folder) Then
        MsgBox folder & " is a valid folder/path.", vbInformation, "Path Exists"
    Else
        MsgBox folder & " is not a valid folder/path.", vbInformation, "Invalid Path"
    End If
End Sub

Public Sub CreateFolder()
    Dim fso
    Dim fol As String
    fol = "c:\MyFolder" ' change to match the folder path
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(fol) Then
        fso.CreateFolder (fol)
    Else
        MsgBox fol & " already exists!", vbExclamation, "Folder Exists"
    End If
End Sub

Public Sub CopyFolder()
    Dim fso
    Dim sfol As String, dfol As String
    sfol = "D:\users" ' change to match the source folder path
    dfol = "F:\users" ' change to match the destination folder path
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(dfol) Then
        fso.CopyFolder sfol, dfol
    Else
        MsgBox dfol & " already exists!", vbExclamation, "Folder Exists"
    End If
End Sub

Public Sub MoveFolder()
    ' ***********************************************************
    ' ***      This will only work if your operating system   ***
    ' ***          allows it otherwise an error occurs        ***
    ' ***********************************************************
    Dim fso
    Dim fol As String, dest As String
    sfol = "c:\MyFolder" ' change to match the source folder path
    dfol = "e:\MyFolder" ' change to match the destination folder path
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(dfol) Then
        fso.MoveFolder sfol, dfol
    Else
        MsgBox dfol & " already exists!", vbExclamation, "Folder Exists"
    End If
End Sub

Public Sub DeleteFolder()
    ' ***********************************************************
    ' *** This will delete a folder even if it contains files ***
    ' ***                 Use With Caution                    ***
    ' ***********************************************************
    Dim fso
    Dim fol As String
    fol = "D:\users" ' change to match the folder path
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FolderExists(fol) Then
        fso.DeleteFolder fol
    Else
        MsgBox fol & " does not exist or has already been deleted!" _
            , vbExclamation, "Folder not Found"
    End If
End Sub

Public Sub MoveFilesFolder2Folder()
    Dim fso
    Dim sfol As String, dfol As String
    sfol = "c:\MyFolder" ' change to match the source folder path
    dfol = "e:\MyFolder" ' change to match the destination folder path
    Set fso = CreateObject("Scripting.FileSystemObject")
On Error Resume Next
    If Not fso.FolderExists(sfol) Then
        MsgBox sfol & " is not a valid folder/path.", vbInformation, "Invalid Source"
    ElseIf Not fso.FolderExists(dfol) Then
        MsgBox dfol & " is not a valid folder/path.", vbInformation, "Invalid Destination"
    Else
        fso.MoveFile (sfol & "\*.*"), dfol ' Change "\*.*" to "\*.xls" to move Excel Files only
    End If
    If Err.Number = 53 Then MsgBox "File not found"
End Sub

Public Sub CopyFilesFolder2Folder()
    Dim fso
    Dim sfol As String, dfol As String
    sfol = "c:\MyFolder" ' change to match the source folder path
    dfol = "e:\MyFolder" ' change to match the destination folder path
    Set fso = CreateObject("Scripting.FileSystemObject")
On Error Resume Next
    If Not fso.FolderExists(sfol) Then
        MsgBox sfol & " is not a valid folder/path.", vbInformation, "Invalid Source"
    ElseIf Not fso.FolderExists(dfol) Then
        MsgBox dfol & " is not a valid folder/path.", vbInformation, "Invalid Destination"
    Else
        fso.CopyFile (sfol & "\*.*"), dfol ' Change "\*.*" to "\*.xls" to move Excel Files only
    End If
    If Err.Number = 53 Then MsgBox "File not found"
End Sub


