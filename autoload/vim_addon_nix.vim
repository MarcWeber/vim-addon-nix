" provide mapping running nix-instantiate (see vim-addon-actions, plugin/vim-addon-nix.vim)
fun! vim_addon_nix#CompileRHS(command_args)
  let target = a:0 > 0 ? a:1 : ""
  let ef= "%m\,\ at\ `%f':%l:%c,"
        \ ."%m\ at\ `%f:%l:%c':,"
        \ ."%m\ at\ `%f'\,\ line\ %l:,"
        \ ."error:\ %m\,\ in\ `%f'"

  let args = actions#VerifyArgs(a:command_args)
  return "call bg#RunQF(".string(args).", 'c', ".string(ef).")"
endfun

" (vim-addon-goto-thing-at-cursor, see plugin/vim-addon-nix.vim)
fun! vim_addon_nix#gfHandler()
  let res = [
        \   expand(expand('%:h').'/'.matchstr(expand('<cWORD>'),'[^;()[\]]*')),
        \   expand('%:h').'/'.matchstr(getline('.'), 'import\s*\zs[^;) \t]\+\ze')
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
