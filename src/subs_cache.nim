import json
import marshal
import db_mysql
import subs_mysql
import subs_windows
import types

const
  CACHE = "logger.cache"
  CACHE2 = "logger.cache.temp"

proc SubmitData*() {.gcsafe.}=
  ## Submit data in local cache to DB
  var exist = moveFile(CACHE, CACHE2)
  if not exist:
    # No cache at the moment => skip
    return
  var
    act: Activity
    conn: TDbConn
    tagRules: seq[TagRule]
  try:
    conn = OpenDbConnection()
    tagRules = conn.GetTagRules()
    for line in lines(CACHE2):
      act = to[Activity](line)
      var res = AppendRecord(conn, act)
      # deal with tags
      discard conn.ApplyTag(res, GetFittedTags(act, tagRules))

    discard deleteFile(CACHE2)
  except EDb:
    discard moveFile(CACHE2, CACHE)
  except IOError:
    #logging missing log
    return
  finally:
    conn.close

proc AddToCache*(act: Activity)=
  var f = open(CACHE, fmAppend)
  f.writeln($$act)
  f.close