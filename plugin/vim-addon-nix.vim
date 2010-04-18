" register functions setting up nix-instantiate invokations for testing and
" learning purposes. See nix-addon-actions
for command_args in [["nix-instantiate","--eval-only","--strict"], ["nix-instantiate","--eval-only","--strict","--xml"]]
  call actions#AddAction('run '.join(command_args," "), {'action': funcref#Function('vim_addon_nix#CompileRHS', { 'args' : [command_args] })})
endfor

" set filetype to nix for *.nix files:
augroup DefaultNix
  autocmd BufRead,BufNewFile *.nix setlocal ft=nix
  autocmd BufWritePost *.nix call vim_addon_nix#CheckSyntax()
augroup end
