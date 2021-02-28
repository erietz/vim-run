if exists('g:run_loaded') || &compatible
  finish
endif

let g:run_loaded = 1

command! RunFile call run#run_file_in_output_buffer()
command! RunStop call run#run_stop_job()
