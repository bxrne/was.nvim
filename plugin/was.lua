if vim.g.loaded_was then
	return
end
vim.g.loaded_was = true

require("was").setup()
