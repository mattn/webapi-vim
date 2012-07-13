" atom
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc5023.txt

let s:save_cpo = &cpo
set cpo&vim

let s:system = function(get(g:, 'webapi#system_function', 'system'))

let s:author_template = {
\ "name": "",
\}

let s:link_template = {
\ "rel": "",
\ "href": "",
\}

let s:category_template = {
\ "term": "",
\ "scheme": "",
\ "label": "",
\}

let s:feed_template = {
\ "id": "",
\ "icon": "",
\ "logo": "",
\ "title": "",
\ "link": [],
\ "category": [],
\ "author": [],
\ "contirubutor": [],
\ "entry": [],
\}

let s:entry_template = {
\ "id": "",
\ "icon": "",
\ "logo": "",
\ "title": "",
\ "link": [],
\ "category": [],
\ "author": [],
\ "contirubutor": [],
\ "copyright": "",
\ "content": "",
\ "content.type": "text/plain",
\ "content.mode": "escaped",
\ "summary": "",
\ "created": "",
\ "updated": "",
\}

for s:name in ['author', 'link', 'category', 'feed', 'entry']
  for s:key in keys(eval('s:'.s:name.'_template'))
    let key = substitute(s:key, '\.\(.\)', '\=toupper(submatch(1))', '')
    exe "function s:".s:name."_template.set".toupper(key[0]).key[1:]."(v) dict\n"
    \. "  let self['".s:key."'] = a:v\n"
    \. "endfunction\n"
    exe "function s:".s:name."_template.get".toupper(key[0]).key[1:]."() dict\n"
    \. "  return self['".s:key."']\n"
    \. "endfunction\n"
  endfor
endfor
function s:entry_template.setContentFromFile(file) dict
  let quote = &shellxquote == '"' ?  "'" : '"'
  let bits = substitute(s:system("xxd -ps ".quote.file.quote), "[ \n\r]", '', 'g')
  let self['mode'] = "base64"
  let self['content'] = webapi#base64#b64encodebin(bits)
endfunction

unlet s:name
unlet s:key

function! webapi#atom#newEntry()
  return deepcopy(s:entry_template)
endfunction

function! s:createXml(entry)
  let entry = webapi#xml#createElement("entry")
  let entry.attr["xmlns"] = "http://purl.org/atom/ns#"

  for key in keys(a:entry)
    if type(a:entry[key]) == 1 && key !~ '\.'
      let node = webapi#xml#createElement(key)
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
  let nonce = webapi#sha1#sha1(now . " " . now)[0:28]
  let created = strftime("%Y-%m-%dT%H:%M:%SZ", now)
  let passworddigest = webapi#base64#b64encodebin(webapi#sha1#sha1(nonce.created.a:pass))
  let nonce = webapi#base64#b64encode(nonce)
  return 'UsernameToken Username="'.a:user.'", PasswordDigest="'.passworddigest.'", Nonce="'.nonce.'", Created="'.created.'"'
endfunction

function! webapi#atom#deleteEntry(uri, user, pass)
  let res = webapi#http#post(a:uri, "",
    \ {
    \   "Content-Type": "application/x.atom+xml",
    \   "X-WSSE": s:createWsse(a:user, a:pass)
    \ }, "DELETE")
  return res
endfunction

function! webapi#atom#updateEntry(uri, user, pass, entry, ...)
  let headdata = a:0 > 0 ? a:000[0] : {}
  let headdata["Content-Type"] = "application/x.atom+xml"
  let headdata["X-WSSE"] = s:createWsse(a:user, a:pass)
  let res = webapi#http#post(a:uri, s:createXml(a:entry), headdata, "PUT")
  let location = filter(res.header, 'v:val =~ "^Location:"')
  if len(location)
    return split(location[0], '\s*:\s\+')[1]
  endif
  return ''
endfunction

function! webapi#atom#createEntry(uri, user, pass, entry, ...)
  let headdata = a:0 > 0 ? a:000[0] : {}
  let headdata["Content-Type"] = "application/x.atom+xml"
  let headdata["X-WSSE"] = s:createWsse(a:user, a:pass)
  let headdata["WWW-Authenticate"] = "WSSE profile=\"UsernameToken\""
  let res = webapi#http#post(a:uri, s:createXml(a:entry), headdata, "POST")
  let location = filter(res.header, 'v:val =~ "^Location:"')
  if len(location)
    return split(location[0], '\s*:\s\+')[1]
  endif
  return ''
endfunction

function! s:parse_node(target, parent)
  for node in a:parent.child
    if type(node) != 4 || !has_key(a:target, node.name)
      unlet node
      continue
    endif
    if node.name == 'content'
      let a:target[node.name] = node.value()
      if has_key(node.attr, 'type')
        let a:target['content.type'] = node.attr['type']
      endif
      if has_key(node.attr, 'type')
        let a:target['content.type'] = node.attr['type']
      endif
    elseif node.name == 'link'
      let link = deepcopy(s:link_template)
      for attr in keys(node.attr)
        if !has_key(link, attr)
          continue
        endif
        let link[attr] = node.attr[attr]
      endfor
      call add(a:target.link, link)
    elseif node.name == 'author'
      let author = deepcopy(s:author_template)
      for item in node.child
        if type(item) == 4 && has_key(author, item.name)
          let author[item.name] = item.value()
        endif
        unlet item
      endfor
      call add(a:target.author, author)
    elseif node.name == 'entry'
      let entry = deepcopy(s:entry_template)
      call s:parse_node(entry, node)
      call add(a:target.entry, entry)
    elseif type(a:target[node.name]) == 3
      call add(a:target[node.name], parent.value())
    else
      let a:target[node.name] = node.value()
    endif
    unlet node
  endfor
endfunction

function! webapi#atom#getFeed(uri, user, pass)
  let headdata = {}
  if len(a:user) > 0 && len(a:pass) > 0
    let headdata["X-WSSE"] = s:createWsse(a:user, a:pass)
  endif
  let res = webapi#http#get(a:uri, {}, headdata)
  let dom = webapi#xml#parse(res.content)
  let feed = deepcopy(s:feed_template)
  call s:parse_node(feed, dom)
  return feed
endfunction

function! webapi#atom#getService(uri, user, pass)
  let headdata = {}
  if len(a:user) > 0 && len(a:pass) > 0
    let headdata["X-WSSE"] = s:createWsse(a:user, a:pass)
  endif
  let res = webapi#http#get(a:uri, {}, headdata)
  return webapi#xml#parse(res.content)
endfunction

function! webapi#atom#getEntry(uri, user, pass)
  let headdata = {}
  if len(a:user) > 0 && len(a:pass) > 0
    let headdata["X-WSSE"] = s:createWsse(a:user, a:pass)
  endif
  let res = webapi#http#get(a:uri, {}, headdata)
  let dom = webapi#xml#parse(res.content)
  let entry = deepcopy(s:entry_template)
  call s:parse_node(entry, dom)
  return entry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
