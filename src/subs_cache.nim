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
  var
    conn = OpenDbConnection()
    tagRules = conn.GetTagRules()

  discard moveFile(CACHE, CACHE2)
  var act: Activity

  for line in lines(CACHE2):
    act = to[Activity](line)
    var res = AppendRecord(conn, act)
    # deal with tags
    discard conn.ApplyTag(res, GetFittedTags(act, tagRules))

  discard deleteFile(CACHE2)
  conn.close

proc AddToCache*(act: Activity)=
  var f = open(CACHE, fmAppend)
  f.writeln($$act)
  f.close