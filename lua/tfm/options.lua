---Configurable user options.
---@class Options
---@field file_manager 'yazi'|'vifm'|'ranger'|'nnn' |'lf' Yazi by default
---@field on_open function(win, buf):void
---@field on_close function(win, buf):void
---@field cache_path string Defautl vim.fn.stdpath("cache") .. "/tfm"
---@field follow_current_file boolean
---@field actions table
---@field replace_netrw boolean If `true` then `netrw` will disabled and file manager will be opened when command is `$nvim .`
---@field ui UI

---@class UI
---@field border string (see ':h nvim_open_win')
---@field height number from 0 to 1 (0 = 0% of screen and 1 = 100% of screen)
---@field width number from 0 to 1 (0 = 0% of screen and 1 = 100% of screen)
---@field x number from 0 to 1 (0 = left most of screen and 1 = right most of
---screen)
---@field y number from 0 to 1 (0 = top most of screen and 1 = bottom most of
---screen)

---@class FileManager
---@field cmd string command name
---@field set_file_chooser_ouput string flag to set the chosen files output file
---@field set_focused_file string flag to set the focused file

local M = {}

local DEFAULT_OPTIONS = {
  replace_netrw = true,
  file_manager = "yazi",
  cache_path = vim.fn.stdpath("cache") .. "/tfm",
  follow_current_file = false,
  ui = {
    height = 0.8,
    width = 0.8,
    x = 0.5,
    y = 0.5,
    border = "rounded",
  },
  actions = {
    open = "<Cr>", -- open in current window
    open_with_window_picker = "<S-Cr>", -- choose window and open
    split = "<C-g>", -- open in split
    vsplit = "<C-v>", -- open in vertical split
    split_with_window_picker = "g<C-g>", -- choose window and open in split
    vsplit_with_window_picker = "g<C-v>", -- choose window and open in vsplit
    tabedit = "<C-t>", -- open in new tab
  },
}

local open_with_window_picker = function(opener)
  return function(path)
    local ok, wp = pcall(require, "window-picker")
    if not ok then
      vim.notify(
        '"window-picker" plugin not found. Open file with default opener',
        vim.log.levels.WARN,
        { title = "Tfm.nvim" }
      )
      opener(path)
    end
    local win = wp.pick_window()
    vim.api.nvim_set_current_win(win)
    opener(path)
  end
end

M.action_cbs = {
  open = vim.cmd.edit,
  open_with_window_picker = open_with_window_picker(vim.cmd.edit),
  split = vim.cmd.split,
  vsplit = vim.cmd.vsplit,
  split_with_window_picker = open_with_window_picker(vim.cmd.split),
  vsplit_with_window_picker = open_with_window_picker(vim.cmd.vsplit),
  tabedit = vim.cmd.tabedit,
}

M.opts = DEFAULT_OPTIONS
M.actions = {}

---@type table<string, FileManager>
M.managers = {
  ranger = {
    cmd = "ranger",
    set_file_chooser_ouput = "--choosefiles",
    set_focused_file = "--selectfile",
  },
  nnn = {
    cmd = "nnn",
    set_file_chooser_ouput = "-p",
    set_focused_file = "",
  },
  lf = {
    cmd = "lf",
    set_file_chooser_ouput = "-selection-path",
    set_focused_file = "",
  },
  yazi = {
    cmd = "yazi",
    set_file_chooser_ouput = "--chooser-file",
    set_focused_file = "",
  },
  vifm = {
    cmd = "vifm",
    set_file_chooser_ouput = "--choose-files",
    set_focused_file = "--select",
  },
}

---Update options
---@param opts Options
function M.update_options(opts)
  if opts then
    M.opts = vim.tbl_deep_extend("force", M.opts, opts)
  end
end

return M
