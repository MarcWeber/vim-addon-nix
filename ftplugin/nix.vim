if !exists('vim_addon_nix') | let vim_addon_nix = {} | endif | let s:c = g:vim_addon_nix 

if s:c.nix_folding
  " don't fold if there are no heaaders (default.nix files)
  if search('###','nw') > 0
    setlocal foldexpr=getline(v:lnum)=~'###'?'>1':1
    setlocal foldmethod=expr
    setlocal foldtext=getline(v:foldstart)
  endif
endif

setlocal sw=2

call on_thing_handler#AddOnThingHandler('b', funcref#Function('vim_addon_nix#gfHandler'))

" this search can be used so often and is so useful ..
noremap <buffer> <m-n> /^<space><space>

call vim_addon_completion#InoremapCompletions(s:c, [
 \ { 'setting_keys' : ['complete_lhs'], 'fun': 'vim_addon_nix#FuzzyNixCompletion'},
 \ { 'setting_keys' : ['complete_lhs_option'], 'fun': 'vim_addon_nix#OptionCompletion'},
 \ ] )
