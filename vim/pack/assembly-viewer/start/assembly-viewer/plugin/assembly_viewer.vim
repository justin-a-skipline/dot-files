" Assembly Viewer for Vim and Neovim
" Shows the assembly of each C line under that line, read from the .mylint
" object that mylint.vim builds.
"
" bin/assembly_viewer.py does the reading. It runs as a job, through async.vim,
" which is the one job API that works in both editors. mylint.vim uses it too.

if exists('g:loaded_assembly_viewer')
    finish
endif
let g:loaded_assembly_viewer = 1

" Both editors draw text that is not in the buffer, under different names.
" Vim calls it a text property, Neovim calls it an extmark.
if has('nvim')
    if !has('nvim-0.6')
        echom 'Assembly viewer needs Neovim 0.6 or later'
        finish
    endif
elseif !has('patch-9.0.0067')
    echom 'Assembly viewer needs Vim 9.0.0067 or later'
    finish
endif

if !executable('python3')
    echom 'Assembly viewer requires python3'
    finish
endif

if !exists('g:assembly_viewer_enabled')
    let g:assembly_viewer_enabled = 0
endif

if !exists('g:assembly_viewer_auto_update')
    let g:assembly_viewer_auto_update = 1
endif

let s:reader = expand('<sfile>:p:h:h') . '/bin/assembly_viewer.py'

" One job for each buffer. A second request replaces the first, so a fast
" typist does not queue up work that is already out of date.
let s:jobs = {}

highlight default link AssemblyInline Comment

if has('nvim')
    let s:namespace = nvim_create_namespace('assembly_viewer')
elseif empty(prop_type_get('AssemblyInline'))
    call prop_type_add('AssemblyInline', {'highlight': 'AssemblyInline'})
endif

function! s:StopJob(bufnr)
    if !has_key(s:jobs, a:bufnr)
        return
    endif

    silent! call async#job#stop(s:jobs[a:bufnr])
    unlet s:jobs[a:bufnr]
endfunction

" Reads the assembly of a buffer, and calls Done with what it found.
function! s:ReadAssembly(bufnr, done)
    if !exists('*async#job#start')
        echom 'Assembly viewer needs async.vim, the same one mylint.vim uses'
        return
    endif

    let l:file_path = fnamemodify(bufname(a:bufnr), ':p')
    if empty(l:file_path)
        echom 'Assembly viewer: no file name for this buffer'
        return
    endif

    call s:StopJob(a:bufnr)

    let l:answer = tempname()
    let l:command = ['python3', s:reader, l:file_path, l:answer]

    let s:jobs[a:bufnr] = async#job#start(l:command,
        \ {'on_exit': function('s:JobFinished', [a:bufnr, l:answer, a:done])})
endfunction

function! s:JobFinished(bufnr, answer, done, job, status, ...)
    if has_key(s:jobs, a:bufnr)
        unlet s:jobs[a:bufnr]
    endif

    if !filereadable(a:answer)
        echohl ErrorMsg
        echom 'Assembly viewer: the reader failed with ' . a:status
        echohl None
        return
    endif

    let l:result = json_decode(join(readfile(a:answer), ''))
    call delete(a:answer)

    if type(l:result) != type({}) || has_key(l:result, 'error')
        echohl ErrorMsg
        echom 'Assembly viewer: ' . get(l:result, 'error', 'unreadable answer')
        echohl None
        return
    endif

    call a:done(a:bufnr, l:result)
endfunction

" The assembly is of the last build. Saying so is the only way to explain an
" instruction that does not match the line above it.
function! s:ReportStaleObject(result)
    if a:result.object_time >= a:result.source_time
        return
    endif

    echohl WarningMsg
    echom 'Assembly viewer: ' . fnamemodify(a:result.object, ':t')
        \ . ' is older than this file. Showing the last build.'
    echohl None
endfunction

function! s:ClearAssemblyDisplay(bufnr)
    if has('nvim')
        call nvim_buf_clear_namespace(a:bufnr, s:namespace, 0, -1)
    else
        call prop_remove({'type': 'AssemblyInline', 'bufnr': a:bufnr, 'all': 1})
    endif
endfunction

" Each instruction gets its own screen line under the C line, indented to match
" it.
function! s:AssemblyLineTexts(bufnr, line_num, instructions)
    let l:text = get(getbufline(a:bufnr, a:line_num), 0, '')
    let l:indent = repeat(' ', strdisplaywidth(matchstr(l:text, '^\s*')))
    let l:texts = []

    for l:instruction in a:instructions
        call add(l:texts, l:indent . '│ ' . l:instruction)
    endfor

    return l:texts
endfunction

function! s:PlaceAssembly(bufnr, line_num, texts)
    if has('nvim')
        let l:virt_lines = []
        for l:text in a:texts
            call add(l:virt_lines, [[l:text, 'AssemblyInline']])
        endfor

        call nvim_buf_set_extmark(a:bufnr, s:namespace, a:line_num - 1, 0,
            \ {'virt_lines': l:virt_lines})
        return
    endif

    for l:text in a:texts
        call prop_add(a:line_num, 0, {'type': 'AssemblyInline',
            \ 'text': l:text,
            \ 'text_align': 'below',
            \ 'text_wrap': 'wrap',
            \ 'bufnr': a:bufnr})
    endfor
endfunction

function! s:DisplayAssembly(bufnr, result)
    call s:ClearAssemblyDisplay(a:bufnr)

    let l:last_line = get(getbufinfo(a:bufnr)[0], 'linecount', 0)

    for [l:key, l:instructions] in items(a:result.lines)
        let l:line_num = str2nr(l:key)
        if l:line_num <= 0 || l:line_num > l:last_line
            continue
        endif

        call s:PlaceAssembly(a:bufnr, l:line_num,
            \ s:AssemblyLineTexts(a:bufnr, l:line_num, l:instructions))
    endfor

    let g:assembly_viewer_enabled = 1
    call s:ReportStaleObject(a:result)
endfunction

function! s:ShowAssemblyForBuffer()
    call s:ReadAssembly(bufnr('%'), function('s:DisplayAssembly'))
endfunction

function! s:HideAssemblyForBuffer()
    let l:bufnr = bufnr('%')

    call s:StopJob(l:bufnr)
    call s:ClearAssemblyDisplay(l:bufnr)
    let g:assembly_viewer_enabled = 0
endfunction

" A buffer holding the same view, with the assembly as real text. The cursor
" rests on an instruction, / finds it and y copies it, none of which virtual
" text can do.
function! s:FillAssemblyBuffer(bufnr, result)
    let l:source = getbufline(a:bufnr, 1, '$')
    let l:lines = []
    let l:line_of_source = {}

    for l:number in range(1, len(l:source))
        let l:line_of_source[l:number] = len(l:lines) + 1
        call add(l:lines, l:source[l:number - 1])

        let l:key = string(l:number)
        if has_key(a:result.lines, l:key)
            call extend(l:lines,
                \ s:AssemblyLineTexts(a:bufnr, l:number, a:result.lines[l:key]))
        endif
    endfor

    let l:name = fnamemodify(bufname(a:bufnr), ':t') . ' [assembly]'
    let l:source_filetype = getbufvar(a:bufnr, '&filetype')

    new
    call setline(1, l:lines)
    let b:assembly_line_of_source = l:line_of_source

    silent! execute 'file ' . fnameescape(l:name)
    setlocal buftype=nofile bufhidden=wipe noswapfile nomodified nomodifiable
    let &l:filetype = l:source_filetype

    " The arrows name a line of the C file. In here that line sits somewhere
    " else, so follow it by the number it had.
    nnoremap <buffer> <silent> <CR> :call <SID>FollowArrow()<CR>

    call s:ReportStaleObject(a:result)
endfunction

function! s:ShowAssemblyBuffer()
    call s:ReadAssembly(bufnr('%'), function('s:FillAssemblyBuffer'))
endfunction

function! s:FollowArrow()
    let l:target = matchstr(getline('.'), '→ Line \zs\d\+')
    if empty(l:target)
        return
    endif

    execute get(b:assembly_line_of_source, str2nr(l:target), line('.'))
    normal! zz
endfunction

" mylint.vim compiles after the write, and the build takes as long as it takes.
" Wait for the object to grow newer than the file, then redraw once.
function! s:WaitForBuild(bufnr, attempts, timer)
    if !g:assembly_viewer_enabled || a:attempts <= 0
        return
    endif

    call s:ReadAssembly(a:bufnr, function('s:RedrawWhenBuilt', [a:attempts]))
endfunction

function! s:RedrawWhenBuilt(attempts, bufnr, result)
    if a:result.object_time >= a:result.source_time
        call s:DisplayAssembly(a:bufnr, a:result)
        return
    endif

    call timer_start(1000,
        \ function('s:WaitForBuild', [a:bufnr, a:attempts - 1]))
endfunction

command! AssemblyShow call s:ShowAssemblyForBuffer()
command! AssemblyHide call s:HideAssemblyForBuffer()
command! AssemblyToggle if g:assembly_viewer_enabled | call s:HideAssemblyForBuffer() | else | call s:ShowAssemblyForBuffer() | endif
command! AssemblyUpdate call s:ShowAssemblyForBuffer()
command! AssemblyBuffer call s:ShowAssemblyBuffer()

nnoremap <silent> <Leader>aa :AssemblyToggle<CR>
nnoremap <silent> <Leader>as :AssemblyShow<CR>
nnoremap <silent> <Leader>ah :AssemblyHide<CR>
nnoremap <silent> <Leader>au :AssemblyUpdate<CR>
nnoremap <silent> <Leader>ab :AssemblyBuffer<CR>

if get(g:, 'assembly_viewer_auto_update', 1)
    augroup AssemblyViewerIntegration
        autocmd! BufWritePost *.c if g:assembly_viewer_enabled | call timer_start(1000, function('s:WaitForBuild', [bufnr('%'), 30])) | endif
    augroup END
endif
