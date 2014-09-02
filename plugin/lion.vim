" lion.vim - A Vim plugin for text alignment operators
" Maintainer:   Tom McDonald <http://github.com/tommcdo>
" Version:      1.0

let s:count = 1
if !exists('g:lion_prompt')
	let g:lion_prompt = 'Pattern [/]: '
endif
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

" Align a range to a particular character
function! s:align(mode, type, vis, align_char)
	let sel_save = &selection
	let &selection = "inclusive"

	try
		" Do we have a character from argument, or should we get one from input?
		let align_pattern = a:align_char
		if align_pattern == ''
			let align_pattern = nr2char(getchar())
		endif
		if align_pattern == '/'
			let align_pattern .= input(g:lion_prompt)
		endif

		" Determine range boundaries
		if a:vis
			let pos = s:getpos("'<", "'>", visualmode())
		else
			let pos = s:getpos("'[", "']", a:type)
		endif
		let [start_line, end_line, start_col, end_col, middle_start_col, middle_end_col] = pos

		let changed = 0 " TODO: Use this for 'all' mode when I get around to it

		" Align for each character up to count
		for iteration in range(1, s:count)
			let line_virtual_pos = [] " Keep track of positions
			let longest = -1          " Track longest sequence

			" Find the longest substring before the align character
			for line_number in range(start_line, end_line)
				if line_number == start_line
					let start = start_col
				else
					let start = middle_start_col
				endif
				if line_number == end_line
					let end = end_col
				else
					let end = middle_end_col
				endif
				let line_str = getline(line_number)
				" Find the 'real' and 'virtual' positions of the align character in this line
				let [real_pos, virtual_pos] = s:match_pos(a:mode, line_str, align_pattern, iteration, line_number, start, end)
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

		if align_pattern[0] == '/'
			silent! call repeat#set("\<Plug>LionRepeat".align_pattern."\<CR>")
		else
			silent! call repeat#set("\<Plug>LionRepeat".align_pattern)
		endif
	finally
		let &selection = sel_save
	endtry
endfunction

function! s:getpos(start, end, mode)
	let [_, start_line, start_col, _] = getpos(a:start)
	let [_, end_line, end_col, _] = getpos(a:end)
	let [middle_start_col, middle_end_col] = [0, -1]
	if a:mode == 'V' || a:mode == 'line'
		let [start_col, end_col] = [0, -1]
	elseif a:mode == "\<C-V>"
		let [middle_start_col, middle_end_col] = [start_col, end_col]
	endif
	return [start_line, end_line, start_col, end_col, middle_start_col, middle_end_col]
endfunction

" Match the position of a character in a line after accounting for artificial width set by tabs
function! s:match_pos(mode, line, char, count, line_number, start, end)
	if strlen(a:char) == 1
		let pattern = escape(a:char, '~^$.')
	else
		let pattern = a:char[1:]
		" Add start-of-match anchor at the end if there isn't already one in the pattern
		if a:mode == 'left' && match(pattern, '\\zs') == -1
			let pattern .= '\zs'
		endif
	endif
	if a:end == -1
		let line = a:line
	else
		let line = a:line[:(a:end - 1)]
	endif
	if a:mode == 'right'
		let real_pos = match(line, pattern, a:start - 1, a:count)
	elseif a:mode == 'left'
		let real_pos = s:first_non_ws_after(line, pattern, a:start - 1, a:count)
	endif
	if real_pos == -1
		let virtual_pos = -1
	else
		let virtual_pos = virtcol([a:line_number, real_pos])
	endif
	return [real_pos, virtual_pos]
endfunction

" Get the first non-whitespace after [count] instances of [char]
function! s:first_non_ws_after(line, pattern, start, count)
	let char_pos = match(a:line, a:pattern, a:start, a:count)
	if char_pos == -1
		return -1
	else
		let m = match(a:line, '[^[:space:]]', char_pos + 1)
		return m
	endif
endfunction

" Echo a string and wait for input (used when I'm debugging)
function! s:debug_str(str)
	echo a:str
	let x = getchar()
endfunction

function! s:assign_map(map, func)
	if a:map == ''
		return
	endif
	execute 'nmap <silent> ' . a:map . ' <Plug>Lion' . a:func
	execute 'vmap <silent> ' . a:map . ' <Plug>VLion' . a:func
endfunction

nnoremap <silent> <Plug>LionRepeat .
nnoremap <silent> <expr> <Plug>LionRight <SID>command("<SID>alignRight")
vnoremap <silent> <expr> <Plug>VLionRight <SID>command("<SID>alignRight", 1)
nnoremap <silent> <expr> <Plug>LionLeft <SID>command("<SID>alignLeft")
vnoremap <silent> <expr> <Plug>VLionLeft <SID>command("<SID>alignLeft", 1)

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

	call s:assign_map(g:lion_map_right, 'Right')
	call s:assign_map(g:lion_map_left, 'Left')
endif
