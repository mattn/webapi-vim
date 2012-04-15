scriptencoding utf-8

let hatena_id = 'your-hatena-id'
let password = 'your-hatena-password'

" write entry
let entry = atom#newEntry()
call entry.setTitle("title of entry")
call entry.setContentType("text/html")
call entry.setContent("<script>alert(2)</script>")

" post draft
let id = atom#createEntry("http://d.hatena.ne.jp/".hatena_id."/atom/draft", hatena_id, password, entry)

" modify it. publish it.
call entry.setContent("<script>alert(1)</script>")
let id = atom#updateEntry(id, hatena_id, password, entry, {"X-HATENA-PUBLISH": 1})

" get the entry.
let entry = atom#getEntry(id, hatena_id, password)
echo entry.getTitle()
echo entry.getContent()

" delete the entry.
call atom#deleteEntry(id, hatena_id, password)

" vim:set ft=vim:
