" atom
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc5023.txt

let s:save_cpo = &cpo
set cpo&vim

let s:template = {
\ "id": "",
\ "icon": "",
\ "logo": "",
\ "title": "",
\ "link": "",
\ "category": "",
\ "author": "",
\ "contirubutor": "",
\ "copyright": "",
\ "content": "",
\ "content.type": "text/plain",
\ "content.mode": "escaped",
\ "summary": "",
\ "created": "",
\ "updated": "",
\}

for s:key in keys(s:template)
  let key = substitute(s:key, '\.\(.\)', '\=toupper(submatch(1))', '')
  exe "function s:template.set".toupper(key[0]).key[1:]."(v) dict\n"
  \. "  let self['".s:key."'] = a:v\n"
  \. "endfunction\n"
  exe "function s:template.get".toupper(key[0]).key[1:]."() dict\n"
  \. "  return self['".s:key."']\n"
  \. "endfunction\n"
endfor
unlet s:key

function! atom#newEntry()
  return deepcopy(s:template)
endfunction

function! s:createXml(entry)
  let entry = xml#createElement("entry")
  let entry.attr["xmlns"] = "http://purl.org/atom/ns#"

  for key in keys(a:entry)
    if type(a:entry[key]) == 1 && key !~ '\.'
      let node = xml#createElement(key)
      call node.value(a:entry[key])
	  if key == "content"
        let node.attr["type"] = a:entry['content.type']
        let node.attr["mode"] = a:entry['content.mode']
	  endif
      call add(entry.child, node)
	endif
  endfor
  let xml = '<?xml version="1.0" encoding="utf-8"?>' . entry.toString()
  return iconv(xml, &encoding, "utf-8")
endfunction

function! s:createWsse(user, pass)
  let now = localtime()
  let nonce = base64#b64encodebin(sha1#sha1(now . " " . now)[0:28])
  let created = strftime("%Y-%m-%dT%H:%M:%SZ", now)
  let passworddigest = base64#b64encodebin(sha1#sha1(nonce.created.a:pass))
  return 'UsernameToken Username="'.a:user.'", PasswordDigest="'.passworddigest.'", Nonce="'.nonce.'", Created="'.created.'"'
endfunction

function! atom#deleteEntry(uri, user, pass)
  let res = http#post(a:uri, "",
    \ {
    \   "Content-Type": "application/x.atom+xml",
    \   "X-WSSE": s:createWsse(a:user, a:pass)
	\ }, "DELETE")
  return res
endfunction

function! atom#updateEntry(uri, user, pass, entry, ...)
  let headdata = a:0 > 0 ? a:000[0] : {}
  let headdata["Content-Type"] = "application/x.atom+xml"
  let headdata["X-WSSE"] = s:createWsse(a:user, a:pass)
  let res = http#post(a:uri, s:createXml(a:entry), headdata, "PUT")
  let location = filter(res.header, 'v:val =~ "^Location:"')
  if len(location)
    return split(location[0], '\s*:\s\+')[1]
  endif
  return ''
endfunction

function! atom#createEntry(uri, user, pass, entry, ...)
  let headdata = a:0 > 0 ? a:000[0] : {}
  let headdata["Content-Type"] = "application/x.atom+xml"
  let headdata["X-WSSE"] = s:createWsse(a:user, a:pass)
  let res = http#post(a:uri, s:createXml(a:entry), headdata, "POST")
  let location = filter(res.header, 'v:val =~ "^Location:"')
  if len(location)
    return split(location[0], '\s*:\s\+')[1]
  endif
  return ''
endfunction

function! atom#getEntry(uri, user, pass)
  let res = http#get(a:uri, {},
    \ {
    \   "X-WSSE": s:createWsse(a:user, a:pass)
	\ })
  let entry = deepcopy(s:template)
  let dom = xml#parse(res.content)
  for node in dom.child
    if type(node) == 4 && has_key(node, 'name') && has_key(entry, node.name)
      let entry[node.name] = node.value()
      if node.name == 'content'
        if has_key(node.attr, 'type')
          let entry['content.type'] = node.attr['type']
        endif
        if has_key(node.attr, 'type')
          let entry['content.type'] = node.attr['type']
        endif
      endif
	endif
	unlet node
  endfor  
  return entry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
