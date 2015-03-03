import db_mysql
import mysql
import os
import parsecfg
import strutils
import streams
from times import Time
import types

proc AppendRecord(db: TDbConn, activity: Activity): int64=
  var
    title = activity.job.title
    path = activity.job.path
  
  title = replace(title, r"\", r"\\")
  path = replace(path, r"\", r"\\")

  result = insertId(db, sql"INSERT INTO activity (title, path, begin, finish, idle) VALUES (?, ?, ?, ?, ?)",
      title, path, activity.begin.uint32, activity.finish.uint32, activity.idle.uint8
      )

proc GetDbConfig(): array[4, string]=
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

proc OpenDbConnection(): TDbConn=
  var db = GetDbConfig()
  result = db_mysql.open(db[0], db[1], db[2], db[3])
  if mysql.set_character_set(result, "utf8") == 0:
    discard "set_character_set failed"

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
