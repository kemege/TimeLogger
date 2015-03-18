import sqlite3
import parseopt2
import strutils
import times
import os

proc writeHelp()=
  echo("SQL2SQLite <SQL Filename>")

proc writeVersion()=
  echo("SQL2SQLite 0.0.1")

var
  filename = ""
  time1, time2: float

time1 = epochTime()

for kind, key, val in getopt():
  case kind
  of cmdArgument:
    filename = key
  of cmdLongOption, cmdShortOption:
    case key
    of "help", "h": writeHelp()
    of "version", "v": writeVersion()
    else: discard
  else:
    discard

block main:
  if filename.len == 0:
    # no filename has been given, so we show the help:
    writeHelp()
    break
  else:
    var
      conn: PSqlite3
      query: string = ""
      errmsg: cstring
      flag: int32

    var sqliteName = filename & ".db3"

    discard open(sqliteName, conn)

    discard conn.exec("BEGIN TRANSACTION".cstring, nil, nil, errmsg)

    for fp in walkFiles(filename & "_*.sql"):
      echo("Working with " & fp)
      for line in lines(fp):
        # iterate over the file
        if line[0..1] == "--" or line.len == 0:
          continue
        query &= line

        if line[line.len-1] == ';':
          # conn.exec(sql(query))
          if query[0..5] == "CREATE" or query[0..5] == "INSERT":
            flag = conn.exec(query.cstring, nil, nil, errmsg)
            if flag != 0:
              echo(query)
          query = ""

    discard conn.exec("END TRANSACTION".cstring, nil, nil, errmsg)
    discard conn.close()

time2 = epochTime() - time1
echo("Program finished in $1 seconds." % $time2)