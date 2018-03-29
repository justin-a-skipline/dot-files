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

"things after case labels aren't indented
"so I can add braces in case statements
set cino==0

set nu

set splitright
set splitbelow

set showcmd

let g:markdown_folding = 1
"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Code Navigation
"""""""""""""""""""""""""""""""""""""""""""""""""""""
if has('nvim-0.1.5')
	set termguicolors
  set shada="NONE"
endif

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

set autoread

"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Key maps
"""""""""""""""""""""""""""""""""""""""""""""""""""""
set timeout timeoutlen=1000 ttimeoutlen=200
let mapleader = '\'
imap jk <esc>
vmap s( c()<ESC>P
vmap s{ c{}<ESC>P
vmap s" c""<ESC>P
vmap s` c``<ESC>P
vmap s' c''<ESC>P
vmap <leader>bs c{<CR>}<ESC>P
vmap s<SPACE> di<SPACE><SPACE><ESC>P
nmap j gj
nmap k gk
nmap <c-j> :lnext<CR>
nmap <c-k> :lprevious<CR>
nmap <a-j> :lolder<CR>
nmap <a-k> :lnewer<CR>
nmap <SPACE> za
nmap <a-.> 10<c-w>>
nmap <a-,> 10<c-w><
nmap <a--> 10<c-w>-
nmap <a-=> 10<c-w>+
nmap <leader>u g-
nmap <leader>r g+
nmap <leader>l :call LocationListToggle()<CR>
vmap <leader>/ :call Comment()<CR>
vmap <leader>\ :call Uncomment()<CR>
nmap <leader>] :call TogglePreview()<CR>
nmap <leader>n :call VerticalSplitNoteToggle()<CR>
nmap <leader>i =i{

"ag search hotkeys
nmap <leader>s yiw:call EasyAgSearch('<c-R>0')<CR>
nmap <leader>S :call EasyAgSearch('')<LEFT><LEFT>
vmap <leader>s y<Leader>S<c-R>0<CR>
vmap <leader>S y<Leader>S<c-R>0

"lvimgrep search hotkeys
nmap <leader>vs yiw:call EasylvimgrepSearch('<c-R>0')<CR>
nmap <leader>vS :call EasylvimgrepSearch('')<LEFT><LEFT>
vmap <leader>vs y<Leader>vS<c-R>0<CR>
vmap <leader>vS y<leader>vS<c-R>0
"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! EasylvimgrepSearch(term)
  if (&filetype ==? "c") || (&filetype ==? "cpp") 
    execute('lvimgrep `' . a:term . '` **/*.c **/*.h **/*.cpp **/*.hpp')
  elseif (&filetype ==? "msp")
    execute('lvimgrep `' . a:term . '` **/*.s43 **/*.h **/*.inc')
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! EasyAgSearch(term)
  if ((&filetype ==? "c") || (&filetype ==? "cpp"))
    execute('lex system(''ag --cc --ignore=external "' . a:term . '" "' . fnamemodify(getcwd(), ':p:h') . "\" ')")
  elseif (&filetype ==? "msp")
"still searches *.s43~ files~ ARGH~
    execute('lex system(''ag "' . a:term . '" **.s43 **.h'')')
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! EasyCtags()
  if ((&filetype ==? "c") || (&filetype ==? "cpp"))
    execute('!ctags --langmap=C:.c.h.C --regex-C="/^(DEFCW\|DEFC\|DEFW)\(\s*([a-zA-Z0-9_]+)/\2/d,definition/" -R .')
  elseif (&filetype ==? "msp")
"still searches *.s43~ files~ ARGH~
    execute('!ctags --langmap=Asm:.s43.h -R .')
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! EasyLinuxCtags()
    execute('!ctags --langmap=C:.c.h.C -R . && ctags -Ra /lib/modules/$(uname -r)')
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! LocationListToggle()
  if exists("w:location_list_open")
    unlet w:location_list_open
    lclose
  else
    lopen
    let w:location_list_open = 1
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! Comment()
  if (&filetype ==? "c") || (&filetype ==? "cpp") 
    s;^;//;e
  elseif (&filetype ==? "msp")
    s/^/;/e
  elseif (&filetype ==? "sh") || (&filetype ==? "pov")
    s/^/# /e
  elseif (&filetype ==? "vim")
    s/^/"/e
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! Uncomment()
  if (&filetype ==? "c") || (&filetype ==? "cpp") 
    s;^//;;e
  elseif (&filetype ==? "msp")
    s/^;//e
  elseif (&filetype ==? "sh") || (&filetype ==? "pov")
    s/^# //e
  elseif (&filetype ==? "vim")
    s/^"//e
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! PwinOpen()
  let w:pwin = 1
  wincmd }
endfunction

function! PwinClose()
  unlet w:pwin
  pclose
endfunction

function! TogglePreview()
  if exists("w:pwin")
    call PwinClose()
  else
    call PwinOpen()
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! VerticalSplitNoteToggle()
  if exists("t:notes_buf_number")
    call VerticalSplitNoteClose()
  else
    call VerticalSplitNoteOpen()
  endif
endfunction

function! VerticalSplitNoteOpen()
  execute "vsplit NOTES.md"
  let t:notes_buf_number = bufnr("%")
  wincmd L "move window all the way to the right
  65wincmd | "set window width to notes_width
endfunction

function! VerticalSplitNoteClose()
  100wincmd l
  100wincmd k
  close
  unlet t:notes_buf_number
endfunction
  

"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Auto Functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""
augroup vimrc
  autocmd! vimrc
  au BufNewFile,BufRead *.s43 set ft=msp
  au BufNewFile,BufRead *.au3 set ft=autoit
"  au BufNewFile,BufRead *     syn keyword Todo NOTE
augroup END

let g:onedark_termcolors=16
set background=dark
silent! colorscheme onedark

"syn keyword MyHighlightGroup NOTE
"hi MyHighlightGroup guifg=Blue ctermfg=Blue term=bold
"hi link MyHighlightGroup Todo

if has('win32')
  silent! set guifont=Consolas:h11
endif

