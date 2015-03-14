## some Windows-specific procedures for collecting 
## activity information
import unicode
import windows
import logging
import os
import types

const BUFFER_LENGTH = 2048 ## max buffer length
type
  TLastInputInfo = object
    cbSize*: WINUINT
    dwTime*: DWORD

proc QueryFullProcessImageNameW(hProcess: HANDLE, dwFlags: DWORD, lpExeName: LPWSTR, lpdwSize: PDWORD): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "QueryFullProcessImageNameW".}
  ## QueryFullProcessImageNameW: 
  ## https://msdn.microsoft.com/en-us/library/windows/desktop/ms684919%28v=vs.85%29.aspx

proc GetLastInputInfo(plii: ptr TLastInputInfo): WINBOOL{.
    stdcall, dynlib: "user32", importc: "GetLastInputInfo".}
  ## GetLastInputInfo
  ## https://msdn.microsoft.com/en-us/library/windows/desktop/ms646302%28v=vs.85%29.aspx

proc GetTickCount64(): ULONGLONG{.
    stdcall, dynlib: "kernel32", importc: "GetTickCount64".}
  ## GetTickCount64
  ## https://msdn.microsoft.com/en-us/library/windows/desktop/ms724411%28v=vs.85%29.aspx

proc UTF16ToString(buffer: array[0..BUFFER_LENGTH, uint16], length: int): string=
  ## convert LPWSTR(uint16 array) to Nim string
  result = ""
  for i in 0..length:
    result.add(Rune(buffer[i]).toUTF8)

proc getCurrentJob*(): Job=
  ## grab the current active window's title and image file path 
  ## using the Windows API
  ## 
  ## requires Windows Vista or higher
  var
    title, path: array[0..BUFFER_LENGTH, uint16]
    pTitle, pPath: LPWSTR
    lTitle, lPath: int
    pid, dPathLength: DWORD
    ppid, pPathLength: ptr DWORD
    hProcess: HANDLE
    hWindow = GetForegroundWindow()

  if hWindow == 0:
    result.title = ""
    result.path = "Unknown"
  else:
    pTitle = addr(title[0])
    pPath = addr(path[0])
    result = Job()

    lTitle = GetWindowTextW(hWindow, pTitle, BUFFER_LENGTH)
    result.title = UTF16ToString(title, lTitle)

    ppid = addr(pid)
    pPathLength = addr(dPathLength)
    dPathLength = BUFFER_LENGTH
    discard GetWindowThreadProcessId(hWindow, ppid)

    if pid == 0:
      var e: ref OSError
      new(e)
      e.msg = "Failed to retrieve PID. ErrNo=" & $GetLastError()
      raise e
    hProcess = OpenProcess(SYNCHRONIZE or PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, WINBOOL(true), pid)

    var err = QueryFullProcessImageNameW(hProcess, DWORD(0), pPath, pPathLength)
    if err == 0:
      var e: ref OSError
      new(e)
      e.msg = "Failed to retrieve Process Image Name. ErrNo=" & $GetLastError()
      echo result.title
      echo pid
      raise e
    
    result.path = UTF16ToString(path, dPathLength)

proc isIdle*(time: int64): bool=
  ## judge is the mouse/keyboard has moved in the last `time` 
  ## milliseconds
  var
    lastinput = TLastInputInfo()
    pLastInput: ptr TLastInputInfo

  lastInput.cbSize = WINUINT(sizeof(lastinput))
  pLastInput = addr(lastInput)
  discard GetLastInputInfo(plastInput)

  result = (GetTickCount64() - lastInput.dwTime) > time

proc moveFile*(oldName, newName: string): bool=
  ## move file 
  var
    lpExistingFileName = newWideCString(oldName)
    lpNewFileName = newWideCString(newName)
  var r = MoveFileW(cast[LPWSTR](lpExistingFileName[0].addr), cast[LPWSTR](lpNewFileName[0].addr))
  result = r.bool

proc deleteFile*(fileName: string): bool=
  ## move file 
  var
    lpFileName = newWideCString(fileName)
  var r = DeleteFileW(cast[LPWSTR](lpFileName[0].addr))
  result = r.bool

when isMainModule:
  var j: Job
  for i in 0..100:
    j = getCurrentJob()
    echo j.title
    echo j.path
    echo isIdle(3000).repr
    sleep(1500)
