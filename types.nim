type
  Job* = object
    title*: string
    path*: string

  Activity* = object
    job*: Job
    begin: int
    finish: int