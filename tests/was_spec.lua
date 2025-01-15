local mock = require("luassert.mock")
local stub = require("luassert.stub")

describe("was.nvim", function()
	local was = require("was")

	-- Mock vim functions
	local mock_vim

	before_each(function()
		-- Create a new mock for vim
		mock_vim = mock(vim, true)

		-- Mock stdpath
		mock_vim.fn.stdpath.returns("/mock/path")

		-- Mock mkdir
		mock_vim.fn.mkdir.returns(1)

		-- Mock getcwd
		mock_vim.fn.getcwd.returns("/test/project")

		-- Mock finddir
		mock_vim.fn.finddir.returns("/test/project/.git")

		-- Mock fnamemodify
		mock_vim.fn.fnamemodify.returns("/test/project")

		-- Mock json functions
		mock_vim.json = {
			decode = vim.json.decode,
			encode = vim.json.encode,
		}

		-- Mock notification
		mock_vim.notify = stub()
	end)

	after_each(function()
		mock_vim:revert()
	end)

	describe("get_project_root", function()
		it("should return git root when .git directory exists", function()
			local root = was._get_project_root()
			assert.equals("/test/project", root)
			assert.stub(mock_vim.fn.finddir).was_called_with(".git", "/test/project;")
		end)

		it("should return cwd when no .git directory exists", function()
			mock_vim.fn.finddir.returns("")
			local root = was._get_project_root()
			assert.equals("/test/project", root)
		end)
	end)

	describe("storage", function()
		local temp_file

		before_each(function()
			-- Create temporary file for testing
			temp_file = os.tmpname()
		end)

		after_each(function()
			-- Clean up temporary file
			os.remove(temp_file)
		end)

		it("should save and load intentions", function()
			-- Mock storage file location
			stub(was, "_get_storage_file").returns(temp_file)

			local test_intentions = {
				["/test/project"] = "Test intention",
			}

			-- Test saving
			assert.is_true(was._save_intentions(test_intentions))

			-- Test loading
			local loaded = was._load_intentions()
			assert.same(test_intentions, loaded)
		end)

		it("should handle empty file gracefully", function()
			-- Mock storage file location
			stub(was, "_get_storage_file").returns(temp_file)

			-- Create empty file
			local file = io.open(temp_file, "w")
			file:close()

			local loaded = was._load_intentions()
			assert.same({}, loaded)
		end)
	end)

	describe("handle", function()
		it("should show message when no intention is set", function()
			was.handle("")
			assert.stub(mock_vim.notify).was_called_with("No intention set for this project.", mock_vim.log.levels.WARN)
		end)

		it("should save and show new intention", function()
			-- Mock storage functions
			stub(was, "_save_intentions").returns(true)
			stub(was, "_load_intentions").returns({})

			was.handle("Test intention")

			assert.stub(mock_vim.notify).was_called_with("Intention saved: Test intention", mock_vim.log.levels.INFO)
		end)
	end)
end)
