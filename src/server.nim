import json
import jsonrpc
import jester
import asyncdispatch
import strutils
import subs_mysql
import db_mysql
import openssl_evp

routes:
  get "/rpc":
    resp ($request.params)

  post "/rpc":
    var json = parseJson(request.body)
    var req = parseRequest(json)
    case req.Method:
    of "addActivity":
      discard
    of "addTag":
      discard
    of "queryTagList":
      ## returns full tag list and criteria
      var conn = OpenDbConnection()
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
      discard

runForever()