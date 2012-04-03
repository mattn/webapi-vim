" base64 codec
" Last Change: 2010-07-25
" Maintainer:   Yukihiro Nakadaira <yukihiro.nakadaira@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   [The Base16, Base32, and Base64 Data Encodings]
"   http://tools.ietf.org/rfc/rfc3548.txt

let s:save_cpo = &cpo
set cpo&vim

function! webapi#base64#b64encode(data)
  let b64 = s:b64encode(s:str2bytes(a:data), s:standard_table, '=')
  return join(b64, '')
endfunction

function! webapi#base64#b64encodebin(data)
  let b64 = s:b64encode(s:binstr2bytes(a:data), s:standard_table, '=')
  return join(b64, '')
endfunction

function! webapi#base64#b64decode(data)
  let bytes = s:b64decode(split(a:data, '\zs'), s:standard_table, '=')
  return s:bytes2str(bytes)
endfunction

function! webapi#base64#test()
  if webapi#base64#b64encode("hello, world") ==# "aGVsbG8sIHdvcmxk"
    echo "test1: ok"
  else
    echoerr "test1: failed"
  endif
  if webapi#base64#b64encode("hello, worldx") ==# "aGVsbG8sIHdvcmxkeA=="
    echo "test2: ok"
  else
    echoerr "test2: failed"
  endif
  if webapi#base64#b64encode("hello, worldxx") ==# "aGVsbG8sIHdvcmxkeHg="
    echo "test3: ok"
  else
    echoerr "test3: falied"
  endif
  if webapi#base64#b64encode("hello, worldxxx") ==# "aGVsbG8sIHdvcmxkeHh4"
    echo "test4: ok"
  else
    echoerr "test4: falied"
  endif
  if webapi#base64#b64decode(webapi#base64#b64encode("hello, world")) ==# "hello, world"
    echo "test5: ok"
  else
    echoerr "test5: failed"
  endif
  if webapi#base64#b64decode(webapi#base64#b64encode("hello, worldx")) ==# "hello, worldx"
    echo "test6: ok"
  else
    echoerr "test6: failed"
  endif
  if webapi#base64#b64decode(webapi#base64#b64encode("hello, worldxx")) ==# "hello, worldxx"
    echo "test7: ok"
  else
    echoerr "test7: failed"
  endif
  if webapi#base64#b64decode(webapi#base64#b64encode("hello, worldxxx")) ==# "hello, worldxxx"
    echo "test8: ok"
  else
    echoerr "test8: failed"
  endif
endfunction

let s:standard_table = [
      \ "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
      \ "Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f",
      \ "g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v",
      \ "w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"]

let s:urlsafe_table = [
      \ "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
      \ "Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f",
      \ "g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v",
      \ "w","x","y","z","0","1","2","3","4","5","6","7","8","9","-","_"]

function! s:b64encode(bytes, table, pad)
  let b64 = []
  for i in range(0, len(a:bytes) - 1, 3)
    let n = a:bytes[i] * 0x10000
          \ + get(a:bytes, i + 1, 0) * 0x100
          \ + get(a:bytes, i + 2, 0)
    call add(b64, a:table[n / 0x40000])
    call add(b64, a:table[n / 0x1000 % 0x40])
    call add(b64, a:table[n / 0x40 % 0x40])
    call add(b64, a:table[n % 0x40])
  endfor
  if len(a:bytes) % 3 == 1
    let b64[-1] = a:pad
    let b64[-2] = a:pad
  endif
  if len(a:bytes) % 3 == 2
    let b64[-1] = a:pad
  endif
  return b64
endfunction

function! s:b64decode(b64, table, pad)
  let a2i = {}
  for i in range(len(a:table))
    let a2i[a:table[i]] = i
  endfor
  let bytes = []
  for i in range(0, len(a:b64) - 1, 4)
    let n = a2i[a:b64[i]] * 0x40000
          \ + a2i[a:b64[i + 1]] * 0x1000
          \ + (a:b64[i + 2] == a:pad ? 0 : a2i[a:b64[i + 2]]) * 0x40
          \ + (a:b64[i + 3] == a:pad ? 0 : a2i[a:b64[i + 3]])
    call add(bytes, n / 0x10000)
    call add(bytes, n / 0x100 % 0x100)
    call add(bytes, n % 0x100)
  endfor
  if a:b64[-1] == a:pad
    unlet a:b64[-1]
  endif
  if a:b64[-2] == a:pad
    unlet a:b64[-1]
  endif
  return bytes
endfunction

function! s:binstr2bytes(str)
  return map(range(len(a:str)/2), 'eval("0x".a:str[v:val*2 : v:val*2+1])')
endfunction

function! s:str2bytes(str)
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:bytes2str(bytes)
  return eval('"' . join(map(copy(a:bytes), 'printf(''\x%02x'', v:val)'), '') . '"')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
