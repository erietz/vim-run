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
        if s:chunks[0] == ''
            call remove(s:chunks, 0)
        elseif s:chunks[-1] == ''
            call remove(s:chunks, -1)
        endif
        let the_data = s:chunks
        "let the_data = join(a:data)
        let str = the_data
    elseif a:event == 'stderr'
        let the_data = join(a:data)
        if the_data == '' | return | endif
        call appendbufline(self.win_num, '$', '')
        let str = 'stderr: ' . the_data
    else
        "let str = 'exited ' . a:data
        let finished_time = localtime()
        let run_time = finished_time - self.start_time
        let str = '[Done] exited with code=' . string(a:data) . ' in '  . run_time . ' seconds'
    endif
    call appendbufline(self.win_num, '$', str)
endfunction

let s:callbacks = {
\ 'on_stdout': function('s:OnEvent'),
\ 'on_stderr': function('s:OnEvent'),
\ 'on_exit': function('s:OnEvent')
\ }

function run#GetWindow(cmd)
    for i in range(1, winnr('$'))
        if bufname(winbufnr(i)) == '_run_output_'
            let win_num = i
            break
        endif
    endfor
    let first_line = '[Running] ' . join(a:cmd)
    if exists('win_num')
        execute win_num . 'wincmd w'
        silent normal ggdG
        call setline(1, first_line)
        wincmd p
    else
        keepalt belowright vsplit _run_output_
        setlocal filetype=run_output buftype=nofile bufhidden=wipe noswapfile nowrap cursorline modifiable nospell
        let win_num = bufnr('%')
        call setline(1, first_line)
        wincmd p
    endif
    return win_num
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
    let cmd = run#GetCommand()
    let full_cmd = extend(cmd, [expand("%:p")])
    let win_num = run#GetWindow(full_cmd)
    let start_time = localtime()
    let job = jobstart(full_cmd, extend({'win_num': win_num, 'start_time': start_time}, s:callbacks))
endfunction
