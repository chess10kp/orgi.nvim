# orgi.nvim

A Neovim plugin for interacting with [orgi](https://github.com/chess10kp/orgi) 

## Requirements

- Neovim 0.10+
- [orgi CLI](https://github.com/chess10kp/orgi) installed and available in PATH
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

## Installation

### Tree-sitter Setup

The plugin includes a tree-sitter grammar for Org mode. To use it:

```lua
require('nvim-treesitter.configs').setup({
  highlight = {
    enable = true,
    custom_captures = {
      ["org"] = "org",
    },
  },
  parser_install_dir = vim.fn.stdpath("data") .. "/site/pack/packer/start/orgi.nvim/parser",
})
```

## Configuration

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `orgi_file` | string | `".orgi/orgi.org"` | Path to the orgi file |
| `auto_refresh` | boolean | `true` | Auto-refresh UI on file changes |
| `colors` | table | See defaults | Highlight groups for states/priorities |

## Usage

### Commands

#### Issue Management

| Command | Description |
|---------|-------------|
| `:OrgiInit` | Initialize orgi in the current directory |
| `:OrgiList [--all\|--open] [file]` | List issues in a picker |
| `:OrgiAdd [title] [body]` | Add a new issue |
| `:OrgiDone <id>` | Mark an issue as done |
| `:OrgiGather [--dry-run]` | Gather TODOs from source code |
| `:OrgiSync [--auto-confirm]` | Sync completed issues back to source |

#### Pull Request Management

| Command | Description |
|---------|-------------|
| `:OrgiPrList` | List pull requests |
| `:OrgiPrCreate <title> <source_branch> [description]` | Create a new PR |
| `:OrgiPrApprove <id>` | Approve a pull request |
| `:OrgiPrDeny <id>` | Deny a pull request |
| `:OrgiPrMerge <id>` | Merge a pull request |

### Picker Actions

In the issue picker:
- `Enter` / `CR`: Show issue details
- `d`: Mark issue as done (in picker)

In the detail popup:
- `d`: Mark issue as done 

Highlight groups

```vim
highlight OrgiTodo guifg=#E5C07B gui=bold
highlight OrgiInProgress guifg=#61AFEF gui=bold
highlight OrgiDone guifg=#98C379 gui=bold
highlight OrgiKill guifg=#E06C75 gui=bold
highlight OrgiPriorityA guifg=#E06C75 gui=bold
highlight OrgiPriorityB guifg=#E5C07B gui=bold
highlight OrgiPriorityC guifg=#98C379 gui=bold
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

GPL V3 License 

## Acknowledgments

- [snacks.nvim](https://github.com/folke/snacks.nvim) 
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
