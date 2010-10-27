" soap
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc4743.txt

let s:save_cpo = &cpo
set cpo&vim

function! s:soap_call(url, func, ...)
  let envelope = xml#createElement("soap:Envelope")
  let envelope.attr["xmlns:soap"] = "http://schemas.xmlsoap.org/soap/envelope/"
  let envelope.attr["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"

  let body = xml#createElement("soap:Body")
  call add(envelope.child, body)
  let func = xml#createElement(a:func)
  call add(body.child, func)

  let n = 1
  for a in a:000
    let arg = xml#createElement("param".n)
    let arg.attr["xsi:type"] = "xsd:string"
    call arg.value(a)
    call add(func.child, arg)
    let n += 1
  endfor

  let str = '<?xml version="1.0" encoding="UTF-8"?>' . envelope.toString()
  let res = http#post(a:url, str)
  let dom = xml#parse(res.content)
  let ret = {}
  for item in dom.findAll("item")
    let ret[item.find("key").value()] = item.find("value").value()
  endfor
  return ret
endfunction

function! s:get_convert_code(arg)
  let code = ''
  let arg = a:arg
  if arg.type == "xsd:string"
    let code .= "let ".arg.name." = a:".arg.name
  elseif arg.type == "xsd:int"
    let code .= "let ".arg.name." = 0+a:".arg.name
  elseif arg.type == "xsd:boolean"
    let code .= "let ".arg.name." = (0+a:".arg.name.") ? 'true' : 'false'"
  elseif arg.type == "xsd:float"
    let code .= "let ".arg.name." = nr2float(0+a:".arg.name.")"
  elseif arg.type == "soap-enc:Array"
    let code .= "let ".arg.name." = a:".arg.name
  else
    echoerr "unknown type:". arg.type
  endif
  return code
endfunction

function! soap#proxy(url)
  let dom = xml#parseURL(a:url)
  let l:api = {}
  let action = dom.childNode("service").find("soap:address").attr["location"]
  let operations = dom.childNode("portType").childNodes("operation")
  for operation in operations
    let name = operation.attr["name"]
    let inp = substitute(operation.childNode("input").attr["message"], "^tns:", "", "")
    let out = substitute(operation.childNode("output").attr["message"], "^tns:", "", "")
    let message = dom.childNode("message", {"name": inp})
    let args = []
    for part in message.childNodes("part")
      call add(args, {"name": part.attr["name"], "type": part.attr["type"]})
    endfor
    let argnames = []
    let code = ""
    for arg in args
      call add(argnames, arg.name)
      let code .= "  ".s:get_convert_code(arg)."\n"
    endfor
    let code .= "  return s:soap_call(".string(action).", ".string(name).", ".join(argnames, ",").")\n"
    let source = "function! l:api.".name."(".join(argnames, ",").") dict\n"
    let source .= code
    let source .= "endfunction\n"
    exe source
  endfor
  return api
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
