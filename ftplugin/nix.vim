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
