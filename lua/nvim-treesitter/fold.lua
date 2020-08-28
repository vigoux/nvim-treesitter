local api = vim.api
local utils = require'nvim-treesitter.ts_utils'
local query = require'nvim-treesitter.query'
local parsers = require'nvim-treesitter.parsers'

local M = {}

-- This is cached on buf tick to avoid computing that multiple times
-- Especially not for every line in the file when `zx` is hit
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

  -- We now have the list of fold opening and closing, fill the gaps and mark where fold start
  for lnum=0,api.nvim_buf_line_count(bufnr) do
    local prefix= ''
    local shift = levels_tmp[lnum] or 0

    -- Determine if it's the start of a fold
    if levels_tmp[lnum] and shift >= 0 then
      prefix = '>'
    end

    current_level = current_level + shift
    levels[lnum + 1] = prefix .. tostring(current_level)
  end

  return levels
end)

function M.get_fold_indic(lnum)
  if not parsers.has_parser() or not lnum then return '0' end

  local buf = api.nvim_get_current_buf()

  local levels = folds_levels(buf) or {}

  return levels[lnum] or '0'
end

return M
