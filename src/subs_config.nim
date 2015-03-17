import parsecfg
import os
import strutils
import streams

proc getParameter(filename, section, key: string): string {.raises: [IOError]}=
  var
    f = newFileStream(filename, fmRead)
    p: CfgParser
  if f == nil: raise newException[IOError]("Config file doesn't exist.")
  p.open(f, filename)
  while true:
    var
      e = next(p)
      thisSection = false
    case e.kind
    of cfgEof:
      break
    of cfgSectionStart:
      if section == e.section:
        thisSection = true
    of cfgKeyValuePair:
      if e.key == key:
        result = e.value
        break
    of cfgOption:
      discard
    of cfgError:
      echo("Config file error: " & e.msg)
  p.close