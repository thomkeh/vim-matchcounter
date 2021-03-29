" NOTES:
"   problem:  cchar cannot be more than 1 character.
"   strategy: make fg/bg the same color, then conceal the other char.

let s:matchmap = {}
let s:match_ids = []
let s:orig_conceal_matches = []

if exists('*strcharpart')
  func! s:strchar(s, i) abort
    return strcharpart(a:s, a:i, 1)
  endf
else
  func! s:strchar(s, i) abort
    return matchstr(a:s, '.\{'.a:i.'\}\zs.')
  endf
endif

func! s:placematch(c, pos) abort
  let s:matchmap[a:c] = a:pos
  let pat = '\%'.a:pos[0].'l\%'.a:pos[1].'c.'
  let id = matchadd('Conceal', pat, 999, -1, { 'conceal': a:c })
  call add(s:match_ids, id)

  if matchcounter#util#strlen(a:c) > 1
    let pat2 = '\%'.a:pos[0].'l\%'.(a:pos[1]+1).'c.'
    let label = s:strchar(a:c, 1)
    let id2 = matchadd('Conceal', pat2, 999, -1, { 'conceal': label })
    call add(s:match_ids, id2)
  endif

  if matchcounter#util#strlen(a:c) > 2
    let pat3 = '\%'.a:pos[0].'l\%'.(a:pos[1]+2).'c.'
    let label = s:strchar(a:c, 2)
    let id3 = matchadd('Conceal', pat3, 999, -1, { 'conceal': label })
    call add(s:match_ids, id3)
  endif
endf

func! s:save_conceal_matches() abort
  for m in getmatches()
    if m.group ==# 'Conceal'
      call add(s:orig_conceal_matches, m)
      silent! call matchdelete(m.id)
    endif
  endfor
endf

func! s:restore_conceal_matches() abort
  for m in s:orig_conceal_matches
    let d = {}
    if has_key(m, 'conceal') | let d.conceal = m.conceal | endif
    if has_key(m, 'window') | let d.window = m.window | endif
    silent! call matchadd(m.group, m.pattern, m.priority, m.id, d)
  endfor
  let s:orig_conceal_matches = []
endf

func! matchcounter#label#to(s, v, label) abort
  let whatever = s:do_label(a:s, a:v, a:s._reverse, a:label)
endf

func! s:do_label(s, v, reverse, label) abort "{{{
  let w = winsaveview()
  call s:before()
  let search_pattern = (a:s.prefix).(a:s.search).(a:s.get_onscreen_searchpattern(w))

  let i = 1
  let overflow = [0, 0] "position of the next match (if any) after we have run out of target labels.
  while 1
    " searchpos() is faster than 'norm! /'
    let p = searchpos(search_pattern, a:s.search_options_no_s, a:s.get_stopline())
    let skippedfold = matchcounter#util#skipfold(p[0], a:reverse) "Note: 'set foldopen-=search' does not affect search().

    if 0 == p[0] || -1 == skippedfold
      break
    elseif 1 == skippedfold
      continue
    endif

    call s:placematch(1 == i ? 'n' : string(i).'n', p)

    let i += 1
  endwhile

  call winrestview(w) | redraw
endf "}}}

func! s:after() abort
  autocmd! matchcounter_label_cleanup
  try | call matchdelete(s:matchcounter_cursor_hl) | catch | endtry
  call map(s:match_ids, 'matchdelete(v:val)')
  let s:match_ids = []
  "remove temporary highlight links
  exec 'hi! link Conceal '.s:orig_hl_conceal
  call s:restore_conceal_matches()
  exec 'hi! link Matchcounter '.s:orig_hl_matchcounter

  let [&l:concealcursor,&l:conceallevel]=[s:o_cocu,s:o_cole]
endf

func! s:disable_conceal_in_other_windows() abort
  for w in range(1, winnr('$'))
    if 'help' !=# getwinvar(w, '&buftype') && w != winnr()
        \ && empty(getbufvar(winbufnr(w), 'dirvish'))
      call setwinvar(w, 'matchcounter_orig_cl', getwinvar(w, '&conceallevel'))
      call setwinvar(w, '&conceallevel', 0)
    endif
  endfor
endf
func! s:restore_conceal_in_other_windows() abort
  for w in range(1, winnr('$'))
    if 'help' !=# getwinvar(w, '&buftype') && w != winnr()
        \ && empty(getbufvar(winbufnr(w), 'dirvish'))
      call setwinvar(w, '&conceallevel', getwinvar(w, 'matchcounter_orig_cl'))
    endif
  endfor
endf

func! s:before() abort
  let s:matchmap = {}
  for o in ['spell', 'spelllang', 'cocu', 'cole', 'fdm', 'synmaxcol', 'syntax']
    exe 'let s:o_'.o.'=&l:'.o
  endfor

  setlocal concealcursor=ncv conceallevel=2

  " Highlight the cursor location (because cursor is hidden during getchar()).
  let s:matchcounter_cursor_hl = matchadd("MatchcounterScope", '\%#', 11, -1)

  let s:orig_hl_conceal = matchcounter#util#links_to('Conceal')
  call s:save_conceal_matches()
  let s:orig_hl_matchcounter   = matchcounter#util#links_to('Matchcounter')
  "set temporary link to our custom 'conceal' highlight
  hi! link Conceal MatchcounterLabel
  "set temporary link to hide the sneak search targets
  hi! link Matchcounter MatchcounterLabelMask

  augroup matchcounter_label_cleanup
    autocmd!
    autocmd CursorMoved * call <sid>after()
  augroup END
endf
