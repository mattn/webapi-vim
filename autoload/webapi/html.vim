" html
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

function! webapi#html#decodeEntityReference(str)
  let str = a:str
  let str = substitute(str, '&gt;', '>', 'g')
  let str = substitute(str, '&lt;', '<', 'g')
  let str = substitute(str, '&quot;', '"', 'g')
  let str = substitute(str, '&apos;', "'", 'g')
  let str = substitute(str, '&nbsp;', ' ', 'g')
  let str = substitute(str, '&yen;', '\&#65509;', 'g')
  let str = substitute(str, '&#\(\d\+\);', '\=s:nr2enc_char(submatch(1))', 'g')
  let str = substitute(str, '&amp;', '\&', 'g')
  let str = substitute(str, '&raquo;', '>', 'g')
  let str = substitute(str, '&laquo;', '<', 'g')
  return str
endfunction

function! webapi#html#encodeEntityReference(str)
  let str = a:str
  let str = substitute(str, '&', '\&amp;', 'g')
  let str = substitute(str, '>', '\&gt;', 'g')
  let str = substitute(str, '<', '\&lt;', 'g')
  let str = substitute(str, "\n", '\&#x0d;', 'g')
  let str = substitute(str, '"', '\&quot;', 'g')
  let str = substitute(str, "'", '\&apos;', 'g')
  let str = substitute(str, ' ', '\&nbsp;', 'g')
  return str
endfunction

function! webapi#html#parse(html)
  let html = substitute(a:html, '<\(area\|base\|basefont\|br\|nobr\|col\|frame\|hr\|img\|input\|isindex\|link\|meta\|param\|embed\|keygen\|command\)\([^>]*[^/]\|\)>', '<\1\2/>', 'g')
  return webapi#xml#parse(html)
endfunction

function! webapi#html#parseFile(fname)
  return webapi#html#parse(join(readfile(a:fname), "\n"))
endfunction

function! webapi#html#parseURL(url)
  return webapi#html#parse(webapi#http#get(a:url).content)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
