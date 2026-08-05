" Persistent info related to the current working directory for the buffer
let s:dir_info = {}
" Persistent info related to the current buffer
let s:buf_info = {}
" Persistent info related to a job and ID'd by channel
let s:channel_info = {}

function! P(name)
    if a:name =~ "dir"
        echomsg s:dir_info
    elseif a:name =~ "buf"
        echomsg s:buf_info
    elseif a:name =~ "channel"
        echomsg s:channel_info
    endif
endfunction

" async#job#start() returns a plain job id in both vim and neovim, so
" s:channel_info is keyed on that and there is no channel string to unpick.

function! GetOrCreateSubDict(map, key)
  if !has_key(a:map, a:key)
    let a:map[a:key] = {}
  endif
  return a:map[a:key]
endfunction

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

" This function parses complete compiler output lines for warning and error
" messages and appends what was found to the list of lint errors for the buffer
function! s:ParseLintLines(buf_dict, lines)
  let l:match_str = '\v^(.+):(\d+):(\d+): (fatal error|error|warning): (.+)$'
  let l:match_header_error = '\v^(.+):(\d+):(\d+):\s+required from here.*$'
  let l:match_header_error2 = '\v^In file included from (.+):(\d+):\s*$'
  for l:line in a:lines
    " continue, not return: one call carries many lines now, so returning here
    " would discard the rest of the compiler output
    if l:line =~ l:match_header_error
      let a:buf_dict["multi_line_match_list"] = matchlist(l:line, l:match_header_error)
      continue
    elseif l:line =~ l:match_header_error2
      let a:buf_dict["multi_line_match_list"] = matchlist(l:line, l:match_header_error2)
      continue
    " Match lines with errors or warnings
    elseif l:line =~ l:match_str
      let l:match_list = matchlist(l:line, l:match_str)
      if has_key(a:buf_dict, "multi_line_match_list")
        let l:file = a:buf_dict["multi_line_match_list"][1]
        let l:lnum = a:buf_dict["multi_line_match_list"][2]
        let l:throwaway = remove(a:buf_dict, "multi_line_match_list")
      else
        let l:file = l:match_list[1]
        let l:lnum = l:match_list[2]
      endif
      let l:type = l:match_list[4]
      let l:text = l:match_list[5]

      let l:type = l:type == "warning" ? "W" : "E"

      call add(a:buf_dict["lint_errors"], { "filename": l:file, "lnum": l:lnum, "type": l:type, "text": l:text })
    endif
  endfor
endfunction

" This function collects the compiler warnings from stdout and stderr. A chunk
" can end part way through a line, so the trailing fragment is held back until
" the next chunk completes it. The two streams are independent and each keeps
" its own fragment.
function! CollectGCCWarningsAndErrors(job, data, event)
  if !has_key(s:channel_info, a:job) || empty(a:data)
      " something went wrong, return
      return
  endif

  let l:channel_dict = s:channel_info[a:job]
  let l:buf_dict = s:buf_info[l:channel_dict["bufnr"]]

  let l:fragment_key = a:event . "_fragment"
  let l:fragment = get(l:channel_dict, l:fragment_key, '') . a:data[0]
  let l:complete = []
  for l:i in range(1, len(a:data) - 1)
    call add(l:complete, l:fragment)
    let l:fragment = a:data[l:i]
  endfor
  let l:channel_dict[l:fragment_key] = l:fragment

  call s:ParseLintLines(l:buf_dict, l:complete)
endfunction

" This function is called after the compiler exits. That is the condition when
" finally all of the compiler errors are turned into warning and error signs
" in the margin
" a:status is the exit code here, not compiler text.
function! ParseGCCWarningsAndErrors(job, status, event)
  if !has_key(s:channel_info, a:job)
      " something went wrong, return
      return
  endif

  let l:channel_dict = s:channel_info[a:job]
  let l:bufnr = l:channel_dict["bufnr"]
  let l:buf_dict = s:buf_info[l:bufnr]

  " A last line without a terminating newline is still a real warning
  for l:fragment_key in ['stdout_fragment', 'stderr_fragment']
    if !empty(get(l:channel_dict, l:fragment_key, ''))
      call s:ParseLintLines(l:buf_dict, [l:channel_dict[l:fragment_key]])
      let l:channel_dict[l:fragment_key] = ''
    endif
  endfor

  " Clear all signs in the current buffer
  execute 'sign unplace * buffer=' . l:bufnr
  " Display errors and warnings using quickfix
  if !empty(l:buf_dict["lint_errors"])
    execute 'sign define WarningSign text=W texthl=WarningMsg'
    execute 'sign define ErrorSign text=E texthl=ErrorMsg'

    let l:error_count = 0
    for l:error in l:buf_dict["lint_errors"]
      let l:error_count += 1
      let l:sign_name = ''
      if has_key(l:error, 'type')
        if l:error.type == 'W'
          let l:sign_name = 'WarningSign'
        elseif l:error.type == 'E'
          let l:sign_name = 'ErrorSign'
        endif
      endif

      execute 'sign place ' . l:error_count . ' line=' . l:error.lnum . ' name=' . l:sign_name . ' buffer=' . l:bufnr

    endfor
  endif
endfunction

" This function is run when the cursor moves and displays the compiler error
" for the line in the bottom of the vim screen
function! ShowSignMessage()
    let l:bufnr = bufnr('%')
    if !has_key(s:buf_info, l:bufnr)
        return
    endif

    let l:buf_dict = s:buf_info[l:bufnr]

    if empty(l:buf_dict->get("lint_errors", []))
        return
    endif

    let lnum = line('.')
    for l:error in l:buf_dict["lint_errors"]
        if l:error.lnum == lnum
            echohl WarningMsg
            echomsg l:error.text
            echohl None
            return
        endif
    endfor
    "if no message, clear it
    echo
endfunction

" Function to add .mylint suffix to output files
function! s:AddMylintSuffix(command)
  let l:modified_command = a:command

  " Only add .mylint if not already present
  if l:modified_command !~ '\.mylint\>'
    " Simple approach: split command into words and find -o flags
    let l:words = split(l:modified_command, ' ')
    let l:new_words = []
    let l:i = 0

    while l:i < len(l:words)
      if l:words[l:i] ==# '-o' && l:i + 1 < len(l:words)
        " Handle -o filename (space separated)
        call add(l:new_words, '-o')
        call add(l:new_words, l:words[l:i + 1] . '.mylint')
        let l:i += 2
      elseif l:words[l:i][:1] ==# '-o' && len(l:words[l:i]) > 2
        " Handle -ofilename (directly attached)
        call add(l:new_words, '-o' . l:words[l:i][2:] . '.mylint')
        let l:i += 1
      else
        " Leave other words unchanged (including -O flags)
        call add(l:new_words, l:words[l:i])
        let l:i += 1
      endif
    endwhile

    let l:modified_command = join(l:new_words, ' ')
  endif

  return l:modified_command
endfunction

" Function to generate objdump -l command for assembly with source info
function! s:GenerateObjdumpCommand(object_file)
  " Use objdump -l to show assembly with source file and line info
  " This is exactly what Compiler Explorer uses
  return 'objdump -d -l --demangle ' . shellescape(a:object_file)
endfunction

" Function to extract output file from compile command
function! s:ExtractOutputFile(command)
  " Extract output file from compile command
  " Handles patterns like: -o file.o or -ofile.o
  let l:words = split(a:command, ' ')
  let l:i = 0

  while l:i < len(l:words)
    if l:words[l:i] ==# '-o' && l:i + 1 < len(l:words)
      " Handle -o filename (space separated)
      return l:words[l:i + 1]
    elseif l:words[l:i][:1] ==# '-o' && len(l:words[l:i]) > 2
      " Handle -ofilename (directly attached)
      return l:words[l:i][2:]
    endif
    let l:i += 1
  endwhile

  return ''
endfunction

" Test function for the suffix modification
function! s:TestMylintSuffix()
  echo "Testing MyLint Suffix Function..."
  echo ""

  let l:tests = [
    \ {'input': 'gcc -g -c file.c -o file.o', 'expected': 'gcc -g -c file.c -o file.o.mylint'},
    \ {'input': 'gcc -g -c file.c -ofile.o', 'expected': 'gcc -g -c file.c -ofile.o.mylint'},
    \ {'input': 'gcc -O2 -g -c file.c -o file.o', 'expected': 'gcc -O2 -g -c file.c -o file.o.mylint'},
    \ {'input': 'gcc -Wno-overflow -g -c file.c -o file.o', 'expected': 'gcc -Wno-overflow -g -c file.c -o file.o.mylint'},
    \ {'input': 'gcc -g -c file.c -O2 -o file.o', 'expected': 'gcc -g -c file.c -O2 -o file.o.mylint'},
    \ {'input': 'gcc -g -c file.c -o file.o -O2', 'expected': 'gcc -g -c file.c -o file.o.mylint -O2'},
    \ {'input': 'gcc -g -c file.c', 'expected': 'gcc -g -c file.c'},
    \ {'input': 'gcc -g -c file.c -o file.o.mylint', 'expected': 'gcc -g -c file.c -o file.o.mylint'},
  \]

  let l:passed = 0
  let l:total = len(l:tests)

  for l:i in range(len(l:tests))
    let l:test = l:tests[l:i]
    let l:result = s:AddMylintSuffix(l:test.input)

    if l:result ==# l:test.expected
      echo "✅ Test " . (l:i + 1) . ": PASSED"
      let l:passed += 1
    else
      echo "❌ Test " . (l:i + 1) . ": FAILED"
      echo "   Input:    " . l:test.input
      echo "   Expected: " . l:test.expected
      echo "   Got:      " . l:result
    endif
  endfor

  echo ""
  echo "Results: " . l:passed . "/" . l:total . " tests passed"

  if l:passed == l:total
    echo "🎉 All tests passed!"
  else
    echo "⚠️  Some tests failed"
  endif
endfunction

" Test function for objdump command generation
function! s:TestObjdumpCommand()
  echo "Testing Objdump Command Generation..."
  echo ""

  let l:tests = [
    \ {'input': 'file.o', 'expected_contains': ['objdump', '-d', '-l', '--demangle', 'file.o']},
    \ {'input': 'path/to/file.o', 'expected_contains': ['objdump', '-d', '-l', '--demangle', 'path/to/file.o']},
    \ {'input': 'file.o.mylint', 'expected_contains': ['objdump', '-d', '-l', '--demangle', 'file.o.mylint']},
  \]

  let l:passed = 0
  let l:total = len(l:tests)

  for l:i in range(len(l:tests))
    let l:test = l:tests[l:i]
    let l:result = s:GenerateObjdumpCommand(l:test.input)

    let l:all_found = 1
    for l:expected in l:test.expected_contains
      if l:result !~ l:expected
        let l:all_found = 0
        break
      endif
    endfor

    if l:all_found
      echo "✅ Objdump Test " . (l:i + 1) . ": PASSED"
      let l:passed += 1
    else
      echo "❌ Objdump Test " . (l:i + 1) . ": FAILED"
      echo "   Input:    " . l:test.input
      echo "   Result:   " . l:result
      echo "   Expected to contain: " . join(l:test.expected_contains, ', ')
    endif
  endfor

  echo ""
  echo "Objdump Results: " . l:passed . "/" . l:total . " tests passed"

  if l:passed == l:total
    echo "🎉 All objdump command tests passed!"
  else
    echo "⚠️  Some objdump command tests failed"
  endif
endfunction

" Run tests when this file is sourced (only in debug mode)
if exists('g:mylint_debug_test')
  call s:TestMylintSuffix()
  call s:TestObjdumpCommand()
endif

" This function is run when the buffer is re-read or written and calls the
" compiler, kicking off the linting process
function! RunCompilerCommand()
  " Find all compile_commands.json files at this level and one level down
  " Exclude files in . directories like what qt produces
  let l:compile_files = systemlist('find . -maxdepth 2 -name compile_commands.json -a ! -iregex ".*/\..*" -prune')
  if l:compile_files->len() <= 0
    return
  endif

  " Get the current file path
  let l:current_file = resolve(expand('%:p'))
  let l:cwd = getcwd(bufnr('%'))
  let l:bufnr = bufnr('%')

  " Get references to the dictionaries that are stored on a per directory
  " or per buffer basis
  let l:dir_dict = GetOrCreateSubDict(s:dir_info, l:cwd)
  let l:buf_dict = GetOrCreateSubDict(s:buf_info, l:bufnr)

  " Find the most recently updated compile_commands.json
  " and update our cached value for it
  if !has_key(l:dir_dict, "latest_compile_commands")
    let l:dir_dict["latest_compile_commands"] = ''
  endif
  let l:recalculate_file_path_map = 0
  if !has_key(l:dir_dict, "latest_time")
    let l:dir_dict["latest_time"] = 0
    let l:recalculate_file_path_map = 1
  endif
  for l:file in l:compile_files
    let l:file_time = getftime(l:file)
    if l:file_time > l:dir_dict["latest_time"]
      let l:dir_dict["latest_time"] = l:file_time
      let l:recalculate_file_path_map = 1
      let l:dir_dict["latest_compile_commands"] = l:file
    endif
  endfor

  " Get the file path map if we have marked that there is a new file to get or
  " the timestamp was updated from a compile
  if l:recalculate_file_path_map > 0
    let l:dir_dict["file_path_map"] = GetFilePathMap(l:dir_dict["latest_compile_commands"])
  endif

  " Find the symlink path using the resolved current file path
  if has_key(l:dir_dict["file_path_map"], l:current_file)
    let l:cc_file_path = l:dir_dict["file_path_map"][l:current_file]['file']
    let l:cc_dir_path = l:dir_dict["file_path_map"][l:current_file]['directory']
  else
    return
  endif

  " Use jq to find the compiler command and directory for the current file.
  " trim() matters: the trailing newline from system() would otherwise end up
  " inside the -o argument, which both breaks the .mylint suffix and cuts the
  " 2>&1 onto a second shell line.
  let l:command = trim(system('jq -r --arg file "' . l:cc_file_path . '" ''.[] | select(.file == $file) | .command'' ' . l:dir_dict["latest_compile_commands"]))

  " If no command is found, try bear output
  if l:command->match("null") == 0
    let l:command = trim(system('jq -r --arg file "' . l:cc_file_path . '" ''.[] | select(.file == $file) | .arguments | join(" ") '' ' . l:dir_dict["latest_compile_commands"]))
    if l:command->match("null") == 0
      return
    endif
  endif

  " Modify the command to add .mylint suffix to output files
  let l:modified_command = s:AddMylintSuffix(l:command)

  " DEBUG: Log mylint command

  let cmd = ['/bin/sh', "-c", 'cd ' . shellescape(l:cc_dir_path) . ' && ' . l:modified_command . ' 2>&1 && touch /tmp/vim.txt']

  let l:log_entry = "[" . strftime("%Y-%m-%d %H:%M:%S") . "] MYLINE: File=" . l:current_file . " Dir=" . l:cc_dir_path . " CMD=" . cmd[-1]
  call writefile([l:log_entry], "/tmp/mylint_debug.log", "a")

  let l:buf_dict["lint_errors"] = []
  " async#job#start so this file works unchanged under vim and neovim. gcc writes
  " warnings to stderr, and neovim keeps the streams separate, so both are wired
  " to the same collector.
  let l:cc_job = async#job#start(cmd, {
        \ 'on_stdout': function('CollectGCCWarningsAndErrors'),
        \ 'on_stderr': function('CollectGCCWarningsAndErrors'),
        \ 'on_exit': function('ParseGCCWarningsAndErrors'),
        \ })
  " Store the job object with the key being the job id for accessing in
  " the callback
  let l:channel_dict = GetOrCreateSubDict(s:channel_info, l:cc_job)
  let l:channel_dict["job"] = l:cc_job
  let l:channel_dict["bufnr"] = l:bufnr
endfunction

augroup mylint
    autocmd! mylint
    autocmd CursorHold,CursorMoved * call ShowSignMessage()
    autocmd BufWritePost,BufReadPost * call RunCompilerCommand()
augroup END
