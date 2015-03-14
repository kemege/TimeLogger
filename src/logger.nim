import os
import times
import parsecfg
import subs_windows
import subs_cache
import types
import threadpool

proc ThreadSubmitData() {.gcsafe.}=
  while true:
    sleep(1000*900)
    SubmitData()

spawn ThreadSubmitData()

var
  currJob, lastJob: Job = getCurrentJob()
  currAct: Activity

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
        AddToCache(currAct)

      lastJob = currJob
      currAct.job.title = currJob.title
      currAct.job.path = currJob.path
      currAct.begin = getTime()
      currAct.finish = getTime()
      currAct.idle = false
    else:
      currAct.finish = getTime()

  sleep(500)