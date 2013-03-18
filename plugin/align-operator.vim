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

	let iteration = 1
	let longest = -1
	let last_non_ws = -1
	let changed = 0
	while !changed
		for line_number in range(start_line, end_line)
			let line_str = getline(line_number)
			let current = s:match_pos(line_str, align_char, iteration)
			if a:mode == 'l'
				if longest != -1 && current != longest
					let changed = 1
				endif
			elseif a:mode == 'L'
				" TODO: Correctly detect changes in L mode
				let realpos = match(line_str, align_char, 0, iteration)
				let current_non_ws = s:match_pos(line_str[(realpos + 1):], '[^[:space:]]', 1)
				if last_non_ws != -1 && current_non_ws != last_non_ws
					let changed = 1
				endif
				let last_non_ws = max([last_non_ws, current_non_ws])
			endif
			let longest = max([current, longest])
		endfor

		for line_number in range(start_line, end_line)
			let line_str = getline(line_number)
			let pos = s:match_pos(line_str, align_char, iteration)
			if pos < longest
				if a:mode == 'l'
					let padded = repeat(' ', (longest - pos)) . align_char
				elseif a:mode == 'L'
					let padded = align_char . repeat(' ', (longest - pos))
				else
					let padded = align_char
				endif
				let startpos = match(line_str, align_char, 0, iteration)
				let new_line = line_str[:(startpos - 1)] . substitute(line_str[(startpos):], align_char, padded, '')
				let result = setline(line_number, new_line)
			endif
		endfor
		let iteration = iteration + 1
	endwhile

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

	" Testing area for gl with multiple alignments
	" a = b = c
	" foo = bar = baz
	" tiger = monkey = wolf
	" something = another thing = you

	" Testing area for gL with multiple alignments
	" a, b, c
	" tiger, monkey, giraffe
	" foo, bar, baz

	let &selection = sel_save
	let @@ = reg_save
endfunction

" Match the position of a character in a line after accounting for artificial width set by tabs
function! s:match_pos(line, char, count)
	let line = substitute(a:line, "\<Tab>", repeat(' ', &tabstop), 'g')
	let pos = match(line, a:char, 0, a:count)
	return pos
endfunction

nnoremap <silent> <Plug>AlignRight :set opfunc=<SID>opfuncl<CR>g@
vnoremap <silent> <Plug>VAlignRight :<C-U>call <SID>opfuncl(visualmode(), 1)<CR>
nnoremap <silent> <Plug>AlignLeft :set opfunc=<SID>opfuncL<CR>g@
vnoremap <silent> <Plug>VAlignLeft :<C-U>call <SID>opfuncL(visualmode(), 1)<CR>
nnoremap <silent> <Plug>AlignEqual :set opfunc=<SID>opfunceq<CR>g@
vnoremap <silent> <Plug>VAlignEqual :<C-U>call <SID>opfunceq(visualmode(), 1)<CR>
nnoremap <silent> <Plug>AlignColon :set opfunc=<SID>opfuncco<CR>g@
vnoremap <silent> <Plug>VAlignColon :<C-U>call <SID>opfuncco(visualmode(), 1)<CR>

if !exists("g:align_no_mappings") || !g:align_no_mappings
	nmap <silent> gl <Plug>AlignRight
	vmap <silent> gl <Plug>VAlignRight
	nmap <silent> gL <Plug>AlignLeft
	vmap <silent> gL <Plug>VAlignLeft
	nmap <silent> g= <Plug>AlignEqual
	vmap <silent> g= <Plug>VAlignEqual
	nmap <silent> g: <Plug>AlignColon
	vmap <silent> g: <Plug>VAlignColon
endif
