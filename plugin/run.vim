if exists('g:run_loaded') || &compatible
  finish
endif

let g:run_loaded = 1

command! RunFile call run#Run()
command! RunStop call run#RunStop()
