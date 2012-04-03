" xmlrpc
" Last Change: 2010-11-05
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc3529.txt

let s:save_cpo = &cpo
set cpo&vim

function! webapi#xmlrpc#nil()
  return 0
endfunction

function! webapi#xmlrpc#true()
  return 1
endfunction

function! webapi#xmlrpc#false()
  return 0
endfunction

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
    if get(g:, 'webapi#xmlrpc#allow_nil', 0) != 0
      return function('webapi#xmlrpc#nil')
    endif
    return 0
  else
    throw "unknown type: ".value.name
  endif
endfunction

function! s:to_value(content)
  if type(a:content) == 4
    if has_key(a:content, 'bits')
      let struct = webapi#xml#createElement("struct")

      let member = webapi#xml#createElement("member")
      call add(struct.child, member)
      let name = webapi#xml#createElement("name")
      call add(member.child, name)
      call name.value("name")
      let value = webapi#xml#createElement("value")
      call add(member.child, value)
      call add(value.child, s:to_value(a:content["name"]))

      let member = webapi#xml#createElement("member")
      call add(struct.child, member)
      let name = webapi#xml#createElement("name")
      call name.value("bits")
      call add(member.child, name)
      let value = webapi#xml#createElement("value")
      call add(member.child, value)
      let base64 = webapi#xml#createElement("base64")
      call add(value.child, base64)
      if has_key(a:content, "bits") && len(a:content["bits"])
        call base64.value(a:content["bits"])
      elseif has_key(a:content, "path")
        let quote = &shellxquote == '"' ?  "'" : '"'
        let bits = substitute(system("xxd -ps ".quote.a:content["path"].quote), "[ \n\r]", '', 'g')
        call base64.value(webapi#base64#b64encodebin(bits))
      endif
      return struct
    else
      let struct = webapi#xml#createElement("struct")
      for key in keys(a:content)
        let member = webapi#xml#createElement("member")
        let name = webapi#xml#createElement("name")
        call name.value(key)
        call add(member.child, name)
        let value = webapi#xml#createElement("value")
        call add(value.child, s:to_value(a:content[key]))
        call add(member.child, value)
        call add(struct.child, member)
      endfor
      return struct
    endif
  elseif type(a:content) == 3
    let array = webapi#xml#createElement("array")
    let data = webapi#xml#createElement("data")
    for item in a:content
      let value = webapi#xml#createElement("value")
      call add(value.child, s:to_value(item))
      call add(data.child, value)
    endfor
    call add(array.child, data)
    return array
  elseif type(a:content) == 2
    if a:content == function('webapi#xmlrpc#true')
      let true = webapi#xml#createElement("boolean")
      call true.value('true')
      return true
    elseif a:content == function('webapi#xmlrpc#false')
      let false = webapi#xml#createElement("boolean")
      call false.value('false')
      return false
    else
      return webapi#xml#createElement("nil")
    endif
  elseif type(a:content) <= 1 || type(a:content) == 5
    if type(a:content) == 0
      let int = webapi#xml#createElement("int")
      call int.value(a:content)
      return int
    elseif type(a:content) == 1
      let str = webapi#xml#createElement("string")
      call str.value(a:content)
      return str
    elseif type(a:content) == 5
      let double = webapi#xml#createElement("double")
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

function! webapi#xmlrpc#call(uri, func, args)
  let methodCall = webapi#xml#createElement("methodCall")
  let methodName = webapi#xml#createElement("methodName")
  call methodName.value(a:func)
  call add(methodCall.child, methodName)
  let params = webapi#xml#createElement("params")
  for Arg in a:args
    let param = webapi#xml#createElement("param")
    let value = webapi#xml#createElement("value")
    call value.value(s:to_value(Arg))
    call add(param.child, value)
    call add(params.child, param)
    unlet Arg
  endfor
  call add(methodCall.child, params)
  let xml = iconv(methodCall.toString(), &encoding, "utf-8")
  let res = webapi#http#post(a:uri, xml, {"Content-Type": "text/xml"})
  let dom = webapi#xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return s:from_value(dom)
  endif
endfunction

function! webapi#xmlrpc#wrap(contexts)
  let api = {}
  for context in a:contexts
    let target = api
    let namespaces = split(context.name, '\.')[:-2]
    if len(namespaces) > 0
      for ns in namespaces
        if !has_key(target, ns)
          let target[ns] = {".uri": context.uri}
        endif
        let target = target[ns]
      endfor
    endif
    if len(context.argnames) && context.argnames[-1] == '...'
      let arglist = '[' . join(map(copy(context.argnames[:-2]),'"a:".v:val'),',') . ']+a:000'
    else
      let arglist = '[' . join(map(copy(context.argnames),'"a:".v:val'),',') . ']'
    endif
    if has_key(context, 'alias')
      exe "function api.".context.alias."(".join(context.argnames,",").") dict\n"
      \.  "  return webapi#xmlrpc#call(self['.uri'], '".context.name."', ".arglist.")\n"
      \.  "endfunction\n"
    else
      exe "function api.".context.name."(".join(context.argnames,",").") dict\n"
      \.  "  return webapi#xmlrpc#call('".context.uri."', '".context.name."', ".arglist.")\n"
      \.  "endfunction\n"
    endif
  endfor
  return api
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
