set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=2

inoremap jk <esc>
vnoremap jk <esc>

set nu
set rnu

syntax on
syntax enable
set syntax
set showcmd

filetype indent on
set lazyredraw

set showmatch

set incsearch
set hlsearch

set foldlevelstart=20
set foldmethod=syntax

set backup
set writebackup

nnoremap j gj
nnoremap k gk

inoremap {<CR> {<ESC>o<CR>}<ESC><UP>A<TAB>

vnoremap s( da()<ESC>P

nnoremap <c-j> :lnext<CR>
nnoremap <c-k> :lprevious<CR>

let g:onedark_termcolors=16
colorscheme onedark
