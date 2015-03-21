import parsecfg
import os
import strutils
import streams

proc getParameter*(filename, section, key: string): string {.raises: [Exception]}=
  var
    f = newFileStream(filename, fmRead)
    p: CfgParser
  if f == nil: raise newException(IOError, "Config file doesn't exist.")
  result = ""
  p.open(f, filename)
  var thisSection = false
  while true:
    var e = next(p)
    case e.kind
    of cfgEof:
      break
    of cfgSectionStart:
      if section == e.section:
        thisSection = true
      else:
        thisSection = false
    of cfgKeyValuePair:
      if thisSection and e.key == key:
        result = e.value
        break
    of cfgOption:
      discard
    of cfgError:
      echo("Config file error: " & e.msg)
  p.close