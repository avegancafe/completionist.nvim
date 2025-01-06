local BULLET = '•'
local X_MARK = '✗'
local BUFFER_NAME = 'TodoList'

local KEYBINDS = {
	{ key = 'a', desc = 'Add new note' },
	{ key = 'A', desc = 'Add new subnote' },
	{ key = 'd', desc = 'Delete note' },
	{ key = 'x', desc = 'Toggle done' },
	{ key = 'p', desc = 'Set priority' },
	{ key = 'q', desc = 'Close window' },
	{ key = '?', desc = 'Show help' },
}

local M = {
	config = {
		filepath = nil,
		colors = {
			normal = '#ffffff',
			done = '#666666',
			medium = '#ffff00',
			high = '#ff0000',
		},
		icons = {
			bullet = '•',
			done = '✗',
		}
	},
	buffer = nil,
	window = nil,
	notes = {},
	help_visible = false,
}

local function render_note(note, level, lines, ancestors_done)
	local indent = string.rep('  ', level)
	local checkbox = note.done and M.config.icons.done or M.config.icons.bullet
	local text = note.note
	local is_done = note.done or ancestors_done

	local line = indent .. checkbox .. ' ' .. text
	local hl = 'TodoListNormal'

	if is_done then
		hl = 'TodoListDone'
	elseif note.priority == 'high' then
		hl = 'TodoListHigh'
	elseif note.priority == 'medium' then
		hl = 'TodoListMedium'
	end

	table.insert(lines, { line = line, hl = hl })

	if note.subnotes then
		for _, subnote in ipairs(note.subnotes) do
			render_note(subnote, level + 1, lines, is_done)
		end
	end
end

local function render()
	if not M.buffer or not vim.api.nvim_buf_is_valid(M.buffer) then
		return
	end

	local lines = {}
	for _, note in ipairs(M.notes) do
		render_note(note, 0, lines, false)
	end

	if M.help_visible then
		table.insert(lines, { line = '', hl = 'Comment' })
		table.insert(lines, { line = 'Keybindings:', hl = 'Comment' })
		table.insert(lines, { line = '----------', hl = 'Comment' })
		for _, bind in ipairs(KEYBINDS) do
			table.insert(lines, {
				line = string.format('%s : %s', bind.key, bind.desc),
				hl = 'Comment',
			})
		end
	end

	vim.api.nvim_buf_set_option(M.buffer, 'modifiable', true)

	local plain_lines = vim.tbl_map(function(item)
		return item.line
	end, lines)
	vim.api.nvim_buf_set_lines(M.buffer, 0, -1, false, plain_lines)

	for i, item in ipairs(lines) do
		if item.hl then
			vim.api.nvim_buf_add_highlight(M.buffer, -1, item.hl, i - 1, 0, -1)
		end
	end

	vim.api.nvim_buf_set_option(M.buffer, 'modifiable', false)
end

local function save_notes()
	if not M.config.filepath then
		return
	end

	local file = io.open(M.config.filepath, 'w')
	if not file then
		return
	end

	local ok, content = pcall(vim.json.encode, M.notes)
	if ok then
		file:write(content)
	else
		vim.notify('Failed to save notes', vim.log.levels.ERROR)
	end
	file:close()
end

local function get_note_at_cursor()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local current_line = 0

	local function traverse_notes(notes, parent)
		for i, note in ipairs(notes) do
			current_line = current_line + 1
			if current_line == cursor_line then
				return note, notes, i, parent
			end

			if note.subnotes then
				local found, container, index, p = traverse_notes(note.subnotes, note)
				if found then
					return found, container, index, p
				end
			end
		end
		return nil, nil, nil, nil
	end

	return traverse_notes(M.notes)
end

function M.add_note(is_subnote, note_text)
	local new_note = {
		note = note_text,
		done = false,
		priority = 'low',
		subnotes = {},
	}

	if is_subnote then
		local current_note = get_note_at_cursor()
		if current_note then
			current_note.subnotes = current_note.subnotes or {}
			table.insert(current_note.subnotes, new_note)
		end
	else
		table.insert(M.notes, new_note)
	end

	save_notes()
	render()
end

function M.mark_done()
	local note = get_note_at_cursor()
	if note then
		note.done = true
		save_notes()
		render()
	end
end

function M.mark_undone()
	local note = get_note_at_cursor()
	if note then
		note.done = false
		save_notes()
		render()
	end
end

function M.delete_note()
	local note, container, index = get_note_at_cursor()
	if note and container and index then
		table.remove(container, index)
		save_notes()
		render()
	end
end

function M.set_priority()
	local note = get_note_at_cursor()
	if not note then
		return
	end

	local priorities = { 'low', 'medium', 'high' }

	local function on_choice(choice)
		if type(choice) == 'string' and vim.tbl_contains(priorities, choice) then
			note.priority = choice
			save_notes()
			render()
		end
	end

	local opts = {
		prompt = 'Select priority:',
		format_item = function(item)
			return item:sub(1, 1):upper() .. item:sub(2) -- Capitalize first letter
		end,
	}

	local ok = pcall(vim.ui.select, priorities, opts, on_choice)
	if not ok then
		local current = note.priority or 'low'
		local next_index = 1

		for i, p in ipairs(priorities) do
			if p == current then
				next_index = (i % #priorities) + 1
				break
			end
		end

		note.priority = priorities[next_index]
		save_notes()
		render()
	end
end

local function load_notes()
	if not M.config.filepath then
		error('Filepath not configured')
		return
	end

	local file = io.open(M.config.filepath, 'r')
	if not file then
		M.notes = {}
		return
	end

	local content = file:read('*all')
	file:close()

	local ok, result = pcall(vim.json.decode, content)
	if ok then
		M.notes = result or {}
	else
		M.notes = {}
		vim.notify('Failed to parse notes file', vim.log.levels.ERROR)
	end
end

function M.setup(opts)
	opts = opts or {}
	M.config.filepath = opts.filepath or vim.fn.stdpath('data') .. '/todolist.json'

	if opts.colors then
		M.config.colors = vim.tbl_deep_extend('force', M.config.colors, opts.colors)
	end

	if opts.icons then
		M.config.icons = vim.tbl_deep_extend('force', M.config.icons, opts.icons)
	end

	vim.cmd(string.format(
		[[
		highlight default TodoListNormal guifg=%s
		highlight default TodoListDone guifg=%s
		highlight default TodoListMedium guifg=%s
		highlight default TodoListHigh guifg=%s
	]],
		M.config.colors.normal,
		M.config.colors.done,
		M.config.colors.medium,
		M.config.colors.high
	))

	load_notes()
end

local function show_help()
	M.help_visible = not M.help_visible
	render()
end

local function setup_keymaps()
	if not M.buffer then
		return
	end

	local function map(key, func, desc)
		vim.keymap.set('n', key, func, { buffer = M.buffer, silent = true, desc = desc })
	end

	map('a', function()
		if M.help_visible then
			M.help_visible = false
			render()
		end
		vim.ui.input({ prompt = 'New note: ' }, function(input)
			if input then
				M.add_note(false, input)
			end
		end)
	end, 'Add new note')

	map('A', function()
		if M.help_visible then
			M.help_visible = false
			render()
		end
		vim.ui.input({ prompt = 'New subnote: ' }, function(input)
			if input then
				M.add_note(true, input)
			end
		end)
	end, 'Add new subnote')

	map('d', function()
		if M.help_visible then
			M.help_visible = false
			render()
		end
		M.delete_note()
	end, 'Delete note')

	map('x', function()
		if M.help_visible then
			M.help_visible = false
			render()
		end
		local note = get_note_at_cursor()
		if note then
			if note.done then
				M.mark_undone()
			else
				M.mark_done()
			end
		end
	end, 'Toggle done')

	map('p', function()
		if M.help_visible then
			M.help_visible = false
			render()
		end
		M.set_priority()
	end, 'Set priority')

	map('q', function()
		if M.help_visible then
			M.help_visible = false
			render()
		end
		M.toggle()
	end, 'Close window')

	map('?', show_help, 'Show help')
end

function M.toggle()
	if M.window and vim.api.nvim_win_is_valid(M.window) then
		local win_to_close = M.window
		M.window = nil

		if M.buffer and vim.api.nvim_buf_is_valid(M.buffer) then
			vim.api.nvim_buf_set_option(M.buffer, 'bufhidden', 'hide')
		end

		vim.api.nvim_win_close(win_to_close, true)

		vim.schedule(function()
			if M.config.filepath then
				local ok, content = pcall(vim.json.encode, M.notes)
				if ok then
					vim.fn.writefile({ content }, M.config.filepath)
				end
			end
		end)

		return
	end

	if not M.buffer or not vim.api.nvim_buf_is_valid(M.buffer) then
		M.buffer = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(M.buffer, BUFFER_NAME)

		local opts = {
			modifiable = false,
			buftype = 'nofile',
			swapfile = false,
			bufhidden = 'hide',
			filetype = 'todolist',
		}

		for k, v in pairs(opts) do
			vim.api.nvim_buf_set_option(M.buffer, k, v)
		end

		if M.config.filepath and vim.fn.filereadable(M.config.filepath) == 1 then
			local content = vim.fn.readfile(M.config.filepath)
			if #content > 0 then
				local ok, result = pcall(vim.json.decode, content[1])
				if ok then
					M.notes = result or {}
				end
			end
		end
	end

	vim.cmd('botright vertical split')
	vim.cmd('vertical resize 60')
	M.window = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(M.window, M.buffer)

	if not vim.b[M.buffer].keymaps_setup then
		setup_keymaps()
		vim.b[M.buffer].keymaps_setup = true
	end

	render()
end

return M
