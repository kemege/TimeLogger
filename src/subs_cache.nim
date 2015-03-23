import json
import marshal
import db_mysql
import subs_mysql
import subs_remote
import subs_windows
import subs_config
import types
import times

const
  CACHE = "logger.cache"
  CACHE2 = "logger.cache.temp"

proc SubmitData*() {.gcsafe.}=
  ## Submit data in local cache to DB
  var db = getParameter(CONFIG, "logging", "db")
  case db:
  of "mysql":
    var exist = moveFile(CACHE, CACHE2)
    if not exist:
      # No cache at the moment => skip
      return
    var
      act: Activity
      tagRules: seq[TagRule]
      conn: TDbConn
    try:
      conn = subs_mysql.Init()
      tagRules = conn.GetTagRules()
      for line in lines(CACHE2):
        act = to[Activity](line)
        var res = subs_mysql.AppendRecord(conn, act)
        # deal with tags
        discard conn.ApplyTag(res, subs_mysql.GetFittedTags(act, tagRules))

      discard deleteFile(CACHE2)
    except EDb:
      discard moveFile(CACHE2, CACHE)
    except IOError:
      #logging missing log
      return
    finally:
      conn.close
  of "remote":
    var exist = moveFile(CACHE, CACHE2)
    if not exist:
      # No cache at the moment => skip
      return
    var
      actList = newSeq[Activity](0)
      tagRules: seq[TagRule]
      conn: string
    try:
      conn = subs_remote.Init()
      tagRules = conn.GetTagRules()
      for line in lines(CACHE2):
        actList.add(to[Activity](line))
      discard subs_remote.AppendRecords(conn, actList)
      # deal with tags
      # discard conn.ApplyTag(res, subs_remote.GetFittedTags(act, tagRules))

      discard deleteFile(CACHE2)
    except EDb:
      discard moveFile(CACHE2, CACHE & "." & $epochTime())
    except IOError:
      #logging missing log
      return
  else:
    discard