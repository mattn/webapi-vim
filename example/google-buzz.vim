set rtp+=.

let ctx = {}
let configfile = expand('~/.google-buzz-vim')
if filereadable(configfile)
  let ctx = eval(join(readfile(configfile), ""))
else
  let ctx.consumer_key = input("consumer_key:")
  let ctx.consumer_secret = input("consumer_secret:")
  let ctx.domain = input("domain:")
  let ctx.callback = input("callback:")

  let request_token_url = "https://www.google.com/accounts/OAuthGetRequestToken"
  let auth_url = "https://www.google.com/accounts/OAuthAuthorizeToken"
  let access_token_url = "https://www.google.com/accounts/OAuthGetAccessToken"

  let ctx = webapi#oauth#request_token(request_token_url, ctx, {"scope": "https://www.googleapis.com/auth/buzz", "oauth_callback": ctx.callback})
  if has("win32") || has("win64")
    exe "!start rundll32 url.dll,FileProtocolHandler ".auth_url."?oauth_token=".ctx.request_token."&domain=".ctx.domain."&scope=https://www.googleapis.com/auth/buzz"
  else
    call system("xdg-open '".auth_url."?oauth_token=".ctx.request_token. "&domain=".ctx.domain."&scope=https://www.googleapis.com/auth/buzz'")
  endif
  let verifier = input("VERIFIER:")
  let ctx = webapi#oauth#access_token(access_token_url, ctx, {"oauth_verifier": verifier})
  call writefile([string(ctx)], configfile)
endif

let post_url = "https://www.googleapis.com/buzz/v1/activities/@me/@self"
let data = ''
\.'<entry xmlns:activity="http://activitystrea.ms/spec/1.0/"'
\.' xmlns:poco="http://portablecontacts.net/ns/1.0"'
\.' xmlns:georss="http://www.georss.org/georss"'
\.' xmlns:buzz="http://schemas.google.com/buzz/2010">'
\.'  <activity:object>'
\.'    <activity:object-type>http://activitystrea.ms/schema/1.0/note</activity:object-type>'
\.'    <content>ばず! ばず!</content>'
\.'  </activity:object>'
\.'</entry>'
let ret = webapi#oauth#post(post_url, ctx, {}, data, {"Content-Type": "application/atom+xml", "GData-Version": "2.0"})
echo ret
