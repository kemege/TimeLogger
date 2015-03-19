import json
import httpclient

const VER = "2.0"

type
  RpcRequest* {.inheritable.} = object
    Method*: string
    Params*: JsonNode
    Id*: string

  RpcError* = object
    Code*: BiggestInt
    Message*: string
    Data*: JsonNode

  RpcResponse* = object
    err: bool
    Result*: JsonNode
    RpcError*: RpcError
    Id*: string

  JsonRpcError* = object of ValueError



proc beResponse(r: var RpcResponse)=
  r.err = false

proc beError(r: var RpcResponse)=
  r.err = true

proc isResponse*(r: RpcResponse): bool=
  result = not r.err

proc `%`(r: RpcRequest): JsonNode {.raises: [], tags: [].}=
  result = newJObject()
  if r.Id != nil: result.add("id", %r.Id)
  result.add("method", %r.Method)
  result.add("params", r.Params)
  result.add("jsonrpc", %VER)

proc `%`(r: RpcError): JsonNode {.raises: [], tags: [].}=
  result = newJObject()
  result.add("Code", %r.Code)
  result.add("Message", %r.Message)
  result.add("Data", r.Data)

proc `%`(r: RpcResponse): JsonNode {.raises: [], tags: [].}=
  result = newJObject()
  result.add("id", %r.Id)
  if r.isResponse:
    result.add("result", r.Result)
  else:
    result.add("error", %r.RpcError)
  result.add("jsonrpc", %VER)

proc `$`*(r: RpcRequest): string=
  var jsonBody = %r
  result = $jsonBody

proc `$`*(rs: seq[RpcRequest]): string=
  var jsonBody = newJArray()
  for req in rs:
    jsonBody.add(%req)
  result = $jsonBody

proc `$`*(r: RpcResponse): string=
  var jsonBody = %r
  result = $jsonBody

proc `$`*(rs: seq[RpcResponse]): string=
  var jsonBody = newJArray()
  for req in rs:
    jsonBody.add(%req)
  result = $jsonBody

proc `$$`*(j: JsonNode): string=
  case j.kind:
  of JString: 
    result = j.str
  of JInt: 
    result = $j.num
  of JFloat: 
    result = $j.fnum
  of JBool: 
    result = $j.bval
  of JNull: 
    result = nil
  of JObject: 
    result = nil
  of JArray: 
    result = nil

proc notValidJson2(j: JsonNode): bool=
  result = not j.hasKey("jsonrpc") or j["jsonrpc"].kind != JString or j["jsonrpc"].str != VER or not j.hasKey("id") or not (j.hasKey("result") xor j.hasKey("error"))

proc SendRequest*(server: string, body: RpcRequest): RpcResponse=
  ## Send a request to server
  var resp = postContent(server, body= $body)
  var j = resp.parseJson

  # check if the response is valid JSON-RPC 2.0
  if notValidJson2(j):
    raise newException(JsonRpcError, "RpcResponse is not valid JSON-RPC 2.0!")

  if j["id"].kind == JString:
    result.Id = j["id"].str
  elif j["id"].kind == JString:
    result.Id = $j["id"].num
  elif j["id"].kind == JNull:
    result.Id = nil
  else:
    raise newException(JsonRpcError, "Invalid id, must be string or integer!")

  if j.hasKey("result"):
    # a response with no error
    result.Result = j["result"]
    result.beResponse
  elif j.hasKey("error"):
    # an error occured
    result.beError
    if not j["error"].hasKey("code") or not j["error"].hasKey("message") or j["error"]["code"].kind != JInt or j["error"]["message"].kind != JString:
      raise newException(JsonRpcError, "RpcError in response is not valid!")
    result.RpcError.Code = j["error"]["code"].num
    result.RpcError.Message = j["error"]["message"].str
    if j["error"].hasKey("data"):
      result.RpcError.Data = j["error"]["data"]
    else:
      result.RpcError.Data = nil

proc SendRequest*(server: string, body: seq[RpcRequest]): seq[RpcResponse]=
  ## Send a request to server
  var resp = postContent(server, body= $body)
  var j = resp.parseJson
  if j.kind != JArray:
    raise newException(JsonRpcError, "RpcResponse is not valid JSON-RPC 2.0 Batch!")

  result = newSeq[RpcResponse](j.len)
  for i in 0 .. <j.len:
    # check if the response is valid JSON-RPC 2.0
    if notValidJson2(j[i]):
      raise newException(JsonRpcError, "Part of response is not valid JSON-RPC 2.0!")

    if j[i]["id"].kind == JString:
      result[i].Id = j[i]["id"].str
    elif j[i]["id"].kind == JInt:
      result[i].Id = $j[i]["id"].num
    elif j[i]["id"].kind == JNull:
      result[i].Id = nil
    else:
      raise newException(JsonRpcError, "Invalid id, must be string or integer!")

    if j[i].hasKey("result"):
      # a response with no error
      result[i].Result = j[i]["result"]
      result[i].beResponse
    if j[i].hasKey("error"):
      # an error occured
      result[i].beError
      if not j[i]["error"].hasKey("code") or not j[i]["error"].hasKey("message") or j[i]["error"]["code"].kind != JInt or j[i]["error"]["message"].kind != JString:
        raise newException(JsonRpcError, "RpcError in response is not valid!")
      result[i].RpcError.Code = j[i]["error"]["code"].num
      result[i].RpcError.Message = j[i]["error"]["message"].str
      if j[i]["error"].hasKey("data"):
        result[i].RpcError.Data = j[i]["error"]["data"]
      else:
        result[i].RpcError.Data = nil

# proc parseResponse(json: JsonNode): RpcResponse=
#   if json.kind == JArray:
#     # result = newSeq[RpcResponse](json.len)
#     raise newException(JsonRpcError, "Batch responses are not supported yet.")
#   elif json.kind != JObject or notValidJson2(json):
#     raise newException(JsonRpcError, "Invalid JSON-RPC 2.0 Response!")

#   result.Id = $$json["id"]
#   result.Result = json["result"]

proc parseRequest*(json: JsonNode): RpcRequest=
  if json.kind == JArray:
    # result = newSeq[RpcResponse](json.len)
    raise newException(JsonRpcError, "Batch responses are not supported yet.")
  elif json.kind != JObject or notValidJson2(json):
    raise newException(JsonRpcError, "Invalid JSON-RPC 2.0 Response!")

  result.Id = $$json["id"]
  result.Method = json["method"].str
  result.Params = json["params"]

when isMainModule:
  var x = RpcRequest(Id: "1", Method: "test", Params: %"233")
  var y = %x
  echo($y)
  var x2 = RpcResponse(Id: "1", Result: %"test")
  echo(x2.isResponse)
  x2.beResponse
  y = %x2
  echo($y)