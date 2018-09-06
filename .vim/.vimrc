"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Indentation
"""""""""""""""""""""""""""""""""""""""""""""""""""""
set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=2
set textwidth=0

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

set nostartofline

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
set ruler
set tagcase=smart "smart case sensitivity with :tag command
set ignorecase
set smartcase

set foldlevelstart=99
set foldmethod=indent

set nobackup
set nowritebackup
set undofile

if has("win32")
  set directory=~/dot-files/.vim/swap//
  set undodir=~/dot-files/.vim/undo//
elseif has("unix")
  set directory=~/.vim/swap//
  set undodir=~/.vim/swap//
endif

if has("gui_running")
  set lines=30 columns=120
endif

set hidden
set history=200
set nrformats=bin,hex
set backspace=indent,eol,start " be able to backspace over these chars

set autoread

set wildmode=list:longest,full " tab complete to longest match, second tab lists all matches
set wildignorecase " ignore case when completing file and dir names

set virtualedit=block " allow visual mode block editing to extend past EOL

set path+=**

set laststatus=2    " always display statusline
set statusline=%<%f " file name and path
set statusline+=\ %m%r " modified, read-only flags
set statusline+=\ %y  " filetype according to vim
set statusline+=\ [%{&ff}] " show detected line endings for file
set statusline+=%=
set statusline+=\ [0x\%02.2B] " hex value under cursor
set statusline+=\ [%{v:register}] " active register
set statusline+=\ [%2.10(%l:%c%V%)\ \/\ %L] " line:column / total lines

if executable('rg')
  set grepprg=rg\ --no-messages\ --vimgrep\ --max-filesize\ 5M\ --type-add\ work:include:cpp,c,asm\ --type-add\ work:*.s43\ --type-add\ work:*.S43\ --type-add\ work:*.xcl\ --type-add\ zig:*.zig
  set grepformat=%f:%l:%c:%m,%f:%l:%m
"lgrep search hotkeys
  nmap <Bslash>s yiw:lgrep "<c-R>0"<SPACE>
  nmap <Bslash>S :lgrep<SPACE>
  vmap <Bslash>s y<Bslash>S"<c-R>0"<SPACE>-F<SPACE>

elseif executable("ag")
  set grepprg=ag\ --nogroup\ --nocolor\ --ignore-case\ --column\ --vimgrep
  set grepformat=%f:%l:%c:%m,%f:%l:%m
"lgrep search hotkeys
  nmap <Bslash>s yiw:lgrep "<c-R>0"<SPACE>
  nmap <Bslash>S :lgrep<SPACE>
  vmap <Bslash>s y<Bslash>S"<c-R>0"<SPACE>

endif
"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Key maps
"""""""""""""""""""""""""""""""""""""""""""""""""""""
set timeout timeoutlen=1000 ttimeoutlen=200
let mapleader = ','
imap jk <esc>
vmap s( c()<ESC>P
vmap s{ c{}<ESC>P
vmap s" c""<ESC>P
vmap s` c``<ESC>P
vmap s' c''<ESC>P
nmap ds( %x<c-o>x
nmap ds{ %x<c-o>x
nmap ds" %x<c-o>x
nmap ds` %x<c-o>x
nmap ds' %x<c-o>x
nmap dif viwl%d
nmap yif viwl%y
vmap <Bslash>bs c{<CR>}<ESC>P=i{
vmap s<SPACE> di<SPACE><SPACE><ESC>P
nmap j gj
nmap k gk
vmap j gj
vmap k gk
nmap <c-j> :lnext<CR>z.
nmap <c-k> :lprevious<CR>z.
nmap <Bslash>j :lnewer<CR>
nmap <Bslash>k :lolder<CR>
nmap [[ [[zt3<c-y>
nmap ]] ]]zt3<c-y>
nmap [] []zb<c-e>
nmap ][ ][zb<c-e>
nmap <SPACE> za
nmap <Bslash>. 10<c-w>>
nmap <Bslash>, 10<c-w><
nmap <Bslash>- 10<c-w>-
nmap <Bslash>= 10<c-w>+
nmap <Bslash>u g-
nmap <Bslash>r g+
nmap <Bslash>l :call LocationListToggle()<CR>
vmap <Bslash>/ :call Comment()<CR>
vmap <Bslash>\ :call Uncomment()<CR>
nmap <Bslash>] :call TogglePreview()<CR>
nmap <Bslash>n :call VerticalSplitNoteToggle()<CR>
nmap <Bslash>t :call TerminalToggle()<CR>
" Svn directory diff hotkeys
nmap <Bslash>q :call SvnDiffClose()<CR>:cprev<CR>:call SvnDiffOpen()<CR>
nmap <Bslash>w :call SvnDiffClose()<CR>:cnext<CR>:call SvnDiffOpen()<CR>


tmap <c-\>gt <c-w>:normal gt<CR>
tmap <c-\>gT <c-w>:normal gT<CR>
nmap <c-\>gt <c-w>:normal gt<CR>
nmap <c-\>gT <c-w>:normal gT<CR>
"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! EasyCtags()
  if ((&filetype ==? "c") || (&filetype ==? "cpp") || (&filetype ==? "msp"))
    execute('!ctags -R --languages=C,C++ --exclude=*Examples* . && ctags -Ra --langmap=Asm:+.s43.S43.h --exclude=*Examples* .')
  else
    execute('!ctags -R .')
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! LocationListToggle()
  if exists("w:location_list_orig") "we are in location list
    execute w:location_list_orig."wincmd w"
    unlet w:location_list_winnr
    lclose
  elseif exists("w:location_list_winnr") "we are in original window
    unlet w:location_list_winnr
    lclose
  else
    let t:temp1 = winnr() "original window number
    lopen
    let t:temp2 = winnr() "location list window number tied to previous window
    let w:location_list_orig = t:temp1
    execute w:location_list_orig."wincmd w"
    let w:location_list_winnr = t:temp2
    execute w:location_list_winnr."wincmd w"
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! Comment()
  if (&filetype ==? "c") || (&filetype ==? "cpp") || (&filetype ==? "cs") || (&filetype ==? "zig")
    s;^;//;e
  elseif (&filetype ==? "msp")
    s/^/;/e
  elseif (&filetype ==? "sh")||(&filetype ==? "pov")||(&filetype ==? "nim")||(&filetype ==? "make")
    s/^/# /e
  elseif (&filetype ==? "vim")
    s/^/"/e
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! Uncomment()
  if (&filetype ==? "c") || (&filetype ==? "cpp") || (&filetype ==? "cs") || (&filetype ==? "zig")
    s;^//;;e
  elseif (&filetype ==? "msp")
    s/^;//e
  elseif (&filetype ==? "sh")||(&filetype ==? "pov")||(&filetype ==? "nim")||(&filetype ==? "make")
    s/^# //e
  elseif (&filetype ==? "vim")
    s/^"//e
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TogglePreview()
  if exists("t:pwin")
    unlet t:pwin
    pclose
  else
    let t:pwin = 1
    wincmd }
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! VerticalSplitNoteToggle()
  if exists("t:notes_win_number")
    if win_id2win(t:notes_win_number)
      execute win_id2win(t:notes_win_number)."close!"
    endif
    unlet t:notes_win_number
  else
    botright vsplit NOTES.md
    let t:notes_win_number = win_getid(winnr())
    vertical resize 85
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TerminalToggle()
  if exists("t:terminal_win_num")
    if win_id2win(t:terminal_win_num)
      execute win_id2win(t:terminal_win_num)."wincmd w"
      hide
    endif
    unlet t:terminal_win_num
  else
    botright new
    resize 16 "16 lines tall
    let t:terminal_win_num = win_getid(winnr())
    if exists("t:terminal_buf_num") && bufexists(t:terminal_buf_num)
      execute "buf ".t:terminal_buf_num
    else
      terminal ++curwin ++norestore
      let t:terminal_buf_num = bufnr("%")
    endif
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
set diffexpr="git diff --histogram"
function! SvnDiff()
  if exists("t:svn_head_buf_number")
    call SvnDiffClose()
  else
    call SvnDiffOpen()
  endif
endfunction

function! SvnDiffOpen()
  let t:diff_file_name = expand('%')
  let t:diff_win_num = winnr()
  let t:diff_ft = &filetype
  execute "vert new"
  execute "read !svn cat \"" . t:diff_file_name . "\""
  let t:svn_head_buf_number = bufnr('%')
  execute "set ft=".t:diff_ft
  execute "diffthis"
  execute "normal gg"
  wincmd h
  execute "diffthis"
  execute "normal gg"
endfunction

function! SvnDiffClose()
  execute "windo diffoff"
  if exists("t:svn_head_buf_number")
    execute "bd! " . t:svn_head_buf_number
    unlet t:svn_head_buf_number
  endif
  if exists("t:diff_win_num")
    execute t:diff_win_num . "wincmd w"
    unlet t:diff_win_num
  endif
endfunction
  
function! SvnBeginDirDiff()
  nohl
  botright copen
  execute "set modifiable"
  execute "normal ggVGdd"
  execute "read !svn diff --summarize"
  execute "normal ggdd"
  execute "%normal dw"
  execute "%normal A|1 col 1|"
  execute "setlocal errorformat=%f\\|%l\\ col\\ %c\\|"
  execute "cgetbuffer"
  let qflist = getqflist()
  if len(qflist)
    execute "cfirst"
    call SvnDiffOpen()
  else
    echo "No modified files found."
  endif
endfunction

function! SvnEndDirDiff()
  call SvnDiffClose()
  cclose
endfunction

function! SvnBlameLine()
  let g:blame_file_name = expand('%')
  let g:blame_line_no = line('.')
  let g:blame_cwd = getcwd()
  execute "normal yy"
  execute "tab new"
  "retain working directory information
  execute "normal :lcd ". g:blame_cwd .""
  let g:svn_prev_buf_number = bufnr('%')
  execute "vert new"
  let g:svn_head_buf_number = bufnr('%')
  execute "read !svn blame " . g:blame_file_name
  execute "normal ggdd"
  execute "normal ".g:blame_line_no."ggeyiw"
  execute "normal :let g:blameno=\""
  execute "normal :let g:blameprevno=\"-1"
  normal ggVGd
  "read in revision on right
  execute "read !svn cat " . g:blame_file_name . " -r " . g:blameno
  execute "normal ggi" . g:blame_file_name.":" . g:blameno . ""
  "read in prev revision on left
  wincmd h
  execute "read !svn cat " . g:blame_file_name . " -r " . g:blameprevno
  "diff
  execute "windo diffthis"
  execute "normal gg"
endfunction

function! SvnBlameClose()
  execute "windo diffoff"
  tabprevious
  if exists("g:svn_head_buf_number")
    execute "bd! " . g:svn_head_buf_number
  endif
  if exists("g:svn_prev_buf_number")
    execute "bd! " . g:svn_prev_buf_number
  endif
  if exists("g:blame_line_no")
    execute "normal ".g:blame_line_no."gg"
  endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""
"Auto Functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""
augroup vimrc
  autocmd! vimrc
  au BufNewFile,BufRead *.s43,*.S43 set ft=msp
  au BufNewFile,BufRead *.au3 set ft=autoit
  au BufNewFile,BufRead *.md setlocal textwidth=80
augroup END

let g:onedark_termcolors=16
set background=dark
silent! colorscheme onedark

if has('win32')
  silent! set guifont=Consolas:h11
endif

