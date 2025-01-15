local was = require("was")
local plenary_path = require("plenary.path")

describe("was.nvim", function()
	local test_dir = plenary_path:new(vim.fn.stdpath("data"), "was_test")
	local test_file = test_dir:joinpath("intentions.json")

	before_each(function()
		-- Mock the data path to use a test directory
		was._get_storage_file = function()
			test_dir:mkdir({ parents = true })
			return test_file:absolute()
		end
		-- Clear test data
		if test_file:exists() then
			test_file:remove()
		end
	end)

	after_each(function()
		-- Ensure no lingering data
		if test_file:exists() then
			test_file:remove()
		end
		if test_dir:exists() then
			test_dir:rmdir()
		end
	end)

	it("saves and loads intentions correctly", function()
		local intentions = { ["test/project"] = "Fixing bugs" }
		assert.is_true(was._save_intentions(intentions))

		local loaded_intentions = was._load_intentions()
		assert.are.same(intentions, loaded_intentions)
	end)

	it("handles non-existent storage file gracefully", function()
		-- ignore pre-existing intentions
		local intentions = {}
		assert.is_true(was._save_intentions(intentions))

		-- Ensure the file doesn't exist
		if test_file:exists() then
			test_file:remove()
		end

		local loaded_intentions = was._load_intentions()
		assert.are.same({}, loaded_intentions)
	end)

	it("notifies when retrieving a non-existent intention", function()
		local notify_called = false
		vim.notify = function(_, _)
			notify_called = true
		end

		was.handle("")
		assert.is_true(notify_called)
	end)
end)
