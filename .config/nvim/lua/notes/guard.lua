local templater = require("templater")

-- slipnote.nvim refreshes `updated_at` in every Markdown buffer before it is
-- saved. In a template that would replace the {{updated_at}} placeholder with a
-- real timestamp, so skip the refresh for template files.
local M = {}
local patched = false

function M.setup()
	local ok, frontmatter = pcall(require, "slipnote.frontmatter")
	if not ok or patched then
		return
	end
	patched = true

	-- slipnote's autocmd looks this function up on the module at save time, so
	-- replacing it here takes effect without touching the plugin's files.
	local update_updated_at = frontmatter.update_frontmatter_updated_at
	frontmatter.update_frontmatter_updated_at = function(buffer)
		if templater.is_template(vim.api.nvim_buf_get_name(buffer or 0)) then
			return
		end
		return update_updated_at(buffer)
	end
end

return M
