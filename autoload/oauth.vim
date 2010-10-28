" oauth
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc5849.txt

let s:save_cpo = &cpo
set cpo&vim

function! oauth#request_token(url, ctx, ...)
  let params = a:0 > 0 ? a:000[0] : {}
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:ctx.consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_version"] = "1.0"
  for key in keys(params)
    let query[key] = params[key]
  endfor
  let query_string = "POST&"
  let query_string .= http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= http#encodeURI(http#encodeURI(query))
  let hmacsha1 = hmac#sha1(http#encodeURI(a:ctx.consumer_secret) . "&", query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  let res = http#post(a:url, query, {})
  let a:ctx.request_token = http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token='")[0], '^[^=]*=', '', ''))
  let a:ctx.request_token_secret = http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token_secret='")[0], '^[^=]*=', '', ''))
  return a:ctx
endfunction

function! oauth#access_token(url, ctx, ...)
  let params = a:0 > 0 ? a:000[0] : {}
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:ctx.consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_token"] = a:ctx.request_token
  let query["oauth_token_secret"] = a:ctx.request_token_secret
  let query["oauth_version"] = "1.0"
  for key in keys(params)
    let query[key] = params[key]
  endfor
  let query_string = "POST&"
  let query_string .= http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= http#encodeURI(http#encodeURI(query))
  let hmacsha1 = hmac#sha1(http#encodeURI(a:ctx.consumer_secret) . "&" . http#encodeURI(a:ctx.request_token_secret), query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  let res = http#post(a:url, query, {})
  let a:ctx.access_token = http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token='")[0], '^[^=]*=', '', ''))
  let a:ctx.access_token_secret = http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token_secret='")[0], '^[^=]*=', '', ''))
  return a:ctx
endfunction

function! oauth#get(url, ctx, ...)
  let params = a:0 > 0 ? a:000[0] : {}
  let getdata = a:0 > 1 ? a:000[1] : {}
  let headdata = a:0 > 2 ? a:000[2] : {}
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:ctx.consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "GET"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_token"] = a:ctx.access_token
  let query["oauth_version"] = "1.0"
  for key in keys(params)
    let query[key] = params[key]
  endfor
  let query_string = query["oauth_request_method"] . "&"
  let query_string .= http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= http#encodeURI(http#encodeURI(query))
  let hmacsha1 = hmac#sha1(http#encodeURI(a:ctx.consumer_secret) . "&" . http#encodeURI(a:ctx.access_token_secret), query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  let auth = 'OAuth '
  for key in sort(keys(query))
    let auth .= key . '="' . http#encodeURI(query[key]) . '", '
  endfor
  let auth = auth[:-3]
  let headdata["Authorization"] = auth
  let res = http#get(a:url, getdata, headdata)
  return res
endfunction

function! oauth#post(url, ctx, ...)
  let params = a:0 > 0 ? a:000[0] : {}
  let postdata = a:0 > 1 ? a:000[1] : {}
  let headdata = a:0 > 2 ? a:000[2] : {}
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:ctx.consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_token"] = a:ctx.access_token
  let query["oauth_version"] = "1.0"
  if type(params) == 4
    for key in keys(params)
      let query[key] = params[key]
    endfor
  endif
  if type(postdata) == 4
    for key in keys(postdata)
      let query[key] = postdata[key]
    endfor
  endif
  let query_string = query["oauth_request_method"] . "&"
  let query_string .= http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= http#encodeURI(http#encodeURI(query))
  let hmacsha1 = hmac#sha1(http#encodeURI(a:ctx.consumer_secret) . "&" . http#encodeURI(a:ctx.access_token_secret), query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  if type(postdata) == 4
    for key in keys(postdata)
      call remove(query, key)
    endfor
  endif
  let auth = 'OAuth '
  for key in sort(keys(query))
    let auth .= http#escape(key) . '="' . http#escape(query[key]) . '",'
  endfor
  let auth = auth[:-2]
  let headdata["Authorization"] = auth
  let res = http#post(a:url, postdata, headdata)
  return res
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
