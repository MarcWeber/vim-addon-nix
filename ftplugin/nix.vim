if !exists('vim_addon_nix') | let vim_addon_nix = {} | endif | let s:c = g:vim_addon_nix 

if !exists('g:no_nix_folding')
  " don't fold if there are no heaaders (default.nix files)
  if search('###','nw') > 0
    setlocal foldexpr=getline(v:lnum)=~'###'?'>1':1
    setlocal foldmethod=expr
    setlocal foldtext=getline(v:foldstart)
  endif
endif

setlocal sw=2

call on_thing_handler#AddOnThingHandler('b', funcref#Function('vim_addon_nix#gfHandler'))

inoremap <buffer> <C-x><C-n> <c-r>=vim_addon_completion#CompleteUsing('vim_addon_nix#FuzzyNixCompletion')<cr>

inoremap <buffer> <C-x><C-c> <c-r>=vim_addon_completion#CompleteUsing('vim_addon_nix#OptionCompletion')<cr>

" this search can be used so often and is so useful ..
noremap <buffer> <m-n> /^<space><space>

exec 'inoremap <silent><exec> '.s:c.complete_lhs
      \ .' vim_addon_completion#CompleteUsing("vim_addon_nix#FuzzyNixCompletion","preview,menu,menuone")'
