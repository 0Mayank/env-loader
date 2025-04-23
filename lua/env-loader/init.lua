local M = {}

-- Store loaded directory states
M.loaded_dirs = {}

-- Function to check and load .nvimrc files
function M.check_and_load_nvimrc()
	local current_dir = vim.fn.getcwd()

	-- Skip if we've already loaded for this directory
	if M.loaded_dirs[current_dir] then
		return
	end

	local nvimrc_path = current_dir .. "/.nvimrc.lua"

	-- Check if .nvimrc exists in the current directory
	if vim.fn.filereadable(nvimrc_path) == 1 then
		-- Check if we need confirmation
		local should_load = true

		if vim.g.nvimrc_trusted ~= true and vim.g.nvimrc_ask_confirmation == true then
			local confirm = vim.fn.confirm("Do you want to source " .. nvimrc_path .. "?", "&Yes\n&No", 2)
			should_load = (confirm == 1)
		end

		if should_load then
			-- Execute the .nvimrc file
			local success, err = pcall(dofile, nvimrc_path)

			if success then
				vim.notify("Loaded project .nvimrc from: " .. nvimrc_path, vim.log.levels.INFO)
				-- Mark this directory as loaded
				M.loaded_dirs[current_dir] = true
			else
				vim.notify("Error loading .nvimrc: " .. tostring(err), vim.log.levels.ERROR)
			end
		end
	end
end

-- Setup autocommands to check for .nvimrc
function M.setup()
	-- Create an autocommand group
	local augroup = vim.api.nvim_create_augroup("NvimrcLoader", { clear = true })

	-- Check for .nvimrc when entering a directory
	vim.api.nvim_create_autocmd({ "DirChanged" }, {
		group = augroup,
		callback = function()
			M.check_and_load_nvimrc()
		end,
	})

	-- Also check when Neovim starts
	vim.api.nvim_create_autocmd({ "VimEnter" }, {
		group = augroup,
		callback = function()
			M.check_and_load_nvimrc()
		end,
	})

	-- Check immediately for the current directory
	M.check_and_load_nvimrc()

	-- Add command to manually reload .nvimrc
	vim.api.nvim_create_user_command("ReloadNvimrc", function()
		local current_dir = vim.fn.getcwd()
		-- Remove from loaded dirs to force reloading
		M.loaded_dirs[current_dir] = nil
		M.check_and_load_nvimrc()
	end, {})
end

return M
