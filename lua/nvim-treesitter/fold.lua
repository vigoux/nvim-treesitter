local api = vim.api
local utils = require'nvim-treesitter.ts_utils'
local query = require'vim.treesitter.query'
local parsers = require'nvim-treesitter.parsers'

local M = {
  enabled_buffers = {}
}

function map_windows(bufnr, func)
  for _, winnr in ipairs(vim.fn.win_findbuf(bufnr)) do
    func(winnr)
  end
end

function setup_folds(bufnr, start_row, start_col, end_row, end_col)
  map_windows(bufnr, function(winnr)
    api.nvim_win_del_fold(winnr, start_row + 1, end_row + 1, true)
  end)

  local parser = parsers.get_parser(bufnr)
  local q = query.get_query(parser:lang(), "folds")

  for _, tree in ipairs(parser:trees()) do
    local root = tree:root()

    local starting_point = root:descendant_for_range(start_row, start_col, end_row, end_col)
    if starting_point then
      for id, node in q:iter_captures(starting_point, bufnr, start_row, end_row) do
        local sr, sc, er, ec = node:range();
        map_windows(bufnr, function(winnr)
          api.nvim_win_add_fold(winnr, sr + 1, sc+1, er+1, ec+1)
        end)
      end
    end
  end
end

function changes_cb(bufnr, changes, tree)
  if not M.enabled_buffers[bufnr] then return end

  for change in changes do
    setup_folds(bufnr, unpack(change))
  end
end

function M.attach(bufnr, lang)
  local parser = parsers.get_parser(bufnr, lang)
  if not parser then return end
  -- For now do this only for root level
  parser:register_cbs { on_changedtree = function(...) changes_cb(bufnr, ...) end }

  M.enabled_buffers[bufnr] = true
end

function M.detach(bufnr)
  M.enabled_buffers[bufnr] = false
end

return M
