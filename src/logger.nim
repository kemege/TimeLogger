import os
import times
import threadpool
import subs_windows
import subs_cache
import subs_cache_write
import subs_config
import types

proc ThreadSubmitData() {.gcsafe.}=
  while true:
    SubmitData()
    sleep(1000*900)

proc main()=
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

when isMainModule:
  main()