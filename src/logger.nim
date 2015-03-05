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
  tagRules = conn.GetTagRules()

currAct.job.title = currJob.title
currAct.job.path = currJob.path
currAct.begin = getTime()
currAct.finish = getTime()
currAct.idle = false

while true:
  currJob = getCurrentJob()
  if isIdle(1000*60*15):
    currAct.idle = true
    currAct.job.title = "Idle"
    currAct.job.path = "Idle"
  else:
    if not (currJob == lastJob):
      if currAct.finish - currAct.begin > 0:
        var res = AppendRecord(conn, currAct)
        if res == -1:
          conn = OpenDbConnection()
          res = AppendRecord(conn, currAct)
        # deal with tags
        discard conn.ApplyTag(res, GetFittedTags(currAct, tagRules))

      lastJob = currJob
      currAct.job.title = currJob.title
      currAct.job.path = currJob.path
      currAct.begin = getTime()
      currAct.finish = getTime()
      currAct.idle = false
    else:
      currAct.finish = getTime()

  sleep(500)