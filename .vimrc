set tabpagemax=25
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set ignorecase
set smartcase
set colorcolumn=79
filetype plugin on
filetype indent on
syntax on
colorscheme desert

vmap Q gq
nmap Q gqap

nmap <F8> :TagbarToggle<CR>

" Enable pathogen
execute pathogen#infect()

" Format XML files with gg=G command
au FileType xml setlocal equalprg=xmllint\ --format\ --recover\ -\ 2>/dev/null

" Allow pylakes vim plugin to open automatically
filetype plugin indent on
" Automatically call flake8 when saving python version
autocmd BufWritePost *.py call Flake8()

" Remove trailing spaces before writing Change * with *.py to only remove on
" python files
autocmd BufWritePre *.py :%s/\s\+$//e
autocmd BufWritePre *.rst :%s/\s\+$//e

" Configure isort for tryton
let g:vim_isort_config_overrides = {
      \ 'multi_line_output': 4, 'known_first_party': ['trytond']}

" Vim indent file
" Language: Python
" Maintainer: Cédric Krier <ced@b2ck.com>
" Author: Bram Moolenaar <Bram@vim.org>
" Original Author: David Bustos <bustos@caltech.edu>
" Last Change: 2011 Jul 27

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" Some preliminary settings
setlocal nolisp            " Make sure lisp indenting doesn't supersede us
setlocal autoindent      " indentexpr isn't much help otherwise

setlocal indentexpr=GetPythonIndent(v:lnum)
setlocal indentkeys+=<:>,=elif,=except

" Only define the function once.
if exists("*GetPythonIndent")
  finish
endif

" Come here when loading the script the first time.

let s:maxoff = 50      " maximum number of lines to look backwards for ()

function GetPythonIndent(lnum)

  " If this line is explicitly joined: If the previous line was also joined,
  " line it up with that one, otherwise add on 'shiftwidth'
  if getline(a:lnum - 1) =~ '\\$'
    if a:lnum > 1 && getline(a:lnum - 2) =~ '\\$'
      return indent(a:lnum - 1)
    endif
    return indent(a:lnum - 1) + (exists("g:pyindent_continue") ? eval(g:pyindent_continue) : &sw)
  endif

  " Search backwards for the previous non-empty line.
  let plnum = prevnonblank(v:lnum - 1)

  if plnum == 0
    " This is the first non-empty line, use zero indent.
    return 0
  endif

  " If the previous line is inside parenthesis, use the indent of the starting
  " line.
  " Trick: use the non-existing "dummy" variable to break out of the loop when
  " going too far back.
  call cursor(plnum, 1)
  let parlnum = searchpair('(\|{\|\[', '', ')\|}\|\]', 'nbW',
        \ "line('.') < " . (plnum - s:maxoff) . " ? dummy :"
        \ . " synIDattr(synID(line('.'), col('.'), 1), 'name')"
        \ . " =~ '\\(Comment\\|String\\)$'")
  if parlnum > 0
    let plindent = indent(parlnum)
    let plnumstart = parlnum
  else
    let plindent = indent(plnum)
    let plnumstart = plnum
  endif


  " When inside parenthesis: Indent by the number of opened parenthesis.
  " i = (((a
  "             + b)
  "         + c)
  "     + d)
  call cursor(a:lnum, 1)
  let p = searchpair('(\|{\|\[', '', ')\|}\|\]', 'bW',
        \ "line('.') < " . (a:lnum - s:maxoff) . " ? dummy :"
        \ . " synIDattr(synID(line('.'), col('.'), 1), 'name')"
        \ . " =~ '\\(Comment\\|String\\)$'")
  if p > 0
    let nindent = 0
    let pp = p
    while pp > 0
      let lp = pp
      let pp = searchpair('(\|{\|\[', '', ')\|}\|\]', 'bW',
        \ "line('.') < " . (a:lnum - s:maxoff) . " ? dummy :"
        \ . " synIDattr(synID(line('.'), col('.'), 1), 'name')"
        \ . " =~ '\\(Comment\\|String\\)$'")
      let nindent = nindent + 1
    endwhile
    " If the open parenthesis is on a for/if/while/def line then indent one
    " more time
    if getline(lp) =~ '^\s*\(if\|while\|def\|for\s.*\sin\|with\)\s'
      let nindent = nindent + 1
    endif
    return indent(lp) + ((exists("g:pyindent_paren") ? eval(g:pyindent_paren) : &sw) * nindent)
  endif


  " Get the line and remove a trailing comment.
  " Use syntax highlighting attributes when possible.
  let pline = getline(plnum)
  let pline_len = strlen(pline)
  if has('syntax_items')
    " If the last character in the line is a comment, do a binary search for
    " the start of the comment.  synID() is slow, a linear search would take
    " too long on a long line.
    if synIDattr(synID(plnum, pline_len, 1), "name") =~ "Comment$"
      let min = 1
      let max = pline_len
      while min < max
      let col = (min + max) / 2
      if synIDattr(synID(plnum, col, 1), "name") =~ "Comment$"
        let max = col
      else
        let min = col + 1
      endif
      endwhile
      let pline = strpart(pline, 0, min - 1)
    endif
  else
    let col = 0
    while col < pline_len
      if pline[col] == '#'
      let pline = strpart(pline, 0, col)
      break
      endif
      let col = col + 1
    endwhile
  endif

  " If the previous line ended with a colon, indent this line
  if pline =~ ':\s*$'
    return plindent + &sw
  endif

  " If the previous line was a stop-execution statement...
  if getline(plnum) =~ '^\s*\(break\|continue\|raise\|return\|pass\)\>'
    " See if the user has already dedented
    if indent(a:lnum) > indent(plnum) - &sw
      " If not, recommend one dedent
      return indent(plnum) - &sw
    endif
    " Otherwise, trust the user
    return -1
  endif

  " If the current line begins with a keyword that lines up with "try"
  if getline(a:lnum) =~ '^\s*\(except\|finally\)\>'
    let lnum = a:lnum - 1
    while lnum >= 1
      if getline(lnum) =~ '^\s*\(try\|except\)\>'
      let ind = indent(lnum)
      if ind >= indent(a:lnum)
        return -1      " indent is already less than this
      endif
      return ind      " line up with previous try or except
      endif
      let lnum = lnum - 1
    endwhile
    return -1            " no matching "try"!
  endif

  " If the current line begins with a header keyword, dedent
  if getline(a:lnum) =~ '^\s*\(elif\|else\)\>'

    " Unless the previous line was a one-liner
    if getline(plnumstart) =~ '^\s*\(for\|if\|try\)\>'
      return plindent
    endif

    " Or the user has already dedented
    if indent(a:lnum) <= plindent - &sw
      return -1
    endif

    return plindent - &sw
  endif

  " When after a () construct we probably want to go back to the start line.
  " a = (b
  "       + c)
  " here
  if parlnum > 0
    return plindent
  endif

  return -1

endfunction

" vim:sw=2
