import json
import jsonrpc
import jester
import asyncdispatch
import strutils
import subs_mysql
import db_mysql
import openssl_evp
import types
import times

routes:
  get "/rpc":
    resp ($request.params)

  post "/rpc":
    var json = parseJson(request.body)
    var req = parseRequest(json)
    case req.Method:
    of "addActivity":
      # add activities into Database
      if req.Params.kind != JArray:
        resp "Invalid activity list"
        break
      var
        conn = Init()
        activity = Activity()
        failure = newJArray()
      for act in req.Params.elems:
        if act["title"] != nil and act["path"] != nil and act["begin"] != nil and act["finish"] != nil and act["idle"] != nil:
          activity.job.path = $$act["path"]
          activity.job.title = $$act["title"]
          activity.begin = act["begin"].num.fromSeconds
          activity.finish = act["finish"].num.fromSeconds
          activity.idle = act["idle"].bval

          if conn.AppendRecord(activity) == -1:
            failure.add(act)
        else:
          failure.add(act)

      var res: RpcResponse
      if failure.len == 0:
        # no errors occured
        res.Id = ""
        res.Result = %true
      else:
        var err: RpcError
        err.Code = 1
        err.Message = "failed to add some activities"
        err.Data = failure
        res.Id = ""
        res.isError = true
        res.Error = err
      resp ($res)

    of "addTag":

      discard
    of "queryTagList":
      # returns full tag list and criteria
      var conn = Init()
      var tagrules = conn.GetTagRules()
      conn.close()
      var rulelist = newJArray()
      for i in 0 .. <tagrules.len:
        var rule = newJObject()
        rule["id_tag"] = %tagrules[i].tag
        rule["keyword"] = %tagrules[i].keyword
        rule["column"] = %tagrules[i].column
        rulelist.add(rule)

      var res: RpcResponse
      res.Id = ""
      res.Result = rulelist

      resp ($res)
    of "applyTag":

      discard
    else:

      resp "Unknown action"

runForever()