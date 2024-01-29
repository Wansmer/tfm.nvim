local options = require("tfm.options")

local M = {}

---Builds the TFM launch command
---@param file_manager FileManager
---@param path string|nil Path to the file/directory to open. If `nil`, the current file will be used. If this is invalid, the `cwd` will be used as the fallback.
---@return string
function M.build_tfm_cmd(file_manager, path)
  -- FILE CHOOSER MODE
  local chooser = string.format("%s %s", file_manager.set_file_chooser_ouput, options.opts.cache_path)

  -- FILE TO BE FOCUSED
  -- Take the given path or fallback to the current file
  local file_to_focus = path and path or vim.fn.expand("%")
  -- If there is a file path, quote it to avoid issues with spaces in file names
  file_to_focus = file_to_focus == "" and "" or '"' .. file_to_focus .. '"'

  local arg_focus_file = string.format("%s %s", file_manager.set_focused_file, file_to_focus)

  return string.format(
    "%s %s %s",
    file_manager.cmd,
    chooser,
    -- Must be last, as most TFMs just accept the filename to focus it, without requiring a specific flag
    arg_focus_file
  )
end

---Opens the TFM float window
---@param ui UI
---@return number, number
function M.open_win(ui)
  local buf = vim.api.nvim_create_buf(false, true)
  local height = math.ceil(vim.o.lines * ui.height)
  local width = math.ceil(vim.o.columns * ui.width)
  local row = math.ceil((vim.o.lines - height) * ui.y - 1)
  local col = math.ceil((vim.o.columns - width) * ui.x)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    border = ui.border,
    row = row,
    col = col,
    style = "minimal",
  })

  return win, buf
end

---Returns a table with the names of all the currently listed buffers, which point to existing filenames
---@return table<string>
function M.get_buffers_for_existing_files()
  local buffer_names = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fn.buflisted(buf) == 1 then
      local buf_name = vim.fn.bufname(buf)
      if vim.fn.filereadable(buf_name) == 1 then
        table.insert(buffer_names, buf_name)
      end
    end
  end

  return buffer_names
end

---Closes any buffers from the given table of buffer names which point to files that don't exist
---@param buffers table<string>
function M.close_empty_buffers(buffers)
  for _, buf in ipairs(buffers) do
    if vim.fn.filereadable(buf) ~= 1 then
      vim.cmd.bdelete(buf)
    end
  end
end

---Clean up temporary files used to communicate between the terminal file manager and the plugin
function M.clean_cache()
  vim.fn.delete(options.opts.cache_path)
end

return M
