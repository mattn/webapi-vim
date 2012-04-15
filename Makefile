all : webapi-vim.zip

remove-zip:
	-rm -f doc/tags
	-rm -f webapi-vim.zip

webapi-vim.zip: remove-zip
	zip -r webapi-vim.zip autoload doc README

release: webapi-vim.zip
	vimup update-script webapi.vim
