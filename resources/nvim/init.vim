filetype plugin indent on    " required
syntax on

colorscheme Monokai

set exrc secure " source local init.vim file if present

set number " line numbers

set mouse=a " enable mouse
if &term =~ '^screen'
    " tmux knows the extended mouse mode
    set ttymouse=xterm2
endif

set backspace=indent,eol,start

set tabstop=4     " how many columns a tab counts for
set softtabstop=4 " how many spaces should be treated as a tab
set shiftwidth=4  " how far an indent is with reindent operations
set expandtab     " tab becomes spaces
set autoindent    " applies indent of current line to the next one
set smartindent   " reacts to syntax/style of code

set colorcolumn=80,100,120 " ruler at col 80 and 100
set cursorline " highlight current line

set clipboard=unnamedplus " use system clipboard

set laststatus=2          " make statusline appear even with single window
set statusline=%f         " filename
set statusline+=\ %r%m    " readonly, modified flags
set statusline+=%=        " right align the next part
set statusline+=%y        " filetype
set statusline+=\ (%l,%c) " line number, col number

set hlsearch  " highlight found words on search
set incsearch " jump to best fit
set showmatch " highlight matching parentheses

set showcmd " show commands as they are typed
let mapleader = "," " set leader key to comma

" Remove trailing whitespace
autocmd BufWritePre * :%s/\s\+$//e

" Turn off search highlighting with <CR> (return).
nnoremap <CR> :nohlsearch<CR><CR>

" Set .h files to C by default instead of C++
augroup global
    autocmd!
    autocmd BufRead,BufNewFile *.h set filetype=c
augroup END

" Autoinstall vim-plug
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
  silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

" " Specify plugin directory
call plug#begin()
  " Built-in LSP
  "   run `:help lsp` for more information
  Plug 'neovim/nvim-lspconfig'

  Plug 'kabouzeid/nvim-lspinstall'

  " Neovim Completion Manager
  "   run `:help ncm2` for more information
  Plug 'ncm2/ncm2'
  Plug 'roxma/nvim-yarp'

  "" Completion Sources
  """ General Purpose
  Plug 'ncm2/ncm2-bufword'
  Plug 'ncm2/ncm2-path'

  """ Python
  Plug 'ncm2/ncm2-jedi'

  """ Snippets
  " Plug 'SirVer/ultisnips'
  " Plug 'honza/vim-snippets'

  " Treesitter
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'nvim-treesitter/nvim-treesitter-refactor'
  Plug 'nvim-treesitter/playground'

  " nvim-compe
  "   run `:help compe` for more information
  Plug 'hrsh7th/nvim-compe'

  " Telescope
  "   run `:help telescope` for more information

  "" Dependencies
  Plug 'nvim-lua/popup.nvim'
  Plug 'nvim-lua/plenary.nvim'

  Plug 'nvim-telescope/telescope.nvim'

  " NerdTree (file browser)
  "   run `:help nerdtree` for more information
  Plug 'preservim/nerdtree'

  " TagBar (browse tags of source code files)
  "   run `:help tagbar` for more information
  Plug 'preservim/tagbar'

  " Fugitive (git wrapper for vim)
  "   run `:help fugitive` for more information
  Plug 'tpope/vim-fugitive'

  " NNN (NNN file picker)
  "   run `:help nnn` for more information
  Plug 'mcchrish/nnn.vim'

  " FZF
  "   run `:help fzf` for more information
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

" Initialize the plugin system
call plug#end()

lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  -- ignore_install = { "javascript" }, -- List of parsers to ignore installing
  highlight = {
    enable = false,              -- false will disable the whole extension
    -- disable = { "c", "rust" },  -- list of language that will be disabled
  },
  refactor = {
    smart_rename = {
      enable = true,
      keymaps = {
        smart_rename = "grr",
      },
    },
  },
}

--[[ LSP ]]

local lspconfig = require'lspconfig'

--- ccls for C/C++
lspconfig.ccls.setup{}

--- bashls for Bash scripts
lspconfig.bashls.setup{
  cmd_env = {
    GLOB_PATTERN = "**/*@(.sh|.inc|.bash|.command)"
  }
}

--- pylsp for Python
lspconfig.pylsp.setup{}

vim.o.completeopt = "menuone,noselect"

require'compe'.setup {
  enabled = true;
  autocomplete = true;
  debug = false;
  min_length = 1;
  preselect = 'enable';
  throttle_time = 80;
  source_timeout = 200;
  incomplete_delay = 400;
  max_abbr_width = 100;
  max_kind_width = 100;
  max_menu_width = 100;
  documentation = true;

  source = {
    path = true;
    buffer = true;
    calc = true;
    nvim_lsp = true;
    nvim_lua = true;
  };
}

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-n>"
  elseif check_back_space() then
    return t "<Tab>"
  else
    return vim.fn['compe#complete']()
  end
end
_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-p>"
  else
    -- If <S-Tab> is not working in your terminal, change it to <C-h>
    return t "<S-Tab>"
  end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})

local nnn_actions = {};
nnn_actions['<C-T>'] = 'tab drop';
nnn_actions['<C-X>'] = 'split';
nnn_actions['<C-V>'] = 'vsplit';
require('nnn').setup{
  action = nnn_actions,
  session = 'global',
  layout = { window = { width = 0.9, height = 0.6, highlight = 'Debug' } }
}
EOF

" HotKeys
"   Can see keybindings with `:Telescope keymaps`

"" Run Telescope with ,,
nnoremap <Leader><Leader> :Telescope<CR>

"" I prefer to use FZF for finding files. Can always access this through
"" Telescope
" nnoremap <Leader>f :Telescope find_files<CR>
"" Run FZF with ,f
nnoremap <Leader>f :FZF<CR>

"" Run Telescope live grep with ,g
nnoremap <Leader>g :Telescope live_grep<CR>

"" Run Telescope LSP definitions with ,d
nnoremap <Leader>d :Telescope lsp_definitions<CR>

"" Run Telescope LSP references with ,r
nnoremap <Leader>r :Telescope lsp_references<CR>

"" Run Telescope TreeSitter with ,s
nnoremap <Leader>s :Telescope treesitter<CR>

"" Run NnnPicker with ,n
nnoremap <Leader>n :NnnPicker<CR>

"" Toggle NerdTree with ,t
nnoremap <Leader>t :NERDTreeToggle<CR>

"" Toggle Tagbar with ,b
nnoremap <Leader>b :TagbarToggle<CR>

" Set syntax highlighting for personal extensions
" autocmd BufNewFile,BufRead *.howto set filetype=text
