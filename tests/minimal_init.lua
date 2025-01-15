local plenary_status, plenary = pcall(require, "plenary")
if not plenary_status then
	print("Plenary plugin not loaded")
	return
end

vim.cmd([[set runtimepath+=.]])
vim.cmd([[set runtimepath+=~/.local/share/nvim/site/pack/packer/start/plenary.nvim]])
