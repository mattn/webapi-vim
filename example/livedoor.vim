scriptencoding utf-8

let livedoor_id = 'your-livedoor-id'
let password = 'your-livedoor-password'

" write entry
let entry = atom#newEntry()
call entry.setTitle("title of entry")
call entry.setContentType("text/html")
call entry.setContent("<script>alert(3)</script>")

let postUrl = "http://cms.blog.livedoor.com/atom"
echo atom#createEntry(postUrl, livedoor_id, password, entry)

" vim:set ft=vim:
