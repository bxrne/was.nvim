local was = require("was")
local plenary_path = require("plenary.path")

describe("was.nvim", function()
	local test_dir = plenary_path:new(vim.fn.stdpath("data"), "was_test")
	local test_file = test_dir:joinpath("intentions.json")

	before_each(function()
		-- Mock the storage file path to use a test directory
		was._get_storage_file = function()
			test_dir:mkdir({ parents = true })
			return test_file:absolute()
		end

		-- Clear any previous test data
		if test_file:exists() then
			test_file:remove()
		end
	end)

	after_each(function()
		-- Clean up the test data
		if test_file:exists() then
			test_file:remove()
		end
		if test_dir:exists() then
			test_dir:rmdir()
		end
	end)

	it("saves and loads intentions correctly", function()
		local intentions = { ["test/project"] = { message = "Fixing bugs", timestamp = vim.loop.now() / 1000 } }
		assert.is_true(was._save_intentions(intentions))

		local loaded_intentions = was._load_intentions()
		assert.are.same(intentions, loaded_intentions)
	end)

	it("handles non-existent storage file gracefully", function()
		-- Ensure no previous intentions exist
		local intentions = {}
		assert.is_true(was._save_intentions(intentions))

		-- Remove the storage file
		if test_file:exists() then
			test_file:remove()
		end

		local loaded_intentions = was._load_intentions()
		assert.are.same({}, loaded_intentions)
	end)

	it("properly formats the human-readable time", function()
		local timestamp = vim.loop.now() / 1000 - 86400 -- 1 day ago
		local time_str = was.time_diff(timestamp)
		assert.are.equal(time_str, "1 days ago")
	end)

	it("handles UI closing on 'q' key press", function()
		-- Open a window first
		local win = vim.api.nvim_open_win(
			0,
			true,
			{ style = "minimal", relative = "editor", width = 10, height = 3, row = 10, col = 10 }
		)
		local buf = vim.api.nvim_get_current_buf()

		-- Set the keybinding for 'q' to close the window
		vim.api.nvim_buf_set_keymap(
			buf,
			"n",
			"q",
			':lua require("was").close_ui(' .. win .. ")\n",
			{ noremap = true, silent = true }
		)

		-- Simulate pressing 'q' to close the window
		vim.cmd("normal! q")

		-- Delay to ensure window is closed properly
		vim.defer_fn(function()
			assert.is_false(vim.api.nvim_win_is_valid(win), "Window should be closed")
		end, 100)
	end)
end)
