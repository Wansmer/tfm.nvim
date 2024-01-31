local options = require("tfm.options")
local u = require("tfm.utils")

local ns = vim.api.nvim_create_namespace("__tfm__")

---@class WindowData
---@field win number
---@field buf number
---@field enter_win number Window id in which the Tfm was called

---@class Tfm
---@field opts Options
---@field opener function(path):void
---@field data WindowData
local Tfm = {}
Tfm.__index = Tfm

---Create new Fmt instance
---@param opts Options
---@return Tfm
function Tfm.new(opts)
  return setmetatable({
    opts = vim.tbl_deep_extend("force", options.opts, opts),
    opener = options.action_cbs.open,
    data = {},
  }, Tfm)
end

function Tfm:open_win()
  local prev_win = vim.api.nvim_get_current_win()
  local win, buf = u.open_win(self.opts.ui)

  self.data = { win = win, buf = buf, enter_win = prev_win }
  self:set_mappings()

  vim.api.nvim_set_hl(ns, "NormalFloat", { bg = "#000000" })
  vim.api.nvim_set_hl(ns, "FloatBorder", { fg = "#ffffff", bg = "#000000" })
  vim.api.nvim_win_set_hl_ns(win, ns)

  if self.opts.on_open and type(self.opts.on_open) == "function" then
    self.opts.on_open(win, buf)
  end
end

function Tfm:set_mappings()
  for action, keys in pairs(self.opts.actions) do
    vim.keymap.set("t", keys, function()
      self.opener = options.action_cbs[action]
      vim.api.nvim_feedkeys(vim.keycode("<Cr>"), "n", true)
    end, { buffer = self.data.buf, desc = action })
  end
end

function Tfm:run(path)
  -- In case there are leftover files
  u.clean_cache()

  -- Store buffers that are open (and not empty) prior to running the terminal file manager
  local buffers_for_existing_files = u.get_buffers_for_existing_files()

  path = path and path or (self.opts.follow_current_file and vim.fn.expand("%:p") or vim.fn.getcwd())

  local cmd = u.build_tfm_cmd(options.managers[self.opts.file_manager], path)

  self:open_win()

  vim.fn.termopen(cmd, {
    on_exit = function(_, code, _)
      -- Return early if there was some error with the TFM
      if code ~= 0 then
        return
      end

      self:handle_choosen_files()

      u.clean_cache()
      -- Close any buffers that were previously pointing to existing files, but don't
      -- after running the TFM. This should close any buffers for files which were
      -- deleted using the TFM.
      u.close_empty_buffers(buffers_for_existing_files)
    end,
  })

  vim.cmd.startinsert()
end

function Tfm:handle_choosen_files()
  if vim.fn.filereadable(self.opts.cache_path) ~= 1 then
    return
  end

  local selected_files = vim.fn.readfile(self.opts.cache_path)
  local directories = {}

  for _, path in ipairs(selected_files) do
    if vim.fn.isdirectory(path) == 1 then
      table.insert(directories, path)
    else
      vim.api.nvim_win_close(self.data.win, true)
      vim.api.nvim_buf_delete(self.data.buf, { force = true })
      self.opener(path)
    end
  end

  -- Reopen the TFM again with the selected first directory, ignore the rest
  local _, first_dir = next(directories)
  if first_dir ~= nil then
    self:run(first_dir)
  end
end

return Tfm
