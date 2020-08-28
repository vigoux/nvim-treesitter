local api = vim.api
local utils = require'nvim-treesitter.ts_utils'
local query = require'nvim-treesitter.query'
local parsers = require'nvim-treesitter.parsers'

local M = {}

local folds_levels = utils.memoize_by_buf_tick(function(bufnr)
  local levels_tmp = {}

  for _, node in ipairs(query.get_capture_matches(bufnr, "@fold", "fold")) do
    local start, _, stop, _ = node.node:range()
    stop = stop + 1

    -- This can be folded
    -- Fold only multiline nodes that are not exactly the same as prevsiously met folds
    if start ~= stop and not (levels_tmp[start] and levels_tmp[stop]) then
      if levels_tmp[start] and levels_tmp[stop] then
        print("folding twice :", start, stop)
      end

      levels_tmp[start] = (levels_tmp[start] or 0) + 1
      levels_tmp[stop] = (levels_tmp[stop] or 0) - 1
    end

  end

  local levels = {}
  local current_level = 0

  for lnum=0,api.nvim_buf_line_count(bufnr) do
    current_level = current_level + (levels_tmp[lnum] or 0)
    levels[lnum + 1] = current_level
  end

  return levels
end)

function M.get_fold_indic(lnum)
  if not parsers.has_parser() or not lnum then return '0' end

  local buf = api.nvim_get_current_buf()

  local levels = folds_levels(buf) or {}

  return tostring(levels[lnum] or 0)

end

return M
