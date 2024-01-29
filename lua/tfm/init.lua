local options = require("tfm.options")
local tfm = require("tfm.tfm")

local M = {}

---Setup tfm.nvim
---@param opts Options
function M.setup(opts)
  options.update_options(opts)
end

---Open float window with terminal filemanager
function M.open()
  tfm.new(options.opts):run()
end

return M
