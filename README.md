# completionist.nvim

Completionist is a todo list plugin that keeps a global notepad to help you
complete tasks

- Supports infinitely nested items
- Visually discern priority between low, medium, and high priority items
- Mark items as completed and delete them whenever you want
- Display highest priority note in the winbar with full path to root

![image](https://github.com/user-attachments/assets/93ae23ce-d571-4fc9-8624-70798bef52af)

## Installation

You can install completionist.nvim with your favorite plugin manager, as long as
you call `setup`. Here is an example in lazy.nvim

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
  }},
  opts = {
    -- Path to the JSON file where notes are stored
    filepath = vim.fn.stdpath('data') .. '/todolist.json',

    -- Colors for different note states and priorities
    colors = {
      normal = '#ffffff',
      done = '#666666',
      medium = '#ffff00',
      high = '#ff0000',
    },

    icons = {
      -- Icon for bullet points
      bullet = '•',
      -- Icon for completed items
      done = '✗',
    }
  }
}
```

## Usage

A key mapping help section is available by pressing `?` when completionist is
focused, but here is also a verbal summary of those commands:

- `a` : Add new note to the end of the todo list
- `A` : Add new subnote under the item currently under the cursor
- `e` : Edit the current note under the cursor
- `d` : Delete item under the current cursor
- `x` : Toggle the item under the current cursor as done
- `p` : Set priority of the item under the current cursor
- `q` : Close window

### Lualine Integration

You can display the current highest priority task in your lualine status bar.
Here's how to set it up with lazy.nvim:

```lua
{
  'avegancafe/completionist.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  -- ... other completionist config ...
},
{
  'nvim-lualine/lualine.nvim',
  dependencies = { 'avegancafe/completionist.nvim' },
  config = function()
    require('lualine').setup({
      sections = {
        lualine_x = {
          {
            function()
              return require('completionist').current_task()
            end,
            cond = function()
              return require('completionist').current_task() ~= ''
            end,
            color = { fg = '#ff0000' }, -- Red color for high priority tasks
          },
        },
      },
    })
  end,
}
```

This will show the highest priority task in your status line, with the full path
to the root task. The task will only be displayed when there are active tasks
(not empty). The color is set to red to match the high priority color scheme,
but you can customize it to match your theme.

## Contributing

Contributions are welcome! Here's how to get started:

### Setup Development Environment

1. Clone the repository:

```bash
git clone https://github.com/avegancafe/completionist.nvim
cd completionist.nvim
```

2. Install dependencies:

```bash
git submodule update --init
```

### Running Tests

The test suite uses plenary.nvim's test runner. To run tests:

1. Make sure you have plenary.nvim installed and available in your runtime path
2. Run the test command:

```bash
make test
```
