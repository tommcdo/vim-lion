" Vim Align Operator

let s:count = 1

function! s:command(func, ...)
	let s:count = v:count1
	if a:0
		return ":" . "\<C-U>call " . a:func . "(visualmode(), 1)\<CR>"
	else
		return ":" . "\<C-U>set opfunc=" . a:func . "\<CR>g@"
	endif
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

" Align a range to a particular character
function! s:align(mode, type, vis, align_char)
	let sel_save = &selection
	let &selection = "inclusive"

	" Do we have a character from argument, or should we get one from input?
	if a:align_char == ''
		let align_char = nr2char(getchar())
	else
		let align_char = a:align_char
	endif

	" Determine range boundaries
	if a:vis
		let start_line = line("'<")
		let end_line = line("'>")
	else
		let start_line = line("'[")
		let end_line = line("']")
	endif

	let changed = 0 " TODO: Use this for 'all' mode when I get around to it

	" Align for each character up to count
	for iteration in range(1, s:count)
		let line_virtual_pos = [] " Keep track of positions
		let longest = -1          " Track longest sequence

		" Find the longest substring before the align character
		for line_number in range(start_line, end_line)
			let line_str = getline(line_number)
			" Find the 'real' and 'virtual' positions of the align character in this line
			let [real_pos, virtual_pos] = s:match_pos(a:mode, line_str, align_char, iteration)
			let line_virtual_pos += [[real_pos, virtual_pos]]
			if longest != -1 && virtual_pos != -1 && virtual_pos != longest
				let changed = 1 " TODO: Detect changes in 'all' mode
			endif
			let longest = max([longest, virtual_pos])
		endfor

		" Align each line according to the longest
		for line_number in range(start_line, end_line)
			let line_str = getline(line_number)
			let [real_pos, virtual_pos] = line_virtual_pos[(line_number - start_line)]
			if virtual_pos != -1 && virtual_pos < longest
				let spaces = repeat(' ', (longest - virtual_pos))
				let new_line = line_str[:(real_pos - 1)] . spaces . line_str[(real_pos):]
				let result = setline(line_number, new_line)
			endif
		endfor
		if longest == -1
			let changed = 1 " TODO: Detect changes in 'all' mode
		endif
	endfor
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

" Get the first non-whitespace after [count] instances of [char]
function! s:first_non_ws_after(line, char, count)
	let char_pos = match(a:line, a:char, 0, a:count)
	if char_pos == -1
		return -1
	else
		let m = match(a:line, '[^[:space:]]', char_pos + 1)
		return m
	endif
endfunction

" Echo a string and wait for input (used when I'm debugging)
function! s:debug_str(str)
	echomsg a:str
	let x = getchar()
endfunction

nnoremap <silent> <expr> <Plug>AlignRight <SID>command("<SID>alignRight")
vnoremap <silent> <expr> <Plug>VAlignRight <SID>command("<SID>alignRight", 1)
nnoremap <silent> <expr> <Plug>AlignLeft <SID>command("<SID>alignLeft")
nnoremap <silent> <expr> <Plug>VAlignLeft <SID>command("<SID>alignLeft", 1)
nnoremap <silent> <expr> <Plug>AlignEqual <SID>command("<SID>alignEqual")
nnoremap <silent> <expr> <Plug>VAlignEqual <SID>command("<SID>alignEqual", 1)
nnoremap <silent> <expr> <Plug>AlignColon <SID>command("<SID>alignColon")
nnoremap <silent> <expr> <Plug>VAlignColon <SID>command("<SID>alignColon", 1)

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
