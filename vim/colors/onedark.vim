" vim:fdm=marker
" Vim Color File
" Name:       onedark.vim
" Maintainer: https://github.com/joshdick/onedark.vim/
" License:    The MIT License (MIT)
" Based On:   https://github.com/MaxSt/FlatColor/

" A companion [vim-airline](https://github.com/bling/vim-airline) theme is available at: https://github.com/joshdick/airline-onedark.vim

" Color Reference {{{

" The following colors were measured inside Atom using its built-in inspector.

" +---------------------------------------------+
" |  Color Name  |         RGB        |   Hex   |
" |--------------+--------------------+---------|
" | Black        | rgb(40, 44, 52)    | #282c34 |
" |--------------+--------------------+---------|
" | White        | rgb(171, 178, 191) | #abb2bf |
" |--------------+--------------------+---------|
" | Light Red    | rgb(224, 108, 117) | #e06c75 |
" |--------------+--------------------+---------|
" | Dark Red     | rgb(190, 80, 70)   | #be5046 |
" |--------------+--------------------+---------|
" | Green        | rgb(152, 195, 121) | #98c379 |
" |--------------+--------------------+---------|
" | Light Yellow | rgb(229, 192, 123) | #e5c07b |
" |--------------+--------------------+---------|
" | Dark Yellow  | rgb(209, 154, 102) | #d19a66 |
" |--------------+--------------------+---------|
" | Blue         | rgb(97, 175, 239)  | #61afef |
" |--------------+--------------------+---------|
" | Magenta      | rgb(198, 120, 221) | #c678dd |
" |--------------+--------------------+---------|
" | Cyan         | rgb(86, 182, 194)  | #56b6c2 |
" |--------------+--------------------+---------|
" | Gutter Grey  | rgb(76, 82, 99)    | #4b5263 |
" |--------------+--------------------+---------|
" | Comment Grey | rgb(92, 99, 112)   | #5c6370 |
" +---------------------------------------------+

" }}}

" Initialization {{{

highlight clear

if exists("syntax_on")
  syntax reset
endif

set t_Co=256

let g:colors_name="onedark"

" Set to "256" for 256-color terminals, or
" set to "16" to use your terminal emulator's native colors
" (a 16-color palette for this color scheme is available; see
" < https://github.com/joshdick/onedark.vim/blob/master/README.md >
" for more information.)
if !exists("g:onedark_termcolors")
  let g:onedark_termcolors = 256
endif

" Not all terminals support italics properly. If yours does, opt-in.
if !exists("g:onedark_terminal_italics")
  let g:onedark_terminal_italics = 0
endif

" This function is based on one from FlatColor: https://github.com/MaxSt/FlatColor/
" Which in turn was based on one found in hemisu: https://github.com/noahfrederick/vim-hemisu/
function! s:h(group, style)
  if g:onedark_terminal_italics == 0
    if has_key(a:style, "cterm") && a:style["cterm"] == "italic"
      unlet a:style.cterm
    endif
    if has_key(a:style, "gui") && a:style["gui"] == "italic"
      unlet a:style.gui
    endif
  endif
  if g:onedark_termcolors == 16
    let l:ctermfg = (has_key(a:style, "fg") ? a:style.fg.cterm16 : "NONE")
    let l:ctermbg = (has_key(a:style, "bg") ? a:style.bg.cterm16 : "NONE")
  else
    let l:ctermfg = (has_key(a:style, "fg") ? a:style.fg.cterm : "NONE")
    let l:ctermbg = (has_key(a:style, "bg") ? a:style.bg.cterm : "NONE")
  endif
  execute "highlight" a:group
    \ "guifg="   (has_key(a:style, "fg")    ? a:style.fg.gui   : "NONE")
    \ "guibg="   (has_key(a:style, "bg")    ? a:style.bg.gui   : "NONE")
    \ "guisp="   (has_key(a:style, "sp")    ? a:style.sp.gui   : "NONE")
    \ "gui="     (has_key(a:style, "gui")   ? a:style.gui      : "NONE")
    \ "ctermfg=" . l:ctermfg
    \ "ctermbg=" . l:ctermbg
    \ "cterm="   (has_key(a:style, "cterm") ? a:style.cterm    : "NONE")
endfunction

" public {{{

function! onedark#set_highlight(group, style)
  call s:h(a:group, a:style)
endfunction

" }}}

" }}}

" Color Variables {{{

" Dark theme colors (original onedark)
let s:dark_colors = {
      \ 'String': { "gui": "#98C379", "cterm": "114", "cterm16": "2" },
      \ 'Character': { "gui": "#98C379", "cterm": "114", "cterm16": "2" },
      \ 'Number': { "gui": "#D19A66", "cterm": "173", "cterm16": "11" },
      \ 'Boolean': { "gui": "#D19A66", "cterm": "173", "cterm16": "11" },
      \ 'Float': { "gui": "#D19A66", "cterm": "173", "cterm16": "11" },
      \ 'Identifier': { "gui": "#E06C75", "cterm": "204", "cterm16": "1" },
      \ 'Function': { "gui": "#61AFEF", "cterm": "39", "cterm16": "4" },
      \ 'Statement': { "gui": "#C678DD", "cterm": "170", "cterm16": "5" },
      \ 'Conditional': { "gui": "#C678DD", "cterm": "170", "cterm16": "5" },
      \ 'Repeat': { "gui": "#C678DD", "cterm": "170", "cterm16": "5" },
      \ 'Label': { "gui": "#C678DD", "cterm": "170", "cterm16": "5" },
      \ 'Operator': { "gui": "#C678DD", "cterm": "170", "cterm16": "5" },
      \ 'Keyword': { "gui": "#E06C75", "cterm": "204", "cterm16": "1" },
      \ 'Exception': { "gui": "#C678DD", "cterm": "170", "cterm16": "5" },
      \ 'PreProc': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'Include': { "gui": "#61AFEF", "cterm": "39", "cterm16": "4" },
      \ 'Define': { "gui": "#C678DD", "cterm": "170", "cterm16": "5" },
      \ 'Macro': { "gui": "#C678DD", "cterm": "170", "cterm16": "5" },
      \ 'PreCondit': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'Type': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'StorageClass': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'Structure': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'Typedef': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'Special': { "gui": "#61AFEF", "cterm": "39", "cterm16": "4" },
      \ 'SpecialChar': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'Tag': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'Delimiter': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'SpecialComment': { "gui": "#5C6370", "cterm": "59", "cterm16": "15" },
      \ 'Debug': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'Underlined': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'Ignore': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'Error': { "gui": "#E06C75", "cterm": "204", "cterm16": "1" },
      \ 'Todo': { "gui": "#C678DD", "cterm": "170", "cterm16": "5" },
      \ 'Comment': { "gui": "#5C6370", "cterm": "59", "cterm16": "15" },
      \ 'Constant': { "gui": "#56B6C2", "cterm": "38", "cterm16": "6" },
      \ 'Cursor': { "gui": "#61AFEF", "cterm": "39", "cterm16": "4" },
      \ 'Normal': { "gui": "#ABB2BF", "cterm": "145", "cterm16": "7" },
      \ 'ColorColumn': { "gui": "#2C323C", "cterm": "236", "cterm16": "8" },
      \ 'CursorLine': { "gui": "#2C323C", "cterm": "236", "cterm16": "8" },
      \ 'CursorColumn': { "gui": "#2C323C", "cterm": "236", "cterm16": "8" },
      \ 'Directory': { "gui": "#61AFEF", "cterm": "39", "cterm16": "4" },
      \ 'DiffAdd': { "gui": "#98C379", "cterm": "114", "cterm16": "2" },
      \ 'DiffChange': { "gui": "#D19A66", "cterm": "173", "cterm16": "11" },
      \ 'DiffDelete': { "gui": "#E06C75", "cterm": "204", "cterm16": "1" },
      \ 'DiffText': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'ErrorMsg': { "gui": "#E06C75", "cterm": "204", "cterm16": "1" },
      \ 'Folded': { "gui": "#5C6370", "cterm": "59", "cterm16": "15" },
      \ 'FoldColumn': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'SignColumn': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'IncSearch': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'LineNr': { "gui": "#4B5263", "cterm": "238", "cterm16": "15" },
      \ 'CursorLineNr': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'MatchParen': { "gui": "#61AFEF", "cterm": "39", "cterm16": "4" },
      \ 'ModeMsg': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'MoreMsg': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'NonText': { "gui": "#3B4048", "cterm": "238", "cterm16": "15" },
      \ 'Pmenu': { "gui": "#3E4452", "cterm": "237", "cterm16": "8" },
      \ 'PmenuSel': { "gui": "#61AFEF", "cterm": "39", "cterm16": "4" },
      \ 'PmenuSbar': { "gui": "#3B4048", "cterm": "238", "cterm16": "15" },
      \ 'PmenuThumb': { "gui": "#ABB2BF", "cterm": "145", "cterm16": "7" },
      \ 'Question': { "gui": "#C678DD", "cterm": "170", "cterm16": "5" },
      \ 'Search': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'QuickFixLine': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'SpecialKey': { "gui": "#3B4048", "cterm": "238", "cterm16": "15" },
      \ 'SpellBad': { "gui": "#E06C75", "cterm": "204", "cterm16": "1" },
      \ 'SpellCap': { "gui": "#D19A66", "cterm": "173", "cterm16": "11" },
      \ 'SpellLocal': { "gui": "#D19A66", "cterm": "173", "cterm16": "11" },
      \ 'SpellRare': { "gui": "#D19A66", "cterm": "173", "cterm16": "11" },
      \ 'StatusLine': { "gui": "#ABB2BF", "cterm": "145", "cterm16": "7" },
      \ 'StatusLineNC': { "gui": "#5C6370", "cterm": "59", "cterm16": "15" },
      \ 'TabLine': { "gui": "#5C6370", "cterm": "59", "cterm16": "15" },
      \ 'TabLineFill': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'TabLineSel': { "gui": "#ABB2BF", "cterm": "145", "cterm16": "7" },
      \ 'Title': { "gui": "#98C379", "cterm": "114", "cterm16": "2" },
      \ 'Visual': { "gui": "NONE", "cterm": "NONE", "cterm16": "7" },
      \ 'VisualNOS': { "gui": "#3E4452", "cterm": "237", "cterm16": "15" },
      \ 'WarningMsg': { "gui": "#E5C07B", "cterm": "180", "cterm16": "3" },
      \ 'WildMenu': { "gui": "#61AFEF", "cterm": "39", "cterm16": "4" },
      \ 'Background': { "gui": "#282C34", "cterm": "235", "cterm16": "0" },
      \ 'Foreground': { "gui": "#ABB2BF", "cterm": "145", "cterm16": "7" },
      \ 'LessIntenseGreen': { "gui": "#98C379", "cterm": "108", "cterm16": "2" },
      \ 'LessIntenseRed': { "gui": "#BE5046", "cterm": "196", "cterm16": "9" },
      \ 'VisualBlack': { "gui": "NONE", "cterm": "NONE", "cterm16": "0" },
      \ 'GutterFgGrey': { "gui": "#4B5263", "cterm": "238", "cterm16": "15" },
      \ 'CursorGrey': { "gui": "#2C323C", "cterm": "236", "cterm16": "8" },
      \ 'VisualGrey': { "gui": "#3E4452", "cterm": "237", "cterm16": "15" },
      \ 'MenuGrey': { "gui": "#3E4452", "cterm": "237", "cterm16": "8" },
      \ 'SpecialGrey': { "gui": "#3B4048", "cterm": "238", "cterm16": "15" },
      \ }

" Light theme colors (peachpuff-inspired)
let s:light_colors = {
      \ 'String': { "gui": "#c00058", "cterm": "161", "cterm16": "2" },
      \ 'Character': { "gui": "#c00058", "cterm": "161", "cterm16": "2" },
      \ 'Number': { "gui": "#c00058", "cterm": "161", "cterm16": "2" },
      \ 'Boolean': { "gui": "#c00058", "cterm": "161", "cterm16": "2" },
      \ 'Float': { "gui": "#c00058", "cterm": "161", "cterm16": "2" },
      \ 'Identifier': { "gui": "Red3", "cterm": "160", "cterm16": "1" },
      \ 'Function': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'Statement': { "gui": "#3E2723", "cterm": "52", "cterm16": "5" },
      \ 'Conditional': { "gui": "#3E2723", "cterm": "52", "cterm16": "5" },
      \ 'Repeat': { "gui": "#3E2723", "cterm": "52", "cterm16": "5" },
      \ 'Label': { "gui": "#3E2723", "cterm": "52", "cterm16": "5" },
      \ 'Operator': { "gui": "#3E2723", "cterm": "52", "cterm16": "5" },
      \ 'Keyword': { "gui": "#3E2723", "cterm": "52", "cterm16": "5" },
      \ 'Exception': { "gui": "#3E2723", "cterm": "52", "cterm16": "5" },
      \ 'PreProc': { "gui": "SeaGreen", "cterm": "29", "cterm16": "3" },
      \ 'Include': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'Define': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'Macro': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'PreCondit': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'Type': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'StorageClass': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'Structure': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'Typedef': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'Special': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'SpecialChar': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'Tag': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'Delimiter': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'SpecialComment': { "gui": "#406090", "cterm": "24", "cterm16": "8" },
      \ 'Debug': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'Underlined': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'Ignore': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'Error': { "gui": "Red3", "cterm": "160", "cterm16": "1" },
      \ 'Todo': { "gui": "Magenta3", "cterm": "171", "cterm16": "5" },
      \ 'Comment': { "gui": "#406090", "cterm": "24", "cterm16": "8" },
      \ 'Constant': { "gui": "DarkCyan", "cterm": "30", "cterm16": "6" },
      \ 'Cursor': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'Normal': { "gui": "Black", "cterm": "16", "cterm16": "0" },
      \ 'ColorColumn': { "gui": "fg", "cterm": "NONE", "cterm16": "15" },
      \ 'CursorLine': { "gui": "fg", "cterm": "NONE", "cterm16": "15" },
      \ 'CursorColumn': { "gui": "fg", "cterm": "NONE", "cterm16": "15" },
      \ 'Directory': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'DiffAdd': { "gui": "White", "cterm": "231", "cterm16": "15" },
      \ 'DiffChange': { "gui": "#8B4513", "cterm": "130", "cterm16": "11" },
      \ 'DiffDelete': { "gui": "#ff8060", "cterm": "203", "cterm16": "1" },
      \ 'DiffText': { "gui": "SeaGreen", "cterm": "29", "cterm16": "3" },
      \ 'ErrorMsg': { "gui": "Red3", "cterm": "160", "cterm16": "1" },
      \ 'VertSplit': { "gui": "Gray45", "cterm": "244", "cterm16": "8" },
      \ 'Folded': { "gui": "#406090", "cterm": "24", "cterm16": "8" },
      \ 'FoldColumn': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'SignColumn': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'IncSearch': { "gui": "SeaGreen", "cterm": "29", "cterm16": "3" },
      \ 'LineNr': { "gui": "Red3", "cterm": "160", "cterm16": "8" },
      \ 'CursorLineNr': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'MatchParen': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'ModeMsg': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'MoreMsg': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'NonText': { "gui": "SlateBlue", "cterm": "62", "cterm16": "8" },
      \ 'Pmenu': { "gui": "Yellow", "cterm": "226", "cterm16": "11" },
      \ 'PmenuSel': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'PmenuSbar': { "gui": "SlateBlue", "cterm": "62", "cterm16": "8" },
      \ 'PmenuThumb': { "gui": "Black", "cterm": "16", "cterm16": "0" },
      \ 'Question': { "gui": "Magenta3", "cterm": "171", "cterm16": "5" },
      \ 'Search': { "gui": "SeaGreen", "cterm": "29", "cterm16": "3" },
      \ 'QuickFixLine': { "gui": "SeaGreen", "cterm": "29", "cterm16": "3" },
      \ 'SpecialKey': { "gui": "SlateBlue", "cterm": "62", "cterm16": "8" },
      \ 'SpellBad': { "gui": "Red3", "cterm": "160", "cterm16": "1" },
      \ 'SpellCap': { "gui": "#8B4513", "cterm": "130", "cterm16": "11" },
      \ 'SpellLocal': { "gui": "#8B4513", "cterm": "130", "cterm16": "11" },
      \ 'SpellRare': { "gui": "#8B4513", "cterm": "130", "cterm16": "11" },
      \ 'StatusLine': { "gui": "Black", "cterm": "16", "cterm16": "0" },
      \ 'StatusLineNC': { "gui": "#406090", "cterm": "24", "cterm16": "8" },
      \ 'TabLine': { "gui": "#406090", "cterm": "24", "cterm16": "8" },
      \ 'TabLineFill': { "gui": "NONE", "cterm": "NONE", "cterm16": "NONE" },
      \ 'TabLineSel': { "gui": "Black", "cterm": "16", "cterm16": "0" },
      \ 'Title': { "gui": "#c00058", "cterm": "161", "cterm16": "2" },
      \ 'Visual': { "gui": "Grey80", "cterm": "252", "cterm16": "7" },
      \ 'VisualNOS': { "gui": "Grey80", "cterm": "252", "cterm16": "7" },
      \ 'WarningMsg': { "gui": "SeaGreen", "cterm": "29", "cterm16": "3" },
      \ 'WildMenu': { "gui": "Blue", "cterm": "21", "cterm16": "4" },
      \ 'Background': { "gui": "PeachPuff", "cterm": "223", "cterm16": "7" },
      \ 'Foreground': { "gui": "Black", "cterm": "16", "cterm16": "0" },
      \ 'LessIntenseGreen': { "gui": "White", "cterm": "231", "cterm16": "15" },
      \ 'LessIntenseRed': { "gui": "#ff8060", "cterm": "203", "cterm16": "1" },
      \ 'VisualBlack': { "gui": "Grey80", "cterm": "252", "cterm16": "7" },
      \ 'GutterFgGrey': { "gui": "Red3", "cterm": "160", "cterm16": "8" },
      \ 'CursorGrey': { "gui": "fg", "cterm": "NONE", "cterm16": "15" },
      \ 'VisualGrey': { "gui": "Grey80", "cterm": "252", "cterm16": "7" },
      \ 'MenuGrey': { "gui": "Yellow", "cterm": "226", "cterm16": "11" },
      \ 'SpecialGrey': { "gui": "SlateBlue", "cterm": "62", "cterm16": "8" },
      \ }

function! s:get_color_for(group)
  if &background == 'light'
    return get(s:light_colors, a:group, s:light_colors['Normal'])
  else
    return get(s:dark_colors, a:group, s:dark_colors['Normal'])
  endif
endfunction

" }}}

" Syntax Groups (descriptions and ordering from `:h w18`) {{{

call s:h("Comment", { "fg": s:get_color_for("Comment"), "gui": "italic", "cterm": "italic" }) " any comment
call s:h("Constant", { "fg": s:get_color_for("Constant") }) " any constant
call s:h("String", { "fg": s:get_color_for("String") }) " a string constant: "this is a string"
call s:h("Character", { "fg": s:get_color_for("Character") }) " a character constant: 'c', '\n'
call s:h("Number", { "fg": s:get_color_for("Number") }) " a number constant: 234, 0xff
call s:h("Boolean", { "fg": s:get_color_for("Boolean") }) " a boolean constant: TRUE, false
call s:h("Float", { "fg": s:get_color_for("Float") }) " a floating point constant: 2.3e10
call s:h("Identifier", { "fg": s:get_color_for("Identifier") }) " any variable name
call s:h("Function", { "fg": s:get_color_for("Function") }) " function name (also: methods for classes)
call s:h("Statement", { "fg": s:get_color_for("Statement") }) " return, goto, break, continue, switch
call s:h("Conditional", { "fg": s:get_color_for("Conditional") }) " if, then, else, endif
call s:h("Repeat", { "fg": s:get_color_for("Repeat") }) " for, do, while
call s:h("Label", { "fg": s:get_color_for("Label") }) " case, default
call s:h("Operator", { "fg": s:get_color_for("Operator") }) " sizeof, +, *, etc.
call s:h("Keyword", { "fg": s:get_color_for("Keyword") }) " any other keyword
call s:h("Exception", { "fg": s:get_color_for("Exception") }) " try, catch, throw
call s:h("PreProc", { "fg": s:get_color_for("PreProc") }) " generic Preprocessor
call s:h("Include", { "fg": s:get_color_for("Include") }) " preprocessor #include
call s:h("Define", { "fg": s:get_color_for("Define") }) " preprocessor #define
call s:h("Macro", { "fg": s:get_color_for("Macro") }) " same as Define
call s:h("PreCondit", { "fg": s:get_color_for("PreCondit") }) " preprocessor #if, #else, #endif, etc.
call s:h("Type", { "fg": s:get_color_for("Type") }) " int, long, char, float, double, etc.
call s:h("StorageClass", { "fg": s:get_color_for("StorageClass") }) " static, register, volatile, const, extern
call s:h("Structure", { "fg": s:get_color_for("Structure") }) " struct, union, enum
call s:h("Typedef", { "fg": s:get_color_for("Typedef") }) " typedef declarations
call s:h("Special", { "fg": s:get_color_for("Special") }) " any special symbol
call s:h("SpecialChar", { "fg": s:get_color_for("SpecialChar") }) " special character in a constant
call s:h("Tag", { "fg": s:get_color_for("Tag") }) " you can use CTRL-] on this
call s:h("Delimiter", { "fg": s:get_color_for("Delimiter") }) " character that needs attention
call s:h("SpecialComment", { "fg": s:get_color_for("SpecialComment") }) " special things inside a comment
call s:h("Debug", { "fg": s:get_color_for("Debug") }) " debugging statements
call s:h("Underlined", { "gui": "underline", "cterm": "underline" }) " text that stands out, HTML links
call s:h("Ignore", { "fg": s:get_color_for("Ignore") }) " left blank, hidden
call s:h("Error", { "fg": s:get_color_for("Error") }) " any erroneous construct
call s:h("Todo", { "fg": s:get_color_for("Todo") }) " anything that needs extra attention; mostly the keywords TODO FIXME and XXX

" }}}

" Highlighting Groups (descriptions and ordering from `:h highlight-groups`) {{{
call s:h("ColorColumn", { "bg": s:get_color_for("ColorColumn") }) " used for the columns set with 'colorcolumn'
call s:h("Conceal", { "fg": s:get_color_for("Conceal") }) " placeholder characters substituted for concealed text (see 'conceallevel')
call s:h("Cursor", { "fg": s:get_color_for("Background"), "bg": s:get_color_for("Cursor") }) " the character under the cursor
call s:h("CursorIM", { "fg": s:get_color_for("CursorIM") }) " like Cursor, but used when in IME mode
call s:h("CursorColumn", { "bg": s:get_color_for("CursorColumn") }) " the screen column that the cursor is in when 'cursorcolumn' is set
if &diff
  " Don't change the background color in diff mode
  call s:h("CursorLine", { "gui": "underline" }) " the screen line that the cursor is in when 'cursorline' is set
else
  call s:h("CursorLine", { "bg": s:get_color_for("CursorLine") }) " the screen line that the cursor is in when 'cursorline' is set
endif
call s:h("Directory", { "fg": s:get_color_for("Directory") }) " directory names (and other special names in listings)
call s:h("DiffAdd", { "bg": s:get_color_for("DiffAdd"), "fg": s:get_color_for("Background") }) " diff mode: Added line
call s:h("DiffChange", { "bg": s:get_color_for("DiffChange"), "fg": s:get_color_for("Background") }) " diff mode: Changed line
call s:h("DiffDelete", { "bg": s:get_color_for("DiffDelete"), "fg": s:get_color_for("Background") }) " diff mode: Deleted line
call s:h("DiffText", { "bg": s:get_color_for("Background"), "fg": s:get_color_for("DiffText") }) " diff mode: Changed text within a changed line
call s:h("ErrorMsg", { "fg": s:get_color_for("ErrorMsg") }) " error messages on the command line
call s:h("VertSplit", { "fg": s:get_color_for("VertSplit") }) " the column separating vertically split windows
call s:h("Folded", { "fg": s:get_color_for("Folded") }) " line used for closed folds
call s:h("FoldColumn", { "fg": s:get_color_for("FoldColumn") }) " 'foldcolumn'
call s:h("SignColumn", { "fg": s:get_color_for("SignColumn") }) " column where signs are displayed
call s:h("IncSearch", { "fg": s:get_color_for("PreProc"), "bg": s:get_color_for("Comment") }) " 'incsearch' highlighting; also used for the text replaced with ":s///c"
call s:h("LineNr", { "fg": s:get_color_for("LineNr") }) " Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
call s:h("CursorLineNr", { "fg": s:get_color_for("CursorLineNr") }) " Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
call s:h("MatchParen", { "fg": s:get_color_for("Function"), "gui": "underline" }) " The character under the cursor or just before it, if it is a paired bracket, and its match.
call s:h("ModeMsg", { "fg": s:get_color_for("ModeMsg") }) " 'showmode' message (e.g., "-- INSERT --")
call s:h("MoreMsg", { "fg": s:get_color_for("MoreMsg") }) " more-prompt
call s:h("NonText", { "fg": s:get_color_for("NonText") }) " '~' and '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line).
call s:h("Normal", { "fg": s:get_color_for("Foreground"), "bg": s:get_color_for("Background") }) " normal text
call s:h("Pmenu", { "bg": s:get_color_for("Pmenu") }) " Popup menu: normal item.
call s:h("PmenuSel", { "fg": s:get_color_for("Background"), "bg": s:get_color_for("Function") }) " Popup menu: selected item.
call s:h("PmenuSbar", { "bg": s:get_color_for("NonText") }) " Popup menu: scrollbar.
call s:h("PmenuThumb", { "bg": s:get_color_for("Foreground") }) " Popup menu: Thumb of the scrollbar.
call s:h("Question", { "fg": s:get_color_for("Statement") }) " hit-enter prompt and yes/no questions
call s:h("Search", { "fg": s:get_color_for("Background"), "bg": s:get_color_for("PreProc") }) " Last search pattern highlighting (see 'hlsearch'). Also used for similar items that need to stand out.
call s:h("QuickFixLine", { "fg": s:get_color_for("Background"), "bg": s:get_color_for("PreProc") }) " Current quickfix item in the quickfix window.
call s:h("SpecialKey", { "fg": s:get_color_for("NonText") }) " Meta and special keys listed with ":map", also for text used to show unprintable characters in the text, 'listchars'. Generally: text that is displayed differently from what it really is.
call s:h("SpellBad", { "fg": s:get_color_for("Error"), "gui": "underline", "cterm": "underline" }) " Word that is not recognized by the spellchecker. This will be combined with the highlighting used otherwise.
call s:h("SpellCap", { "fg": s:get_color_for("Boolean") }) " Word that should start with a capital. This will be combined with the highlighting used otherwise.
call s:h("SpellLocal", { "fg": s:get_color_for("Boolean") }) " Word that is recognized by the spellchecker as one that is used in another region. This will be combined with the highlighting used otherwise.
call s:h("SpellRare", { "fg": s:get_color_for("Boolean") }) " Word that is recognized by the spellchecker as one that is hardly ever used. spell This will be combined with the highlighting used otherwise.
call s:h("StatusLine", { "fg": s:get_color_for("Foreground"), "bg": s:get_color_for("CursorGrey") }) " status line of current window
call s:h("StatusLineNC", { "fg": s:get_color_for("Comment") }) " status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
call s:h("TabLine", { "fg": s:get_color_for("Comment") }) " tab pages line, not active tab page label
call s:h("TabLineFill", { "fg": s:get_color_for("TabLineFill") }) " tab pages line, where there are no labels
call s:h("TabLineSel", { "fg": s:get_color_for("Foreground") }) " tab pages line, active tab page label
call s:h("Title", { "fg": s:get_color_for("String") }) " titles for output from ":set all", ":autocmd" etc.
call s:h("Visual", { "fg": s:get_color_for("VisualBlack"), "bg": s:get_color_for("VisualGrey") }) " Visual mode selection
call s:h("VisualNOS", { "bg": s:get_color_for("VisualGrey") }) " Visual mode selection when vim is "Not Owning the Selection". Only X11 Gui's gui-x11 and xterm-clipboard supports this.
call s:h("WarningMsg", { "fg": s:get_color_for("PreProc") }) " warning messages
call s:h("WildMenu", { "fg": s:get_color_for("Background"), "bg": s:get_color_for("Function") }) " current match in 'wildmenu' completion

" }}}

" Language-Specific Highlighting {{{

" CSS
call s:h("cssAttrComma", { "fg": s:get_color_for("Statement") })
call s:h("cssAttributeSelector", { "fg": s:get_color_for("String") })
call s:h("cssBraces", { "fg": s:get_color_for("Foreground") })
call s:h("cssClassName", { "fg": s:get_color_for("Boolean") })
call s:h("cssClassNameDot", { "fg": s:get_color_for("Boolean") })
call s:h("cssDefinition", { "fg": s:get_color_for("Statement") })
call s:h("cssFontAttr", { "fg": s:get_color_for("Boolean") })
call s:h("cssFontDescriptor", { "fg": s:get_color_for("Statement") })
call s:h("cssFunctionName", { "fg": s:get_color_for("Function") })
call s:h("cssIdentifier", { "fg": s:get_color_for("Function") })
call s:h("cssImportant", { "fg": s:get_color_for("Statement") })
call s:h("cssInclude", { "fg": s:get_color_for("Foreground") })
call s:h("cssIncludeKeyword", { "fg": s:get_color_for("Statement") })
call s:h("cssMediaType", { "fg": s:get_color_for("Boolean") })
call s:h("cssProp", { "fg": s:get_color_for("Foreground") })
call s:h("cssPseudoClassId", { "fg": s:get_color_for("Boolean") })
call s:h("cssSelectorOp", { "fg": s:get_color_for("Statement") })
call s:h("cssSelectorOp2", { "fg": s:get_color_for("Statement") })
call s:h("cssTagName", { "fg": s:get_color_for("Identifier") })

" Go
call s:h("goDeclaration", { "fg": s:get_color_for("Statement") })

" HTML
call s:h("htmlTitle", { "fg": s:get_color_for("Foreground") })
call s:h("htmlArg", { "fg": s:get_color_for("Boolean") })
call s:h("htmlEndTag", { "fg": s:get_color_for("Foreground") })
call s:h("htmlH1", { "fg": s:get_color_for("Foreground") })
call s:h("htmlLink", { "fg": s:get_color_for("Statement") })
call s:h("htmlSpecialChar", { "fg": s:get_color_for("Boolean") })
call s:h("htmlSpecialTagName", { "fg": s:get_color_for("Identifier") })
call s:h("htmlTag", { "fg": s:get_color_for("Foreground") })
call s:h("htmlTagName", { "fg": s:get_color_for("Identifier") })

" JavaScript
call s:h("javaScriptBraces", { "fg": s:get_color_for("Foreground") })
call s:h("javaScriptFunction", { "fg": s:get_color_for("Statement") })
call s:h("javaScriptIdentifier", { "fg": s:get_color_for("Statement") })
call s:h("javaScriptNull", { "fg": s:get_color_for("Boolean") })
call s:h("javaScriptNumber", { "fg": s:get_color_for("Boolean") })
call s:h("javaScriptRequire", { "fg": s:get_color_for("Special") })
call s:h("javaScriptReserved", { "fg": s:get_color_for("Statement") })
" https://github.com/pangloss/vim-javascript
call s:h("jsArrowFunction", { "fg": s:get_color_for("Statement") })
call s:h("jsClassKeyword", { "fg": s:get_color_for("Statement") })
call s:h("jsClassMethodType", { "fg": s:get_color_for("Statement") })
call s:h("jsDocParam", { "fg": s:get_color_for("Function") })
call s:h("jsDocTags", { "fg": s:get_color_for("Statement") })
call s:h("jsExport", { "fg": s:get_color_for("Statement") })
call s:h("jsExportDefault", { "fg": s:get_color_for("Statement") })
call s:h("jsExtendsKeyword", { "fg": s:get_color_for("Statement") })
call s:h("jsFrom", { "fg": s:get_color_for("Statement") })
call s:h("jsFuncCall", { "fg": s:get_color_for("Function") })
call s:h("jsFunction", { "fg": s:get_color_for("Statement") })
call s:h("jsGenerator", { "fg": s:get_color_for("Type") })
call s:h("jsGlobalObjects", { "fg": s:get_color_for("Type") })
call s:h("jsImport", { "fg": s:get_color_for("Statement") })
call s:h("jsModuleAs", { "fg": s:get_color_for("Statement") })
call s:h("jsModuleWords", { "fg": s:get_color_for("Statement") })
call s:h("jsModules", { "fg": s:get_color_for("Statement") })
call s:h("jsNull", { "fg": s:get_color_for("Boolean") })
call s:h("jsOperator", { "fg": s:get_color_for("Statement") })
call s:h("jsStorageClass", { "fg": s:get_color_for("Statement") })
call s:h("jsSuper", { "fg": s:get_color_for("Identifier") })
call s:h("jsTemplateBraces", { "fg": s:get_color_for("LessIntenseRed") })
call s:h("jsTemplateVar", { "fg": s:get_color_for("String") })
call s:h("jsThis", { "fg": s:get_color_for("Identifier") })
call s:h("jsUndefined", { "fg": s:get_color_for("Boolean") })
" https://github.com/othree/yajs.vim
call s:h("javascriptArrowFunc", { "fg": s:get_color_for("Statement") })
call s:h("javascriptClassExtends", { "fg": s:get_color_for("Statement") })
call s:h("javascriptClassKeyword", { "fg": s:get_color_for("Statement") })
call s:h("javascriptDocNotation", { "fg": s:get_color_for("Statement") })
call s:h("javascriptDocParamName", { "fg": s:get_color_for("Function") })
call s:h("javascriptDocTags", { "fg": s:get_color_for("Statement") })
call s:h("javascriptEndColons", { "fg": s:get_color_for("Foreground") })
call s:h("javascriptExport", { "fg": s:get_color_for("Statement") })
call s:h("javascriptFuncArg", { "fg": s:get_color_for("Foreground") })
call s:h("javascriptFuncKeyword", { "fg": s:get_color_for("Statement") })
call s:h("javascriptIdentifier", { "fg": s:get_color_for("Identifier") })
call s:h("javascriptImport", { "fg": s:get_color_for("Statement") })
call s:h("javascriptMethodName", { "fg": s:get_color_for("Foreground") })
call s:h("javascriptObjectLabel", { "fg": s:get_color_for("Foreground") })
call s:h("javascriptOpSymbol", { "fg": s:get_color_for("Special") })
call s:h("javascriptOpSymbols", { "fg": s:get_color_for("Special") })
call s:h("javascriptPropertyName", { "fg": s:get_color_for("String") })
call s:h("javascriptTemplateSB", { "fg": s:get_color_for("LessIntenseRed") })
call s:h("javascriptVariable", { "fg": s:get_color_for("Statement") })

" JSON
call s:h("jsonCommentError", { "fg": s:get_color_for("Foreground") })
call s:h("jsonKeyword", { "fg": s:get_color_for("Identifier") })
call s:h("jsonBoolean", { "fg": s:get_color_for("Boolean") })
call s:h("jsonNumber", { "fg": s:get_color_for("Boolean") })
call s:h("jsonQuote", { "fg": s:get_color_for("Foreground") })
call s:h("jsonMissingCommaError", { "fg": s:get_color_for("Identifier"), "gui": "reverse" })
call s:h("jsonNoQuotesError", { "fg": s:get_color_for("Identifier"), "gui": "reverse" })
call s:h("jsonNumError", { "fg": s:get_color_for("Identifier"), "gui": "reverse" })
call s:h("jsonString", { "fg": s:get_color_for("String") })
call s:h("jsonStringSQError", { "fg": s:get_color_for("Identifier"), "gui": "reverse" })
call s:h("jsonSemicolonError", { "fg": s:get_color_for("Identifier"), "gui": "reverse" })

" LESS
call s:h("lessVariable", { "fg": s:get_color_for("Statement") })
call s:h("lessAmpersandChar", { "fg": s:get_color_for("Foreground") })
call s:h("lessClass", { "fg": s:get_color_for("Boolean") })

" Markdown
call s:h("markdownCode", { "fg": s:get_color_for("String") })
call s:h("markdownCodeBlock", { "fg": s:get_color_for("String") })
call s:h("markdownCodeDelimiter", { "fg": s:get_color_for("String") })
call s:h("markdownHeadingDelimiter", { "fg": s:get_color_for("Identifier") })
call s:h("markdownRule", { "fg": s:get_color_for("Comment") })
call s:h("markdownHeadingRule", { "fg": s:get_color_for("Comment") })
call s:h("markdownH1", { "fg": s:get_color_for("Identifier") })
call s:h("markdownH2", { "fg": s:get_color_for("Identifier") })
call s:h("markdownH3", { "fg": s:get_color_for("Identifier") })
call s:h("markdownH4", { "fg": s:get_color_for("Identifier") })
call s:h("markdownH5", { "fg": s:get_color_for("Identifier") })
call s:h("markdownH6", { "fg": s:get_color_for("Identifier") })
call s:h("markdownIdDelimiter", { "fg": s:get_color_for("Statement") })
call s:h("markdownId", { "fg": s:get_color_for("Statement") })
call s:h("markdownBlockquote", { "fg": s:get_color_for("Comment") })
call s:h("markdownItalic", { "fg": s:get_color_for("Statement"), "gui": "italic", "cterm": "italic" })
call s:h("markdownBold", { "fg": s:get_color_for("Boolean"), "gui": "bold", "cterm": "bold" })
call s:h("markdownListMarker", { "fg": s:get_color_for("Identifier") })
call s:h("markdownOrderedListMarker", { "fg": s:get_color_for("Identifier") })
call s:h("markdownIdDeclaration", { "fg": s:get_color_for("Function") })
call s:h("markdownLinkText", { "fg": s:get_color_for("Function") })
call s:h("markdownLinkDelimiter", { "fg": s:get_color_for("Foreground") })
call s:h("markdownUrl", { "fg": s:get_color_for("Statement") })

" Perl
call s:h("perlFiledescRead", { "fg": s:get_color_for("String") })
call s:h("perlFunction", { "fg": s:get_color_for("Statement") })
call s:h("perlMatchStartEnd",{ "fg": s:get_color_for("Function") })
call s:h("perlMethod", { "fg": s:get_color_for("Statement") })
call s:h("perlPOD", { "fg": s:get_color_for("Comment") })
call s:h("perlSharpBang", { "fg": s:get_color_for("Comment") })
call s:h("perlSpecialString",{ "fg": s:get_color_for("Special") })
call s:h("perlStatementFiledesc", { "fg": s:get_color_for("Identifier") })
call s:h("perlStatementFlow",{ "fg": s:get_color_for("Identifier") })
call s:h("perlStatementInclude", { "fg": s:get_color_for("Statement") })
call s:h("perlStatementScalar",{ "fg": s:get_color_for("Statement") })
call s:h("perlStatementStorage", { "fg": s:get_color_for("Statement") })
call s:h("perlSubName",{ "fg": s:get_color_for("Type") })
call s:h("perlVarPlain",{ "fg": s:get_color_for("Function") })

" PHP
call s:h("phpVarSelector", { "fg": s:get_color_for("Identifier") })
call s:h("phpOperator", { "fg": s:get_color_for("Foreground") })
call s:h("phpParent", { "fg": s:get_color_for("Foreground") })
call s:h("phpMemberSelector", { "fg": s:get_color_for("Foreground") })
call s:h("phpType", { "fg": s:get_color_for("Statement") })
call s:h("phpKeyword", { "fg": s:get_color_for("Statement") })
call s:h("phpClass", { "fg": s:get_color_for("Type") })
call s:h("phpUseClass", { "fg": s:get_color_for("Foreground") })
call s:h("phpUseAlias", { "fg": s:get_color_for("Foreground") })
call s:h("phpInclude", { "fg": s:get_color_for("Statement") })
call s:h("phpClassExtends", { "fg": s:get_color_for("String") })
call s:h("phpDocTags", { "fg": s:get_color_for("Foreground") })
call s:h("phpFunction", { "fg": s:get_color_for("Function") })
call s:h("phpFunctions", { "fg": s:get_color_for("Special") })
call s:h("phpMethodsVar", { "fg": s:get_color_for("Boolean") })
call s:h("phpMagicConstants", { "fg": s:get_color_for("Boolean") })
call s:h("phpSuperglobals", { "fg": s:get_color_for("Identifier") })
call s:h("phpConstants", { "fg": s:get_color_for("Boolean") })

" Ruby
call s:h("rubyBlockParameter", { "fg": s:get_color_for("Identifier")})
call s:h("rubyBlockParameterList", { "fg": s:get_color_for("Identifier") })
call s:h("rubyClass", { "fg": s:get_color_for("Statement")})
call s:h("rubyConstant", { "fg": s:get_color_for("Type")})
call s:h("rubyControl", { "fg": s:get_color_for("Statement") })
call s:h("rubyEscape", { "fg": s:get_color_for("Identifier")})
call s:h("rubyFunction", { "fg": s:get_color_for("Function")})
call s:h("rubyGlobalVariable", { "fg": s:get_color_for("Identifier")})
call s:h("rubyInclude", { "fg": s:get_color_for("Function")})
call s:h("rubyIncluderubyGlobalVariable", { "fg": s:get_color_for("Identifier")})
call s:h("rubyInstanceVariable", { "fg": s:get_color_for("Identifier")})
call s:h("rubyInterpolation", { "fg": s:get_color_for("Special") })
call s:h("rubyInterpolationDelimiter", { "fg": s:get_color_for("Identifier") })
call s:h("rubyInterpolationDelimiter", { "fg": s:get_color_for("Identifier")})
call s:h("rubyRegexp", { "fg": s:get_color_for("Special")})
call s:h("rubyRegexpDelimiter", { "fg": s:get_color_for("Special")})
call s:h("rubyStringDelimiter", { "fg": s:get_color_for("String")})
call s:h("rubySymbol", { "fg": s:get_color_for("Special")})

" Sass
" https://github.com/tpope/vim-haml
call s:h("sassAmpersand", { "fg": s:get_color_for("Identifier") })
call s:h("sassClass", { "fg": s:get_color_for("Boolean") })
call s:h("sassControl", { "fg": s:get_color_for("Statement") })
call s:h("sassExtend", { "fg": s:get_color_for("Statement") })
call s:h("sassFor", { "fg": s:get_color_for("Foreground") })
call s:h("sassFunction", { "fg": s:get_color_for("Special") })
call s:h("sassId", { "fg": s:get_color_for("Function") })
call s:h("sassInclude", { "fg": s:get_color_for("Statement") })
call s:h("sassMedia", { "fg": s:get_color_for("Statement") })
call s:h("sassMediaOperators", { "fg": s:get_color_for("Foreground") })
call s:h("sassMixin", { "fg": s:get_color_for("Statement") })
call s:h("sassMixinName", { "fg": s:get_color_for("Function") })
call s:h("sassMixing", { "fg": s:get_color_for("Statement") })
call s:h("sassVariable", { "fg": s:get_color_for("Statement") })
" https://github.com/cakebaker/scss-syntax.vim
call s:h("scssExtend", { "fg": s:get_color_for("Statement") })
call s:h("scssImport", { "fg": s:get_color_for("Statement") })
call s:h("scssInclude", { "fg": s:get_color_for("Statement") })
call s:h("scssMixin", { "fg": s:get_color_for("Statement") })
call s:h("scssSelectorName", { "fg": s:get_color_for("Boolean") })
call s:h("scssVariable", { "fg": s:get_color_for("Statement") })

" TypeScript
call s:h("typescriptReserved", { "fg": s:get_color_for("Statement") })
call s:h("typescriptEndColons", { "fg": s:get_color_for("Foreground") })
call s:h("typescriptBraces", { "fg": s:get_color_for("Foreground") })

" XML
call s:h("xmlAttrib", { "fg": s:get_color_for("Boolean") })
call s:h("xmlEndTag", { "fg": s:get_color_for("Identifier") })
call s:h("xmlTag", { "fg": s:get_color_for("Identifier") })
call s:h("xmlTagName", { "fg": s:get_color_for("Identifier") })

" }}}

" Plugin Highlighting {{{

" airblade/vim-gitgutter
hi link GitGutterAdd    SignifySignAdd
hi link GitGutterChange SignifySignChange
hi link GitGutterDelete SignifySignDelete

" mhinz/vim-signify
call s:h("SignifySignAdd", { "fg": s:get_color_for("String") })
call s:h("SignifySignChange", { "fg": s:get_color_for("Type") })
call s:h("SignifySignDelete", { "fg": s:get_color_for("Identifier") })

" neomake/neomake
call s:h("NeomakeWarningSign", { "fg": s:get_color_for("Type") })
call s:h("NeomakeErrorSign", { "fg": s:get_color_for("Identifier") })
call s:h("NeomakeInfoSign", { "fg": s:get_color_for("Function") })

" tpope/vim-fugitive
call s:h("diffAdded", { "fg": s:get_color_for("String") })
call s:h("diffRemoved", { "fg": s:get_color_for("Identifier") })

" }}}

" Git Highlighting {{{

call s:h("gitcommitComment", { "fg": s:get_color_for("Comment") })
call s:h("gitcommitUnmerged", { "fg": s:get_color_for("String") })
call s:h("gitcommitOnBranch", {})
call s:h("gitcommitBranch", { "fg": s:get_color_for("Statement") })
call s:h("gitcommitDiscardedType", { "fg": s:get_color_for("Identifier") })
call s:h("gitcommitSelectedType", { "fg": s:get_color_for("String") })
call s:h("gitcommitHeader", {})
call s:h("gitcommitUntrackedFile", { "fg": s:get_color_for("Special") })
call s:h("gitcommitDiscardedFile", { "fg": s:get_color_for("Identifier") })
call s:h("gitcommitSelectedFile", { "fg": s:get_color_for("String") })
call s:h("gitcommitUnmergedFile", { "fg": s:get_color_for("Type") })
call s:h("gitcommitFile", {})
call s:h("gitcommitSummary", { "fg": s:get_color_for("Foreground") })
call s:h("gitcommitOverflow", { "fg": s:get_color_for("Identifier") })
hi link gitcommitNoBranch gitcommitBranch
hi link gitcommitUntracked gitcommitComment
hi link gitcommitDiscarded gitcommitComment
hi link gitcommitSelected gitcommitComment
hi link gitcommitDiscardedArrow gitcommitDiscardedFile
hi link gitcommitSelectedArrow gitcommitSelectedFile
hi link gitcommitUnmergedArrow gitcommitUnmergedFile

" }}}

" Neovim terminal colors {{{

if has("nvim")
  let l:bg_colors = &background == 'light' ? s:light_colors : s:dark_colors
  let g:terminal_color_0 =  l:bg_colors['Background'].gui
  let g:terminal_color_1 =  l:bg_colors['Identifier'].gui
  let g:terminal_color_2 =  l:bg_colors['String'].gui
  let g:terminal_color_3 =  l:bg_colors['Type'].gui
  let g:terminal_color_4 =  l:bg_colors['Function'].gui
  let g:terminal_color_5 =  l:bg_colors['Statement'].gui
  let g:terminal_color_6 =  l:bg_colors['Special'].gui
  let g:terminal_color_7 =  l:bg_colors['Foreground'].gui
  let g:terminal_color_8 =  l:bg_colors['VisualGrey'].gui
  let g:terminal_color_9 =  l:bg_colors['LessIntenseRed'].gui
  let g:terminal_color_10 = l:bg_colors['String'].gui " No dark version
  let g:terminal_color_11 = l:bg_colors['Boolean'].gui
  let g:terminal_color_12 = l:bg_colors['Function'].gui " No dark version
  let g:terminal_color_13 = l:bg_colors['Statement'].gui " No dark version
  let g:terminal_color_14 = l:bg_colors['Special'].gui " No dark version
  let g:terminal_color_15 = l:bg_colors['Comment'].gui
  let g:terminal_color_background = g:terminal_color_0
  let g:terminal_color_foreground = g:terminal_color_7
endif

" }}}

" Must appear at the end of the file to work around this oddity:
" https://groups.google.com/forum/#!msg/vim_dev/afPqwAFNdrU/nqh6tOM87QUJ
" Note: background is now set dynamically based on user preference
