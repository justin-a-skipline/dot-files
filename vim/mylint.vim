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

" Vim is really stupid and the job_getchannel() function doesn't
" just return a channel number, it returns a string that also
" contains the failed versus running status. Wow.
function! ParseChannelNumber(info)
    return matchlist(a:info, '\v\cchannel (\d+)(.*)')[1]
endfunction

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

" This function collects each line of stdout which has the compiler warnings
" sent to it. The lines are parsed for warning and error messages and what was
" found is appended to the list of lint errors for the buffer
function! CollectGCCWarningsAndErrors(channel, output)
  if !has_key(s:channel_info, ParseChannelNumber(a:channel))
      " something went wrong, return
      return
  endif

  let l:channel_dict = s:channel_info[ParseChannelNumber(a:channel)]
  let l:bufnr = l:channel_dict["bufnr"]
  let l:buf_dict = s:buf_info[l:bufnr]

  " Parse the output for errors and warnings
  let l:lines = split(a:output, "\n")
  let l:match_str = '\v^(.+):(\d+):(\d+): (error|warning): (.+)$'
  let l:match_header_error = '\v^(.+):(\d+):(\d+):\s+required from here.*$'
  let l:match_header_error2 = '\v^In file included from (.+):(\d+):\s*$'
  for l:line in l:lines
    if l:line =~ l:match_header_error
      let l:buf_dict["multi_line_match_list"] = matchlist(l:line, l:match_header_error)
      return
    elseif l:line =~ l:match_header_error2
      let l:buf_dict["multi_line_match_list"] = matchlist(l:line, l:match_header_error2)
      return
    " Match lines with errors or warnings
    elseif l:line =~ l:match_str
      let l:match_list = matchlist(l:line, l:match_str)
      if has_key(l:buf_dict, "multi_line_match_list")
        let l:file = l:buf_dict["multi_line_match_list"][1]
        let l:lnum = l:buf_dict["multi_line_match_list"][2]
        let l:throwaway = remove(l:buf_dict, "multi_line_match_list")
      else
        let l:file = l:match_list[1]
        let l:lnum = l:match_list[2]
      endif
      let l:type = l:match_list[4]
      let l:text = l:match_list[5]

      let l:type = l:type == "warning" ? "W" : "E"

      call add(l:buf_dict["lint_errors"], { "filename": l:file, "lnum": l:lnum, "type": l:type, "text": l:text })
    endif
  endfor
endfunction

" This function is called after the compiler exits. That is the condition when
" finally all of the compiler errors are turned into warning and error signs
" in the margin
function! ParseGCCWarningsAndErrors(job, output)
  if !has_key(s:channel_info, ParseChannelNumber(a:job->job_getchannel()))
      " something went wrong, return
      return
  endif

  let l:channel_dict = s:channel_info[ParseChannelNumber(a:job->job_getchannel())]
  let l:bufnr = l:channel_dict["bufnr"]
  let l:buf_dict = s:buf_info[l:bufnr]

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

  " Use jq to find the compiler command and directory for the current file
  let l:command = system('jq -r --arg file "' . l:cc_file_path . '" ''.[] | select(.file == $file) | .command'' ' . l:dir_dict["latest_compile_commands"])

  " If no command is found, try bear output
  if l:command->match("null") == 0
    let l:command = system('jq -r --arg file "' . l:cc_file_path . '" ''.[] | select(.file == $file) | .arguments | join(" ") '' ' . l:dir_dict["latest_compile_commands"])
    if l:command->match("null") == 0
      return
    endif
  endif

  let cmd = ['/bin/sh', "-c", 'cd ' . shellescape(l:cc_dir_path) . ' && ' . l:command . ' 2>&1 && touch /tmp/vim.txt']
  let l:buf_dict["lint_errors"] = []
  let l:cc_job = job_start(cmd, {'callback': 'CollectGCCWarningsAndErrors', 'out_mode': 'nl', 'exit_cb': 'ParseGCCWarningsAndErrors'})
  " Store the job object with the key being the job channel for accessing in
  " the callback
  let l:channel_dict = GetOrCreateSubDict(s:channel_info, ParseChannelNumber(l:cc_job->job_getchannel()))
  let l:channel_dict["job"] = l:cc_job
  let l:channel_dict["bufnr"] = l:bufnr
endfunction

augroup mylint
    autocmd! mylint
    autocmd CursorHold,CursorMoved * call ShowSignMessage()
    autocmd BufWritePost,BufReadPost * call RunCompilerCommand()
augroup END
