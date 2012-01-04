let s:save_cpo = &cpo
set cpo&vim

let s:utf8len = [
\ 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
\ 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
\ 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
\ 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
\ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
\ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
\ 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
\ 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,6,6,0,0,
\]

function! ucs#byte2nr(byte)
  let p = a:byte
  let n0 = char2nr(p[0])
  if n0 < 0x80
    return n0
  endif
  let l = s:utf8len[n0]
  let n1 = char2nr(p[1])
  if l > 1 && bit#and(n1, 0xc0) == 0x80
    if l == 2
      return bit#shift(bit#and(n0, 0x1f), 6) + bit#and(n1, 0x3f)
    endif
    let n2 = char2nr(p[2])
    if bit#and(n2, 0xc0) == 0x80
      if l == 3
        return bit#shift(bit#and(n0, 0x0f), 12) + bit#shift(bit#and(n1, 0x3f), 6) + bit#and(n2, 0x3f)
      endif
      let n3 = char2nr(p[3])
      if bit#and(n3, 0xc0) == 0x80
        if l == 4
          return bit#shift(bit#and(n0, 0x07), 18) + bit#shift(bit#and(n1, 0x3f), 12) + bit#shift(bit#and(n2, 0x3f), 6) + bit#and(n3, 0x3f)
        endif
        let n4 = char2nr(p[4])
        if bit#and(n4, 0xc0) == 0x80
          if (l == 5)
            return bit#shift(bit#and(n0, 0x03), 24) + bit#shift(bit#and(n1, 0x3f), 18) + bit#shift(bit#and(n2, 0x3f), 12) + bit#shift(bit#and(n3 & 0x3f), 6) + bit#and(n4, 0x3f)
          endif
          let n5 = char2nr(p[5])
          if bit#and(n5, 0xc0) == 0x80 && l == 6
            return bit#shift(bit#and(n0, 0x01), 30) + bit#shift(bit#and(n1, 0x3f), 24) + bit#shift(bit#and(n2, 0x3f), 18) + bit#shift(bit#and(n3, 0x3f), 12) + bit#shift(bit#and(n4, 0x3f), 6) + bit#and(n5, 0x3f)
          endif
        endif
      endif
    endif
  endif
  return n0
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
