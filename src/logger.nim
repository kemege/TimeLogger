import os
import times
import parsecfg
import subs_mysql
import subs_windows
import types

var
  currJob, lastJob: Job = getCurrentJob()
  currAct: Activity
  conn = OpenDbConnection()

currAct.job.title = currJob.title
currAct.job.path = currJob.path
currAct.begin = getTime()
currAct.finish = getTime()
currAct.idle = false

conn = OpenDbConnection()
while true:
  currJob = getCurrentJob()
  if isIdle(1000*60*15):
    currAct.idle = true
  else:
    if not (currJob == lastJob):
      if currAct.finish - currAct.begin > 0:
        if AppendRecord(conn, currAct) == -1:
          conn = OpenDbConnection()
          discard AppendRecord(conn, currAct)
      lastJob = currJob
      currAct.job.title = currJob.title
      currAct.job.path = currJob.path
      currAct.begin = getTime()
      currAct.finish = getTime()
      currAct.idle = false
    else:
      currAct.finish = getTime()

  sleep(500)