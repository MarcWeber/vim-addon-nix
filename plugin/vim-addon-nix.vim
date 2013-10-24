" exec vam#DefineAndBind('s:c','vim_addon_nix','{}')
if !exists('vim_addon_nix') | let vim_addon_nix = {} | endif | let s:c = g:vim_addon_nix 
let s:c.complete_lhs = get(s:c, 'complete_lhs', '<c-x><c-o>')
let s:c.complete_lhs_option = get(s:c, 'complete_lhs_option', '<c-x><c-c>')
let s:c.nix_folding = get(s:c, 'nix_folding', 0)

let s:c.completion_sources = get(s:c,'completion_sources',{})
let s:c.completion_sources.tag_based_completion = funcref#Function('vim_addon_nix#TagBasedCompletion')
let s:c.completion_sources.builtin_completion = funcref#Function('vim_addon_nix#BuiltinsCompletion')
let s:c.tag_command = get(s:c, 'tag_command', 'ctags-svn-wrapped -R')

" register functions setting up nix-instantiate invokations for testing and
" learning purposes. See nix-addon-actions
for command_args in [["nix-instantiate","--eval-only","--strict"], ["nix-instantiate","--eval-only","--strict","--xml"]]
  call actions#AddAction('run '.join(command_args," "), {'action': funcref#Function('vim_addon_nix#CompileRHS', { 'args' : [command_args] })})
endfor

command! NixRetagAllPackages call vim_addon_nix#NixRetagAllPackages()

" set filetype to nix for *.nix files:
augroup DefaultNix
  autocmd BufRead,BufNewFile *.nix setlocal ft=nix | exec 'setlocal tags+='.join(map(vim_addon_nix#DirsToTag(),'",".v:val."/tags"'),"")
  autocmd BufWritePost *.nix call vim_addon_nix#CheckSyntax()
augroup end

" smarter way to pen all-packages.nix:
noremap \aps : if filereadable('pkgs/top-level/all-packages.nix') <bar> e pkgs/top-level/all-packages.nix <bar> else <bar> exec 'e '.expand("$NIXPKGS_ALL") <bar> endif<cr>
