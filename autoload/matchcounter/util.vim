if v:version >= 703
  func! matchcounter#util#strlen(s) abort
    return strwidth(a:s)
    "return call('strdisplaywidth', a:000)
  endf
else
  func! matchcounter#util#strlen(s) abort
    return strlen(substitute(a:s, ".", "x", "g"))
  endf
endif

"returns 1 if the string contains an uppercase char. [unicode-compatible]
func! matchcounter#util#has_upper(s) abort
 return -1 != match(a:s, '\C[[:upper:]]')
endf

"displays a message that will dissipate at the next opportunity.
func! matchcounter#util#echo(msg) abort
  redraw | echo a:msg
  augroup matchcounter_echo
    autocmd!
    autocmd CursorMoved,InsertEnter,WinLeave,BufLeave * redraw | echo '' | autocmd! matchcounter_echo
  augroup END
endf

"returns the least possible 'wincol'
"  - if 'sign' column is displayed, the least 'wincol' is 3
"  - there is (apparently) no clean way to detect if 'sign' column is visible
func! matchcounter#util#wincol1() abort
  let w = winsaveview()
  norm! 0
  let c = wincol()
  call winrestview(w)
  return c
endf

"Moves the cursor to the first line after the current folded lines.
"Returns:
"     1  if the cursor was moved
"     0  if the cursor is not in a fold
"    -1  if the start/end of the fold is at/above/below the edge of the window
func! matchcounter#util#skipfold(current_line, reverse) abort
  let foldedge = a:reverse ? foldclosed(a:current_line) : foldclosedend(a:current_line)
  if -1 != foldedge
    if (a:reverse && foldedge <= line("w0")) "fold starts at/above top of window.
                \ || foldedge >= line("w$")  "fold ends at/below bottom of window.
      return -1
    endif
    call line(foldedge)
    call col(a:reverse ? 1 : '$')
    return 1
  endif
  return 0
endf

" Removes highlighting.
func! matchcounter#util#removehl() abort
  silent! call matchdelete(w:matchcounter_hl_id)
  silent! call matchdelete(w:matchcounter_sc_hl)
endf

" Gets the 'links to' value of the specified highlight group, if any.
func! matchcounter#util#links_to(hlgroup) abort
  redir => hl | exec 'silent highlight '.a:hlgroup | redir END
  let s = substitute(matchstr(hl, 'links to \zs.*'), '\s', '', 'g')
  return empty(s) ? 'NONE' : s
endf

func! s:default_color(hlgroup, what, mode) abort
  let c = synIDattr(synIDtrans(hlID(a:hlgroup)), a:what, a:mode)
  return !empty(c) && c != -1 ? c : (a:what ==# 'bg' ? 'magenta' : 'white')
endfunc

func! s:init_hl() abort
  exec "highlight default Matchcounter guifg=white guibg=magenta ctermfg=white ctermbg=".(&t_Co < 256 ? "magenta" : "201")

  if &background ==# 'dark'
    highlight default MatchcounterScope guifg=black guibg=white ctermfg=0     ctermbg=255
  else
    highlight default MatchcounterScope guifg=white guibg=black ctermfg=255   ctermbg=0
  endif

  let guibg   = s:default_color('Matchcounter', 'bg', 'gui')
  let guifg   = s:default_color('Matchcounter', 'fg', 'gui')
  let ctermbg = s:default_color('Matchcounter', 'bg', 'cterm')
  let ctermfg = s:default_color('Matchcounter', 'fg', 'cterm')
  exec 'highlight default MatchcounterLabel gui=bold cterm=bold guifg='.guifg.' guibg='.guibg.' ctermfg='.ctermfg.' ctermbg='.ctermbg

  let guibg   = s:default_color('MatchcounterLabel', 'bg', 'gui')
  let ctermbg = s:default_color('MatchcounterLabel', 'bg', 'cterm')
  " fg same as bg
  exec 'highlight default MatchcounterLabelMask guifg='.guibg.' guibg='.guibg.' ctermfg='.ctermbg.' ctermbg='.ctermbg
endf

augroup matchcounter_colorscheme  " Re-init on :colorscheme change at runtime. #108
  autocmd!
  autocmd ColorScheme * call <sid>init_hl()
augroup END

call s:init_hl()
