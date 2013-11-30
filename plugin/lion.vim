" lion.vim - A Vim plugin for text alignment operators
" Maintainer:   Tom McDonald <http://github.com/tommcdo>
" Version:      1.0

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
				if real_pos == 0
					let new_line = spaces . line_str
				else
					let new_line = line_str[:(real_pos - 1)] . spaces . line_str[(real_pos):]
				endif
				call setline(line_number, new_line)
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
	let pattern = escape(a:char, '^$.')
	if a:mode == 'right'
		let virtual_pos = match(line, pattern, 0, a:count)
		let real_pos = match(a:line, pattern, 0, a:count)
	elseif a:mode == 'left'
		let virtual_pos = s:first_non_ws_after(line, pattern, a:count)
		let real_pos = s:first_non_ws_after(a:line, pattern, a:count)
	endif
	return [real_pos, virtual_pos]
endfunction

" Convert tabs to spaces, accounting for tabs not aligned to stops
function! s:tabs2spaces(line, ...)
	let line = ''
	if a:0
		let cnt = (a:1 % &tabstop) " Adjust for starting column
	else
		let cnt = 0
	endif
	for idx in range(strlen(a:line))
		let char = a:line[idx]
		if char == "\<Tab>"
			let num_spaces = (&tabstop - cnt)
			let line = line . repeat(' ', num_spaces)
			let cnt += num_spaces
		else
			let line = line . char
			let cnt += 1
		endif
		let cnt = (cnt % &tabstop)
	endfor
	return line
endfunction

" Get the first non-whitespace after [count] instances of [char]
function! s:first_non_ws_after(line, pattern, count)
	let char_pos = match(a:line, a:pattern, 0, a:count)
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

function! s:assign_map(map, func)
	if a:map == ''
		return
	endif
	execute 'nmap <silent> ' . a:map . ' <Plug>Lion' . a:func
	execute 'vmap <silent> ' . a:map . ' <Plug>VLion' . a:func
endfunction

nnoremap <silent> <expr> <Plug>LionRight <SID>command("<SID>alignRight")
vnoremap <silent> <expr> <Plug>VLionRight <SID>command("<SID>alignRight", 1)
nnoremap <silent> <expr> <Plug>LionLeft <SID>command("<SID>alignLeft")
nnoremap <silent> <expr> <Plug>VLionLeft <SID>command("<SID>alignLeft", 1)
nnoremap <silent> <expr> <Plug>LionEqual <SID>command("<SID>alignEqual")
nnoremap <silent> <expr> <Plug>VLionEqual <SID>command("<SID>alignEqual", 1)
nnoremap <silent> <expr> <Plug>LionColon <SID>command("<SID>alignColon")
nnoremap <silent> <expr> <Plug>VLionColon <SID>command("<SID>alignColon", 1)

if !exists('g:lion_create_maps')
	let g:lion_create_maps = 1
endif

if g:lion_create_maps
	if !exists('g:lion_map_right')
		let g:lion_map_right = 'gl'
	endif
	if !exists('g:lion_map_left')
		let g:lion_map_left = 'gL'
	endif
	if !exists('g:lion_map_equal')
		let g:lion_map_equal = 'g='
	endif
	if !exists('g:lion_map_colon')
		let g:lion_map_colon = 'g:'
	endif
	
	call s:assign_map(g:lion_map_right, 'Right')
	call s:assign_map(g:lion_map_left, 'Left')
	call s:assign_map(g:lion_map_equal, 'Equal')
	call s:assign_map(g:lion_map_colon, 'Colon')
endif
