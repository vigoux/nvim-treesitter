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


local indent_level = utils.memoize_by_buf_tick(function(bufnr)
  local levels_tmp = {}

  for _, node in ipairs(query.get_capture_matches(bufnr, "@indent", "indent")) do
    local start, _, stop, _ = node.node:range()
    start = start+1
    stop = stop+1

    local inside_lines = stop - start

    -- This node contains enough lines
    if inside_lines > 1 then
      levels_tmp[start] = (levels_tmp[start] or 0) + 1
      levels_tmp[stop] = (levels_tmp[stop] or 0) - 1
    end

  end

  local levels = {}
  local current_level = 0
  local tabstop = vim.api.nvim_buf_get_option(buf, 'tabstop')

  -- We now have the list of fold opening and closing, fill the gaps and mark where fold start
  for lnum=0,api.nvim_buf_line_count(bufnr) do
    local shift = levels_tmp[lnum] or 0
    current_level = current_level + shift
    levels[lnum + 1] = tostring(current_level * tabstop)
  end

  return levels
end)

local function line_based_fn(get_values)
  return function(lnum)
    if not parsers.has_parser() or not lnum then return '0' end

    local buf = api.nvim_get_current_buf()

    local values = get_values(buf) or {}

    return values[lnum] or '0'
  end
end

M.get_fold_indic = line_based_fn(folds_levels)
M.get_indent_level = line_based_fn(indent_level)

return M
