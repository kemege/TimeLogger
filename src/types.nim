import times
import re

const CONFIG* = "timelogger.config" ## Configuration file name

type
  Job* = object ## A job acquired from system
    title*: string
    path*: string

  Activity* = object ## An activity
    job*: Job
    begin*: Time
    finish*: Time
    idle*: bool

  TagRule* = object ## Rule about auto-tagging
    tag*: int
    reg*: Regex
    column*: int
    keyword*: string

proc `==` *(a, b: Job): bool=
  ## compare if two `Job` object are the same
  if a.title == b.title and a.path == b.path:
    return true
  else:
    return false