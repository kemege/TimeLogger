import marshal
import types

const CACHE = "logger.cache"

proc AddToCache*(act: Activity)=
  var f = open(CACHE, fmAppend)
  f.writeln($$act)
  f.close