Option Explicit

Dim  objFSO, iFileName, oFilePath, TimeStampFilePath, IdlFilePath,        _
     Default1, Find1, Find2, ReplaceWith1, ReplaceWith2, ERGOPLANROOT,    _
     MyFileStream, ThisFileText, CaaFileExist, arrIDLFile, arrStoredFile,     _
     newDateAndTime, IsFileExist, FileSize, NewTimeStampFilePath, FileProcess

Default1 = "// COPYRIGHT DASSAULT SYSTEMES 2000 / DELMIA CORP 2003 " & chr(10) & _
           "/** "                                                    & chr(10) & _
           " *  @CAA2Level L1 "                                      & chr(10) & _
           " *  @CAA2Usage U4 "                                      & chr(10) & _
           " */ "

'Set Command Line Arguments
Find1 = WScript.Arguments(0)
Find2 = WScript.Arguments(1)
ReplaceWith1 = WScript.Arguments(2)
ReplaceWith2 = WScript.Arguments(3)

CaaFileExist = 0
IsFileExist  = 0
FileSize     = 0
FileProcess  = 0

Dim wsh, env
Set wsh = WScript.CreateObject("WScript.Shell")
Set env = wsh.Environment
'Environment Variable :: OUTPUT_DIRPATH
env = wsh.ExpandEnvironmentStrings("%OUTPUT_DIRPATH%")
oFilePath = env + "\"

'Environment Variable :: ERGO_ROOT
env = wsh.ExpandEnvironmentStrings("%ERGO_ROOT%")
TimeStampFilePath = env + "\IDL_Documetation\PublicInterfaces\CAATimeStamp.txt"
NewTimeStampFilePath = env + "\IDL_Documetation\PublicInterfaces\NewCAATimeStamp.txt"
IdlFilePath = env + "\IDL_Documetation\CAAIdlFileList.txt"

'Environment Variable :: ERGOPLAN_ROOT
env = wsh.ExpandEnvironmentStrings("%ERGOPLAN_ROOT%")
ERGOPLANROOT = env
'IdlFilePath = env + "\CAAIdlFileList.txt"

'Create File System Object
Set objFSO = CreateObject("Scripting.FileSystemObject")
CaaFileExist = objFSO.FileExists(TimeStampFilePath)

'Read CAAIdlFileList.txt
IsFileExistAndSize IdlFilePath, IsFileExist, FileSize
If IsFileExist <> 0 And FileSize <> 0 Then
  Set MyFileStream = objFSO.OpenTextFile(IdlFilePath, 1, False)
  ThisFileText = MyFileStream.ReadAll()
  MyFileStream.Close
  arrIDLFile = Split(ThisFileText, vbCrLf)
  IsFileExist = 0
  FileSize = 0
Else
  MsgBox "VBScript QUIT :: File " + IdlFilePath + " Is Not Exist Or File Is Empty."
  WScript.Quit(1)
End If

'Read CAATimeStamp.txt; if exist
IsFileExistAndSize TimeStampFilePath, IsFileExist, FileSize
If IsFileExist <> 0 Then
  If FileSize = 0 Then
    MsgBox "VBScript QUIT :: File " + TimeStampFilePath + " Is Empty."
    WScript.Quit(1)
  End If

  Set MyFileStream = objFSO.OpenTextFile(TimeStampFilePath, 1, False)
  ThisFileText = MyFileStream.ReadAll()
  MyFileStream.Close
  arrStoredFile = Split(ThisFileText, vbCrLf)

  If objFSO.FileExists(NewTimeStampFilePath) Then
    objFSO.DeleteFile NewTimeStampFilePath, True
  End If

  objFSO.MoveFile TimeStampFilePath, NewTimeStampFilePath
  IsFileExist = 0
  FileSize = 0
Else
  CaaFileExist = 0
  CreateTimeStampFile
End If

'Check The Time-Stamp Of Files And Replace The Square Brackets
'On The Last Modified File
ProcessLastModFile

Private Function ProcessLastModFile

  Dim ss, aa, currFilePath, currFileName, storedFileName, _
      FileFound, FileInfo, arrStoredFileInfo, getFileExt, _
      sDateOrTime, cDateOrTime, DateOrTime, strFileInfo
  
  For ss = 0 To UBound(arrIDLFile)
   currFilePath = arrIDLFile(ss)
   currFilePath = RTrim(currFilePath)
   currFilePath = LTrim(currFilePath)
   If currFilePath <> "" Then  
    FileProcess = 1        
    currFileName = objFSO.GetFileName(currFilePath)
    currFilePath = ERGOPLANROOT + "\" + currFilePath
         
    IsFileExistAndSize currFilePath, IsFileExist, FileSize
    If IsFileExist <> 0 And FileSize <> 0 Then
     getFileExt = objFSO.GetExtensionName(currFileName)
     If getFileExt = "idl" Then
      'currFilePath = ERGOPLANROOT + "\" + currFilePath    
      If CaaFileExist = 0 Then 'When First Time File CAATimeStamp.txt Is Created
       ReplaceBrackets(currFilePath)
       IsFileExist = 0
       FileSize = 0
      Else
       FileFound = 0
       For aa = 0 To UBound(arrStoredFile)
        strFileInfo = arrStoredFile(aa)
        If strFileInfo <> "" Then
         arrStoredFileInfo = Split(strFileInfo)
         FileInfo = arrStoredFileInfo(0)              '0 is file path
         storedFileName = objFSO.GetFileName(FileInfo)
         getFileExt = objFSO.GetExtensionName(storedFileName)
         If getFileExt = "idl" Then                   
          If currFileName = storedFileName Then
           'get the information about current file
           GetDateOrTime currFilePath, cDateOrTime
           sDateOrTime = arrStoredFileInfo(1)
                     
           If sDateOrTime <> cDateOrTime Then
            ReplaceBrackets(currFilePath)
            'New Date and Time if different
           End If
           CreateNewTimeStampFile currFilePath, cDateOrTime                     
           FileFound = 1
           Exit For
          End If
         End If
        End If
       Next
       'if file is not found
       If FileFound = 0 Then
        ReplaceBrackets(currFilePath)
        GetDateOrTime currFilePath, cDateOrTime
        'New file add Date and Time
        CreateNewTimeStampFile currFilePath, cDateOrTime
       End If 
      End If
     End If
    End If
   End If
  Next
  
End Function

If FileProcess = 0 Then
  IsFileExistAndSize NewTimeStampFilePath, IsFileExist, FileSize
  If IsFileExist <> 0 And FileSize <> 0 Then
    objFSO.MoveFile NewTimeStampFilePath, TimeStampFilePath
    MsgBox "VBScript QUIT :: File " + IdlFilePath + " Is Empty."
    WScript.Quit(1)
  End If
End If

If CaaFileExist <> 0 Then
  CreateNewTimeStampFile "", ""
End If

'set the property of the file CAATimeStamp.txt as read only
If objFSO.FileExists(TimeStampFilePath) Then
  Set iFileName = objFSO.GetFile(TimeStampFilePath)
  iFileName.Attributes = iFileName.Attributes + 1
End If

'delete caatimestampnew.txt
If objFSO.FileExists(NewTimeStampFilePath) Then
  objFSO.DeleteFile NewTimeStampFilePath, True
End If

Set objFSO = nothing

'Create New Time-Stamp File
Private Function CreateNewTimeStampFile(iFileName, newDateAndTime)

Dim ss, OutStream, spacestr, strFileInfo, FileInfo,_
    arrStoredFileInfo, strFileName, IsStrThere, size

IsStrThere = 0
spacestr = Space(1)

  Set OutStream = objFSO.OpenTextFile(TimeStampFilePath, 8, True)
  If iFileName <> "" And newDateAndTime <> "" Then
    OutStream.Write  iFileName
    OutStream.Write  spacestr
    OutStream.Write  newDateAndTime
    OutStream.WriteBlankLines(1)
  Else
    IsFileExistAndSize TimeStampFilePath, IsFileExist, FileSize
    If IsFileExist <> 0 And FileSize <> 0 Then
      Set MyFileStream = objFSO.OpenTextFile(TimeStampFilePath, 1, False)
      ThisFileText = MyFileStream.ReadAll()
      MyFileStream.Close
      IsFileExist = 0
      FileSize = 0
    End If

    For ss = 0 To UBound(arrStoredFile)
      strFileInfo = arrStoredFile(ss)
      If strFileInfo <> "" Then 
        arrStoredFileInfo = Split(strFileInfo)
        strFileName = arrStoredFileInfo(0)              '0 is file path
        strFileName = objFSO.GetFileName(strFileName)
        
        'search for the string(file name) in newly created CAATimeStamp.txt
        IsStrThere = InStr(ThisFileText, strFileName)
        If IsStrThere = 0 Then
          OutStream.Write  strFileInfo
          OutStream.WriteBlankLines(1)
        End If      
      End If
    Next
  End If

  OutStream.Close

End Function 

'Create the Time-Stamp File
Private Function CreateTimeStampFile

  Dim ss, spacestr, OutStream, DateAndTime, extantion, iIdlFilePath
  Set OutStream = objFSO.OpenTextFile(TimeStampFilePath, 2, True)
  spacestr = Space(1)

  For ss = 0 To UBound(arrIDLFile)
    iIdlFilePath = arrIDLFile(ss)
    If iIdlFilePath <> "" Then
      iIdlFilePath = RTrim(iIdlFilePath)
      iIdlFilePath = LTrim(iIdlFilePath)
      iIdlFilePath = ERGOPLANROOT + "\" + iIdlFilePath
      extantion = objFSO.GetExtensionName(iIdlFilePath)
      If extantion = "idl" Then
        OutStream.Write iIdlFilePath
        OutStream.Write  spacestr
        GetDateOrTime iIdlFilePath, DateAndTime
        OutStream.Write  DateAndTime
        OutStream.WriteBlankLines(1)
      End If
    End If
  Next

  OutStream.Close

End Function 

'Replacing the brackets
Private Function ReplaceBrackets(iFileName)

  If iFileName <> "" Then
    Dim FileStream, FileContents, dFileContents
      On Error Resume Next
      
      IsFileExistAndSize iFileName, IsFileExist, FileSize
      If IsFileExist <> 0 And FileSize <> 0 Then
        Set FileStream = objFSO.OpenTextFile(iFileName, 1, False)
        FileContents = FileStream.ReadAll()
        FileStream.Close
        IsFileExist = 0
        FileSize = 0
        
        'replace all string In the source file
        dFileContents = Replace(FileContents, Find1, ReplaceWith1, 1, -1, 1)
        dFileContents = Replace(dFileContents, Find2, ReplaceWith2, 1, -1, 1)
        
        If dFileContents <> FileContents Then
          'write result If different
          WriteFile iFileName, dFileContents
        End If
      End If
  End If

End Function

'Write string As a text file.
Private Function WriteFile(iFileName, Contents)
  Dim OutStream, cFileName, oFilePathNew

  On Error Resume Next
    cFileName = objFSO.GetFileName(iFileName)
    IF cFileName <> "configfactory.idl" Then
      oFilePathNew = oFilePath + cFileName
      Set OutStream = objFSO.OpenTextFile(oFilePathNew, 2, True)
      OutStream.Write  Default1
      OutStream.WriteBlankLines(2)
      OutStream.Write  Contents
    End IF

    OutStream.Close

End Function

'get current Date and Time
Private Function GetDateOrTime(currFilePath, cDateOrTime)
  If currFilePath <> "" Then
    Dim FileInfo, DateOrTime
    IsFileExistAndSize currFilePath, IsFileExist, FileSize
    If IsFileExist <> 0 And FileSize <> 0 Then
      Set FileInfo = objFSO.GetFile(currFilePath)             
      DateOrTime = FormatDateTime(FileInfo.DateLastModified, vbShortDate) 'Date
      cDateOrTime = DateOrTime
      DateOrTime = FormatDateTime(FileInfo.DateLastModified, vbShortTime) 'Time
      cDateOrTime = cDateOrTime + "|" + DateOrTime
      IsFileExist = 0
      FileSize = 0
    End If
  End If

End Function

'get existance of file and size
Private Function IsFileExistAndSize(iFileName, IsFileExist, FileSize)
  Dim FileInfo
  If iFileName <> "" Then
    IsFileExist = objFSO.FileExists(iFileName)
      If IsFileExist <> 0 Then
      Set FileInfo = objFSO.GetFile(iFileName)
      FileSize = FileInfo.Size
    End If
  End If
End Function
