" exec vam#DefineAndBind('s:c','vim_addon_nix','{}')
if !exists('vim_addon_nix') | let vim_addon_nix = {} | endif | let s:c = g:vim_addon_nix 

fun! vim_addon_nix#EF()
  return   "%m\\\\,\\ at\\ `%f':%l:%c,"
        \ ."%m\\\\,\\ at\\ `%f:%l:%c',"
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
  let res = [ expand(expand('%:h').'/'.matchstr(expand('<cWORD>'),'[^;()[\]]*')) ]
  for match in [matchstr(getline('.'), 'import\s*\zs[^;) \t]\+\ze'), matchstr(getline('.'), 'call\S*\s*\zs[^;) \t]\+\ze')]
    if match == "" | continue | endif
    call add(res, expand('%:h').'/'.match)
  endfor

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

fun! vim_addon_nix#DirsToTag()
  " probably it makes sense sense to tag ../* of dir
  let dir = fnamemodify($NIXPKGS_ALL,':h:h:h')
  if isdirectory(dir)
  return [dir]
endf

fun! vim_addon_nix#NixRetagAllPackages()
  for d in vim_addon_nix#DirsToTag()
    call vcs_checkouts#ExecIndir([{'d': d, 'c': s:c.tag_command.' .'}])
  endfor
endf

" does a word match (for completion)
fun! vim_addon_nix#Match(m)
  let p = get(s:c.patterns, 'vim_regex','')
  return a:m =~ '^'.s:c.base || (p != "" && a:m =~ p)
endf

fun! vim_addon_nix#FuzzyNixCompletion(findstart, base)
  if a:findstart
    let [bc,ac] = vim_addon_completion#BcAc()
    let s:match_text = matchstr(bc,               '\zs[^{.()[\]{}\t ]*$')
    let s:context =    matchstr(bc, '\zs[^{.() \t[\]]\+\ze\.[^.()[\]{}\t ]*$')
    if s:context !~ 'lib\|builtins\|types\|maintainers\|licenses'
      let s:context = ''
    endif
    let s:start = len(bc)-len(s:match_text)
    return s:start
  else
    let base = a:base
    let s:c.context = s:context
    if s:c.context != ''
      " if you complete b: l: or t: you'll get those scopes only
      let contexts = {'b:': 'builtins', 'l:': 'lib', 't:': 'types','m:' : 'maintainers'}
      for [c, context] in items(contexts)
        if base =~ '^'.c
          " overwrite context
          let s:c.context = context
          let base = base[len(c):]
          break
        endif
        unlet c context
      endfor
    endif

    let s:c.base = base

    let patterns = vim_addon_completion#AdditionalCompletionMatchPatterns(base
        \ , "ocaml_completion", { 'match_beginning_of_string': 1})
    let s:c.patterns = patterns

    for f in values(s:c.completion_sources)
      call funcref#Call(f)
    endfor
    return []
endf

let s:builtins_dump = expand('<sfile>:h').'/builtins.dump'

fun! vim_addon_nix#GetBuiltins()

  let tmp = tempname()
  call writefile(["builtins.attrNames builtins"], tmp)
  " list of builtin names:
  let g:result = substitute(join(split(system("nix-instantiate --eval-only --strict ".tmp),"\n"),""),'" "','","','g')
  let g:names = eval(g:result)
  " let g:manual = system("elinks --dump 'http://hydra.nixos.org/build/757694/download/1/manual/'")
  let lines = split(g:manual, "\n")

  let first_line = 1
  while lines[first_line] !~ 'Built-in functions'
    let first_line += 1
  endwhile

  let g:builtins = {}
  for n in g:names
    let regex = '^\s*\%(builtins\.\)\?'.n.'\s\+\zs.*'
    let start = first_line
    while start < len(lines) && lines[start] !~ regex
      let start +=1
    endwhile
    if start == len(lines)
      let menu = "no documentation found for ".n
      let g:builtins[n] = {'word': n, 'menu': menu}
    else
      let args = matchstr( lines[start], regex )
      let menu = printf('%-30s %s', "builtins", args)

      let info = []
      while lines[start+2] =~ '           '
        call add(info, matchstr(lines[start+2], '\s*\zs.*'))
        let start += 1
      endwhile

      let g:builtins[n] = {'word': n, 'menu': menu, 'info' : join(info," "), 'dup': 1}
    endif
  endfor
  call writefile([string(g:builtins)], s:builtins_dump)
endf

fun! vim_addon_nix#BuiltinsCompletion()
  if s:c.context != '' && s:c.context != "builtins" | return  | endif

  " check completness by evaluating:
  for [f,dict] in items(eval(readfile(s:builtins_dump)[0]))
    if  !vim_addon_nix#Match(f) | continue | endif
    call complete_add(dict)
    unlet f dict
  endfor
endf

fun! vim_addon_nix#TagBasedCompletion()

  if s:c.context == "builtins" | return  | endif

  let break_on_context_missmatch  = '0'
  if s:c.context == "lib"
    let break_on_context_missmatch = "m.filename !~ '[/\\\\]lib[/\\\\]'"
  elseif s:c.context == "licenses"
    let break_on_context_missmatch = "m.filename !~ '[/\\\\]licenses.nix'"
  elseif s:c.context == "types"
    let break_on_context_missmatch = "m.filename !~ '[/\\\\]types.nix'"
  elseif s:c.context == "maintainers"
    let break_on_context_missmatch = "m.filename !~ '[/\\\\]maintainers.nix'"
  endif

  let break_on_context_missmatch = 'let do_break = '.break_on_context_missmatch

  for m in taglist('^'. s:c.base[:0])
    if complete_check()| return | endif
    " ignore default.nix files. They usually only contain name, buildInputs etc
    if  m.filename =~ 'default.nix$' || !vim_addon_nix#Match(m.name) | continue | endif

    exec break_on_context_missmatch
    " can't use continue in exec
    if do_break | continue | endif

    let fn = fnamemodify(m.filename, ':h:t').'/'.fnamemodify(m.filename, ':t')
    let args_and_rest = matchstr(m.cmd, '^\/.\{-}\zs=.*\ze\$\/')
    let menu = printf('%-30s %s', fn, args_and_rest)
    call complete_add({'word': m.name, 'menu': menu, 'info' : menu."\n".m.filename, 'dup': 1})
  endfor
endf


" option completion based on man page which you can generate automatically.
fun! vim_addon_nix#OptionsCached() abort
  if !has_key(s:c, 'options')
    " I agree this is very fuzzy, quick and dirty, but works
    let options = {}
    Man configuration.nix

    let key = ''
    let gathered = []
    for l in getline(0, '$')
      if l =~ '^       \S'
        " new section
        if key != ''
          let options[key] = {'description': gathered}
        endif
        let key = l[8:]
        let gathered = []
      else
        call add(gathered, l)
      endif
    endfor

    if key != ''
      let options[key] = {'description': gathered}
    endif

    " quit man page
    bw!
    let s:c.options = options
  endif
  return s:c.options
endf

fun! vim_addon_nix#OptionCompletion(findstart, base)
  if a:findstart
    let [bc,ac] = vim_addon_completion#BcAc()
    let s:match_text = matchstr(bc,               '\zs[^{()[\]{}\t ]*$')
    let s:start = len(bc)-len(s:match_text)
    return s:start
  else
    let base = a:base
    let result = []

    for [key,v] in items(vim_addon_nix#OptionsCached())
      if key =~ a:base
        let defined_at = get(filter(copy(v.description),'v:val =~ '.string('^               <') ),0,'')
        let description = join(v.description,"\n")
        if description =~ 'Obsolete name'
          let defined_at .= ' obsolete'
        endif
        call add(result, {'word': key, 'menu': defined_at, 'info': description})
      endif
    endfor
    return result
endf
