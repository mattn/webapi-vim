" metaweblog
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc3529.txt

let s:save_cpo = &cpo
set cpo&vim

let s:template = {"uri" : ""}

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

function! s:template.newPost(blogid, username, password, content, publish) dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("metaWeblog.newPost")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in split("blogid,username,password,content,publish", ",")
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(eval('a:'.arg)))
    call add(param.child, value)
    call add(params.child, param)
  endfor
  call add(methodCall.child, params)
  let res = http#post(self.uri, methodCall.toString(), {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return substitute(dom.value(), "[ \n\r]", '', 'g')
  endif
endfunction

function! s:template.editPost(postid, username, password, content, publish) dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("metaWeblog.editPost")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in split("postid,username,password,content,publish", ",")
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(eval('a:'.arg)))
    call add(param.child, value)
    call add(params.child, param)
  endfor
  call add(methodCall.child, params)
  let res = http#post(self.uri, methodCall.toString(), {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    let ret = substitute(dom.value(), "[ \n\r]", '', 'g')
    if ret == "true" || ret == "1"
      return 1
    else
      return 0
    endif
  endif
endfunction

function! s:template.getPost(postid, username, password) dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("metaWeblog.getPost")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in split("postid,username,password", ",")
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(eval('a:'.arg)))
    call add(param.child, value)
    call add(params.child, param)
  endfor
  call add(methodCall.child, params)
  let res = http#post(self.uri, methodCall.toString(), {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    let ret = {}
    let struct = dom.find('struct')
    for member in struct.childNodes('member')
      let ret[member.childNode('name').value()] = member.childNode('value').value()
    endfor
    return ret
  endif
endfunction

function! s:template.getRecentPosts(blogid, username, password, numberOfPosts) dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("metaWeblog.getRecentPosts")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in split("blogid,username,password,numberOfPosts", ",")
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(eval('a:'.arg)))
    call add(param.child, value)
    call add(params.child, param)
  endfor
  call add(methodCall.child, params)
  let res = http#post(self.uri, methodCall.toString(), {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    let ret = []
    let values = dom.find('array').childNode('data').childNodes('value')
    for v in values
      let entry = {}
      let struct = v.childNode('struct')
      for member in struct.childNodes('member')
        let entry[member.childNode('name').value()] = member.childNode('value').value()
      endfor
      call add(ret, entry)
    endfor
    return ret
  endif
endfunction

function! s:template.deletePost(appkey, postid, username, password, ...) dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("blogger.deletePost")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in split("appkey,postid,username,password", ",")
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(eval('a:'.arg)))
    call add(param.child, value)
    call add(params.child, param)
  endfor
  let param = xml#createElement("param")
  let value = xml#createElement("value")
  call value.value(1)
  call add(param.child, value)
  call add(params.child, param)

  call add(methodCall.child, params)
  let res = http#post(self.uri, methodCall.toString(), {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    let ret = substitute(dom.value(), "[ \n\r]", '', 'g')
    if ret == "true" || ret == "1"
      return 1
    else
      return 0
    endif
  endif
endfunction

function! s:template.newMediaObject(blogid, username, password, file) dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("metaWeblog.newMediaObject")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in split("blogid,username,password", ",")
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(eval('a:'.arg)))
    call add(param.child, value)
    call add(params.child, param)
  endfor

  let param = xml#createElement("param")
  call add(params.child, param)
  let value = xml#createElement("value")
  call add(param.child, value)
  let struct = xml#createElement("struct")
  call add(value.child, struct)

    let member = xml#createElement("member")
    call add(struct.child, member)
    let name = xml#createElement("name")
    call name.value("bits")
    call add(member.child, name)
    let value = xml#createElement("value")
    call add(member.child, value)
    let base64 = xml#createElement("base64")
    call add(value.child, base64)
    if has_key(a:file, "bits")
      call base64.value(a:file["bits"])
    elseif has_key(a:file, "path")
      let quote = &shellxquote == '"' ?  "'" : '"'
      let bits = substitute(system("xxd -ps ".quote.a:file["path"].quote), "[ \n\r]", '', 'g')
      call base64.value(base64#b64encodebin(bits))
    endif

    let member = xml#createElement("member")
    call add(struct.child, member)
    let name = xml#createElement("name")
    call name.value("name")
    call add(member.child, name)
    let value = xml#createElement("value")
    call value.value(a:file["name"])
    call add(member.child, value)

  call add(methodCall.child, params)
  let res = http#post(self.uri, methodCall.toString(), {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    if len(dom.find('struct'))
      return substitute(dom.find('member').find('value').value(), "[ \n\r]", '', 'g')
    else
      return substitute(dom.value(), "[ \n\r]", '', 'g')
    endif
  endif
endfunction

function! metaWeblog#proxy(uri)
  let ctx = deepcopy(s:template)
  let ctx.uri = a:uri
  return ctx
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
