" metaweblog
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc3529.txt

let s:save_cpo = &cpo
set cpo&vim

let s:template = {"uri" : ""}

function! s:template.newPost(blogid, username, password, content, publish) dict
  return webapi#xmlrpc#call(self.uri, 'metaWeblog.newPost', [a:blogid, a:username, a:password, a:content, a:publish])
endfunction

function! s:template.editPost(postid, username, password, content, publish) dict
  return webapi#xmlrpc#call(self.uri, 'metaWeblog.editPost', [a:postid, a:username, a:password, a:content, a:publish])
endfunction

function! s:template.getPost(postid, username, password) dict
  return webapi#xmlrpc#call(self.uri, 'metaWeblog.getPost', [a:postid, a:username, a:password])
endfunction

function! s:template.getRecentPosts(blogid, username, password, numberOfPosts) dict
  return webapi#xmlrpc#call(self.uri, 'metaWeblog.getRecentPosts', [a:blogid, a:username, a:password, a:numberOfPosts])
endfunction

function! s:template.deletePost(appkey, postid, username, password, ...) dict
  return webapi#xmlrpc#call(self.uri, 'blogger.deletePost', [a:apikey, a:postid, a:username, a:password])
endfunction

function! s:template.newMediaObject(blogid, username, password, file) dict
  return webapi#xmlrpc#call(self.uri, 'metaWeblog.newMediaObject', [a:blogid, a:username, a:password, a:file])
endfunction

function! webapi#metaWeblog#proxy(uri)
  let ctx = deepcopy(s:template)
  let ctx.uri = a:uri
  return ctx
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
