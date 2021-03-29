" matchcounter.vim - The missing motion
" Author:       Justin M. Keyes
" Version:      1.8
" License:      MIT

if exists('g:loaded_matchcounter_plugin') || &compatible || v:version < 700
  finish
endif
let g:loaded_matchcounter_plugin = 1

let s:cpo_save = &cpo
set cpo&vim

func! matchcounter#init() abort
  unlockvar g:matchcounter#opt
  "options                                 v-- for backwards-compatibility
  let g:matchcounter#opt = { 'use_ic_scs'   : get(g:, 'matchcounter#use_ic_scs', 1)
      \ ,'label_esc'    : get(g:, 'matchcounter#label_esc', get(g:, 'matchcounter#streak_esc', "\<space>"))
      \ }

  lockvar g:matchcounter#opt
endf

call matchcounter#init()

func! matchcounter#is_sneaking() abort
  return exists("#matchcounter#CursorMoved")
endf

func! matchcounter#cancel() abort
  call matchcounter#util#removehl()
  augroup matchcounter
    autocmd!
  augroup END
  if maparg('<esc>', 'n') =~# 'matchcounter#cancel' "teardown temporary <esc> mapping
    silent! unmap <esc>
  endif
  return ''
endf


augroup sneakysneak
    au!
    au CmdlineLeave / call s:delayed_call(0)
    au CmdlineLeave \? call s:delayed_call(1)
    " au CmdlineEnter / mark '
augroup END

func! s:delayed_call(reverse) abort
    call timer_start(0, {-> matchcounter#wrap(a:reverse)})
endf

" Entrypoint.
func! matchcounter#wrap(reverse) abort
  " get last search
  let input = @/
  let inputlen = matchcounter#util#strlen(input)

  if exists('#User#MatchcounterEnter')
    doautocmd <nomodeline> User MatchcounterEnter
    redraw
  endif
  " highlight matches
  call matchcounter#to(input, inputlen, a:reverse)
  if exists('#User#MatchcounterLeave')
    doautocmd <nomodeline> User MatchcounterLeave
  endif
endf

func! matchcounter#to(input, inputlen, reverse) abort "{{{
  let s = g:matchcounter#search#instance
  call s.init(a:input, a:reverse)

  let l:gt_lt = a:reverse ? '<' : '>'

  "TODO: refactor vertical scope calculation into search.vim,
  "      so this can be done in s.init() instead of here.
  call s.initpattern()

  "find out if there were matches
  let matchpos = s.dosearch()

  if 0 == max(matchpos)
    let km = empty(&keymap) ? '' : ' ('.&keymap.' keymap)'
    call matchcounter#util#echo('not found'.km.': '.a:input)
    return
  endif
  "search succeeded

  call matchcounter#util#removehl()

  let curlin = string(line('.'))
  let curcol = string(virtcol('.') + (a:reverse ? -1 : 1))

  "Might as well scope to window height (+/- 99).
  let l:top = max([0, line('w0')-99])
  let l:bot = line('w$')+99
  let l:restrict_top_bot = '\%'.l:gt_lt.curlin.'l\%>'.l:top.'l\%<'.l:bot.'l'
  let s.match_pattern .= l:restrict_top_bot
  let curln_pattern  = '\%'.curlin.'l\%'.l:gt_lt.curcol.'v'

  call s:attach_autocmds()

  "highlight actual matches at or below the cursor position
  "  - store in w: because matchadd() highlight is per-window.
  let w:matchcounter_hl_id = matchadd('Matchcounter',
        \ (s.prefix).(s.match_pattern).(s.search).'\|'.curln_pattern.(s.search))

  " Operators always invoke label-mode.
  " If a:label is a string set it as the target, without prompting.
  let label = ''
  let target = (!empty(label) || (s.hasmatches(1))) && matchcounter#label#to(s, 0, label)

endf "}}}

func! s:attach_autocmds() abort
  augroup matchcounter
    autocmd!
    autocmd InsertEnter,WinLeave,BufLeave * call matchcounter#cancel()
    "_nested_ autocmd to skip the _first_ CursorMoved event.
    "NOTE: CursorMoved is _not_ triggered if there is typeahead during a macro/script...
    " autocmd CursorMoved * autocmd matchcounter CursorMoved * call matchcounter#cancel()
    autocmd CursorMoved * call matchcounter#cancel()
  augroup END
endf


let &cpo = s:cpo_save
unlet s:cpo_save
