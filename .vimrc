"Tabs, spaces, etc.
set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=2

"Indentation
set autoindent
filetype indent on
syntax enable

set nu
set rnu


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
inoremap {<CR> {<CR>}<ESC>O
inoremap {<CR> {}<Left><CR><CR><Up>
vnoremap s( da()<ESC>P
nnoremap j gj
nnoremap k gk
nnoremap <c-j> :lnext<CR>
nnoremap <c-k> :lprevious<CR>
nnoremap <SPACE> za

let g:onedark_termcolors=16
set background=dark
colorscheme onedark
