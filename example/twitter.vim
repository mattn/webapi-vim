set rtp+=webapi-vim

function! s:tweet(status) abort
  let ctx = {}
  let configfile = expand('~/.twitter-vim')
  if filereadable(configfile)
    let ctx = eval(join(readfile(configfile), ''))
  else
    let ctx.consumer_key = input('consumer_key:')
	if ctx.consumer_key == ''
      return
    endif
    let ctx.consumer_secret = input('consumer_secret:')
	if ctx.consumer_secret == ''
      return
    endif

    let request_token_url = 'https://api.twitter.com/oauth/request_token'
    let auth_url =  'https://twitter.com/oauth/authorize'
    let access_token_url = 'https://api.twitter.com/oauth/access_token'

    let ctx = webapi#oauth#request_token(request_token_url, ctx, {'oauth_callback': 'oob', 'dummy': 1})
    if type(ctx) != type({})
      echomsg ctx.response.content
      return
    endif
    if has('win32') || has('win64')
      exe printf('!start rundll32 url.dll,FileProtocolHandler %s?oauth_token=%s', auth_url, .ctx.request_token)
    else
      call system(printf("xdg-open '%s?oauth_token=%s'", auth_url, ctx.request_token))
    endif
    let pin = input('PIN:')
    let ctx = webapi#oauth#access_token(access_token_url, ctx, {'oauth_verifier': pin})
    call writefile([string(ctx)], configfile)
  endif

  let post_url = 'https://api.twitter.com/1.1/statuses/update.json'
  let ret = webapi#oauth#post(post_url, ctx, {}, {'status': a:status})
  return ret
endfunction

call s:tweet('tweeeeeeeeet')
