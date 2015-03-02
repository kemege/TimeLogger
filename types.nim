import times

type
  Job* = object
    title*: string
    path*: string

  Activity* = object
    job*: Job
    begin: Time
    finish: Time

proc `==` *(a, b: Job): bool=
  if a.title == b.title and a.path == b.path:
    return true
  else:
    return false