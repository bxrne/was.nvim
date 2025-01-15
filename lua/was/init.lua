local M = {}

-- Function to get the project's root directory
local function get_project_root()
	local cwd = vim.fn.getcwd()
	local git_dir = vim.fn.finddir(".git", cwd .. ";")
	if git_dir ~= "" then -- Try git project root
		return vim.fn.fnamemodify(git_dir, ":h")
	else -- Or use working path
		return cwd
	end
end

-- Function to get the storage file path
local function get_storage_file()
	local data_path = vim.fn.stdpath("data") .. "/was"
	-- Create directory if it doesn't exist
	vim.fn.mkdir(data_path, "p")
	return data_path .. "/intentions.json"
end

-- Function to load intentions from file
local function load_intentions()
	local file_path = get_storage_file()
	local file = io.open(file_path, "r")
	if not file then
		return {}
	end

	local content = file:read("*all")
	file:close()

	-- Handle empty file case
	if content == "" then
		return {}
	end

	local ok, intentions = pcall(vim.json.decode, content)
	if not ok then
		vim.notify("Failed to load intentions: " .. intentions, vim.log.levels.ERROR)
		return {}
	end

	return intentions
end

-- Function to save intentions to file
local function save_intentions(intentions)
	local file_path = get_storage_file()
	local file = io.open(file_path, "w")
	if not file then
		vim.notify("Failed to open storage file for writing", vim.log.levels.ERROR)
		return false
	end

	local ok, encoded = pcall(vim.json.encode, intentions)
	if not ok then
		vim.notify("Failed to encode intentions: " .. encoded, vim.log.levels.ERROR)
		file:close()
		return false
	end

	file:write(encoded)
	file:close()
	return true
end

-- Function to set or get the intention
function M.handle(input)
	local project_root = get_project_root()
	local intentions = load_intentions()

	if input == "" then
		if intentions[project_root] then
			vim.notify("Intention: " .. intentions[project_root], vim.log.levels.INFO)
		else
			vim.notify("No intention set for this project.", vim.log.levels.WARN)
		end
	else
		intentions[project_root] = input
		if save_intentions(intentions) then
			vim.notify("Intention saved: " .. input, vim.log.levels.INFO)
		end
	end
end

-- setup function to create the command
function M.setup()
	vim.api.nvim_create_user_command("Was", function(opts)
		require("was").handle(opts.args)
	end, { nargs = "?" })
end

-- Expose functions for testing
M._get_project_root = get_project_root
M._get_storage_file = get_storage_file
M._load_intentions = load_intentions
M._save_intentions = save_intentions

return M
