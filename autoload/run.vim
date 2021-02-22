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
        let str = 'exited '
    endif
    call appendbufline(self.win_num, '$', str)
endfunction

let s:callbacks = {
\ 'on_stdout': function('s:OnEvent'),
\ 'on_stderr': function('s:OnEvent'),
\ 'on_exit': function('s:OnEvent')
\ }

function run#GetWindow()
    for i in range(1, winnr('$'))
        if bufname(winbufnr(i)) == '_run_output_'
            let win_num = i
            break
        endif
    endfor
    if exists('win_num')
        echo win_num
        execute win_num . 'wincmd w'
        silent normal ggdG
        wincmd p
    else
        keepalt belowright vsplit _run_output_
        setlocal filetype=run_output buftype=nofile bufhidden=wipe
        let win_num = bufnr('%')
        echo win_num
        wincmd p
    endif
    return win_num
endfunction

let s:run_command = {
  \'javascript': 'node',
  \'typescript': 'node',
  \'php': 'php',
  \'python': 'python3',
  \'zsh': 'zsh',
  \'sh': 'sh',
  \'bash': 'bash',
  \'julia': 'julia',
  \'r': 'Rscript',
  \'ruby': 'ruby',
  \'swift': 'swift',
  \'lua': 'lua',
  \}

let s:run_command = extend(s:run_command, g:run_command)

function run#GetCommand()
    let cmd = get(s:run_command, &ft, '')
    return cmd
endfunction

function! run#Run()
    let win_num = run#GetWindow()
    let cmd = run#GetCommand()
    let full_cmd = [cmd, expand("%")]
    let job = jobstart(full_cmd, extend({'win_num': win_num}, s:callbacks))
endfunction
