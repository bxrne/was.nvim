# was.nvim

Neovim plugin to solve "What was I doing here" when moving between dirs

## Features

- Store intentions per workspace (Git root or current directory)
- Persistent storage between Neovim sessions
- Minimal and fast
- Written in pure Lua
- Fully tested

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "bxrne/was.nvim",
  config = true, -- calls setup() automatically
  event = "VeryLazy",
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'bxrne/was.nvim',
  config = function()
    require('was').setup()
  end
}
```

## Usage

Store your current intention:
```vim
:Was Implementing user authentication system
```

View your last stored intention:
```vim
:Was
```

The plugin automatically detects your workspace based on:
1. Git root directory (if in a Git repository)
2. Current working directory (if not in a Git repository)

Intentions are stored persistently in `~/.local/share/nvim/was/intentions.json`.

## Development

### Prerequisites

- Neovim >= 0.8.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (for running tests)

### Running Tests

Install plenary.nvim and run:

```vim
:PlenaryBustedFile tests/was_spec.lua
```

Or using the command line:

```bash
nvim --headless -c "PlenaryBustedFile tests/was_spec.lua" +q
```

### CI

Tests are automatically run on push and pull requests using GitHub Actions.
