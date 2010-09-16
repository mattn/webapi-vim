" http
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"
   
let s:save_cpo = &cpo
set cpo&vim

function! s:nr2byte(nr)
  if a:nr < 0x80
    return nr2char(a:nr)
  elseif a:nr < 0x800
    return nr2char(a:nr/64+192).nr2char(a:nr%64+128)
  else
    return nr2char(a:nr/4096%16+224).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  endif
endfunction

function! s:nr2enc_char(charcode)
  if &encoding == 'utf-8'
    return nr2char(a:charcode)
  endif
  let char = s:nr2byte(a:charcode)
  if strlen(char) > 1
    let char = strtrans(iconv(char, 'utf-8', &encoding))
  endif
  return char
endfunction

function! s:nr2hex(nr)
  let n = a:nr
  let r = ""
  while n
    let r = '0123456789ABCDEF'[n % 16] . r
    let n = n / 16
  endwhile
  return r
endfunction

function! s:urlencode_char(c)
  let utf = iconv(a:c, &encoding, "utf-8")
  if utf == ""
    let utf = a:c
  endif
  let s = ""
  for i in range(strlen(utf))
    let s .= printf("%%%02X", char2nr(utf[i]))
  endfor
  return s
endfunction

function! http#encodeURI(items)
  let ret = ''
  if type(a:items) == 4
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . http#encodeURI(a:items[key])
    endfor
  elseif type(a:items) == 3
    for item in sort(a:items)
      if strlen(ret) | let ret .= "&" | endif
      let ret .= item
    endfor
  else
    let ret = substitute(a:items, '[^a-zA-Z0-9_.~-]', '\=s:urlencode_char(submatch(0))', 'g')
  endif
  return ret
endfunction

function! http#encodeURIComponent(instr)
  let instr = iconv(a:instr, &enc, "utf-8")
  let len = strlen(instr)
  let i = 0
  let outstr = ''
  while i < len
    let ch = instr[i]
    if ch =~# '[0-9A-Za-z-._~!''()*]'
      let outstr .= ch
    elseif ch == ' '
      let outstr .= '+'
    else
      let outstr .= '%' . substitute('0' . s:nr2hex(char2nr(ch)), '^.*\(..\)$', '\1', '')
    endif
    let i = i + 1
  endwhile
  return outstr
endfunction

function! http#get(url, getdata, headdata)
  let url = a:url
  let getdata = http#encodeURI(a:getdata)
  if strlen(getdata)
    let url .= "?" . getdata
  endif
  let command = 'curl -L -s -k -i -H "Accept: *"'
  let quote = &shellxquote == '"' ?  "'" : '"'
  for key in keys(a:headdata)
    let command .= " -H " . quote . key . ": " . a:headdata[key] . quote
  endfor
  let command .= " ".quote.url.quote
  let res = system(command)
  if res =~ '^HTTP/1.\d 3' || res =~ '^HTTP/1\.\d 200 Connection established'
    let pos = stridx(res, "\r\n\r\n")
    if pos != -1
      let res = res[pos+4:]
    else
      let pos = stridx(res, "\n\n")
      let res = res[pos+2:]
    endif
  endif
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = res[pos+4:]
  else
    let pos = stridx(res, "\n\n")
    let content = res[pos+2:]
  endif
  return {
  \ "header" : split(res[0:pos], '\r\?\n'),
  \ "content" : content
  \}
endfunction

function! http#post(url, postdata, headdata)
  let url = a:url
  let postdata = http#encodeURI(a:postdata)
  let command = 'curl -L -s -k -i -H "Accept: *"'
  let quote = &shellxquote == '"' ?  "'" : '"'
  for key in keys(a:headdata)
    if has('win32')
      let command .= " -H " . quote . key . ": " . substitute(a:headdata[key], '"', '"""', 'g') . quote
    else
      let command .= " -H " . quote . key . ": " . a:headdata[key] . quote
	endif
  endfor
  let command .= " ".quote.url.quote
  let file = tempname()
  call writefile([postdata], file)
  let res = system(command . " -d @" . quote.file.quote)
  call delete(file)
  if res =~ '^HTTP/1.\d 3' || res =~ '^HTTP/1\.\d 200 Connection established'
    let pos = stridx(res, "\r\n\r\n")
    if pos != -1
      let res = res[pos+4:]
    else
      let pos = stridx(res, "\n\n")
      let res = res[pos+2:]
    endif
  endif
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = res[pos+4:]
  else
    let pos = stridx(res, "\n\n")
    let content = res[pos+2:]
  endif
  return {
  \ "header" : split(res[0:pos], '\r\?\n'),
  \ "content" : content
  \}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
