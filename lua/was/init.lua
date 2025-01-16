local M = {}
local uv = vim.loop

-- Default Configuration
local config = {
	defer_time = 3000, -- default to 3 seconds
}

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
		M.display_ui("Failed to load intentions: " .. intentions, "error")
		return {}
	end

	return intentions
end

-- Function to save intentions to file
local function save_intentions(intentions)
	local file_path = get_storage_file()
	local file = io.open(file_path, "w")
	if not file then
		M.display_ui("Failed to open storage file for writing", "error")
		return false
	end

	local ok, encoded = pcall(vim.json.encode, intentions)
	if not ok then
		M.display_ui("Failed to encode intentions: " .. encoded, "error")
		file:close()
		return false
	end

	file:write(encoded)
	file:close()
	return true
end

-- Human-readable time format (good enough for this use case)
local function time_diff(timestamp)
	local diff = uv.now() / 1000 - timestamp
	local days = math.floor(diff / (60 * 60 * 24))
	if days > 0 then
		return days .. " days ago"
	else
		local hours = math.floor(diff / (60 * 60))
		if hours > 0 then
			return hours .. " hours ago"
		else
			local minutes = math.floor(diff / 60)
			return minutes .. " minutes ago"
		end
	end
end

-- Function to display UI with messages
function M.display_ui(message, level, footer_message)
	local hl_group = level == "error" and "Error" or "Info"
	local screen_width = vim.api.nvim_get_option("columns")
	local screen_height = vim.api.nvim_get_option("lines")
	local width = math.min(50, screen_width - 10)
	local height = 3
	local col = math.floor((screen_width - width) / 2)
	local row = math.floor((screen_height - height) / 2)

	local buf = vim.api.nvim_create_buf(false, true) -- Create an empty buffer (non-modifiable)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { message })
	vim.api.nvim_buf_add_highlight(buf, -1, hl_group, 0, 0, -1)

	-- Open window in the center
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
		title = "Was",
		title_pos = "center",
		footer = footer_message,
		footer_pos = "right",
	})

	-- Set the buffer to readonly and disable modifications
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "readonly", true)

	-- Automatically close after configured seconds
	vim.defer_fn(function()
		vim.api.nvim_win_close(win, true)
	end, config.defer_time)
end

-- Function to close the UI window manually (via 'q' key)
function M.close_ui(win)
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

-- Function to set or get the intention
function M.handle(input)
	local project_root = vim.fn.getcwd()
	local intentions = load_intentions()

	if input == "" then
		if intentions[project_root] then
			local timestamp = intentions[project_root].timestamp
			local time_display = time_diff(timestamp)
			local message = "You were " .. intentions[project_root].message

			M.display_ui(message, "info", time_display)
		else
			M.display_ui("No intention set for this project.", "warn", "Set one using :Was <intention>")
		end
	else
		local intention = { message = input, timestamp = uv.now() / 1000 }
		intentions[project_root] = intention
		if save_intentions(intentions) then
			M.display_ui("saved: " .. input, "info", "You can check it using :Was")
		end
	end
end

-- setup function to create the command
function M.setup(user_config)
	-- Merge user config with default config
	config = vim.tbl_extend("force", config, user_config or {})
	vim.api.nvim_create_user_command("Was", function(opts)
		require("was").handle(opts.args)
	end, { nargs = "?" })
end

-- Expose functions for testing
M._get_storage_file = get_storage_file
M._load_intentions = load_intentions
M._save_intentions = save_intentions
M.time_diff = time_diff

return M
