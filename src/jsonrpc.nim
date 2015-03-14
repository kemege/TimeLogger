import json
import uri
import httpclient

const VER = "2.0"

type
  Notification* {.inheritable.} = object
    Method*: string
    Params*: JsonNode

  Request* = object of Notification
    Id*: string

  Error* = object
    Code*: BiggestInt
    Message*: string
    Data*: JsonNode

  Response* = object
    err: bool
    Result*: JsonNode
    Error*: Error
    Id*: string


proc `%`(r: Request): JsonNode {.raises: [], tags: [].}=
  result = newJObject()
  result.add("id", %r.Id)
  result.add("method", %r.Method)
  result.add("params", r.Params)
  result.add("jsonrpc", %VER)

proc `%`(n: Notification): JsonNode {.raises: [], tags: [].}=
  result = newJObject()
  result.add("method", %n.Method)
  result.add("params", n.Params)
  result.add("jsonrpc", %VER)

proc `%`(r: Error): JsonNode {.raises: [], tags: [].}=
  result = newJObject()
  result.add("Code", %r.Code)
  result.add("Message", %r.Message)
  result.add("Data", r.Data)

proc `%`(r: Response): JsonNode {.raises: [], tags: [].}=
  result = newJObject()
  result.add("id", %r.Id)
  result.add("error", %r.Error)
  result.add("result", r.Result)
  result.add("jsonrpc", %VER)

proc beResponse(r: var Response)=
  r.err = false

proc beError(r: var Response)=
  r.err = true

proc isResponse*(r: Response): bool=
  result = r.err

proc `$`*(r: Request): string=
  var jsonBody = %r
  result = $jsonBody

proc `$`*(rs: seq[Request]): string=
  var jsonBody = newJArray()
  for req in rs:
    jsonBody.add(%req)
  result = $jsonBody

proc `$`*(r: Response): string=
  var jsonBody = %r
  result = $jsonBody

proc `$`*(rs: seq[Response]): string=
  var jsonBody = newJArray()
  for req in rs:
    jsonBody.add(%req)
  result = $jsonBody

proc SendRequest*(server: string, body: Request): Response=
  ## Send a request to server
  var resp = postContent(server, body= $body)
  var j = resp.parseJson

  # check if the response is valid JSON-RPC 2.0
  if not j.hasKey("jsonrpc") or j["jsonrpc"].kind != JString or j["jsonrpc"].str != VER or not j.hasKey("id") or not (j.hasKey("result") xor j.hasKey("error")):
    raise newException(ValueError, "Response is not valid JSON-RPC 2.0!")

  if j["id"].kind == JString:
    result.Id = j["id"].str
  elif j["id"].kind == JString:
    result.Id = $j["id"].num
  elif j["id"].kind == JNull:
    result.Id = nil
  else:
    raise newException(ValueError, "Invalid id, must be string or integer!")

  if j.hasKey("result"):
    # a response with no error
    result.Result = j["result"]
    result.beResponse
  elif j.hasKey("error"):
    # an error occured
    result.beError
    if not j["error"].hasKey("code") or not j["error"].hasKey("message") or j["error"]["code"].kind != JInt or j["error"]["message"].kind != JString:
      raise newException(ValueError, "Error in response is not valid!")
    result.Error.Code = j["error"]["code"].num
    result.Error.Message = j["error"]["message"].str
    if j["error"].hasKey("data"):
      result.Error.Data = j["error"]["data"]
    else:
      result.Error.Data = nil

proc SendRequest*(server: string, body: seq[Request]): seq[Response]=
  ## Send a request to server
  var resp = postContent(server, body= $body)
  var j = resp.parseJson
  if j.kind != JArray:
    raise newException(ValueError, "Response is not valid JSON-RPC 2.0 Batch!")

  result = newSeq[Response](j.len)
  for i in 0 .. <j.len:
    # check if the response is valid JSON-RPC 2.0
    if not j[i].hasKey("jsonrpc") or j[i]["jsonrpc"].kind != JString or j[i]["jsonrpc"].str != VER or not j[i].hasKey("id") or not (j[i].hasKey("result") xor j[i].hasKey("error")):
      raise newException(ValueError, "Part of response is not valid JSON-RPC 2.0!")

    if j[i]["id"].kind == JString:
      result[i].Id = j[i]["id"].str
    elif j[i]["id"].kind == JInt:
      result[i].Id = $j[i]["id"].num
    elif j[i]["id"].kind == JNull:
      result[i].Id = nil
    else:
      raise newException(ValueError, "Invalid id, must be string or integer!")

    if j[i].hasKey("result"):
      # a response with no error
      result[i].Result = j[i]["result"]
      result[i].beResponse
    if j[i].hasKey("error"):
      # an error occured
      result[i].beError
      if not j[i]["error"].hasKey("code") or not j[i]["error"].hasKey("message") or j[i]["error"]["code"].kind != JInt or j[i]["error"]["message"].kind != JString:
        raise newException(ValueError, "Error in response is not valid!")
      result[i].Error.Code = j[i]["error"]["code"].num
      result[i].Error.Message = j[i]["error"]["message"].str
      if j[i]["error"].hasKey("data"):
        result[i].Error.Data = j[i]["error"]["data"]
      else:
        result[i].Error.Data = nil

when isMainModule:
  var x = Request(Id: "1", Method: "test", Params: %"233")
  var y = %x
  echo($y)