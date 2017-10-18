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
"let g:syntastic_quiet_messages = { "regex": "c++11"}

"Tabs, spaces, etc.
set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=2

"Indentation
set autoindent
filetype plugin indent on
syntax enable

set nu
set rnu

set splitright
set splitbelow

set showcmd

"Code Navigation
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

"Key maps
inoremap jk <esc>
inoremap {<CR> {}<Left><CR><CR><Up>
vnoremap s( di()<ESC>P
nnoremap j gj
nnoremap k gk
nnoremap <c-j> :lnext<CR>
nnoremap <c-k> :lprevious<CR>
nnoremap <SPACE> za

let g:onedark_termcolors=16
set background=dark
colorscheme onedark
