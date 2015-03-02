import unicode
import windows
import logging
import os
import types

const BUFFER_LENGTH = 2048
type
  TLastInputInfo = object
    cbSize*: WINUINT
    dwTime*: DWORD

proc QueryFullProcessImageNameW(hProcess: HANDLE, dwFlags: DWORD, lpExeName: LPWSTR, lpdwSize: PDWORD): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "QueryFullProcessImageNameW".}

proc GetLastInputInfo(plii: ptr TLastInputInfo): WINBOOL{.
    stdcall, dynlib: "user32", importc: "GetLastInputInfo".}

proc GetTickCount64(): ULONGLONG{.
    stdcall, dynlib: "kernel32", importc: "GetTickCount64".}

proc UTF16ToString(buffer: array[0..BUFFER_LENGTH, uint16], length: int): string=
  result = ""
  for i in 0..length:
    result.add(Rune(buffer[i]).toUTF8)

proc getCurrentJob(): Job=
  var
    title, path: array[0..BUFFER_LENGTH, uint16]
    pTitle, pPath: LPWSTR
    lTitle, lPath: int
    pid, dPathLength: DWORD
    ppid, pPathLength: ptr DWORD
    hProcess: HANDLE

  pTitle = addr(title[0])
  pPath = addr(path[0])
  result = Job()

  lTitle = GetWindowTextW(GetForegroundWindow(), pTitle, BUFFER_LENGTH)
  result.title = UTF16ToString(title, lTitle)

  ppid = addr(pid)
  pPathLength = addr(dPathLength)
  dPathLength = BUFFER_LENGTH
  discard GetWindowThreadProcessId(GetForegroundWindow(), ppid)
  hProcess = OpenProcess(SYNCHRONIZE or PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, WINBOOL(true), pid)

  var err = QueryFullProcessImageNameW(hProcess, DWORD(0), pPath, pPathLength)
  if err == 0:
    var e: ref OSError
    new(e)
    e.msg = "Failed to retrieve Process Image Name. ErrNo=" & $GetLastError()
    raise e
  
  result.path = UTF16ToString(path, dPathLength)

proc isIdle(): bool=
  var
    lastinput = TLastInputInfo()
    pLastInput: ptr TLastInputInfo

  lastInput.cbSize = WINUINT(sizeof(lastinput))
  pLastInput = addr(lastInput)
  discard GetLastInputInfo(plastInput)

  result = (GetTickCount64() - lastInput.dwTime) > 500

when isMainModule:
  var j: Job
  for i in 0..100:
    j = getCurrentJob()
    echo j.title
    echo j.path
    echo isIdle().repr
    sleep(1500)
