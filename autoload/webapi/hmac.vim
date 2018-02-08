" This is a port of rfc2104 hmac function.
" http://www.ietf.org/rfc/rfc2104.txt
" Last Change:  2010-02-13
" Maintainer:   Yukihiro Nakadaira <yukihiro.nakadaira@gmail.com>
" License: This file is placed in the public domain.

" @param mixed key List or String
" @param mixed text List or String
" @param Funcref hash   function digest_hex(key:List, text:List):String
" @param Number blocksize
function webapi#hmac#hmac(key, text, hash, blocksize) abort
  let key = (type(a:key) == type("")) ? s:str2bytes(a:key) : a:key
  let text = (type(a:text) == type("")) ? s:str2bytes(a:text) : a:text
  return s:Hmac(key, text, a:hash, a:blocksize)
endfunction

function webapi#hmac#md5(key, text) abort
  return webapi#hmac#hmac(a:key, a:text, 'webapi#md5#md5bin', 64)
endfunction

function webapi#hmac#sha1(key, text) abort
  return webapi#hmac#hmac(a:key, a:text, 'webapi#sha1#sha1bin', 64)
endfunction

" http://www.ietf.org/rfc/rfc2202.txt
" Test Cases for HMAC-MD5 and HMAC-SHA-1
function webapi#hmac#test() abort
  " Test Cases for HMAC-MD5
  call s:test("md5: 1", "webapi#hmac#md5",
        \ repeat("\x0b", 16),
        \ "Hi There",
        \ "9294727a3638bb1c13f48ef8158bfc9d")
  call s:test("md5: 2", "webapi#hmac#md5",
        \ "Jefe",
        \ "what do ya want for nothing?",
        \ "750c783e6ab0b503eaa86e310a5db738")
  call s:test("md5: 3", "webapi#hmac#md5",
        \ repeat("\xaa", 16),
        \ repeat("\xdd", 50),
        \ "56be34521d144c88dbb8c733f0e8b3f6")
  call s:test("md5: 4", "webapi#hmac#md5",
        \ s:hex2bytes("0102030405060708090a0b0c0d0e0f10111213141516171819"),
        \ repeat([0xcd], 50),
        \ "697eaf0aca3a3aea3a75164746ffaa79")
  call s:test("md5: 5", "webapi#hmac#md5",
        \ repeat("\x0c", 16),
        \ "Test With Truncation",
        \ "56461ef2342edc00f9bab995690efd4c")
  call s:test("md5: 6", "webapi#hmac#md5",
        \ repeat("\xaa", 80),
        \ "Test Using Larger Than Block-Size Key - Hash Key First",
        \ "6b1ab7fe4bd7bf8f0b62e6ce61b9d0cd")
  call s:test("md5: 7", "webapi#hmac#md5",
        \ repeat("\xaa", 80),
        \ "Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data",
        \ "6f630fad67cda0ee1fb1f562db3aa53e")

  " Test Cases for HMAC-SHA1
  call s:test("sha1: 1", "webapi#hmac#sha1",
        \ repeat("\x0b", 20),
        \ "Hi There",
        \ "b617318655057264e28bc0b6fb378c8ef146be00")
  call s:test("sha1: 2", "webapi#hmac#sha1",
        \ "Jefe",
        \ "what do ya want for nothing?",
        \ "effcdf6ae5eb2fa2d27416d5f184df9c259a7c79")
  call s:test("sha1: 3", "webapi#hmac#sha1",
        \ repeat("\xaa", 20),
        \ repeat("\xdd", 50),
        \ "125d7342b9ac11cd91a39af48aa17b4f63f175d3")
  call s:test("sha1: 4", "webapi#hmac#sha1",
        \ s:hex2bytes("0102030405060708090a0b0c0d0e0f10111213141516171819"),
        \ repeat([0xcd], 50),
        \ "4c9007f4026250c6bc8414f9bf50c86c2d7235da")
  call s:test("sha1: 5", "webapi#hmac#sha1",
        \ repeat("\x0c", 20),
        \ "Test With Truncation",
        \ "4c1a03424b55e07fe7f27be1d58bb9324a9a5a04")
  call s:test("sha1: 6", "webapi#hmac#sha1",
        \ repeat("\xaa", 80),
        \ "Test Using Larger Than Block-Size Key - Hash Key First",
        \ "aa4ae5e15272d00e95705637ce8a3b55ed402112")
  call s:test("sha1: 7", "webapi#hmac#sha1",
        \ repeat("\xaa", 80),
        \ "Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data",
        \ "e8e99d0f45237d786d6bbaa7965c7808bbff1a91")
endfunction

function s:test(name, func, key, data, digest) abort
  let result = call(a:func, [a:key, a:data])
  echo "test_case:" a:name
  echo "expect:" a:digest
  echo "result:" result
  if a:digest ==? result
    echo "test: OK"
  else
    echohl Error
    echo "test: NG"
    echohl None
  endif
endfunction

" @param List key
" @param List text
" @param Funcref hash
" @param Number blocksize
function! s:Hmac(key, text, hash, blocksize) abort
  let key = a:key
  if len(key) > a:blocksize
    let key = s:hex2bytes(call(a:hash, [key]))
  endif
  let k_ipad = repeat([0], a:blocksize)
  let k_opad = repeat([0], a:blocksize)
  for i in range(a:blocksize)
    let k_ipad[i] = xor(get(key, i, 0), 0x36)
    let k_opad[i] = xor(get(key, i, 0), 0x5c)
  endfor
  let hash1 = s:hex2bytes(call(a:hash, [k_ipad + a:text]))
  let hmac = call(a:hash, [k_opad + hash1])
  return hmac
endfunction

function! s:str2bytes(str) abort
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:hex2bytes(str) abort
  return map(split(a:str, '..\zs'), 'str2nr(v:val, 16)')
endfunction
