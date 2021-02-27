if exists('g:run_autoloaded') || &cp
    finish
endif

let g:run_autoloaded = 1

function! s:OnEvent(job_id, data, event) dict
    "let output_string = join(a:data)
    if a:event == 'stdout'
        " TODO: data arrives in inconsistant order and results in
        " string new line issues
        " see Note 2 of :h job-control
        let s:chunks = ['']
        let s:chunks[-1] .= a:data[0]
        call extend(s:chunks, a:data[1:])
        "if s:chunks[0] == ''
        "    call remove(s:chunks, 0)
        "elseif s:chunks[-1] == ''
        "    call remove(s:chunks, -1)
        "endif
        call filter(s:chunks, '!empty(v:val)')
        let the_data = s:chunks
        "let the_data = join(a:data)
        let str = the_data
        "echomsg str
    elseif a:event == 'stderr'
        let the_data = join(a:data)
        caddexpr a:data
        cwindow
        if the_data == '' | return | endif
        call appendbufline(self.win_num, '$', '')
        let str = 'stderr: check the quickfix window for errors'
    else
        "let str = 'exited ' . a:data
        let finished_time = localtime()
        let run_time = finished_time - self.start_time
        let str = '[Done] exited with code=' . string(a:data) . ' in '  . run_time . ' seconds'
        cwindow
    endif
    call appendbufline(self.win_num, '$', str)
endfunction

if has('nvim')
    let s:callbacks = {
    \ 'on_stdout': function('s:OnEvent'),
    \ 'on_stderr': function('s:OnEvent'),
    \ 'on_exit': function('s:OnEvent')
    \ }
else
    let s:callbacks = {
    \ 'out_cb': function('s:OnEvent'),
    \ 'err_cb': function('s:OnEvent'),
    \ 'close_cb': function('s:OnEvent')
    \ }
endif

function run#GetWindow(cmd)
    let first_line = '[Running] ' . join(a:cmd)
    let error_format = &errorformat

    let buf_num = bufnr('_run_output_')
    if buf_num == -1
        keepalt belowright split _run_output_
        exec 'resize ' . string(&lines - &lines / 1.618)
        setlocal filetype=run_output buftype=nofile bufhidden=wipe noswapfile nowrap cursorline modifiable nospell
        let &errorformat=error_format
        let buf_num = bufnr('%')
        call setline(1, first_line)
        wincmd p
    else
        let buffer_name = bufname(buf_num)
        "execute("belowright split " . buffer_name)
        "exec 'resize ' . string(&lines - &lines / 1.618)
        call deletebufline(buffer_name, 1, '$')
        "call appendbufline(buffer_name, 1, first_line)
        call setbufline(buffer_name, 1, first_line)
        "wincmd p
    endif

    return buf_num
endfunction

let s:run_command = {
  \'javascript': ['node'],
  \'typescript': ['node'],
  \'php': ['php'],
  \'python' : ['python3', '-u'],
  \'zsh': [ 'zsh'],
  \'sh': [ 'sh'],
  \'bash': [ 'bash'],
  \'julia': [ 'julia'],
  \'r': [ 'Rscript'],
  \'ruby': [ 'ruby'],
  \'swift': [ 'swift'],
  \'lua': [ 'lua'],
  \}

let s:run_command = extend(s:run_command, g:run_command)

function run#GetCommand()
    let cmd = get(s:run_command, &ft, '')
    return cmd
endfunction

function! run#Run()
    cexpr ''
    let cmd = deepcopy(run#GetCommand())
    let full_cmd = extend(cmd, [expand("%:p")])
    let win_num = run#GetWindow(full_cmd)
    let start_time = localtime()
    if has('nvim')
        let job = jobstart(full_cmd, extend({'win_num': win_num, 'start_time': start_time}, s:callbacks))
    else
        let job = job_start(full_cmd, extend({'win_num': win_num, 'start_time': start_time}, s:callbacks))
    endif
endfunction
