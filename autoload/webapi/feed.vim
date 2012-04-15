let s:save_cpo = &cpo
set cpo&vim

function! webapi#feed#parseURL(url)
  let dom = webapi#xml#parse(webapi#http#get(a:url).content)
  let items = []
  if dom.name == 'rss'
    let channel = dom.childNode('channel')
    for item in channel.childNodes('item')
      call add(items, {
      \  "title": item.childNode('title').value(),
      \  "link": item.childNode('link').value(),
      \  "content": item.childNode('description').value(),
      \  "id": item.childNode('guid').value(),
      \  "date": item.childNode('pubDate').value(),
      \})
    endfor
  elseif dom.name == 'rdf:RDF'
    for item in dom.childNodes('item')
      call add(items, {
      \  "title": item.childNode('title').value(),
      \  "link": item.childNode('link').value(),
      \  "content": item.childNode('description').value(),
      \  "id": item.childNode('link').value(),
      \  "date": item.childNode('dc:date').value(),
      \})
    endfor
  elseif dom.name == 'feed'
    for item in dom.childNodes('entry')
      call add(items, {
      \  "title": item.childNode('title').value(),
      \  "link": item.childNode('link').attr['href'],
      \  "content": item.childNode('content').value(),
      \  "id": item.childNode('id').value(),
      \  "date": item.childNode('updated').value(),
      \})
    endfor
  endif
  return items
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
