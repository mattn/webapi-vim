function! s:dump(node, syntax)
  let syntax = a:syntax
  if type(a:node) == 1
    if len(syntax) | exe "echohl ".syntax | endif
    echon webapi#html#decodeEntityReference(a:node)
    echohl None
  elseif type(a:node) == 3
    for n in a:node
      call s:dump(n, syntax)
    endfor
    return
  elseif type(a:node) == 4
      "echo a:node.name
      "echo a:node.attr
    let syndef = {'kt' : 'Type', 'mi' : 'Number', 'nb' : 'Statement', 'kp' : 'Statement', 'nn' : 'Define', 'nc' : 'Constant', 'no' : 'Constant', 'k'  : 'Include', 's'  : 'String', 's1' : 'String', 'err': 'Error', 'kd' : 'StorageClass', 'c1' : 'Comment', 'ss' : 'Delimiter', 'vi' : 'Identifier'}
    for a in keys(syndef)
      if has_key(a:node.attr, 'class') && a:node.attr['class'] == a | let syntax = syndef[a] | endif
    endfor
    if has_key(a:node.attr, 'class') && a:node.attr['class'] == 'line' | echon "\n" | endif
    for c in a:node.child
      call s:dump(c, syntax)
      unlet c
    endfor
  endif
endfunction

let no = 357275
let res = webapi#http#get(printf('http://gist.github.com/%d.json', no))
let obj = webapi#json#decode(res.content)
let dom = webapi#html#parse(obj.div)
echo "-------------------------------------------------"
for file in dom.childNodes('div')
  unlet! meta
  let meta = file.childNodes('div')
  if len(meta) > 1
    echo "URL:".meta[1].find('a').attr['href']
  endif
  echo "\n"
  call s:dump(file.find('pre'), '')
  echo "-------------------------------------------------"
endfor

" vim: set et:
