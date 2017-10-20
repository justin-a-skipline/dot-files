"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Syntax Checking and Linter
"""""""""""""""""""""""""""""""""""""""""""""""""""""
try
  execute pathogen#infect()
  let g:syntastic_cpp_checkers = ['gcc', 'cppcheck']
  set statusline+=%#warningmsg#
  let g:syntastic_cpp_compiler_options = ' -std=c++11 -stdlib=libc++'
  set statusline+=%{SyntasticStatuslineFlag()}
  set statusline+=%*

  let g:syntastic_always_populate_loc_list = 1
  "When set to 2 the error window will be automatically closed when no errors are
  "detected, but not opened automatically.
  let g:syntastic_auto_loc_list = 2
  let g:syntastic_check_on_open = 1
  let g:syntastic_check_on_wq = 0

  "Syntastic check ignore
  "let g:syntastic_quiet_messages = { "regex": "file not found"}
endtry

"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Indentation
"""""""""""""""""""""""""""""""""""""""""""""""""""""
set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=2

set autoindent
filetype plugin indent on
syntax enable

set nu
set rnu

set splitright
set splitbelow

set showcmd

"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Code Navigation
"""""""""""""""""""""""""""""""""""""""""""""""""""""
set showmatch
set incsearch
set hlsearch
set ruler

set foldlevelstart=99
set foldmethod=syntax

set backup
set writebackup
set undofile

set hidden
set history=200
set nrformats=bin,hex
set backspace=indent,eol,start

"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Key maps
"""""""""""""""""""""""""""""""""""""""""""""""""""""
set timeout timeoutlen=1000 ttimeoutlen=200
let mapleader = '\'
imap jk <esc>
imap {<CR> {}<Left><CR><CR><Up>
vmap s( di()<ESC>P
vmap s" di""<ESC>P
nmap j gj
nmap k gk
nmap <c-j> :lnext<CR>
nmap <c-k> :lprevious<CR>
nmap <SPACE> za
nmap <leader>l :call LocationListToggle()<CR>
vmap <leader>/ :call Comment()<CR>
vmap <leader>\ :call Uncomment()<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:location_list_open = 0
function! LocationListToggle()
  if s:location_list_open
    lclose
    let s:location_list_open = 0
  else
    lopen
    let s:location_list_open = 1
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! Comment()
  if (&filetype ==? "c") || (&filetype ==? "cpp") 
    s;^;//;e
  elseif (&filetype ==? "msp")
    s/^/;/e
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! Uncomment()
  if (&filetype ==? "c") || (&filetype ==? "cpp") 
    s;^//;;e
  elseif (&filetype ==? "msp")
    s/^;//e
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""


let g:onedark_termcolors=16
set background=dark
silent! colorscheme onedark
