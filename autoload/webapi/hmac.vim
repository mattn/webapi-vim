" This is a port of rfc2104 hmac function.
" http://www.ietf.org/rfc/rfc2104.txt
" Last Change:  2010-02-13
" Maintainer:   Yukihiro Nakadaira <yukihiro.nakadaira@gmail.com>
" License: This file is placed in the public domain.

" @param mixed key List or String
" @param mixed text List or String
" @param Funcref hash   function digest_hex(key:List, text:List):String
" @param Number blocksize
function webapi#hmac#hmac(key, text, hash, blocksize)
  let key = (type(a:key) == type("")) ? s:str2bytes(a:key) : a:key
  let text = (type(a:text) == type("")) ? s:str2bytes(a:text) : a:text
  return s:Hmac(key, text, a:hash, a:blocksize)
endfunction

function webapi#hmac#md5(key, text)
  return webapi#hmac#hmac(a:key, a:text, 'webapi#md5#md5bin', 64)
endfunction

function webapi#hmac#sha1(key, text)
  return webapi#hmac#hmac(a:key, a:text, 'webapi#sha1#sha1bin', 64)
endfunction

" http://www.ietf.org/rfc/rfc2202.txt
" Test Cases for HMAC-MD5 and HMAC-SHA-1
function webapi#hmac#test()
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

function s:test(name, func, key, data, digest)
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
function! s:Hmac(key, text, hash, blocksize)
  let key = a:key
  if len(key) > a:blocksize
    let key = s:hex2bytes(call(a:hash, [key]))
  endif
  let k_ipad = repeat([0], a:blocksize)
  let k_opad = repeat([0], a:blocksize)
  for i in range(a:blocksize)
    let k_ipad[i] = s:bitwise_xor(get(key, i, 0), 0x36)
    let k_opad[i] = s:bitwise_xor(get(key, i, 0), 0x5c)
  endfor
  let hash1 = s:hex2bytes(call(a:hash, [k_ipad + a:text]))
  let hmac = call(a:hash, [k_opad + hash1])
  return hmac
endfunction

function! s:str2bytes(str)
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:hex2bytes(str)
  return map(split(a:str, '..\zs'), 'str2nr(v:val, 16)')
endfunction

let s:xor = [
      \ [0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF],
      \ [0x1, 0x0, 0x3, 0x2, 0x5, 0x4, 0x7, 0x6, 0x9, 0x8, 0xB, 0xA, 0xD, 0xC, 0xF, 0xE],
      \ [0x2, 0x3, 0x0, 0x1, 0x6, 0x7, 0x4, 0x5, 0xA, 0xB, 0x8, 0x9, 0xE, 0xF, 0xC, 0xD],
      \ [0x3, 0x2, 0x1, 0x0, 0x7, 0x6, 0x5, 0x4, 0xB, 0xA, 0x9, 0x8, 0xF, 0xE, 0xD, 0xC],
      \ [0x4, 0x5, 0x6, 0x7, 0x0, 0x1, 0x2, 0x3, 0xC, 0xD, 0xE, 0xF, 0x8, 0x9, 0xA, 0xB],
      \ [0x5, 0x4, 0x7, 0x6, 0x1, 0x0, 0x3, 0x2, 0xD, 0xC, 0xF, 0xE, 0x9, 0x8, 0xB, 0xA],
      \ [0x6, 0x7, 0x4, 0x5, 0x2, 0x3, 0x0, 0x1, 0xE, 0xF, 0xC, 0xD, 0xA, 0xB, 0x8, 0x9],
      \ [0x7, 0x6, 0x5, 0x4, 0x3, 0x2, 0x1, 0x0, 0xF, 0xE, 0xD, 0xC, 0xB, 0xA, 0x9, 0x8],
      \ [0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7],
      \ [0x9, 0x8, 0xB, 0xA, 0xD, 0xC, 0xF, 0xE, 0x1, 0x0, 0x3, 0x2, 0x5, 0x4, 0x7, 0x6],
      \ [0xA, 0xB, 0x8, 0x9, 0xE, 0xF, 0xC, 0xD, 0x2, 0x3, 0x0, 0x1, 0x6, 0x7, 0x4, 0x5],
      \ [0xB, 0xA, 0x9, 0x8, 0xF, 0xE, 0xD, 0xC, 0x3, 0x2, 0x1, 0x0, 0x7, 0x6, 0x5, 0x4],
      \ [0xC, 0xD, 0xE, 0xF, 0x8, 0x9, 0xA, 0xB, 0x4, 0x5, 0x6, 0x7, 0x0, 0x1, 0x2, 0x3],
      \ [0xD, 0xC, 0xF, 0xE, 0x9, 0x8, 0xB, 0xA, 0x5, 0x4, 0x7, 0x6, 0x1, 0x0, 0x3, 0x2],
      \ [0xE, 0xF, 0xC, 0xD, 0xA, 0xB, 0x8, 0x9, 0x6, 0x7, 0x4, 0x5, 0x2, 0x3, 0x0, 0x1],
      \ [0xF, 0xE, 0xD, 0xC, 0xB, 0xA, 0x9, 0x8, 0x7, 0x6, 0x5, 0x4, 0x3, 0x2, 0x1, 0x0]
      \ ]

function! s:bitwise_xor(a, b)
  let a = a:a < 0 ? a:a - 0x80000000 : a:a
  let b = a:b < 0 ? a:b - 0x80000000 : a:b
  let r = 0
  let n = 1
  while a || b
    let r += s:xor[a % 0x10][b % 0x10] * n
    let a = a / 0x10
    let b = b / 0x10
    let n = n * 0x10
  endwhile
  if (a:a < 0) != (a:b < 0)
    let r += 0x80000000
  endif
  return r
endfunction

