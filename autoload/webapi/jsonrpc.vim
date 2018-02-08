" jsonrpc
" Last Change: 2012-03-08
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc4627.txt

let s:save_cpo = &cpo
set cpo&vim

function! webapi#jsonrpc#call(uri, func, args, ...) abort
  let opts = a:0 > 0 ? a:000[0] : {}
  let data = webapi#json#encode({
  \ 'jsonrpc': '2.0',
  \ 'method':  a:func,
  \ 'params':  a:args,
  \ 'id': has_key(opts, 'id') ? opts['id'] : 0,
  \})
  let res = webapi#http#post(a:uri, data, {"Content-Type": "application/json"})
  let obj = webapi#json#decode(res.content)
  if has_key(obj, 'error')
    if type(obj.error) == 0 && obj.error != 0
      throw obj.error
    elseif type(obj.error) == 1 && obj.error != ''
      throw obj.error
    elseif type(obj.error) == 2 && string(obj.error) != "function('webapi#json#null')"
      throw obj.error
    endif
  endif
  if has_key(obj, 'result')
    return obj.result
  endif
  throw "Parse Error"
endfunction

function! webapi#jsonrpc#wrap(contexts) abort
  let api = {}
  for context in a:contexts
    let target = api
    let namespaces = split(context.name, '\.')[:-2]
    if len(namespaces) > 0
      for ns in namespaces
        if !has_key(target, ns)
          let target[ns] = {".uri": context.uri}
        endif
        let target = target[ns]
      endfor
    endif
    if !has_key(context, 'argnames')
      let context['argnames'] = ['args']
      let arglist = 'a:args'
    else
      if len(context.argnames) && context.argnames[-1] == '...'
        let arglist = '[' . join(map(copy(context.argnames[:-2]),'"a:".v:val'),',') . ']+a:000'
      else
        let arglist = '[' . join(map(copy(context.argnames),'"a:".v:val'),',') . ']'
      endif
    endif
    if has_key(context, 'alias')
      exe "function api.".context.alias."(".join(context.argnames,",").") dict\n"
      \.  "  return webapi#jsonrpc#call(self['.uri'], '".context.name."', ".arglist.")\n"
      \.  "endfunction\n"
    else
      exe "function api.".context.name."(".join(context.argnames,",").") dict\n"
      \.  "  return webapi#jsonrpc#call('".context.uri."', '".context.name."', ".arglist.")\n"
      \.  "endfunction\n"
    endif
  endfor
  return api
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
