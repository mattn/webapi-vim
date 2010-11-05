" xmlrpc
" Last Change: 2010-11-05
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc3529.txt

let s:save_cpo = &cpo
set cpo&vim

function! s:from_value(value)
  let value = a:value
  if value.name == 'methodResponse'
    let param = value.childNode('params').childNodes('param')
    if len(param) == 1
      return s:from_value(param[0].childNode('value').childNode())
    else
      let ret = []
      for v in param
        call add(ret, s:from_value(v.childNode('value').childNode()))
      endfor
      return ret
    endif
  elseif value.name == 'string'
    return value.value()
  elseif value.name == 'int'
    return 0+substitute(value.value(), "[ \n\r]", '', 'g')
  elseif value.name == 'double'
    return str2float(substitute(value.value(), "[ \n\r]", '', 'g'))
  elseif value.name == 'struct'
    let ret = {}
    for member in value.childNodes('member')
      let ret[member.childNode('name').value()] = s:from_value(member.childNode('value').childNode())
    endfor
    return ret
  elseif value.name == 'array'
    let ret = []
    for v in value.childNode('data').childNodes('value')
      call add(ret, s:from_value(v.childNode()))
    endfor
    return ret
  elseif value.name == 'nil'
    return 0
  else
    throw "unknown type: ".value.name
  endif
endfunction

function! s:to_value(content)
  if type(a:content) == 4
    let struct = xml#createElement("struct")
    for key in keys(a:content)
      let member = xml#createElement("member")
      let name = xml#createElement("name")
      call name.value(key)
      call add(member.child, name)
      let value = xml#createElement("value")
      call add(value.child, s:to_value(a:content[key]))
      call add(member.child, value)
      call add(struct.child, member)
    endfor
    return struct
  elseif type(a:content) == 3
    let array = xml#createElement("array")
    let data = xml#createElement("data")
    for item in a:content
      let value = xml#createElement("value")
      call add(value.child, s:to_value(item))
      call add(data.child, value)
    endfor
    call add(array.child, data)
    return array
  elseif type(a:content) <= 1 || type(a:content) == 5
    if type(a:content) == 0
      let int = xml#createElement("int")
      call int.value(a:content)
      return int
    elseif type(a:content) == 1
      let str = xml#createElement("string")
      call str.value(a:content)
      return str
    elseif type(a:content) == 5
      let double = xml#createElement("double")
      call double.value(a:content)
      return double
    endif
  endif
  return {}
endfunction

function! s:to_fault(dom)
  let struct = a:dom.find('struct')
  let faultCode = ""
  let faultString = ""
  for member in struct.childNodes('member')
    if member.childNode('name').value() == "faultCode"
      let faultCode = member.childNode('value').value()
    elseif member.childNode('name').value() == "faultString"
      let faultString = member.childNode('value').value()
    endif
  endfor
  return faultCode.":".faultString
endfunction

function! s:xmlrpc_call(uri, func, args)
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value(a:func)
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in a:args
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(arg))
    call add(param.child, value)
    call add(params.child, param)
  endfor
  call add(methodCall.child, params)
  let xml = iconv(methodCall.toString(), &encoding, "utf-8")
  let res = http#post(a:uri, xml, {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return s:from_value(dom)
  endif
endfunction

function! xmlrpc#wrap(contexts)
  let api = {}
  for context in a:contexts
    let target = api
    let namespaces = split(context.name, '\.')[:-2]
    for ns in namespaces
      if !has_key(target, ns)
        let target[ns] = {".uri": context.uri}
      endif
      let target = target[ns]
    endfor
    exe "function api.".context.name."(".join(context.argnames,",").") dict\n"
    \.  "  return s:xmlrpc_call(self['.uri'], '".context.name."', [".join(map(copy(context.argnames),'"a:".v:val'),",")."])\n"
    \.  "endfunction\n"
  endfor
  return api
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
