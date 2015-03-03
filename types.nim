import times

const CONFIG* = "timelogger.config"

type
  Job* = object
    title*: string
    path*: string

  Activity* = object
    job*: Job
    begin*: Time
    finish*: Time
    idle*: bool

proc `==` *(a, b: Job): bool=
  if a.title == b.title and a.path == b.path:
    return true
  else:
    return false