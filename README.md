# completionist.nvim

Completionist is a todo list plugin that keeps a global notepad to help you complete tasks

- Supports infinitely nested items
- Visually discern priority between low, medium, and high priority items
- Mark items as completed and delete them whenever you want
- 

## Installation
You can install completionist.nvim with your favorite plugin manager, as long as you call `setup`. Here is an example in lazy.nvim

```lua
{
  'avegancafe/completionist.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {{
    '<leader>\\',
    function()
      require('completionist').toggle()
    end,
    desc = 'Open completionist.nvim',
    silent = true
  }}
  opts = {}
}
```

## Usage

A key mapping help section is available by pressing `?` when completionist is focused, but here is also a verbal summary of those commands:

- `a` : Add new note to the end of the todo list
- `A` : Add new subnote under the item under the current cursor
- `d` : Delete item under the current cursor
- `x` : Toggle the item under the current cursor as done
- `p` : Set priority of the item under the current cursor
- `q` : Close window
