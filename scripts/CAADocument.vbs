Option Explicit

Dim  MyFileStream, objFSO, ThisFileText, arrThisFile,   _
     iFileName, oFilePath, oTimeStampFile, IdlFileList, _
     Find1, Find2, ReplaceWith1, ReplaceWith2,          _
     ERGOPLANROOT, filebool

Dim Default1
Default1 = "// COPYRIGHT DASSAULT SYSTEMES 2000 / DELMIA CORP 2003 " & chr(10) & _
           "/** " & chr(10) & _
           " *  @CAA2Level L1 " & chr(10) & _
           " *  @CAA2Usage U4 " & chr(10) & _
           " */ "

'Set Command Line Arguments
Find1 = WScript.Arguments(0)
Find2 = WScript.Arguments(1)
ReplaceWith1 = WScript.Arguments(2)
ReplaceWith2 = WScript.Arguments(3)

Dim wsh, env
Set wsh = WScript.CreateObject("WScript.Shell")
Set env = wsh.Environment
'Environment Variable :: OUTPUT_DIRPATH
env = wsh.ExpandEnvironmentStrings("%OUTPUT_DIRPATH%")
oFilePath = env + "\"

'Environment Variable :: ERGO_ROOT
env = wsh.ExpandEnvironmentStrings("%ERGO_ROOT%")
oTimeStampFile = env + "\caatimestamp.txt"

'Environment Variable :: ERGOPLAN_ROOT
env = wsh.ExpandEnvironmentStrings("%ERGOPLAN_ROOT%")
ERGOPLANROOT = env
IdlFileList = env + "\CAAIdlFile.txt"

'Create File System Object
Set objFSO = CreateObject("Scripting.FileSystemObject")
filebool = objFSO.FileExists(oTimeStampFile)
'MsgBox filebool

'Create Time-Stamp File
If filebool = 0 Then
  CreateTimeStampFile
End If 

'Check The Time-Stamp Of Files And Replace The Square Brackets
Set MyFileStream = objFSO.OpenTextFile(oTimeStampFile, 1, False)

ThisFileText = MyFileStream.ReadAll()
MyFileStream.Close

arrThisFile = Split(ThisFileText, vbCrLf)

Dim  ss,iFileInfo, arrStoredFileInfo, arrCurrFileInfo, currDate, storeDate, _
     currTime, storeTime, currFileToProc, currDateAndTime, iStoredFileName, IsDateSame

For ss = 0 To UBound(arrThisFile) - 1
    iFileName = arrThisFile(ss)
    arrStoredFileInfo = Split(iFileName)

    '0 Is File Name
    iStoredFileName = arrStoredFileInfo(0)
    Set currFileToProc = objFSO.GetFile(iStoredFileName)
    currDateAndTime = currFileToProc.DateLastModified
    arrCurrFileInfo = Split(currDateAndTime)

    If filebool = 0 Then 'When First Time File caatimestamp.txt Is Created
        ReplaceBrackets(iStoredFileName)
    Else
        'File Date
        storeDate = arrStoredFileInfo(1)
        currDate = arrCurrFileInfo(0)
        If storeDate <> currDate Then
          ReplaceBrackets(iStoredFileName)
          IsDateSame = 0
        Else
          IsDateSame = 1
        End If
        
        'If Date is same then only check for the time
        If IsDateSame = 1 Then
          'File Time
          Dim formatStorTime, formatCurrTime
          storeTime = arrStoredFileInfo(2)
          currTime = arrCurrFileInfo(1)
          storeTime = storeTime + " " + arrStoredFileInfo(3)
          currTime = currTime + " " + arrCurrFileInfo(2)
        
          'Convert Time Into 24 Hrs Basis
          storeTime = FormatDateTime(storeTime, 4)
          currTime = FormatDateTime(currTime, 4)
          
          If storeTime <> currTime Then
             ReplaceBrackets(iStoredFileName)
          End If

        End If

    End If

Next


CreateTimeStampFile
Set objFSO = nothing


'Create the Time-Stamp File
Private Function CreateTimeStampFile

  Dim ss, spacestr, OutStream, DateAndTime, filetoprocess,_
      Folder, fileName, extantion, filePath, ReadIdlFileList, _
      IdlFileText, arrIdlFileList, iIdlFilePath

  Set ReadIdlFileList = objFSO.OpenTextFile(IdlFileList, 1, False)
  Set OutStream = objFSO.OpenTextFile(oTimeStampFile, 2, True)
  spacestr = Space(1)

  IdlFileText =  ReadIdlFileList.ReadAll()
  ReadIdlFileList.Close

  arrIdlFileList = Split( IdlFileText, vbCrLf)

  For ss = 0 To UBound(arrIdlFileList)
    iIdlFilePath = arrIdlFileList(ss)
    If iIdlFilePath <> "" Then
      iIdlFilePath = ERGOPLANROOT + "\" + iIdlFilePath

      'IsFileExist = objFSO.FileExists(iIdlFilePath)
      extantion = objFSO.GetExtensionName(iIdlFilePath)
      If extantion = "idl" Then
        OutStream.Write iIdlFilePath
        OutStream.Write  spacestr
        Set filetoprocess = objFSO.GetFile(iIdlFilePath)
        DateAndTime = filetoprocess.DateLastModified
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
  'MsgBox iFileName
    Dim FileStream, FileContents, dFileContents
      On Error Resume Next
      Set FileStream = objFSO.OpenTextFile(iFileName)
      FileContents = FileStream.ReadAll()
      FileStream.Close

      'replace all string In the source file
      dFileContents = Replace(FileContents, Find1, ReplaceWith1, 1, -1, 1)
      dFileContents = Replace(dFileContents, Find2, ReplaceWith2, 1, -1, 1)

      If dFileContents <> FileContents Then
        'write result If different
        WriteFile iFileName, dFileContents
        
        'Calculate The Total Replacements
        'Dim aa
        'aa = aa + ((Len(dFileContents) - Len(FileContents)) / (Len(ReplaceWith1) - Len(Find1)))
        'MsgBox "Total Replacements Are"
        'MsgBox aa + aa
      End If
  End If

End Function

'Write string As a text file.
Private Function WriteFile(iFileName, Contents)
  Dim OutStream, cFileName, oFilePathNew

  On Error Resume Next
    cFileName = objFSO.GetFileName(iFileName)
    IF cFileName <> "configfactory.idl" Then
      'MsgBox cFileName
      oFilePathNew = oFilePath + cFileName
      Set OutStream = objFSO.OpenTextFile(oFilePathNew, 2, True)
      OutStream.Write  Default1
      OutStream.WriteBlankLines(2)

      OutStream.Write  Contents
    End IF

    OutStream.Close

End Function
