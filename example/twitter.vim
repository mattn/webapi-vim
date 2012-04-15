set rtp+=webapi-vim

let ctx = {}
let configfile = expand('~/.twitter-vim')
if filereadable(configfile)
  let ctx = eval(join(readfile(configfile), ""))
else
  let ctx.consumer_key = input("consumer_key:")
  let ctx.consumer_secret = input("consumer_secret:")

  let request_token_url = "https://twitter.com/oauth/request_token"
  let auth_url =  "https://twitter.com/oauth/authorize"
  let access_token_url = "https://api.twitter.com/oauth/access_token"

  let ctx = webapi#oauth#request_token(request_token_url, ctx)
  if has("win32") || has("win64")
    exe "!start rundll32 url.dll,FileProtocolHandler ".auth_url."?oauth_token=".ctx.request_token
  else
    call system("xdg-open '".auth_url."?oauth_token=".ctx.request_token."'")
  endif
  let pin = input("PIN:")
  let ctx = webapi#oauth#access_token(access_token_url, ctx, {"oauth_verifier": pin})
  call writefile([string(ctx)], configfile)
endif

let post_url = "https://api.twitter.com/1/statuses/update.xml"
let status = "tweeeeeeeeeeeeeet"
let ret = webapi#oauth#post(post_url, ctx, {}, {"status": status})
echo ret
