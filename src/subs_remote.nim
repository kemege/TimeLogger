import strutils
import sockets
import jsonrpc
import json
import subs_config
import types
import times
import subs_cache_write
import re

proc AppendRecord*(server: string, activity: Activity): int64 {.gcsafe.}=
  return 0

proc AppendRecords*(server: string, actList: seq[Activity]): int64 {.gcsafe.}=
  var
    request: RpcRequest
    jList = newJArray()
  for act in actList:
    var jAct = newJObject()
    jAct["path"] = %act.job.path
    jAct["title"] = %act.job.title
    jAct["begin"] = %act.begin.toSeconds.int
    jAct["finish"] = %act.finish.toSeconds.int
    jAct["idle"] = %act.idle
    jList.add(jAct)

  request.Method = "addActivity"
  request.Params = jList
  request.Id = ""
  var response = SendRequest(server, request)
  echo response
  if response.isError:
    if response.Error.Code == 1:
      var failAct: Activity
      for failJAct in response.Error.Data:
        failAct.job.path = failJAct["path"].str
        failAct.job.title = failJAct["title"].str
        failAct.begin = failJAct["begin"].num.fromSeconds
        failAct.finish = failJAct["finish"].num.fromSeconds
        failAct.idle = failJAct["idle"].bval
        failAct.AddToCache
    result = response.Error.Data.len
  else:
    result = 0

proc GetTagRules*(server: string): seq[TagRule] {.gcsafe.}=
  var
    request: RpcRequest

  request.Method = "queryTagList"
  request.Params = newJNull()
  request.Id = ""
  var response = SendRequest(server, request)
  echo response
  if response.isError:
    echo "Error: ", response.Error.Code
  else:
    if response.Result.kind != JArray:
      echo "Malformed response"
    result = newSeq[TagRule](response.Result.len)
    for i in 0 .. <response.Result.len:
      result[i].tag = response.Result[i]["id_tag"].num.int
      result[i].reg = re(response.Result[i]["keyword"].str)
      result[i].keyword = response.Result[i]["keyword"].str
      result[i].column = response.Result[i]["column"].num.int

proc GetFittedTags*(activity: Activity, tagRules: seq[TagRule]): seq[int] {.gcsafe.}=
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

proc ApplyTag*(server: string, id_activity: int64, ids_tag: seq[int]): bool {.gcsafe.}=
  discard

proc GetServer(): string {.gcsafe.}=
  result = getParameter(CONFIG, "remote", "address")

proc Init*(): string {.gcsafe.}=
  result = GetServer()