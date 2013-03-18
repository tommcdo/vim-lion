" Vim Align Operator

let s:count = 1

function! s:command(func)
	let s:count = v:count1
	return ":" . "\<C-U>set opfunc=" . a:func . "\<CR>g@"
endfunction

function! s:alignRight(type, ...)
	return s:align('right', a:type, a:0, '')
endfunction

function! s:alignLeft(type, ...)
	return s:align('left', a:type, a:0, '')
endfunction

function! s:alignEqual(type, ...)
	return s:align('right', a:type, a:0, '=')
endfunction

function! s:alignColon(type, ...)
	return s:align('left', a:type, a:0, ':')
endfunction

function! s:align(mode, type, count, align_char)
	let sel_save = &selection
	let &selection = "inclusive"
	let reg_save = @@

	if a:align_char == ''
		let align_char = nr2char(getchar())
	else
		let align_char = a:align_char
	endif

	if a:count
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
	let changed = 0
	while !changed
		let line_virtual_pos = []
		let longest = -1
		for line_number in range(start_line, end_line)
			let line_str = getline(line_number)
			let [real_pos, virtual_pos] = s:match_pos(a:mode, line_str, align_char, iteration)
			let line_virtual_pos += [[real_pos, virtual_pos]]
			if longest != -1 && virtual_pos != -1 && virtual_pos != longest
				let changed = 1
			endif
			let longest = max([longest, virtual_pos])
		endfor

		for line_number in range(start_line, end_line)
			let line_str = getline(line_number)
			let [real_pos, virtual_pos] = line_virtual_pos[(line_number - start_line)]
			if virtual_pos != -1 && virtual_pos < longest
				let spaces = repeat(' ', (longest - virtual_pos))
				let new_line = line_str[:(real_pos - 1)] . spaces . line_str[(real_pos):]
				let result = setline(line_number, new_line)
			endif
		endfor
		let iteration = iteration + 1
		if longest == -1
			let changed = 1
		endif
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

	" Testing area for gl with repeats
	" monkey = tiger = fish
	" a = b = c
	" foo = bar = window

	" Testing area for gL with repeats
	" alice, bob, charlie
	" daniel, ernest, frank
	" greg, harrison, ingrid

endfunction

" Match the position of a character in a line after accounting for artificial width set by tabs
function! s:match_pos(mode, line, char, count)
	" Get the line as if it had tabs instead of spaces
	let line = s:tabs2spaces(a:line)
	if a:mode == 'right'
		let virtual_pos = match(line, a:char, 0, a:count)
		let real_pos = match(a:line, a:char, 0, a:count)
	elseif a:mode == 'left'
		let virtual_pos = s:first_non_ws_after(line, a:char, a:count)
		let real_pos = s:first_non_ws_after(a:line, a:char, a:count)
	endif
	return [real_pos, virtual_pos]
endfunction

" Convert tabs to spaces in a line
function! s:tabs2spaces(line, ...)
	" TODO: Account for tabs occurring at columns that don't define tabstops
	return substitute(a:line, "\<Tab>", repeat(' ', &tabstop), 'g')
endfunction

function! s:first_non_ws_after(line, char, count)
	" monkey, tiger, fish
	let char_pos = match(a:line, a:char, 0, a:count)
	if char_pos == -1
		return -1
	else
		let m = match(a:line, '[^[:space:]]', char_pos + 1)
		return m
	endif
endfunction

function! s:debug_str(str)
	echomsg a:str
	let x = getchar()
endfunction

nnoremap <silent> <expr> <Plug>AlignRight <SID>command("<SID>alignRight")
vnoremap <silent> <Plug>VAlignRight :<C-U>call <SID>alignRight(visualmode(), v:count1)<CR>
nnoremap <silent> <expr> <Plug>AlignLeft <SID>command("<SID>alignLeft")
vnoremap <silent> <Plug>VAlignLeft :<C-U>call <SID>alignLeft(visualmode(), v:count1)<CR>
nnoremap <silent> <expr> <Plug>AlignEqual <SID>command("<SID>alignEqual")
vnoremap <silent> <Plug>VAlignEqual :<C-U>call <SID>alignEqual(visualmode(), v:count1)<CR>
nnoremap <silent> <expr> <Plug>AlignColon <SID>command("<SID>alignColon")
vnoremap <silent> <Plug>VAlignColon :<C-U>call <SID>alignColon(visualmode(), v:count1)<CR>

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
