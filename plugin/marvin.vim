" ============================================================================
" File: plugin/marvin.vim
" Description: Maven plugin for Neovim - main entry point
" ============================================================================

" Prevent loading twice
if exists('g:loaded_marvin')
  finish
endif
let g:loaded_marvin = 1

" Check if Neovim
if !has('nvim')
  echohl ErrorMsg
  echomsg 'Marvin requires Neovim'
  echohl None
  finish
endif

" Set up filetype detection for Maven files
augroup marvin_filetype
  autocmd!
  autocmd BufRead,BufNewFile pom.xml setfiletype xml
  autocmd BufRead,BufNewFile *.pom setfiletype xml
  autocmd BufRead,BufNewFile settings.xml setfiletype xml
augroup END

" Optional: Highlight Maven-specific XML tags
augroup marvin_highlight
  autocmd!
  autocmd FileType xml syntax keyword xmlTag dependencies dependency groupId artifactId version scope
augroup END

" Load the Lua module
lua << EOF
require('marvin').setup({})
EOF
