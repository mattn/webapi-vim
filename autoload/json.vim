" json
" Last Change: 2012-03-08
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"
let s:save_cpo = &cpo
set cpo&vim

if !exists('g:json#allow_nil')
  let g:json#allow_nil = 0
endif

function! json#nil()
  return 0
endfunction

function! json#true()
  return 1
endfunction

function! json#false()
  return 0
endfunction

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

function! json#decode(json)
  let json = iconv(a:json, "utf-8", &encoding)
  let json = substitute(json, '\n', '', 'g')
  let json = substitute(json, '\\u34;', '\\"', 'g')
  let json = substitute(json, '\\u\(\x\x\x\x\)', '\=s:nr2enc_char("0x".submatch(1))', 'g')
  if g:json#allow_nil
    let [null,true,false] = [
    \ function('json#null'),
    \ function('json#true'),
    \ function('json#false')]
  else
    let [null,true,false] = [0,1,0]
  endif
  sandbox let ret = eval(json)
  return ret
endfunction

function! json#encode(val)
  if type(a:val) == 0
    return a:val
  elseif type(a:val) == 1
    let json = '"' . escape(a:val, '\"') . '"'
    let json = substitute(json, "\r", '\\r', 'g')
    let json = substitute(json, "\n", '\\n', 'g')
    let json = substitute(json, "\t", '\\t', 'g')
    return iconv(json, &encoding, "utf-8")
  elseif type(a:val) == 2
    let s = string(a:val)
    if s == "function('json#nil')"
      return 'NULL'
    elseif s == "function('json#true')"
      return 'true'
    elseif s == "function('json#false')"
      return 'false'
    endif
  elseif type(a:val) == 3
    return '[' . join(map(copy(a:val), 'json#encode(v:val)'), ',') . ']'
  elseif type(a:val) == 4
    return '{' . join(map(keys(a:val), 'json#encode(v:val).":".json#encode(a:val[v:val])'), ',') . '}'
  else
    return string(a:val)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
