local assert = require('luassert')
local M = require('completionist')

describe('completionist.nvim', function()
	before_each(function()
		M.config = {
			filepath = vim.fn.tempname(),
			colors = {
				normal = '#ffffff',
				done = '#666666',
				medium = '#ffff00',
				high = '#ff0000',
			},
			icons = {
				bullet = '•',
				done = '✗',
			},
		}
		M.setup({ filepath = M.config.filepath })
		
		local bufnr = vim.fn.bufnr('TodoList')
		if bufnr ~= -1 then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
		M.buffer = nil
		M.window = nil
		M.notes = {}
		M.help_visible = false
	end)

	after_each(function()
		if vim.fn.filereadable(M.config.filepath) == 1 then
			vim.fn.delete(M.config.filepath)
		end
		if M.window and vim.api.nvim_win_is_valid(M.window) then
			vim.api.nvim_win_close(M.window, true)
		end
		if M.buffer and vim.api.nvim_buf_is_valid(M.buffer) then
			vim.api.nvim_buf_delete(M.buffer, { force = true })
		end
		local bufnr = vim.fn.bufnr('TodoList')
		if bufnr ~= -1 then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
	end)

	describe('basic functionality', function()
		it('should initialize with default config', function()
			assert.truthy(M.config)
			assert.equals('#ffffff', M.config.colors.normal)
			assert.equals('•', M.config.icons.bullet)
		end)

		it('should manage buffer state', function()
			assert.falsy(M.buffer)
			assert.falsy(M.window)
			assert.same({}, M.notes)
			assert.falsy(M.help_visible)
		end)

		it('should open todo list window', function()
			M.toggle()
			assert.truthy(M.window)
			assert.truthy(M.buffer)
			assert.truthy(vim.api.nvim_win_is_valid(M.window))
			assert.truthy(vim.api.nvim_buf_is_valid(M.buffer))
		end)

		it('should add new note', function()
			M.toggle()
			M.add_note(false, 'Test note')
			local lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals('• Test note', lines[1])
		end)

		it('should toggle note completion', function()
			M.toggle()
			M.add_note(false, 'Test note')
			vim.api.nvim_win_set_cursor(M.window, { 1, 0 })
			M.mark_done()
			local lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals('✗ Test note', lines[1])
		end)

		it('should add subnote', function()
			M.toggle()
			M.add_note(false, 'Parent note')
			vim.api.nvim_win_set_cursor(M.window, { 1, 0 })
			M.add_note(true, 'Child note')
			local lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals('• Parent note', lines[1])
			assert.equals('  • Child note', lines[2])
		end)

		it('should set priority', function()
			M.toggle()
			M.add_note(false, 'Test note')
			vim.api.nvim_win_set_cursor(M.window, { 1, 0 })
			local note = M.notes[1]
			note.priority = 'high'
			M.toggle()
			M.toggle()
			local ns = vim.api.nvim_get_namespaces()['TodoListHigh']
			local marks = vim.api.nvim_buf_get_extmarks(M.buffer, ns or -1, 0, -1, {})
			assert.truthy(#marks > 0)
		end)

		it('should delete note', function()
			M.toggle()
			M.add_note(false, 'Test note')

			assert.equals(1, #M.notes)
			local initial_lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals(1, #initial_lines)
			assert.equals('• Test note', initial_lines[1])

			vim.api.nvim_win_set_cursor(M.window, { 1, 0 })

			local orig_input = vim.fn.input
			local orig_inputsave = vim.fn.inputsave
			local orig_inputrestore = vim.fn.inputrestore
			local orig_cmd = vim.cmd
			vim.fn.input = function()
				return 'y'
			end
			vim.fn.inputsave = function() end
			vim.fn.inputrestore = function() end
			vim.cmd = function() end

			M.delete_note()

			vim.fn.input = orig_input
			vim.fn.inputsave = orig_inputsave
			vim.fn.inputrestore = orig_inputrestore
			vim.cmd = orig_cmd

			assert.equals(0, #M.notes)

			M.toggle()
			M.toggle()

			local final_lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals(1, #final_lines)
			assert.equals('', final_lines[1])
		end)

		it('should save and load notes', function()
			M.toggle()
			M.add_note(false, 'Test note')

			M.notes = {}
			M.toggle()

			local lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals('• Test note', lines[1])
		end)

		it('should edit note', function()
			M.toggle()
			M.add_note(false, 'Test note')
			vim.api.nvim_win_set_cursor(M.window, { 1, 0 })

			local orig_input = vim.ui.input
			vim.ui.input = function(opts, cb)
				assert.equals('Edit note: ', opts.prompt)
				assert.equals('Test note', opts.default)
				cb('Edited note')
			end

			M.edit_note()

			vim.ui.input = orig_input

			local lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals('• Edited note', lines[1])
			assert.equals('Edited note', M.notes[1].note)
		end)
	end)

	describe('window management', function()
		it('should handle window state', function()
			assert.falsy(M.window)
			M.toggle()
			assert.truthy(M.window)
			M.toggle()
			assert.falsy(M.window)
		end)

		it('should toggle help', function()
			M.toggle()
			local initial_lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			M.help_visible = true
			M.toggle()
			M.toggle()
			local help_lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.is_true(#help_lines > #initial_lines)
		end)
	end)

	describe('current_task', function()
		it('should return empty string when no notes exist', function()
			assert.equals('', M.current_task())
		end)

		it('should return single note when no subnotes exist', function()
			M.notes = {
				{ note = 'Test note', priority = 'low' },
			}
			assert.equals('Test note', M.current_task())
		end)

		it('should return highest priority note path', function()
			M.notes = {
				{
					note = 'Parent note',
					priority = 'low',
					subnotes = {
						{ note = 'High priority child', priority = 'high' },
						{ note = 'Low priority child', priority = 'low' },
					},
				},
			}
			assert.equals('Parent note > High priority child', M.current_task())
		end)

		it('should handle multiple levels of subnotes', function()
			M.notes = {
				{
					note = 'Root note',
					priority = 'low',
					subnotes = {
						{
							note = 'Medium priority',
							priority = 'medium',
							subnotes = {
								{ note = 'High priority', priority = 'high' },
							},
						},
					},
				},
			}
			assert.equals('Root note > Medium priority > High priority', M.current_task())
		end)

		it('should handle multiple root notes with different priorities', function()
			M.notes = {
				{ note = 'Low priority root', priority = 'low' },
				{ note = 'High priority root', priority = 'high' },
				{ note = 'Medium priority root', priority = 'medium' },
			}
			assert.equals('High priority root', M.current_task())
		end)

		it('should handle notes with no priority set', function()
			M.notes = {
				{ note = 'No priority note' },
				{ note = 'High priority note', priority = 'high' },
			}
			assert.equals('High priority note', M.current_task())
		end)
	end)

	describe('setup configuration', function()
		it('should handle filepath as a string', function()
			local test_filepath = vim.fn.tempname() .. '_string_test.json'
			M.setup({ filepath = test_filepath })

			assert.equals(test_filepath, M.config.filepath)

			if vim.fn.filereadable(test_filepath) == 1 then
				vim.fn.delete(test_filepath)
			end
		end)

		it('should handle filepath as a function', function()
			local test_filepath = vim.fn.tempname() .. '_function_test.json'
			local filepath_fn = function()
				return test_filepath
			end

			M.setup({ filepath = filepath_fn })

			assert.equals(test_filepath, M.config.filepath)

			if vim.fn.filereadable(test_filepath) == 1 then
				vim.fn.delete(test_filepath)
			end
		end)

		it('should use default filepath when not specified', function()
			M.setup({})
			local default_path = vim.fn.stdpath('data') .. '/todolist.json'

			assert.equals(default_path, M.config.filepath)
		end)
	end)

	describe('note movement', function()
		it('should move note up in root list', function()
			M.toggle()
			M.add_note(false, 'First note')
			M.add_note(false, 'Second note')
			M.add_note(false, 'Third note')

			vim.api.nvim_win_set_cursor(M.window, { 2, 0 })

			M.move_note_up()

			assert.equals('Second note', M.notes[1].note)
			assert.equals('First note', M.notes[2].note)
			assert.equals('Third note', M.notes[3].note)

			local lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals('• Second note', lines[1])
			assert.equals('• First note', lines[2])
			assert.equals('• Third note', lines[3])
		end)

		it('should move note down in root list', function()
			M.toggle()
			M.add_note(false, 'First note')
			M.add_note(false, 'Second note')
			M.add_note(false, 'Third note')

			vim.api.nvim_win_set_cursor(M.window, { 2, 0 })

			M.move_note_down()

			assert.equals('First note', M.notes[1].note)
			assert.equals('Third note', M.notes[2].note)
			assert.equals('Second note', M.notes[3].note)

			local lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals('• First note', lines[1])
			assert.equals('• Third note', lines[2])
			assert.equals('• Second note', lines[3])
		end)

		it('should not move first note up', function()
			M.toggle()
			M.add_note(false, 'First note')
			M.add_note(false, 'Second note')

			vim.api.nvim_win_set_cursor(M.window, { 1, 0 })

			M.move_note_up()

			assert.equals('First note', M.notes[1].note)
			assert.equals('Second note', M.notes[2].note)
		end)

		it('should not move last note down', function()
			M.toggle()
			M.add_note(false, 'First note')
			M.add_note(false, 'Second note')

			vim.api.nvim_win_set_cursor(M.window, { 2, 0 })

			M.move_note_down()

			assert.equals('First note', M.notes[1].note)
			assert.equals('Second note', M.notes[2].note)
		end)

		it('should move subnote up within parent', function()
			M.toggle()
			M.add_note(false, 'Parent note')
			vim.api.nvim_win_set_cursor(M.window, { 1, 0 })
			M.add_note(true, 'First child')
			M.add_note(true, 'Second child')
			M.add_note(true, 'Third child')

			vim.api.nvim_win_set_cursor(M.window, { 3, 0 })

			M.move_note_up()

			local parent = M.notes[1]
			assert.equals('Second child', parent.subnotes[1].note)
			assert.equals('First child', parent.subnotes[2].note)
			assert.equals('Third child', parent.subnotes[3].note)

			local lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals('• Parent note', lines[1])
			assert.equals('  • Second child', lines[2])
			assert.equals('  • First child', lines[3])
			assert.equals('  • Third child', lines[4])
		end)

		it('should move subnote down within parent', function()
			M.toggle()
			M.add_note(false, 'Parent note')
			vim.api.nvim_win_set_cursor(M.window, { 1, 0 })
			M.add_note(true, 'First child')
			M.add_note(true, 'Second child')
			M.add_note(true, 'Third child')

			vim.api.nvim_win_set_cursor(M.window, { 3, 0 })

			M.move_note_down()

			local parent = M.notes[1]
			assert.equals('First child', parent.subnotes[1].note)
			assert.equals('Third child', parent.subnotes[2].note)
			assert.equals('Second child', parent.subnotes[3].note)

			local lines = vim.api.nvim_buf_get_lines(M.buffer, 0, -1, false)
			assert.equals('• Parent note', lines[1])
			assert.equals('  • First child', lines[2])
			assert.equals('  • Third child', lines[3])
			assert.equals('  • Second child', lines[4])
		end)

		it('should save notes after moving', function()
			M.toggle()
			M.add_note(false, 'First note')
			M.add_note(false, 'Second note')

			vim.api.nvim_win_set_cursor(M.window, { 2, 0 })
			M.move_note_up()

			assert.equals('Second note', M.notes[1].note)
			assert.equals('First note', M.notes[2].note)

			M.toggle()
			
			vim.wait(100, function() return false end)
			
			assert.truthy(vim.fn.filereadable(M.config.filepath) == 1)
			
			if M.buffer and vim.api.nvim_buf_is_valid(M.buffer) then
				vim.api.nvim_buf_delete(M.buffer, { force = true })
			end
			M.buffer = nil
			
			M.notes = {}
			M.toggle()

			assert.equals(2, #M.notes)
			assert.equals('Second note', M.notes[1].note)
			assert.equals('First note', M.notes[2].note)
		end)

		it('should handle cursor movement after moving note up', function()
			M.toggle()
			M.add_note(false, 'First note')
			M.add_note(false, 'Second note')
			M.add_note(false, 'Third note')

			vim.api.nvim_win_set_cursor(M.window, { 3, 0 })
			local initial_cursor = vim.api.nvim_win_get_cursor(M.window)

			M.move_note_up()

			local final_cursor = vim.api.nvim_win_get_cursor(M.window)
			assert.equals(initial_cursor[1] - 1, final_cursor[1])
		end)

		it('should handle cursor movement after moving note down', function()
			M.toggle()
			M.add_note(false, 'First note')
			M.add_note(false, 'Second note')
			M.add_note(false, 'Third note')

			vim.api.nvim_win_set_cursor(M.window, { 1, 0 })
			local initial_cursor = vim.api.nvim_win_get_cursor(M.window)

			M.move_note_down()

			local final_cursor = vim.api.nvim_win_get_cursor(M.window)
			assert.equals(initial_cursor[1] + 1, final_cursor[1])
		end)

		it('should handle mixed hierarchy movement', function()
			M.toggle()
			M.add_note(false, 'Root 1')
			M.add_note(false, 'Root 2')

			vim.api.nvim_win_set_cursor(M.window, { 1, 0 })
			M.add_note(true, 'Root 1 Child 1')
			M.add_note(true, 'Root 1 Child 2')

			vim.api.nvim_win_set_cursor(M.window, { 4, 0 })
			M.add_note(true, 'Root 2 Child 1')

			vim.api.nvim_win_set_cursor(M.window, { 3, 0 })
			M.move_note_up()

			assert.equals('Root 1 Child 2', M.notes[1].subnotes[1].note)
			assert.equals('Root 1 Child 1', M.notes[1].subnotes[2].note)

			assert.equals('Root 2 Child 1', M.notes[2].subnotes[1].note)
		end)
	end)
end)
