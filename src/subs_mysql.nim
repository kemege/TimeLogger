import math
import db_mysql
import mysql
import os
import re
import parsecfg
import strutils
import streams
from times import Time
import types

proc AppendRecord*(db: TDbConn, activity: Activity): int64=
  ## add the specified activity into database
  var
    title = activity.job.title
    path = activity.job.path
    id_program: int64
  
  title = replace(title, r"\", r"\\")
  path = replace(path, r"\", r"\\")

  try:
    # check for existing programs
    var str_program = getRow(db, sql"SELECT id FROM program WHERE path = ? LIMIT 1", path)[0]

    if str_program == "":
      # generate a new random color for this program
      randomize()
      var color = format("$1$2$3", toHex(random(256), 2), toHex(random(256), 2), toHex(random(256), 2))
      # add a new program into database
      id_program = insertId(db, sql"INSERT INTO program (path, color) VALUES (?, ?)", path, color)
    else:
      id_program = parseInt(str_program)

    # actually insert the activity
    result = insertId(db, 
        sql"INSERT INTO activity (title, program, begin, finish, idle, duration) VALUES (?, ?, ?, ?, ?, ?)",
        title, id_program, activity.begin.uint32, activity.finish.uint32, 
        activity.idle.uint8, activity.finish.int32 - activity.begin.int32
        )
  except EDb:
    result = -1

proc GetDbConfig*(): array[4, string]=
  ## read database configurations from CONFIG file
  var file = newFileStream(CONFIG, fmRead)
  if file != nil:
    var 
      p: CfgParser
      section = false
    open(p, file, CONFIG)
    while true:
      var e = next(p)
      case e.kind
      of cfgEof:
        break
      of cfgSectionStart:
        if e.section == "Database":
          section = true
        else:
          section = false
      of cfgKeyValuePair:
        if section:
          case e.key
          of "server":
            result[0] = e.value
          of "db":
            result[3] = e.value
          of "user":
            result[1] = e.value
          of "password":
            result[2] = e.value
          else:
            discard
      else:
        discard
    close(p)

proc OpenDbConnection*(): TDbConn=
  ## open a connection to mysql database, and change character set from latin1(default) to utf8
  var db = GetDbConfig()
  result = db_mysql.open(db[0], db[1], db[2], db[3])
  if mysql.set_character_set(result, "utf8") == 0:
    discard "set_character_set failed"

proc GetTagRules*(db: TDbConn): seq[TagRule]=
  ## Fetch all tag rules from database
  ##
  ## column: 0 for window title, 1 for executable path
  var tagrules = db.getAllRows(sql"SELECT `id_tag`, `column`, `keyword` FROM activity_tag_rule")
  result = newSeq[TagRule](tagrules.len)
  for i, row in tagrules:
    result[i] = TagRule(tag: parseInt(row[0]), column: parseInt(row[1]), reg: re(row[2]))

proc GetFittedTags*(activity: Activity, tagRules: seq[TagRule]): seq[int]=
  ## Find out which tag to apply by matching the window 
  ## title and executable of an activity
  result = @[]
  for rule in tagRules:
    if rule.column == 0:
      if activity.job.title.find(rule.reg) > -1:
        result.add(rule.tag)
    if rule.column == 1:
      if activity.job.path.find(rule.reg) > -1:
        result.add(rule.tag)

proc ApplyTag*(db: TDbConn, id_activity: int, ids_tag: seq[int]): bool=
  ## add tags into database
  for id_tag in ids_tag:
    db.exec(sql"INSERT INTO activity_tag (id_activity, id_tag) VALUES (?, ?)", id_activity, id_tag)

when isMainModule:
  echo("Getting database config....")
  var cfg = GetDbConfig()
  for i in 0..cfg.high:
    echo(cfg[i])

  echo("Testing connection....")
  var conn = OpenDbConnection()
  var query = sql"SELECT COUNT(*) FROM activity"
  var row = getRow(conn, query)
  echo($row)

  echo("Testing data insertion....")
  var act = Activity(job: Job(title: "te;\"'st", path: r"C:\nim\bin\nim.exe 中文"), begin: Time(0), finish: Time(1), idle: false)
  var res = AppendRecord(conn, act)
  echo("Insertion succeeded.")
  # exec(conn, sql"DELETE FROM activity WHERE id = ?", res)

  echo("Closing connection....")
  db_mysql.close(conn)
