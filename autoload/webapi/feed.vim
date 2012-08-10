let s:save_cpo = &cpo
set cpo&vim

function! s:attr(node, name)
  let n = a:node.childNode(a:name)
  if empty(n)
    return ""
  endif
  return n.value()
endfunction

function! webapi#feed#parseURL(url)
  let dom = webapi#xml#parseURL(a:url)
  let items = []
  if dom.name == 'rss'
    let channel = dom.childNode('channel')
    for item in channel.childNodes('item')
      call add(items, {
      \  "title": s:attr(item, 'title'),
      \  "link": s:attr(item, 'link'),
      \  "content": s:attr(item, 'description'),
      \  "id": s:attr(item, 'guid'),
      \  "date": s:attr(item, 'pubDate'),
      \})
    endfor
  elseif dom.name == 'rdf:RDF'
    for item in dom.childNodes('item')
      call add(items, {
      \  "title": s:attr(item, 'title'),
      \  "link": s:attr(item, 'link'),
      \  "content": s:attr(item, 'description'),
      \  "id": s:attr(item, 'guid'),
      \  "date": s:attr(item, 'dc:date'),
      \})
    endfor
  elseif dom.name == 'feed'
    for item in dom.childNodes('entry')
      call add(items, {
      \  "title": s:attr(item, 'title'),
      \  "link": item.childNode('link').attr['href'],
      \  "content": s:attr(item, 'content'),
      \  "id": s:attr(item, 'id'),
      \  "date": s:attr(item, 'update'),
      \})
    endfor
  endif
  return items
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
