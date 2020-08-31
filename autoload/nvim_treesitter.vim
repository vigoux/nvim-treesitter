function! nvim_treesitter#statusline(len)
  return luaeval("require'nvim-treesitter'.statusline(_A)", a:len)
endfunction

function! nvim_treesitter#foldexpr()
	return luaeval(printf('require"nvim-treesitter.vim_fns".get_fold_indic(%d)', v:lnum))
endfunction

function! nvim_treesitter#indentexpr()
	return luaeval(printf('require"nvim-treesitter.vim_fns".get_indent_level(%d)', v:lnum))
endfunction
