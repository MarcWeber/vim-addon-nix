" exec scriptmanager#DefineAndBind('s:c','vim_addon_nix','{}')
if !exists('vim_addon_nix') | let vim_addon_nix = {} | endif | let s:c = g:vim_addon_nix 

let s:c.completion_sources = get(s:c,'completion_sources',{})
let s:c.completion_sources.tag_based_completion = funcref#Function('vim_addon_nix#TagBasedCompletion')
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


call vim_addon_completion#RegisterCompletionFunc({
      \ 'description' : 'some fuzzy completion for Vim',
      \ 'completeopt' : 'preview,menu,menuone',
      \ 'scope' : 'nix',
      \ 'func': 'vim_addon_nix#FuzzyNixCompletion'
      \ })
