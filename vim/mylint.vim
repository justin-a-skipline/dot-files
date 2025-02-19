" This function takes all the filenames in the compile_commands.json and
" performs realpath on them as vim tracks only the real file and not
" filenames via symbolic link
function! GetFilePathMap(compile_file)
  " Use jq to extract all file paths and their corresponding directories
  let l:entries = system('jq -r ''.[] | "\(.file) \(.directory)"'' ' . a:compile_file)
  let l:entries_list = split(l:entries, "\n")

  " Create a Vim dictionary to store resolved paths
  let l:file_map = {}

  " Resolve each path and store it in the dictionary
  for l:entry in l:entries_list
    if !empty(l:entry)
      let l:parts = split(l:entry, ' ')
      let l:file = l:parts[0]
      let l:directory = l:parts[1]
      let l:resolved_path = resolve(l:file)
      let l:resolved_path = substitute(l:resolved_path, '\n', '', 'g') " Remove newline
      let l:file_map[l:resolved_path] = {'file': l:file, 'directory': l:directory}
    endif
  endfor

  return l:file_map
endfunction

" This function collects each line of stdout which has the compiler warnings
" sent to it. The lines are parsed for warning and error messages and what was
" found is appended to the list of lint errors for the buffer
function! CollectGCCWarningsAndErrors(channel, output)
  " Parse the output for errors and warnings
  let l:lines = split(a:output, "\n")
  let l:match_str = '\v^(.+):(\d+):(\d+): (error|warning): (.+)$'
  let l:match_header_error = '\v^(.+):(\d+):(\d+):\s+required from here.*$'
  for l:line in l:lines
    if l:line =~ l:match_header_error
      let b:multi_line_match_list = matchlist(l:line, l:match_header_error)
      return
    " Match lines with errors or warnings
    elseif l:line =~ l:match_str
      let l:match_list = matchlist(l:line, l:match_str)
      if exists('b:multi_line_match_list')
        let l:file = b:multi_line_match_list[1]
        let l:lnum = b:multi_line_match_list[2]
        let l:col = b:multi_line_match_list[3]
        unlet b:multi_line_match_list
      else
        let l:file = l:match_list[1]
        let l:lnum = l:match_list[2]
        let l:col = l:match_list[3]
      endif
      let l:type = l:match_list[4]
      let l:text = l:match_list[5]

      let l:type = l:type == "warning" ? "W" : "E"

      call add(b:lint_errors, { "filename": l:file, "lnum": l:lnum, "type": l:type, "text": l:text })
    endif
  endfor
endfunction

" This function is called after the compiler exits. That is the condition when
" finally all of the compiler errors are turned into warning and error signs
" in the margin
function! ParseGCCWarningsAndErrors(channel, output)
  " Clear all signs in the current buffer
  execute 'sign unplace * buffer=' . bufnr('%')
  " Display errors and warnings using quickfix
  if !empty('b:lint_errors')
    execute 'sign define WarningSign text=W texthl=WarningMsg'
    execute 'sign define ErrorSign text=E texthl=ErrorMsg'

    let l:error_count = 0
    for l:error in b:lint_errors
      let l:error_count += 1
      let l:sign_name = ''
      if has_key(l:error, 'type')
        if l:error.type == 'W'
          let l:sign_name = 'WarningSign'
        elseif l:error.type == 'E'
          let l:sign_name = 'ErrorSign'
        endif
      endif

      execute 'sign place ' . l:error_count . ' line=' . l:error.lnum . ' name=' . l:sign_name . ' buffer=' . bufnr('%')

    endfor
  endif
endfunction

" This function is run when the cursor moves and displays the compiler error
" for the line in the bottom of the vim screen
function! ShowSignMessage()
    if !exists('b:lint_errors')
        return
    endif

    if empty(b:lint_errors)
        return
    endif

    let lnum = line('.')
    for l:error in b:lint_errors
        if l:error.lnum == lnum
            echohl WarningMsg
            echo l:error.text
            echohl None
            return
        endif
    endfor
    "if no message, clear it
    echo
endfunction

" This function is run when the buffer is re-read or written and calls the
" compiler, kicking off the linting process
function! RunCompilerCommand()
  " Find all compile_commands.json files one level down
  let l:compile_files = systemlist('find . -mindepth 2 -maxdepth 2 -name "compile_commands.json"')
  if l:compile_files->len() <= 0
    return
  endif

  " Find the most recently updated compile_commands.json
  " and update our cached value for it
  if !exists('b:latest_compile_commands')
    let b:latest_compile_commands = ''
  endif
  let l:recalculate_file_path_map = 0
  if !exists('b:latest_time')
    let b:latest_time = 0
    let l:recalculate_file_path_map = 1
  endif
  for l:file in l:compile_files
    let l:file_time = getftime(l:file)
    if l:file_time > b:latest_time
      let b:latest_time = l:file_time
      let l:recalculate_file_path_map = 1
      let b:latest_compile_commands = l:file
    endif
  endfor

  " Get the current file path
  let l:current_file = resolve(expand('%:p'))

  " Get the file path map if we have marked that there is a new file to get or
  " the timestamp was updated from a compile
  if l:recalculate_file_path_map > 0
    let b:file_map = GetFilePathMap(b:latest_compile_commands)
  endif

  " Find the symlink path using the resolved current file path
  if has_key(b:file_map, l:current_file)
    let l:cc_file_path = b:file_map[l:current_file]['file']
    let l:cc_dir_path = b:file_map[l:current_file]['directory']
  else
    return
  endif

  " Use jq to find the compiler command and directory for the current file
  let l:command = system('jq -r --arg file "' . l:cc_file_path . '" ''.[] | select(.file == $file) | .command'' ' . b:latest_compile_commands)

  " If no command is found, try bear output
  if l:command->match("null") == 0
    let l:command = system('jq -r --arg file "' . l:cc_file_path . '" ''.[] | select(.file == $file) | .arguments | join(" ") '' ' . b:latest_compile_commands)
    if l:command->match("null") == 0
      return
    endif
  endif

  let cmd = ['/bin/sh', "-c", 'cd ' . shellescape(l:cc_dir_path) . ' && ' . l:command . ' 2>&1 && touch /tmp/vim.txt']
  let b:lint_errors = []
  let s:cc_job = job_start(cmd, {'callback': 'CollectGCCWarningsAndErrors', 'out_mode': 'nl', 'exit_cb': 'ParseGCCWarningsAndErrors'})
endfunction

augroup mylint
    autocmd! mylint
    autocmd CursorHold,CursorMoved * call ShowSignMessage()
    autocmd BufWritePost,BufReadPost * call RunCompilerCommand()
augroup END
