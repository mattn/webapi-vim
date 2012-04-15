scriptencoding utf-8

let jugem_id = 'your-jugem-id'
let password = 'your-jugem-password'
let imageName = "my-image.gif" 
let imagePath = "/path/to/images/my-image.gif" 

let api = metaWeblog#proxy("http://".jugem_id.".jugem.jp/admin/xmlrpc.php")

let imgurl = api.newMediaObject(jugem_id, jugem_id, password, {
\ "name": imageName,
\ "path": imagePath,
\})

let text = "How about this?<br /><img src=\"".imgurl["url"]."\">"

echo api.newPost(jugem_id, jugem_id, password, {
\ "title": "post from webpi-vim",
\ "description": text,
\ "dateCreated": "",
\ "categories": ["test"],
\}, 1)

" vim:set ft=vim:
