" sha1 digest calculator
" This is a port of rfc3174 sha1 function.
" http://www.ietf.org/rfc/rfc3174.txt
" Last Change:  2010-02-13
" Maintainer:   Yukihiro Nakadaira <yukihiro.nakadaira@gmail.com>
" Original Copyright:
" Copyright (C) The Internet Society (2001).  All Rights Reserved.
"
" This document and translations of it may be copied and furnished to
" others, and derivative works that comment on or otherwise explain it
" or assist in its implementation may be prepared, copied, published
" and distributed, in whole or in part, without restriction of any
" kind, provided that the above copyright notice and this paragraph are
" included on all such copies and derivative works.  However, this
" document itself may not be modified in any way, such as by removing
" the copyright notice or references to the Internet Society or other
" Internet organizations, except as needed for the purpose of
" developing Internet standards in which case the procedures for
" copyrights defined in the Internet Standards process must be
" followed, or as required to translate it into languages other than
" English.
"
" The limited permissions granted above are perpetual and will not be
" revoked by the Internet Society or its successors or assigns.
"
" This document and the information contained herein is provided on an
" "AS IS" basis and THE INTERNET SOCIETY AND THE INTERNET ENGINEERING
" TASK FORCE DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
" BUT NOT LIMITED TO ANY WARRANTY THAT THE USE OF THE INFORMATION
" HEREIN WILL NOT INFRINGE ANY RIGHTS OR ANY IMPLIED WARRANTIES OF
" MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

let s:save_cpo = &cpo
set cpo&vim

function! webapi#sha1#sha1(str) abort
  return s:SHA1Digest(s:str2bytes(a:str))
endfunction

function! webapi#sha1#sha1bin(bin) abort
  return s:SHA1Digest(a:bin)
endfunction

function! webapi#sha1#test() abort
  call s:main()
endfunction

function! s:SHA1Digest(bytes) abort
  let sha = deepcopy(s:SHA1Context, 1)
  let Message_Digest = repeat([0], 20)

  let err = s:SHA1Reset(sha)
  if err
    throw printf("SHA1Reset Error %d", err)
  endif

  let err = s:SHA1Input(sha, a:bytes)
  if err
    throw printf("SHA1Input Error %d", err)
  endif

  let err = s:SHA1Result(sha, Message_Digest)
  if err
    throw printf("SHA1Result Error %d", err)
  endif

  return join(map(Message_Digest, 'printf("%02x", v:val)'), '')
endfunction

"
" sha1.h
"
" Description:
"     This is the header file for code which implements the Secure
"     Hashing Algorithm 1 as defined in FIPS PUB 180-1 published
"     April 17, 1995.
"
"     Many of the variable names in this code, especially the
"     single character names, were used because those were the names
"     used in the publication.
"
"     Please read the file sha1.c for more information.

"
" If you do not have the ISO standard stdint.h header file, then you
" must typdef the following:
"    name              meaning
"  uint32_t         unsigned 32 bit integer
"  uint8_t          unsigned 8 bit integer (i.e., unsigned char)
"  int_least16_t    integer of >= 16 bits
"
"

" enum
let s:shaSuccess = 0
let s:shaNull = 1         " Null pointer parameter
let s:shaInputTooLong = 2 " input data too long
let s:shaStateError = 3   " called Input after Result

" define
let s:SHA1HashSize = 20

"
"  This structure will hold context information for the SHA-1
"  hashing operation
"
" struct
let s:SHA1Context = {}
" uint32_t Intermediate_Hash[SHA1HashSize/4]; /* Message Digest  */
let s:SHA1Context.Intermediate_Hash = repeat([0], s:SHA1HashSize / 4)
" uint32_t Length_Low;            /* Message length in bits      */
let s:SHA1Context.Length_Low = 0
" uint32_t Length_High;           /* Message length in bits      */
let s:SHA1Context.Length_High = 0
"                                 /* Index into message block array   */
" int_least16_t Message_Block_Index;
let s:SHA1Context.Message_Block_Index = 0
" uint8_t Message_Block[64];      /* 512-bit message blocks      */
let s:SHA1Context.Message_Block = repeat([0], 64)
" int Computed;                   /* Is the digest computed?         */
let s:SHA1Context.Computed = 0
" int Corrupted;                  /* Is the message digest corrupted? */
let s:SHA1Context.Corrupted = 0

"
"  sha1.c
"
"  Description:
"      This file implements the Secure Hashing Algorithm 1 as
"      defined in FIPS PUB 180-1 published April 17, 1995.
"
"      The SHA-1, produces a 160-bit message digest for a given
"      data stream.  It should take about 2**n steps to find a
"      message with the same digest as a given message and
"      2**(n/2) to find any two messages with the same digest,
"      when n is the digest size in bits.  Therefore, this
"      algorithm can serve as a means of providing a
"      "fingerprint" for a message.
"
"  Portability Issues:
"      SHA-1 is defined in terms of 32-bit "words".  This code
"      uses <stdint.h> (included via "sha1.h" to define 32 and 8
"      bit unsigned integer types.  If your C compiler does not
"      support 32 bit unsigned integers, this code is not
"      appropriate.
"
"  Caveats:
"      SHA-1 is designed to work with messages less than 2^64 bits
"      long.  Although SHA-1 allows a message digest to be generated
"      for messages of any number of bits less than 2^64, this
"      implementation only works with messages with a length that is
"      a multiple of the size of an 8-bit character.
"
"

"
"  Define the SHA1 circular left shift macro
"
"#define SHA1CircularShift(bits,word) \
"                (((word) << (bits)) | ((word) >> (32-(bits))))
function s:SHA1CircularShift(bits, word) abort
  return or(s:bitwise_lshift(a:word, a:bits), s:bitwise_rshift(a:word, 32 - a:bits))
endfunction

"
"  SHA1Reset
"
"  Description:
"      This function will initialize the SHA1Context in preparation
"      for computing a new SHA1 message digest.
"
"  Parameters:
"      context: [in/out]
"          The context to reset.
"
"  Returns:
"      sha Error Code.
"
"
" int SHA1Reset(SHA1Context *context)
function s:SHA1Reset(context) abort
  if empty(a:context)
    return s:shaNull
  endif

  let a:context.Length_Low            = 0
  let a:context.Length_High           = 0
  let a:context.Message_Block_Index   = 0

  let a:context.Intermediate_Hash[0]  = 0x67452301
  let a:context.Intermediate_Hash[1]  = 0xEFCDAB89
  let a:context.Intermediate_Hash[2]  = 0x98BADCFE
  let a:context.Intermediate_Hash[3]  = 0x10325476
  let a:context.Intermediate_Hash[4]  = 0xC3D2E1F0

  let a:context.Computed  = 0
  let a:context.Corrupted = 0

  return s:shaSuccess
endfunction

"
"  SHA1Result
"
"  Description:
"      This function will return the 160-bit message digest into the
"      Message_Digest array  provided by the caller.
"      NOTE: The first octet of hash is stored in the 0th element,
"            the last octet of hash in the 19th element.
"
"  Parameters:
"      context: [in/out]
"          The context to use to calculate the SHA-1 hash.
"      Message_Digest: [out]
"          Where the digest is returned.
"
"  Returns:
"      sha Error Code.
"
"
"int SHA1Result( SHA1Context *context,
"                uint8_t Message_Digest[SHA1HashSize])
function s:SHA1Result(context, Message_Digest) abort
  if empty(a:context) || empty(a:Message_Digest)
    return s:shaNull
  endif

  if a:context.Corrupted
    return a:context.Corrupted
  endif

  if !a:context.Computed
    call s:SHA1PadMessage(a:context)
    for i in range(64)
      " message may be sensitive, clear it out 
      let a:context.Message_Block[i] = 0
    endfor
    let a:context.Length_Low = 0      " and clear length
    let a:context.Length_High = 0
    let a:context.Computed = 1
  endif

  for i in range(s:SHA1HashSize)
    let a:Message_Digest[i] = s:uint8(
          \   s:bitwise_rshift(
          \     a:context.Intermediate_Hash[s:bitwise_rshift(i, 2)],
          \     8 * (3 - and(i, 0x03))
          \   )
          \ )
  endfor

  return s:shaSuccess
endfunction

"
"  SHA1Input
"
"  Description:
"      This function accepts an array of octets as the next portion
"      of the message.
"
"  Parameters:
"      context: [in/out]
"          The SHA context to update
"      message_array: [in]
"          An array of characters representing the next portion of
"          the message.
"      length: [in]
"          The length of the message in message_array
"
"  Returns:
"      sha Error Code.
"
"
"int SHA1Input(    SHA1Context    *context,
"                  const uint8_t  *message_array,
"                  unsigned       length)
function s:SHA1Input(context, message_array) abort
  if !len(a:message_array)
    return s:shaSuccess
  endif

  if empty(a:context) || empty(a:message_array)
    return s:shaNull
  endif

  if a:context.Computed
    let a:context.Corrupted = s:shaStateError
    return s:shaStateError
  endif

  if a:context.Corrupted
    return a:context.Corrupted
  endif

  for x in a:message_array
    if a:context.Corrupted
      break
    endif
    let a:context.Message_Block[a:context.Message_Block_Index] = and(x, 0xFF)
    let a:context.Message_Block_Index += 1

    let a:context.Length_Low += 8
    if a:context.Length_Low == 0
      let a:context.Length_High += 1
      if a:context.Length_High == 0
        " Message is too long
        let a:context.Corrupted = 1
      endif
    endif

    if a:context.Message_Block_Index == 64
      call s:SHA1ProcessMessageBlock(a:context)
    endif
  endfor

  return s:shaSuccess
endfunction

"
"  SHA1ProcessMessageBlock
"
"  Description:
"      This function will process the next 512 bits of the message
"      stored in the Message_Block array.
"
"  Parameters:
"      None.
"
"  Returns:
"      Nothing.
"
"  Comments:
"      Many of the variable names in this code, especially the
"      single character names, were used because those were the
"      names used in the publication.
"
"
"
" void SHA1ProcessMessageBlock(SHA1Context *context)
function s:SHA1ProcessMessageBlock(context) abort
  " Constants defined in SHA-1
  let K = [
        \ 0x5A827999,
        \ 0x6ED9EBA1,
        \ 0x8F1BBCDC,
        \ 0xCA62C1D6
        \ ]
  let t = 0                         " Loop counter
  let temp = 0                      " Temporary word value
  let W = repeat([0], 80)           " Word sequence
  let [A, B, C, D, E] = [0, 0, 0, 0, 0] " Word buffers

  "
  "  Initialize the first 16 words in the array W
  "
  for t in range(16)
    let W[t] = s:bitwise_lshift(a:context.Message_Block[t * 4], 24)
    let W[t] = or(W[t], s:bitwise_lshift(a:context.Message_Block[t * 4 + 1], 16))
    let W[t] = or(W[t], s:bitwise_lshift(a:context.Message_Block[t * 4 + 2], 8))
    let W[t] = or(W[t], a:context.Message_Block[t * 4 + 3])
  endfor

  for t in range(16, 79)
    let W[t] = s:SHA1CircularShift(1, xor(xor(xor(W[t-3], W[t-8]), W[t-14]), W[t-16]))
  endfor

  let A = a:context.Intermediate_Hash[0]
  let B = a:context.Intermediate_Hash[1]
  let C = a:context.Intermediate_Hash[2]
  let D = a:context.Intermediate_Hash[3]
  let E = a:context.Intermediate_Hash[4]

  for t in range(20)
    let temp = s:SHA1CircularShift(5,A) +
          \ or(and(B, C), and(s:bitwise_not(B), D)) +
          \ E + W[t] + K[0]
    let E = D
    let D = C
    let C = s:SHA1CircularShift(30,B)
    let B = A
    let A = temp
  endfor

  for t in range(20, 39)
    let temp = s:SHA1CircularShift(5,A) + xor(xor(B, C), D) + E + W[t] + K[1]
    let E = D
    let D = C
    let C = s:SHA1CircularShift(30,B)
    let B = A
    let A = temp
  endfor

  for t in range(40, 59)
    let temp = s:SHA1CircularShift(5,A) +
          \ or(or(and(B, C), and(B, D)), and(C, D)) +
          \ E + W[t] + K[2]
    let E = D
    let D = C
    let C = s:SHA1CircularShift(30,B)
    let B = A
    let A = temp
  endfor

  for t in range(60, 79)
    let temp = s:SHA1CircularShift(5,A) +
          \ xor(xor(B, C), D) + E + W[t] + K[3]
    let E = D
    let D = C
    let C = s:SHA1CircularShift(30,B)
    let B = A
    let A = temp
  endfor

  let a:context.Intermediate_Hash[0] += A
  let a:context.Intermediate_Hash[1] += B
  let a:context.Intermediate_Hash[2] += C
  let a:context.Intermediate_Hash[3] += D
  let a:context.Intermediate_Hash[4] += E

  let a:context.Message_Block_Index = 0
endfunction


"
"  SHA1PadMessage
"
"  Description:
"      According to the standard, the message must be padded to an even
"      512 bits.  The first padding bit must be a '1'.  The last 64
"      bits represent the length of the original message.  All bits in
"      between should be 0.  This function will pad the message
"      according to those rules by filling the Message_Block array
"      accordingly.  It will also call the ProcessMessageBlock function
"      provided appropriately.  When it returns, it can be assumed that
"      the message digest has been computed.
"
"  Parameters:
"      context: [in/out]
"          The context to pad
"      ProcessMessageBlock: [in]
"          The appropriate SHA*ProcessMessageBlock function
"  Returns:
"      Nothing.
"
"
" void SHA1PadMessage(SHA1Context *context)
function s:SHA1PadMessage(context) abort
  "
  "  Check to see if the current message block is too small to hold
  "  the initial padding bits and length.  If so, we will pad the
  "  block, process it, and then continue padding into a second
  "  block.
  "
  if a:context.Message_Block_Index > 55
    let a:context.Message_Block[a:context.Message_Block_Index] = 0x80
    let a:context.Message_Block_Index += 1
    while a:context.Message_Block_Index < 64
      let a:context.Message_Block[a:context.Message_Block_Index] = 0
      let a:context.Message_Block_Index += 1
    endwhile

    call s:SHA1ProcessMessageBlock(a:context)

    while a:context.Message_Block_Index < 56
      let a:context.Message_Block[a:context.Message_Block_Index] = 0
      let a:context.Message_Block_Index += 1
    endwhile
  else
    let a:context.Message_Block[a:context.Message_Block_Index] = 0x80
    let a:context.Message_Block_Index += 1
    while a:context.Message_Block_Index < 56
      let a:context.Message_Block[a:context.Message_Block_Index] = 0
      let a:context.Message_Block_Index += 1
    endwhile
  endif

  "
  "  Store the message length as the last 8 octets
  "
  let a:context.Message_Block[56] = s:uint8(s:bitwise_rshift(a:context.Length_High, 24))
  let a:context.Message_Block[57] = s:uint8(s:bitwise_rshift(a:context.Length_High, 16))
  let a:context.Message_Block[58] = s:uint8(s:bitwise_rshift(a:context.Length_High, 8))
  let a:context.Message_Block[59] = s:uint8(a:context.Length_High)
  let a:context.Message_Block[60] = s:uint8(s:bitwise_rshift(a:context.Length_Low, 24))
  let a:context.Message_Block[61] = s:uint8(s:bitwise_rshift(a:context.Length_Low, 16))
  let a:context.Message_Block[62] = s:uint8(s:bitwise_rshift(a:context.Length_Low, 8))
  let a:context.Message_Block[63] = s:uint8(a:context.Length_Low)

  call s:SHA1ProcessMessageBlock(a:context)
endfunction

"
"  sha1test.c
"
"  Description:
"      This file will exercise the SHA-1 code performing the three
"      tests documented in FIPS PUB 180-1 plus one which calls
"      SHA1Input with an exact multiple of 512 bits, plus a few
"      error test checks.
"
"  Portability Issues:
"      None.
"
"

"
"  Define patterns for testing
"
let s:TEST1   = "abc"
let s:TEST2a  = "abcdbcdecdefdefgefghfghighijhi"
let s:TEST2b  = "jkijkljklmklmnlmnomnopnopq"
let s:TEST2   = s:TEST2a . s:TEST2b
let s:TEST3   = "a"
let s:TEST4a  = "01234567012345670123456701234567"
let s:TEST4b  = "01234567012345670123456701234567"
    " an exact multiple of 512 bits
let s:TEST4   = s:TEST4a . s:TEST4b
let s:testarray = [
      \ s:TEST1,
      \ s:TEST2,
      \ s:TEST3,
      \ s:TEST4
      \ ]
let s:repeatcount = [1, 1, 1000000, 10]
let s:resultarray = [
      \ "A9 99 3E 36 47 06 81 6A BA 3E 25 71 78 50 C2 6C 9C D0 D8 9D",
      \ "84 98 3E 44 1C 3B D2 6E BA AE 4A A1 F9 51 29 E5 E5 46 70 F1",
      \ "34 AA 97 3C D4 C4 DA A4 F6 1E EB 2B DB AD 27 31 65 34 01 6F",
      \ "DE A3 56 A2 CD DD 90 C7 A7 EC ED C5 EB B5 63 93 4F 46 04 52"
      \ ]

function s:main() abort
  let sha = deepcopy(s:SHA1Context, 1)
  let Message_Digest = repeat([0], 20)

  "
  "  Perform SHA-1 tests
  "
  for j in range(len(s:testarray))
    if j == 2
      echo "Test 3 will take about 1 hour.  Press CTRL-C to skip."
    endif
    echo ""
    echo printf("Test %d: %d, '%s'",
          \ j+1,
          \ s:repeatcount[j],
          \ s:testarray[j])

    let err = s:SHA1Reset(sha)
    if err
      echo printf("SHA1Reset Error %d.", err )
      break       " out of for j loop
    endif

    try
      for i in range(s:repeatcount[j])
        let err = s:SHA1Input(sha, s:str2bytes(s:testarray[j]))
        if err
          echo printf("SHA1Input Error %d.", err )
          break     " out of for i loop */
        endif
      endfor
    catch /^Vim:Interrupt$/
      echo "Skip ..."
      while getchar(0) | endwhile
      continue
    endtry

    let err = s:SHA1Result(sha, Message_Digest)
    if err
      echo printf("SHA1Result Error %d, could not compute message digest.", err)
    else
      echo "\t"
      for i in range(20)
        echon printf("%02X ", Message_Digest[i])
      endfor
      echo ""
    endif
    echo "Should match:"
    echo printf("\t%s", s:resultarray[j])
  endfor

  " Test some error returns
  let err = s:SHA1Input(sha, s:str2bytes(s:testarray[1][0:0]))
  echo printf("\nError %d. Should be %d.", err, s:shaStateError)
  let err = s:SHA1Reset(0)
  echo printf("\nError %d. Should be %d.", err, s:shaNull)
endfunction



"---------------------------------------------------------------------
" misc
function! s:str2bytes(str) abort
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:cmp(a, b) abort
  let a = printf("%08x", a:a)
  let b = printf("%08x", a:b)
  return a < b ? -1 : a > b ? 1 : 0
endfunction

function! s:uint8(n) abort
  return and(a:n, 0xFF)
endfunction

let s:k = [
      \ 0x1,        0x2,        0x4,        0x8,
      \ 0x10,       0x20,       0x40,       0x80,
      \ 0x100,      0x200,      0x400,      0x800,
      \ 0x1000,     0x2000,     0x4000,     0x8000,
      \ 0x10000,    0x20000,    0x40000,    0x80000,
      \ 0x100000,   0x200000,   0x400000,   0x800000,
      \ 0x1000000,  0x2000000,  0x4000000,  0x8000000,
      \ 0x10000000, 0x20000000, 0x40000000, 0x80000000,
      \ ]

function! s:bitwise_lshift(a, n) abort
  return and(a:a * s:k[a:n], 0xFFFFFFFF)
endfunction

function! s:bitwise_rshift(a, n) abort
  let a = and(a:a, 0xFFFFFFFF)
  let a = a < 0 ? a - 0x80000000 : a
  let a = a / s:k[a:n]
  if a:a < 0
    let a += 0x40000000 / s:k[a:n - 1]
  endif
  return and(a, 0xFFFFFFFF)
endfunction

function! s:bitwise_not(a) abort
  return xor(a:a, 0xFFFFFFFF)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
