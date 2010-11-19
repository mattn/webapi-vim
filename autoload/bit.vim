let s:save_cpo = &cpo
set cpo&vim

function! bit#dec2bin(v)
  let v = a:v
  if v == 0 | return 0 | endif
  let ret = ""
  while v > 0
    let i = v % 2
    let ret = i . ret
    let v = v / 2
  endwhile
  return ret
endfunction

function! bit#bin2dec(v)
  let v = a:v
  if len(v) == 0 | return 0 | endif
  let i = 1
  let ret = ""
  for n in reverse(split(v, '\zs'))
    if n == 1
      let ret = ret + i
    endif
    let i = i * 2
  endfor
  return ret
endfunction

function! bit#or(a,b)
  let a = bit#dec2bin(a:a)
  let b = bit#dec2bin(a:b)
  return bit#bin2dec(tr((a + b), '2', '1'))
endfunction

function! bit#and(a,b)
  let a = bit#dec2bin(a:a)
  let b = bit#dec2bin(a:b)
  return bit#bin2dec(tr((a + b), '21', '10'))
endfunction

function! bit#shift(a,b)
  let a = bit#dec2bin(a:a)
  let a = repeat('0', 32-len(a)) . a
  if a:b < 0
    let a = (repeat('0', -a:b) . a[: a:b-1])[-32:]
  elseif a:b > 0
    let a = (a . repeat('0', a:b))[-32:]
  endif
  return bit#bin2dec(a)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
