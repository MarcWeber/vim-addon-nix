fun! vim_addon_nix#EF()
  " %m\\,\ at\ `%f':%l:%c
  "
  return "%m\\\\,\\ at\\ `%f':%l:%c,"
        \ ."%m\\ at\\ \\`%f:%l:%c':,"
        \ ."%m\\ at\\ \\`%f'\\\\\,\\ line\\ %l:,"
        \ ."error:\\ %m\\\\,\\ in\\ `%f'"
endf

if !exists('g:nix_syntax_check_error_list')
  " use location list by default
  let g:nix_syntax_check_error_list = 'l'
endif

fun! vim_addon_nix#CheckSyntax()
  let p = g:nix_syntax_check_error_list
  if !exists('s:tmpfile')
    let s:tmpfile = tempname()
  endif
  call system('nix-instantiate --parse-only '.shellescape(expand('%')).' &> '.s:tmpfile)
  let succ = v:shell_error == 0
  let old_was_error = exists('b:nix_was_error') && b:nix_was_error
  let b:nix_was_error = !succ
  " if there was an error or if privous run had an error
  " load result into quickfix or error list
  if !succ || old_was_error
    exec 'set errorformat='.vim_addon_nix#EF()
    exec p.'file '.s:tmpfile
    exec succ ? p.'close' : p.'open'
  endif
endf

" provide mapping running nix-instantiate (see vim-addon-actions, plugin/vim-addon-nix.vim)
fun! vim_addon_nix#CompileRHS(command_args)
  let target = a:0 > 0 ? a:1 : ""
  let ef = vim_addon_nix#EF()

  let args = actions#VerifyArgs(a:command_args+[expand('%')])
  return "call bg#RunQF(".string(args).", 'c', ".string(ef).")"
endfun

" (vim-addon-goto-thing-at-cursor, see plugin/vim-addon-nix.vim)
fun! vim_addon_nix#gfHandler()
  let res = [
        \   expand(expand('%:h').'/'.matchstr(expand('<cWORD>'),'[^;()[\]]*')),
        \   expand('%:h').'/'.matchstr(getline('.'), 'import\s*\zs[^;) \t]\+\ze'),
        \   expand('%:h').'/'.matchstr(getline('.'), 'callPackage\s*\zs[^;) \t]\+\ze')
        \ ]

  " if import string is a directory append '/default.nix' :
  call map(res, 'v:val =~ '.string('\.nix').' ? v:val : v:val.'.string('/default.nix'))

  let list = matchlist(getline('.'), '.*selectVersion\s\+\(\S*\)\s\+"\([^"]\+\)"')
  if (!empty(list))
    " something like this has been matched selectVersion ../applications/version-management/codeville "0.8.0"
    call add(res, expand('%:h').'/'.list[1].'/'.list[2].'.nix')
  else
    " something with var instead of "0.8.x" has been matched
    let list = matchlist(getline('.'), '.*selectVersion\s\+\(\S*\)\s\+\(\S\+\)')
    if (!empty(list))
      call extend(res, split(glob(expand('%:h').'/'.list[1].'/*.nix'), "\n"))
      " also add subdirectory files (there won't be that many)
      call extend(res, filter(split(glob(expand('%:h').'/'.list[1].'/*/*.nix'), "\n"),'1'))
    endif
  endif
  return res
endf
