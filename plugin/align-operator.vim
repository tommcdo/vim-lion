" Vim Align Operator

function! s:opfuncl(type, ...)
	return s:align('l', a:type, a:0, '')
endfunction

function! s:opfuncL(type, ...)
	return s:align('L', a:type, a:0, '')
endfunction

function! s:opfunceq(type, ...)
	return s:align('l', a:type, a:0, '=')
endfunction

function! s:opfuncco(type, ...)
	return s:align('L', a:type, a:0, ':')
endfunction

function! s:align(mode, type, vis, align_char)
	let sel_save = &selection
	let &selection = "inclusive"
	let reg_save = @@

	if a:align_char == ''
		let align_char = nr2char(getchar())
	else
		let align_char = a:align_char
	endif

	if a:vis
		silent exe "normal! `<" . a:type . "`>y"
	elseif a:type == 'line'
		silent exe "normal! '[V']y"
	elseif a:type == 'block'
		silent exe "normal! `[\<C-V>`]y"
	else
		silent exe "normal! `[v`]y"
	endif

	let start_line = line("'<")
	let end_line = line("'>")

	let longest = 0
	for line_number in range(start_line, end_line)
		let line_str = getline(line_number)
		let longest = max([s:match_pos(line_str, align_char), longest])
	endfor

	for line_number in range(start_line, end_line)
		let line_str = getline(line_number)
		let pos = s:match_pos(line_str, align_char)
		if pos < longest
			if a:mode == 'l'
				let padded = repeat(' ', (longest - pos)) . align_char
			elseif a:mode == 'L'
				let padded = align_char . repeat(' ', (longest - pos))
			else
				let padded = align_char
			endif
			let new_line = substitute(line_str, align_char, padded, '')
			let result = setline(line_number, new_line)
		endif
	endfor

	" Testing area for gl
	" something = 1
	" something really quite long = 6
	" another thing = 2
	" yet another thing = 3
	" short = 4
	" x = 5

	" Testing area for gL
	" something: 1
	" something really quite long: 6
	" another thing: 2
	" yet another thing: 3
	" short: 4
	" x: 5

	let &selection = sel_save
	let @@ = reg_save
endfunction

" Match the position of a character in a line after accounting for artificial width set by tabs
function! s:match_pos(line, char)
	let line = substitute(a:line, "\<Tab>", repeat(' ', &tabstop), 'g')
	let pos = match(line, a:char)
	return pos
endfunction

nmap <silent> gl :set opfunc=<SID>opfuncl<CR>g@
vmap <silent> gl :<C-U>call <SID>opfuncl(visualmode(), 1)<CR>
nmap <silent> gL :set opfunc=<SID>opfuncL<CR>g@
vmap <silent> gL :<C-U>call <SID>opfuncL(visualmode(), 1)<CR>

nmap <silent> g= :set opfunc=<SID>opfunceq<CR>g@
vmap <silent> g= :<C-U>call <SID>opfunceq(visualmode(), 1)<CR>

nmap <silent> g: :set opfunc=<SID>opfuncco<CR>g@
vmap <silent> g: :<C-U>call <SID>opfuncco(visualmode(), 1)<CR>
