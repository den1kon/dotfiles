-- MINI.NVIM ====================================================================================================

-- mini.files----------------------------------------------------------------------------------------------------
require("mini.files").setup()

--------------------------------------------------
require("mini.icons").setup()
require("mini.pick").setup()
require("mini.indentscope").setup({
	symbol = "│",
})
require("mini.trailspace").setup()
require("mini.visits").setup()
require("mini.git").setup()
require("mini.diff").setup({
	view = {
		-- Visualization style. Possible values are 'sign' and 'number'.
		style = "sign",
	},
})
require("mini.statusline").setup()
require("mini.extra").setup()
require("mini.cmdline").setup()
require("mini.completion").setup()
require("mini.notify").setup()
require("miniclue")

require("mini.tabline").setup()

-----------------------------------------------------------------------------------------------------------------
