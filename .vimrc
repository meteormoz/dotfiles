" 基本設定
set number
set title
set ruler
set laststatus=2
syntax on 
set tabstop=8
set cindent
set incsearch
set hlsearch
set wrap
set whichwrap= 
set ignorecase
set smartcase
set hidden
set wildmode=longest,list
set history=200

" cygwin
if has('win32unix')
	set backspace=indent,eol,start
	inoremap [1;5A <Up>
endif

" カーソル形状の変更
if &term == "xterm"
	let &t_ti.="\e[1 q"
	let &t_SI.="\e[5 q"
	let &t_EI.="\e[1 q"
	let &t_te.="\e[0 q"
endif

" キーバインド
" ドットコマンドが効くように改善します
" 比較演算子のキーバインドを作成します
inoremap {<Enter> {}<Left><CR><ESC><S-o>
inoremap { {}<Left>
inoremap {<Space> {<Space><Space>}<Left><Left>
inoremap {" {""}<Left><Left>
inoremap @ []<Left>
inoremap [ []<Left>
inoremap ( ()<Left>
inoremap ' ''<Left>
inoremap " ""<Left>
inoremap ` ``<Left>
inoremap jk <ESC>

cnoremap jk <C-u><C-h>

nnoremap 0 ^
nnoremap ^ 0
nnoremap <Space>, :<C-u>vs ~/.vimrc<CR>
nnoremap <Space>s :<C-u>source ~/.vimrc<CR>
nnoremap <ESC><ESC> :<C-u>nohlsearch<CR>
nnoremap <Space>h ^
nnoremap <Space>l $
vnoremap <Space>h ^
vnoremap <Space>l $

" コマンドラインモードのフィルタ
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>

" 行挿入
nnoremap <Space>o :<C-u>for i in range(v:count1) \| silent! call append(line('.'), '') \| endfor<CR>
nnoremap <Space>O :<C-u>for i in range(v:count1) \| silent! call append(line('.') - 1, '') \| endfor<CR>

"--Complet Comment--"
nnoremap <Space>/ :<C-u>silent! call ToggleComment(line('.') - 1, line('.') + v:count1)<CR>
vnoremap <Space>/ :<C-u>silent! call ToggleComment(line("'<") - 1, line("'>") + 1)<CR>

"--enter branckets"
nnoremap <Space>( :<C-u>call EnterBrankets()<CR>

" AutoCmd
augroup MyAutoCmd
	"--Initialize--"
	autocmd!

	" InsertLeaveイベントで、if/for文の括弧補完を行う
	autocmd InsertLeave *.c call CompletBrackets(getline('.'))
	autocmd InsertLeave *.cpp call CompletBrackets(getline('.'))

	autocmd InsertLeave *.c while matchstr(getline('.'), '.', col('.')) =~# '\v("|''|\)|]|>)' | call cursor(getline('.'), col('.')+1) | endwhile
	autocmd InsertLeave *.cpp while matchstr(getline('.'), '.', col('.')) =~# '\v("|''|\)|]|\>)' | call cursor(getline('.'), col('.')+1) | endwhile

	" クオートの補完とカーソルの移動
	" 冗長?
	" C/C++
	" autocmd InsertCharPre *.c,*.cpp call CatInputChar('[', ']')
	" autocmd CursorMovedI *.c,*cpp call PutBackCursor('[]')

	" autocmd InsertCharPre *.c,*cpp call CatInputChar('"', '"')
	" autocmd CursorMovedI *.c,*cpp call PutBackCursor('""')
	
	" autocmd InsertCharPre *.c,*cpp call CatInputChar('(', ')')
	" autocmd CursorMovedI *.c,*cpp call PutBackCursor('()')

	" Vimrc
	" autocmd InsertCharPre *.vim,*.vimrc call CatInputChar('"', ' ')

	" LaTeX
	"autocmd InsertLeave *.tex if getline('.') =~# '\\begin{.*}\s*$' | t. | s/begin/end/ | endif

	"--QuickFix--"
	autocmd QuickFixCmdPost *grep* cwindow
	autocmd QuickFixCmdPost vim* cwindow
augroup END

"--Functions--"
function! s:IsComment(str)
	if matchstr(a:str, '\V/*') ==# '/*'
		return 1
	elseif matchstr(a:str, '\V*/') ==# '*/'
		return 2
	else
		return 0
	endif
endfunction

function! ToggleComment(upper, lower)
	let l:upper = a:upper
	let l:lower = a:lower
	let stu1 = 0
	let stu2 = 0
	while l:upper >= 0
		let stu1 = s:IsComment(getline(l:upper))
		if stu1 == 1
			break
		elseif stu2 == 2
			break
		endif
		let l:upper -= 1
	endwhile

	while l:lower <= line('$')
		let stu2 = s:IsComment(getline(l:lower))
		if stu2 == 2
			break
		elseif stu2 == 1
			break
		endif
		let l:lower += 1
	endwhile

	if stu1 == 1 && stu2 == 2
		let s = @"
		exec l:upper . "d"
		exec l:lower-1 . "d"
		let @" = s
	else
		call append(a:upper, '/*') 
		exec a:upper+1 . "normal =="
		call append(a:lower, '*/')
		exec a:lower+1 . "normal =="
		normal hx
	endif
endfunction

" InsertCharPreイベント用
" 80行を跨がないように関数を作成した。
function! CatInputChar(pat, ch)
if v:char == a:pat
	let v:char = a:pat . a:ch
endif
endfunction

" CursorMovedIイベント用
" CursorMovedI モードで取得するカーソルから一番近い文字の位置は、col('.')-2 で取得する。
" col('.')-3から、2文字取得している。
function! PutBackCursor(pat)
if matchstr(getline('.'), '..', col('.')-3) == a:pat
	call cursor(getline('.'), col('.')-1)
endif
endfunction

"引数に置き換え後のパターンを積むように修正します"
function! CompletBrackets(line)
	if a:line =~# '^\s*if\s*(.\+)\s*[^{;]*$' ||
	 \ a:line =~# '^\s*else\s*if\s*(.\+)\s*[^{;]*$' ||
	 \ a:line =~# '^\s*while\s*(.\+)\s*[^{;]*$' ||
	 \ a:line =~# '^\s*else\s*[^{;]*$' ||
	 \ a:line =~# '^\s*for\s*(.*;.*;.*)\s*[^{]*$'
		if (a:line =~# 'if')
			if (a:line =~# 'else')
				let str = matchstr(a:line, '\s*else\s*if\s*(.*)$') 
			else
				let str = matchstr(a:line, '\s*if\s*(.*)$') 
			endif
		elseif (a:line =~# 'else')
			let str = matchstr(a:line, '\s*else$') 
		elseif (a:line =~# 'for')
			let str = matchstr(a:line, '\s*for\s*(.*)$') 
		elseif (a:line =~# '\s*while')
			let str = matchstr(a:line, '\s*while\s*(.*)$') 
		elseif (a:line =~# 'do')
			let str = matchstr(a:line, '\s*do$') 
		endif

		" debug
		echomsg "str..." . str 

		" 文字列の正規化をやめよう
		let str = str . ' {'
		let brank = matchstr(a:line, '\s*')

		call setline(line('.'), str)	
		call append(line('.'), brank . matchstr(brank, '\s'))
		call append(line('.') + 1, brank . '}')
		normal j
		startinsert!
	endif
endfunction

function! EnterBrankets()
	let i = 0
	while line('.') - i >= 0
		let str = getline(line('.') - i)
		if matchstr(str, '(.*)') =~# '(.*)'
			break
		endif
		let i += 1
	endwhile
	if line('.') - i >= 0
		call cursor(line('.') - i, 0)
		call cursor(line('.'), col('$'))
		if matchstr(getline('.'), '.', col('.')) !=# ')'
			normal F)
		endif
		startinsert
	endif
endfunction

" Scouter
function! Scouter(file, ...)
	let pat = '^\s*$\|^\s*"'
	let lines = readfile(a:file)
	if !a:0 || !a:1
		let lines = split(substitute(join(lines, "\n"), '\n\s*\\', '', 'g'), "\n")
	endif
	return len(filter(lines,'v:val !~ pat'))
endfunction

command! -bar -bang -nargs=? -complete=file Scouter
\	echo Scouter(empty(<q-args>) ? $MYVIMRC : expand(<q-args>), <bang>0)
command! -bar -bang -nargs=? -complete=file GScouter
\	echo Scouter(empty(<q-args>) ? $MYGVIMRC : expand(<q-args>), <bang>0)
